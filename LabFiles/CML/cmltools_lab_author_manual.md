# CML Lab Validation & Import Manual
## For Lab Authors – Scoring & Deployment
This manual is for **lab authors** who need to:
1. **Import** labs into CML
2. **Validate** student configurations
3. **Manually Test** via the pyATS scoring server
4. **CML Configuration** steps for configuring CML devices for scoring

It includes:
- Full **import script** (now supports **multiple labs**)
- Full **validation script with two methods**
- **`device_info` JSON** and **single-device parameter** reference & examples
- Best practices
---
## 1. Lab Import Script (Loader) – Multi-Lab Support
### Full Script: `import_lab.sh`
```bash
#!/bin/bash
# =============================================================================
# CML Multi-Lab Import Script - Silent, Sourced-Safe, Outputs ONLY true/false
# Imports multiple labs from array of URLs. All must succeed → true
# =============================================================================

# Source environment
source "$HOME/labfiles/cml_env.sh" 2>/dev/null || { echo false; return; }

# === DEFINE YOUR LAB URLS HERE ===
LAB_URLS=(
  "https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/LabFiles/CCNA.1/Sample_Lab_1.yaml"
  "https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/LabFiles/CCNA.1/CCNA.1-LAB2.yaml"
  # Add more URLs as needed
)

MAX_RETRIES=3
RETRY_DELAY=5

# Function: Import one lab, return 0 on success, 1 on failure
import_single_lab() {
  local url="$1"
  local attempt=1

  while [ $attempt -le $MAX_RETRIES ]; do
    LAB_ID=$(cmltools importlab -source "$url" 2>/dev/null | head -n1)

    if [[ "$LAB_ID" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
      return 0  # Success (new or reused)
    fi

    ((attempt++))
    [ $attempt -le $MAX_RETRIES ] && sleep $RETRY_DELAY
  done

  return 1  # All retries failed
}

# Main: Try to import ALL labs
main() {
  for url in "${LAB_URLS[@]}"; do
    if ! import_single_lab "$url"; then
      return 1  # Any failure → overall failure
    fi
  done
  return 0  # All succeeded
}

# Run and capture result
main
result=$?

# Output ONLY true or false
if [ $result -eq 0 ]; then
  echo "true"
else
  echo "false"
fi
```
---
### How to Modify for Your Labs
1. **Edit the `LAB_URLS` array**:
   ```bash
   LAB_URLS=(
     "https://raw.githubusercontent.com/yourorg/yourrepo/main/LabFiles/CCNA.1/CCNA.1-LAB1.yaml"
     "https://raw.githubusercontent.com/yourorg/yourrepo/main/LabFiles/CCNA.2/CCNA.2-LAB1.yaml"
     "https://raw.githubusercontent.com/yourorg/yourrepo/main/LabFiles/CCNP/CCNP-LAB3.yaml"
   )
   ```
2. **Script Behavior**:
   - Loops through **all URLs**
   - **All must succeed** → `true`
   - **Any failure** → `false`
   - **Idempotent**: skips already-imported labs by title
---
### Lab Title Rules
- **Must be unique** in CML
- **Case-sensitive**
- **Recommended formats**:
  - `CCNA.1-LAB2` (matches Skillable Lab ID)
  - `Lab` (generic, one lab only)
  - `Lab1`, `Lab2` (for multi-lab)
> **Best Practice**: Use **LAB** as title (Allows easier copy/paste of validation code. Just need to focus on device_info.)
> **Avoid**: Duplicates → import skipped
---
### Credential Best Practice
- Use **`cisco / cisco`** for **all devices**
- **Only override** in `device_info` if **required**
---
## 2. Validation Script – **Preferred Method: Single-Device Parameters**
> **NEW PREFERRED METHOD**: Use **command-line parameters** for **single-device, single-command** validations.  
> - Simpler to write  
> - Less JSON escaping  
> - Easier to debug  
> - Ideal for 90% of lab tasks  
>  
> **Use `device_info` JSON only** when:
> - Validating **multiple devices**
> - Running **multiple commands** on one device
> - Needing **complex credential overrides**

### Full Script: `validate_lab_single.sh` (Single-Device Preferred)
```bash
#!/bin/bash
#
# Title: Verify "show version" on SWITCH1 contains Cisco IOS
# Description: Runs command and validates output using wildcard or regex
# Target: PyATS Scoring VM
# Version:  2025.11.02 - Template.v5
#
# Parameters (set in lab definition)
labID="CCNA.1-LAB2"
device="switch1"
username=""
password=""
command="show version"
pattern="cisco*ios"
timeout=""
regex=false
script_debug=false
# ------------------------------------------------------------------
# Update labID with the "Title" of the lab to be evaluated
# Update device with the name of the device for commands to be run on
# Update command with the command to execute
# Add a username and password if the default username and password of cisco/cisco is not used
#    (Leave blank to use the default cisco/cisco credentials)
# Update pattern with the string to find in the return results
#    (Leave pattern blank to return the full response of the command)
# pattern examples:
#   "cisco*ios"          - wildcard (default)
#   "^Version 15\."      - regex (when regex=true)
#   "Cisco.*IOS"         - regex (when regex=true)
# If regex is false, wildcard matching is used with ? for single or * for multiple characters
# If regex is true, full regex matching is performed
# Set timeout to 0 for commands that would hang the interface like 'exit'. Default is 60 when blank.
# Set script_debug to true for verbose output
# ------------------------------------------------------------------

# Set default result
result="false"

# === Main routine ===
main() {
    [[ "$script_debug" == "true" ]] && echo "=== Begin validation ==="

    # Source environment
    if ! source "$HOME/labfiles/cml_env.sh" 2>/dev/null; then
        [[ "$script_debug" == "true" ]] && echo "FAIL: cannot source cml_env.sh" >&2
        echo "false"
        return 1
    fi
    [[ "$script_debug" == "true" ]] && echo "cml_env.sh loaded"

    # Build cmltools command(s)
    cmd=(cmltools validate -labid "$labID" -devicename "$device" -command "$command")

    # Add --regex if enabled
    [[ "$regex" == "true" ]] && cmd+=(--regex)
    
    # Add -username only if not empty
    [[ -n "$username" ]] && cmd+=(-username "$username")
    
    # Add -password only if not empty
    [[ -n "$password" ]] && cmd+=(-password "$password")
    
    # Add -pattern only if not empty
    [[ -n "$pattern" ]] && cmd+=(-pattern "$pattern")

    # Add -timeout only if not empty
    [[ -n "$timeout" ]] && cmd+=(-timeout "$timeout")    

    [[ "$script_debug" == "true" ]] && echo "Running: ${cmd[*]}"

    # Execute
    if [[ "$script_debug" == "true" ]]; then
        full_output=$( "${cmd[@]}" )
        exit_code=$?
    else
        full_output=$( "${cmd[@]}" 2>/dev/null )
        exit_code=$?
    fi

    # Debug output
    [[ "$script_debug" == "true" ]] && echo "$full_output"

    # Final result
    if [[ $exit_code -ne 0 ]]; then
        echo "false"
        return 1
    fi

    final_line=$(echo "$full_output" | tail -n1)
    final_line_lower="${final_line,,}"

    if [[ "$final_line_lower" == "true" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# === Execute safely ===
if [[ "$script_debug" == "true" ]]; then
    result=$(main)
else
    result=$(main 2>/dev/null) || result="false"
fi

# Final output: only true or false
echo "$result"
```
---
### Single-Device Parameter Examples
#### 1. **Basic IOS Version Check**
```bash
labID="CCNA.1-LAB2"
device="switch1"
command="show version"
pattern="cisco*ios"
regex=false
```

#### 2. **Interface Up/Up**
```bash
labID="Lab1"
device="R1"
command="show ip interface brief"
pattern="GigabitEthernet0/0*up*up"
regex=false
```

#### 3. **OSPF Neighbor Full**
```bash
labID="Lab2"
device="R2"
command="show ip ospf neighbor"
pattern="*FULL*"
regex=false
```

#### 4. **Linux Host Kernel**
```bash
labID="LinuxLab"
device="HOST1"
username="admin"
password="cisco"
command="uname -a"
pattern="*Linux*x86_64*"
regex=false
```

#### 5. **Regex: IOS XE Version**
```bash
labID="Lab3"
device="R5"
command="show version"
pattern="^Cisco IOS XE.*17\.\d+\.\d+"
regex=true
```

#### 6. **No Validation – Return Raw Output**
```bash
labID="DebugLab"
device="R1"
command="show running-config"
pattern=""
regex=false
```
> Output: Full command output (no `True`/`False`)

#### 7. **Send Command, No Wait**
```bash
labID="Lab4"
device="R1"
command="configure terminal ; interface Gi0/0 ; shutdown"
pattern=""
regex=false
# Add: cmd+=(-timeout 0) in script
```
> Use `-timeout 0` to send config without waiting

#### 9. **BGP Established – Multiple Neighbors (Comma-Separated Commands)**
```bash
labID="BGP-Lab"
device="R1"
command="show ip bgp summary"
pattern="1.1.1.1*Established,2.2.2.2*Established"
regex=false
```

#### 10. **EIGRP Adjacency – Two Neighbors**
```bash
labID="EIGRP-Lab"
device="R3"
command="show ip eigrp neighbors"
pattern="1.1.1.1*00:0?*H,2.2.2.2*00:0?*H"
regex=false
```

#### 11. **VLAN Exists on Trunk – `show interfaces trunk`**
```bash
labID="TrunkLab"
device="SW1"
command="show interfaces trunk"
pattern="Gi1/0/1*allowed VLANs*10,20,30"
regex=false
```

#### 12. **Port-Channel Load-Balancing Method**
```bash
labID="PoLab"
device="CORE1"
command="show etherchannel load-balance"
pattern="src-dest-ip"
regex=false
```

#### 13. **HSRP Active on Primary Router**
```bash
labID="HSRP-Lab"
device="R1"
command="show standby brief"
pattern="Gi0/0*10*Active*local*1.1.1.1"
regex=false
```

#### 14. **DHCP Server – Pool Configured**
```bash
labID="DHCP-Lab"
device="R4"
command="show running-config | section ip dhcp pool"
pattern="network 192.168.10.0 255.255.255.0"
regex=false
```

#### 15. **Linux – Specific Process Running**
```bash
labID="LinuxLab"
device="HOST2"
username="admin"
password="cisco"
command="ps aux | grep nginx"
pattern="*nginx: master process*"
regex=false
```

---
### Full Script: `validate_lab.sh` (Legacy – Multi-Device JSON)
```bash
#!/bin/bash
# Title: Device Configuration Validation (Container-Safe)
# Description: Validates CML lab devices - safe for textbox injection
# This will run as a Lab Activity for validation purposes in a running lab
# Target: PyATS scoring VM
# Version: 2025.10.28 - Container.v6.0
# ==== LAB-SPECIFIC VALUES ====
LAB_ID="CCNA.1-LAB2"
# match_type can be wildcard,regex or exact
# device names are case-insensitive
# credentials are only required if not using the cisco/cisco default
device_info=$(cat << 'EOF'
[
    {
        "device_name": "switch1",
        "commands": [
            {
                "command": "show version",
                "validations": [
                    {
                        "pattern": "Cisco IOS Software",
                        "match_type": "wildcard"
                    }
                ]
            }
        ]
    },
    {
        "device_name": "HOST1",
        "credentials": {
            "username": "admin",
            "password": "cisco"
        },
        "commands": [
            {
                "command": "uname -a",
                "validations": [
                    {
                        "pattern": "*Linux*",
                        "match_type": "wildcard"
                    }
                ]
            }
        ]
    }
]
EOF
)
# =======================================================
# === CONTROL VARIABLES (hard-coded) ===
scriptDebug="false" # "true" = show debug + errors
showDevices="true" # "true" = show device lines (unless debug off)
# Normalize
scriptDebug="${scriptDebug,,}"
showDevices="${showDevices,,}"
# === Main routine ===
main() {
    # Debug header
    [[ "$scriptDebug" == "true" ]] && echo "=== Begin validation ==="
    # 1. Source environment
    if ! source "$HOME/labfiles/cml_env.sh" 2>/dev/null; then
        [[ "$scriptDebug" == "true" ]] && echo "FAIL: cannot source cml_env.sh" >&2
        echo "false"
        return
    fi
    [[ "$scriptDebug" == "true" ]] && echo "cml_env.sh loaded"
    # 2. Run cmltools - redirect stderr based on debug
    if [[ "$scriptDebug" == "true" ]]; then
        full_output=$(cmltools validate -labid "$LAB_ID" -deviceinfo "$device_info")
        exit_code=$?
    else
        full_output=$(cmltools validate -labid "$LAB_ID" -deviceinfo "$device_info" 2>/dev/null)
        exit_code=$?
    fi
    # 3. Show device lines if allowed
    if [[ "$showDevices" == "true" || "$scriptDebug" == "true" ]]; then
        echo "$full_output" | grep -E "(Correctly|Incorrectly) Configured" || true
    fi
    # 4. Final result: check both output and exit code
    final_line=$(echo "$full_output" | tail -n1)
    final_line_lower="${final_line,,}"
    # If cmltools failed (non-zero exit), force false
    if [[ $exit_code -ne 0 ]]; then
        echo "false"
        return
    fi
    # Otherwise, use the actual result
    if [[ "$final_line_lower" == "true" ]]; then
        echo "true"
    else
        echo "false"
    fi
}
# === Execute ===
main
```
---
### How to Modify
1. **Change `LAB_ID`**:
   ```bash
   LAB_ID="CCNA.2-LAB1"
   ```
2. **Edit `device_info`** (see below)
---
## `device_info` JSON – Full Reference
### Core Structure
```json
[
  {
    "device_name": "string",
    "credentials": {
      "username": "string",
      "password": "string"
    },
    "commands": [
      {
        "command": "string",
        "validations": [
          {
            "pattern": "string",
            "match_type": "wildcard"
          }
        ]
      }
    ]
  }
]
```
---
### Field Details
| Field | Required | Default | Notes |
|------|----------|--------|-------|
| `device_name` | Yes | — | **Exact** from testbed |
| `credentials` | **Only if changed** | `cisco/cisco` | Override login |
| `command` | Yes | — | CLI command |
| `validations` | Yes | — | Output checks |
> **Omit any property** → default used
> **Use full names** in examples
---
### Wildcard Matching (Recommended)
| Symbol | Meaning |
|-------|--------|
| `*` | Zero or more chars |
| `?` | Exactly one char |
---
### `device_info` Examples
#### 1. **IOS Router: Interface Up (Verbose)**
```json
[
  {
    "device_name": "R1",
    "commands": [
      {
        "command": "show ip interface brief",
        "validations": [
          {
            "pattern": "GigabitEthernet0/0*up*up",
            "match_type": "wildcard"
          }
        ]
      }
    ]
  }
]
```
---
#### 2. **IOS Router: OSPF Neighbor**
```json
[
  {
    "device_name": "R2",
    "commands": [
      {
        "command": "show ip ospf neighbor",
        "validations": [
          {
            "pattern": "1.1.1.1*FULL*DR*00:0?*",
            "match_type": "wildcard"
          }
        ]
      }
    ]
  }
]
```
---
#### 3. **IOS Switch: VLAN Configured**
```json
[
  {
    "device_name": "SW1",
    "commands": [
      {
        "command": "show vlan brief",
        "validations": [
          {
            "pattern": "10*Sales*active",
            "match_type": "wildcard"
          }
        ]
      }
    ]
  }
]
```
---
#### 4. **IOS Switch: Port-Channel Up**
```json
[
  {
    "device_name": "CORE1",
    "commands": [
      {
        "command": "show etherchannel summary",
        "validations": [
          {
            "pattern": "1*Po1(SU)*LACP*Gi1/0(P)*Gi1/1(P)",
            "match_type": "wildcard"
          }
        ]
      }
    ]
  }
]
```
---
#### 5. **Linux Host: Kernel & Hostname**
```json
[
  {
    "device_name": "HOST1",
    "credentials": {
      "username": "admin",
      "password": "cisco"
    },
    "commands": [
      {
        "command": "uname -a",
        "validations": [
          {
            "pattern": "*Linux*",
            "match_type": "wildcard"
          },
          {
            "pattern": "*x86_64*",
            "match_type": "wildcard"
          }
        ]
      },
      {
        "command": "hostname",
        "validations": [
          {
            "pattern": "HOST1",
            "match_type": "exact"
          }
        ]
      }
    ]
  }
]
```
---
#### 6. **IOS Router: BGP Established (Simple String – No `pattern`/`match_type`)**
```json
[
  {
    "device_name": "R3",
    "commands": [
      {
        "command": "show ip bgp summary",
        "validations": [
          "2.2.2.2*Established"
        ]
      }
    ]
  }
]
```
> **Note**: This is the **only example** omitting `pattern` and `match_type` — it defaults to `wildcard`.
---
#### 7. **IOS Switch: STP Root Bridge**
```json
[
  {
    "device_name": "DIST1",
    "commands": [
      {
        "command": "show spanning-tree",
        "validations": [
          {
            "pattern": "Root ID*This bridge is the root",
            "match_type": "wildcard"
          }
        ]
      }
    ]
  }
]
```
---
#### 8. **IOS Router: DHCP Binding**
```json
[
  {
    "device_name": "R4",
    "commands": [
      {
        "command": "show ip dhcp binding",
        "validations": [
          {
            "pattern": "192.168.10.10*hardware address*0100.50b7.*",
            "match_type": "wildcard"
          }
        ]
      }
    ]
  }
]
```
---
#### 9. **Regex Example: IOS XE Version**
```json
[
  {
    "device_name": "R5",
    "commands": [
      {
        "command": "show version",
        "validations": [
          {
            "pattern": "^Cisco IOS XE Software, Version 17\\.\\d+\\.\\d+",
            "match_type": "regex"
          }
        ]
      }
    ]
  }
]
```
---
#### 10. **Regex Example: NTP Sync**
```json
[
  {
    "device_name": "R6",
    "commands": [
      {
        "command": "show ntp associations",
        "validations": [
          {
            "pattern": "^\\*~[0-9.]+.*\\+.*\\d+",
            "match_type": "regex"
          }
        ]
      }
    ]
  }
]
```
---
### Auto-Start & Free SKU
- **Lab not running?** → `cmltools validate` starts it
- **CML Free**: Only **one lab** can run
  - `startlab` → stops **all others**
  - Safe for scoring
---
## Best Practices
| Do | Don't |
|----|-------|
| Use **single-device parameters** for simple tasks | Use JSON for single command |
| Use **wildcard strings** | Overuse regex |
| Use **cisco/cisco** | Change creds unless required |
| Match **Skillable Lab ID** | Duplicate titles |
| Test with `--debug` | Assume success |
---
## Manual Validation Testing on the pyATS VM
While developing and debugging your validations, you can **run `cmltools validate` directly on the pyATS VM** — no need to wait for lab deployment.
Follow these steps:
---
### Step 1: Log into the pyATS VM
- SSH or console into the **pyATS scoring VM**
- Ensure `cmltools` is available (from `cml_env.sh`)
---
### Step 2: Quick CLI Test (Single-Device Parameters – Preferred)
```bash
cmltools validate -labid "CCNA.1-LAB2" \
  -devicename "R1" \
  -command "show ip interface brief" \
  -pattern "GigabitEthernet0/0*up*up" \
  --debug
```
> **No JSON needed!**

### Step 3: Quick CLI Test (Compressed JSON)
Use **inline JSON** with `-deviceinfo` for fast iteration.
```bash
cmltools validate -labid "CCNA.1-LAB2" -deviceinfo '[
  {
    "device_name": "R1",
    "commands": [
      {
        "command": "show ip interface brief",
        "validations": [
          { "pattern": "GigabitEthernet0/0*up*up", "match_type": "wildcard" }
        ]
      }
    ]
  }
]' --debug
```
> **Tip**: Use single quotes to avoid shell escaping
---
### Step 4: Multi-Line JSON via Variable (Like the Script)
Replicate the **validation script’s style** using `cat << 'EOF'`.
```bash
device_info=$(cat << 'EOF'
[
  {
    "device_name": "SW1",
    "commands": [
      {
        "command": "show vlan brief",
        "validations": [
          { "pattern": "10*Sales*active", "match_type": "wildcard" },
          { "pattern": "20*Voice*active", "match_type": "wildcard" }
        ]
      }
    ]
  },
  {
    "device_name": "HOST1",
    "credentials": { "username": "admin", "password": "cisco" },
    "commands": [
      {
        "command": "uname -a",
        "validations": [
          { "pattern": "*Linux*", "match_type": "wildcard" }
        ]
      }
    ]
  }
]
EOF
)
# Now run
cmltools validate -labid "CCNA.1-LAB2" -deviceinfo "$device_info" --debug
```
---
### Step 5: Auto-Start Lab (If Stopped)
If the lab is **not running**, `cmltools validate` will:
- Automatically start it
- Wait up to 5 minutes
- Proceed with validation
No extra steps needed.
---
### Step 6: Debug Output
Use `--debug` **only during troubleshooting** — it produces **extensive logs** (testbed, connections, full output).
Look for:
```text
INFO - Executing command on R1: show ip interface brief
INFO - Validation passed: GigabitEthernet0/0*up*up
Correctly Configured - R1 - show ip interface brief
```
> **Warning**: `--debug` is **not for general use** — output is overwhelming in production.
---
### Step 7: Validate Multiple Labs Sequentially
Run **Lab1**, then **Lab2** — **first lab auto-stops** before second starts (CML Free SKU).
```bash
# Lab1
cmltools validate -labid "Lab1" -devicename "R1" -command "show version" -pattern "cisco*"
# Lab2 (Lab1 stops automatically)
cmltools validate -labid "Lab2" -devicename "SW1" -command "show vlan brief" -pattern "10*active"
```
> **CML Free**: Only **one lab** runs at a time.
> `cmltools` handles stop/start safely.
---
### Additional Examples
#### Example 1: **Router BGP Peer (Parameters)**
```bash
cmltools validate -labid "Lab1" \
  -devicename "R1" \
  -command "show ip bgp summary" \
  -pattern "2.2.2.2*Established"
```
---
#### Example 2: **Switch Port Security (JSON)**
```bash
device_info=$(cat << 'EOF'
[
  {
    "device_name": "SW2",
    "commands": [
      {
        "command": "show port-security interface Gi1/0/1",
        "validations": [
          { "pattern": "Port Security*Enabled", "match_type": "wildcard" },
          { "pattern": "Maximum MAC Addresses*1", "match_type": "wildcard" }
        ]
      }
    ]
  }
]
EOF
)
cmltools validate -labid "Lab2" -deviceinfo "$device_info"
```
---
#### Example 3: **Linux Disk Usage (Parameters)**
```bash
cmltools validate -labid "Lab1" \
  -devicename "HOST1" \
  -username "admin" \
  -password "cisco" \
  -command "df -h /" \
  -pattern "/dev/sda1*ext4*/*50%*"
```
#### Example 4: **Switch VLAN Check – Ultra-Minimal JSON (Single Line, No `pattern`/`match_type`)**
Omit `pattern` and `match_type` — **defaults to `wildcard`**.
```bash
cmltools validate -labid "Lab1" -deviceinfo '[{"device_name":"SW1","commands":[{"command":"show vlan brief","validations":["10*Sales*active"]}]}]'
```
> **Confirmed**:
> - `"10*Sales*active"` → treated as **`wildcard`**
> - No `pattern` or `match_type` needed
> - Valid, minimal, single-line JSON
---
#### Example 5: **BGP Established – Multiple Neighbors (Parameters)**
```bash
cmltools validate -labid "BGP-Lab" \
  -devicename "R1" \
  -command "show ip bgp summary" \
  -pattern "1.1.1.1*Established,2.2.2.2*Established"
```
---
#### Example 6: **EIGRP Adjacency – Two Neighbors**
```bash
cmltools validate -labid "EIGRP-Lab" \
  -devicename "R3" \
  -command "show ip eigrp neighbors" \
  -pattern "1.1.1.1*00:0?*H,2.2.2.2*00:0?*H"
```
---
#### Example 7: **VLAN Exists on Trunk**
```bash
cmltools validate -labid "TrunkLab" \
  -devicename "SW1" \
  -command "show interfaces trunk" \
  -pattern "Gi1/0/1*allowed VLANs*10,20,30"
```
---
#### Example 8: **Port-Channel Load-Balancing Method**
```bash
cmltools validate -labid "PoLab" \
  -devicename "CORE1" \
  -command "show etherchannel load-balance" \
  -pattern "src-dest-ip"
```
---
#### Example 9: **HSRP Active on Primary Router**
```bash
cmltools validate -labid "HSRP-Lab" \
  -devicename "R1" \
  -command "show standby brief" \
  -pattern "Gi0/0*10*Active*local*1.1.1.1"
```
---
#### Example 10: **DHCP Server – Pool Configured**
```bash
cmltools validate -labid "DHCP-Lab" \
  -devicename "R4" \
  -command "show running-config | section ip dhcp pool" \
  -pattern "network 192.168.10.0 255.255.255.0"
```
---
### Pro Tips for Testing
| Task | Command |
|------|--------|
| **Check testbed** | `cmltools gettestbed "Lab2" --debug > testbed.yaml` |
| **List devices** | `yq '.devices | keys' testbed.yaml` |
| **Find lab ID** | `cmltools findlab "CCNA"` |
| **Start lab** | `cmltools startlab "Lab2"` |
---
**You’re now ready to test validations in real time.**
---
## 4. CML Configuration
### Switch and Router config updates
- Leave the default username and password set to cisco / cisco. Otherwise, you will need to add the modified username and password to the validation script settings.
- For the **command** variable in the validation script, use `enable\nshow history all` to retrieve all of the previously entered commands. Set the **pattern** variable to the string you want to search for in the output.

### Linux host configuration
- Leave the default username and password set to cisco / cisco. Otherwise, you will need to add the modified username and password to the validation script settings.
- For the **command** variable in the validation script, use `cat /home/admin/.ash_history` to retrieve all of the previously entered commands. Set the **pattern** variable to the string you want to search for in the output.
---
**You're ready to author and score labs.**
