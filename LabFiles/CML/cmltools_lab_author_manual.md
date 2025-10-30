# CML Lab Validation & Import Manual  
## For Lab Authors – Scoring & Deployment  

This manual is for **lab authors** who need to:
1. **Import** labs into CML
2. **Validate** student configurations

It includes:
- Full **import script** (now supports **multiple labs**)
- Full **validation script**
- `device_info` JSON **reference & examples**
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

> **Best Practice**: Use **Skillable Lab ID** as title  
> **Avoid**: Duplicates → import skipped

---

### Credential Best Practice

- Use **`cisco / cisco`** for **all devices**
- **Only override** in `device_info` if **required**

---

## 2. Validation Script

### Full Script: `validate_lab.sh`

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
scriptDebug="false"    # "true" = show debug + errors
showDevices="true"     # "true" = show device lines (unless debug off)

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
| Use **wildcard strings** | Overuse regex |
| Use **cisco/cisco** | Change creds unless required |
| Match **Skillable Lab ID** | Duplicate titles |
| Test with `--debug` | Assume success |

---

**You're ready to author and score labs.**
