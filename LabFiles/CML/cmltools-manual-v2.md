# CML Tools – Complete User Manual
## `cmltools.py` + Lab Validation Environment
This manual describes the **full workflow** for using `cmltools` in **Cisco Modeling Labs (CML)** lab environments. It covers **setup**, **commands**, **validation**, and the **`device_info` JSON format** with **real-world examples**.
---
## Overview
`cmltools` is a **Python-based CLI tool** that runs on a **PyATS scoring VM** inside CML labs. It:
- Imports labs from GitHub
- Starts/stops labs
- Generates PyATS testbeds
- Validates device configuration via **custom or auto-generated** checks
- Supports **optional credential overrides**
- Returns `true`/`false` for **scoring**
All scripts are **container-safe**, **idempotent**, and **debuggable**.
[cmltools reference `cmltools_setup.sh`](https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/LabFiles/CML/cmltools_setup.sh)
---
## Environment Setup
### 1. **Lifecycle Action: `cmltools_setup.sh`**
Runs on VM boot:
- Downloads `cmltools_setup.sh` from GitHub
- Executes it with `CML_IP`, `CML_USERNAME`, `CML_PASSWORD`
- Creates:
  - `~/labfiles/cml_env.sh` (env vars + `cmltools()` wrapper)
  - `~/labfiles/cmltools.py` (main tool)
- Appends `source ~/labfiles/cml_env.sh` to `~/.bashrc`
**Result**: `cmltools` command is available in shell.
[cmltools Loader LCA `cmltools_setup_loader_LCA.sh`](https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/LabFiles/CML/cmltools_setup_loader_LCA.sh)
---
### 2. **Lifecycle Action: Lab Import**
^^^bash
cmltools importlab -source "https://github.com/..."
^^^
- Downloads `.yaml`, `.cml`, or `.zip`
- Converts GitHub blob to raw URL
- Imports into CML
- **Idempotent**: reuses existing lab by title
- Returns lab UUID
[CML lab import LCA `cmltools_lab_loader_LCA.sh`](https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/LabFiles/CML/cmltools_lab_loader_LCA.sh)
---
### 3. **Validation Script**
^^^bash
cmltools validate -labid "LAB_ID" -deviceinfo "$device_info"
^^^
- Starts lab if stopped
- Fetches PyATS testbed
- Applies optional credential overrides from `device_info`
- Runs commands and validates output
- Prints `Correctly/Incorrectly Configured` lines
- Final line: `True` or `False`
[Lab Activity example `cmltools_scoring_example.sh`](https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/LabFiles/CML/cmltools_scoring_example.sh)
---
## `cmltools` Commands
| Command | Args | Description |
|--------|------|-----------|
| `authenticate` | — | Get JWT token |
| `findlab` | [title] | Find lab by title or first running |
| `getlabs` | — | List all labs |
| `getdetails` | labid | Full lab JSON |
| `getstate` | labid | Lab state |
| `startlab` | labid | Start lab |
| `stoplab` | labid | Stop lab |
| `gettestbed` | labid | PyATS YAML |
| `validate` | labid, --deviceinfo or -devicename/-command/etc. | **Scoring** |
| `importlab` | -source URL | Import lab |
Use `--debug` for verbose logs.
### `cmltools` Commands – Detailed Reference
Below is a **complete, expanded reference** for every `cmltools` command, including:
- **Purpose**
- **Syntax**
- **Arguments**
- **Return values**
- **Examples**
- **Debug tips**
All commands support `--debug` for verbose logging. Commands and parameter names are case-insensitive.
---
#### `authenticate`
^^^bash
cmltools authenticate
^^^
**Purpose**:
Authenticate with CML and return the **JWT token** (used internally by all other commands).
**Returns**:
- JWT token string on success
- Empty string on failure
**Use Case**:
Rarely needed manually — used by other commands via `ensure_jwt()`.
**Example**:
^^^bash
cmltools authenticate
# eyJhbGciOiJIUzI1NiIs...
^^^
---
#### `findlab` [title]
^^^bash
cmltools findlab [title]
^^^
**Purpose**:
Find a lab by **title** or return the **first running lab**.
**Arguments**:
- `title` (optional): exact or partial lab title
**Returns**:
- Lab UUID if found
- Empty string if not
**Behavior**:
- If no title: returns first **running** lab
- If title: case-insensitive partial match
- Falls back to first **available** lab if no running
**Examples**:
^^^bash
# Find by title
cmltools findlab "CCNA Lab"
# Find first running
cmltools findlab
^^^
---
#### `getlabs`
^^^bash
cmltools getlabs
^^^
**Purpose**:
List **all labs** in CML with ID, title, and state.
**Returns**:
Pretty-printed JSON array
**Example**:
^^^bash
cmltools getlabs
^^^
^^^json
[
  {
    "id": "b70cc0d4-...",
    "lab_title": "Lab2",
    "state": "STARTED"
  }
]
^^^
---
#### `getdetails` <labid>
^^^bash
cmltools getdetails <labid>
^^^
**Purpose**:
Fetch **full lab topology** including nodes, configs, and connections.
**Arguments**:
- `labid`: UUID or title
**Returns**:
Full JSON from `/api/v0/labs/{labid}`
**Use Case**:
Debugging node labels, startup-config, IP addresses
**Example**:
^^^bash
cmltools getdetails Lab2 > lab_details.json
^^^
---
#### `getstate` <labid>
^^^bash
cmltools getstate <labid>
^^^
**Purpose**:
Check if lab is `STARTED`, `STOPPED`, etc.
**Arguments**:
- `labid`: UUID or title
**Returns**:
- `STARTED`, `STOPPED`, `DEFINED`, etc.
**Example**:
^^^bash
cmltools getstate Lab2
# STARTED
^^^
---
#### `startlab` <labid>
^^^bash
cmltools startlab <labid>
^^^
**Purpose**:
Start a lab. **Free SKU**: stops all other labs first.
**Arguments**:
- `labid`: UUID or title
**Returns**:
- `true` on success
- `false` on failure
**Behavior**:
- Polls every 10s up to 30 times
- Enforces **Free SKU compliance**
**Example**:
^^^bash
cmltools startlab "My Lab"
^^^
---
#### `stoplab` <labid>
^^^bash
cmltools stoplab <labid>
^^^
**Purpose**:
Stop a running lab.
**Arguments**:
- `labid`: UUID or title
**Returns**:
- `true` on success
- `false` on failure
**Example**:
^^^bash
cmltools stoplab Lab2
^^^
---
#### `gettestbed` <labid>
^^^bash
cmltools gettestbed <labid>
^^^
**Purpose**:
Generate **PyATS testbed YAML** with:
- Device connections
- Terminal server proxy
- **Injected credentials** (from `device_info` or defaults)
**Arguments**:
- `labid`: UUID or title
**Returns**:
- Full testbed YAML
**Example**:
^^^bash
cmltools gettestbed Lab2 --debug > testbed.yaml
^^^
---
#### `validate` <labid> [--deviceinfo] or [-devicename] [...]
^^^bash
cmltools validate -labid <labid> -deviceinfo "$device_info"
^^^
or
^^^bash
cmltools validate -labid <labid> -devicename <name> -command <cmd> -pattern <pat> [-timeout <sec>] [--regex] [-username <user>] [-password <pass>]
^^^
**Purpose**:
**Scoring command** — runs validation and returns `True`/`False`.
**Arguments**:
- `-labid`: required (UUID or title)
- `-deviceinfo`: optional JSON string for multi-device/complex validations
- For single-device: `-devicename` (required), `-command` (comma-separated), `-pattern` (optional), `-timeout` (default 60, 0 to send without waiting), `--regex` (use regex instead of wildcard), `-username`/-password (optional overrides)
**Behavior**:
1. Starts lab if stopped
2. Gets testbed
3. Applies credentials if provided
4. Runs commands
5. Validates output if pattern given
6. Prints per-check results
7. Final line: `True` or `False`
If no pattern, returns raw output instead of True/False.
**Example (JSON)**:
^^^bash
cmltools validate -labid Lab2 -deviceinfo "$device_info" --debug
^^^
**Example (Parameters)**:
^^^bash
cmltools validate -labid "CCNA.1-LAB2" -devicename "switch1" -command "show version" -pattern "cisco*ios" --debug
^^^
**Output**:
```
Correctly Configured - HOST1 - uname -a
Incorrectly Configured - SWITCH1 - connect_failed
False
```
---
#### `importlab` -source <url>
^^^bash
cmltools importlab -source <url>
^^^
**Purpose**:
**One-step import** from GitHub (`.yaml`, `.cml`, `.zip`).
**Arguments**:
- `-source`: public GitHub URL
**Features**:
- Converts `blob` → `raw`
- Extracts from ZIP
- **Idempotent**: reuses lab by title
- Returns lab UUID
**Example**:
^^^bash
cmltools importlab -source "https://github.com/user/lab/blob/main/mylab.yaml"
^^^
---
### Pro Tips
- Use `--debug` **always** during development
- Pipe output: `cmltools validate ... | grep Configured`
- Combine with `findlab`:
  ^^^bash
  LAB_ID=$(cmltools findlab "My Lab")
  cmltools validate -labid "$LAB_ID"
  ^^^
- For multi-lab import, use a loop or array in bash:
  ^^^bash
  LAB_URLS=("url1" "url2")
  for url in "${LAB_URLS[@]}"; do
    cmltools importlab -source "$url"
  done
  ^^^
---
## `device_info` JSON Format
A **list** of device validation objects. Use for multi-device or complex validations; for single-device, prefer command-line parameters.
### Core Fields
| Field | Required | Type | Default | Notes |
|------|----------|------|--------|-------|
| `device_name` | Yes | string | — | Exact name from testbed |
| `credentials` | No | object | Testbed defaults | Optional override |
| `commands` | Yes | array | — | List of commands |
| `command` | Yes | string | — | CLI command |
| `validations` | Yes | array | — | Output checks |
---
### `validations` – Flexible Syntax
**Option 1: Simple String List** (Recommended)
^^^json
"validations": [
  "*Linux*",
  "*x86_64*"
]
^^^
→ Each string is **wildcard**
→ `match_type` **optional**, defaults to `wildcard`
**Option 2: Dict with Explicit `match_type`**
^^^json
"validations": [
  { "pattern": "^Linux.*x86_64", "match_type": "regex" },
  { "pattern": "HOST1", "match_type": "exact" }
]
^^^
---
## `match_type` Options
| Type | Behavior | Example |
|------|---------|--------|
| `wildcard` | `*` = any, `?` = one | `"*Linux*"` |
| `regex` | Full regex | `"^Linux.*x86_64"` |
| `exact` | Literal | `"HOST1"` |
> **Default**: `wildcard`
---
## `device_info` Examples
### 1. **Basic IOS Switch**
^^^json
[
  {
    "device_name": "SWITCH1",
    "commands": [
      {
        "command": "show version",
        "validations": [
          "Cisco IOS Software"
        ]
      }
    ]
  }
]
^^^
### Parameter Equivalent:
^^^bash
cmltools validate -labid <labid> -devicename "SWITCH1" -command "show version" -pattern "Cisco IOS Software"
^^^
---
### 2. **Linux Host with Custom Creds**
^^^json
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
          "*Linux*"
        ]
      }
    ]
  }
]
^^^
### Parameter Equivalent:
^^^bash
cmltools validate -labid <labid> -devicename "HOST1" -username "admin" -password "cisco" -command "uname -a" -pattern "*Linux*"
^^^
---
### 3. **EtherChannel (Your Style)**
^^^json
[
  {
    "device_name": "CORE1",
    "commands": [
      {
        "command": "show etherchannel summary",
        "validations": [
          r"12\s+Po12\(SU\)\s+-\s+Gi0/2\(P\)\s+Gi0/3\(P\)",
          r"23\s+Po23\(SU\)\s+LACP\s+Gi1/0\(P\)\s+Gi1/1\(P\)"
        ]
      }
    ]
  }
]
^^^
### Parameter Equivalent (for single validation):
^^^bash
cmltools validate -labid <labid> -devicename "CORE1" -command "show etherchannel summary" -pattern "12\s+Po12\(SU\)\s+-\s+Gi0/2\(P\)\s+Gi0/3\(P\)" --regex
^^^
---
### 4. **Multi-Device, Multi-Command**
^^^json
[
  {
    "device_name": "R1",
    "commands": [
      {
        "command": "show ip interface brief",
        "validations": [
          "GigabitEthernet0/0*up*up"
        ]
      },
      {
        "command": "show version",
        "validations": [
          { "pattern": "^Cisco IOS XE.*17\\.", "match_type": "regex" }
        ]
      }
    ]
  },
  {
    "device_name": "HOST2",
    "credentials": {
      "username": "root",
      "password": "secret123"
    },
    "commands": [
      {
        "command": "df -h",
        "validations": [
          "/dev/sda1*ext4"
        ]
      }
    ]
  }
]
^^^
### Parameter Equivalent (single device/command; repeat for multi):
^^^bash
cmltools validate -labid <labid> -devicename "R1" -command "show ip interface brief,show version" -pattern "GigabitEthernet0/0*up*up" --regex
^^^
---
### 5. **Auto Mode (No `device_info`)**
^^^bash
cmltools validate -labid Lab2
^^^
→ Auto-generates:
- IOS: `show version` → `"Cisco IOS Software"`
- Linux: `uname -a` → `"Linux"`
---
## Best Practices
| Do | Don't |
|----|-------|
| Use **parameters** for single-device cases | Overuse JSON for simple validations |
| Use **string list** for 95% of cases | Overuse `regex` |
| Use **exact** `device_name` | Guess names |
| Test with `--debug` | Run blind |
| Use `r"...` in bash for backslashes | Escape manually |
---
## Debug Tips
^^^bash
# See testbed
cmltools gettestbed Lab2 --debug > testbed.yaml
# See validation
cmltools validate -labid Lab2 -deviceinfo "$device_info" --debug
^^^
Look for:
^^^bash
INFO - Applied device_info credentials to HOST1: admin/cis***
INFO - Correctly Configured - HOST1 - uname -a
^^^
---
## Summary
| Feature | Optional? | Default |
|-------|----------|--------|
| `device_name` | No | — |
| `credentials` | Yes | Testbed |
| `commands` | No | — |
| `validations` | No | — |
| `match_type` | Yes | `wildcard` |
| `device_info` | Yes | Auto-generated |
---
