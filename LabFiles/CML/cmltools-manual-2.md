Got it — you want the entire Markdown content to stay inside a single code block so it doesn't render as formatted HTML. Here's the full content wrapped in a fenced code block using triple backticks and specifying `markdown` for clarity:

````markdown
# CML Tools & Validation Manual

**Version:** 1.20251029.0151  
**Date:** October 29, 2025  
**Authors:** xAI Engineering Team  
**Target Environment:** Cisco Modeling Labs (CML) + PyATS Validation

---

## Table of Contents

1. Overview  
2. Setup Script (`setup_cml.sh`)  
3. Python Library (`cmltools.py`)  
   - Commands  
   - Environment Variables  
   - Key Classes & Methods  
4. Validation JSON Schema & Usage  
   - Structure  
   - Default Behavior  
   - Permutations & Examples  
5. Validation Script (`validate.sh`)  
6. Troubleshooting  
7. Summary

---

## Overview

This system enables automated management and validation of Cisco CML labs using:

- A bash setup script that generates environment and tools  
- A Python CLI tool (`cmltools.py`) for CML API interaction  
- A JSON-based validation specification for device configuration checks  
- A container-safe validation script for scoring environments  

All components are case-insensitive and support flexible argument styles.

---

## Setup Script (`setup_cml.sh`)

### Purpose

Creates:

- `~/labfiles/cml_env.sh` – environment variables + `cmltools()` wrapper  
- `~/labfiles/cmltools.py` – main Python tool  
- Auto-sources environment in `~/.bashrc`

### Usage

```bash
./setup_cml.sh <CML_IP> <USERNAME> <PASSWORD>
```

### Example

```bash
./setup_cml.sh 192.168.100.10 admin secret
```

### Output

- Environment variables and functions written to `/home/labuser/labfiles/cml_env.sh`  
- Added `source ...` to `/home/labuser/.bashrc`  
- To apply changes: `source ~/.bashrc`  
- `true`

Run `source ~/.bashrc` or restart shell to use `cmltools` command.

---

## Python Library (`cmltools.py`)

### CLI Usage

```bash
cmltools [COMMAND] [LABID] [--deviceinfo JSON] [-source URL] [--debug]
# or
cmltools -command validate -labid LAB2 --deviceinfo '...'
```

All flags and values are case-insensitive.

### Commands

| Command                     | Description                                      | Requires LABID? | Example                                  |
|----------------------------|--------------------------------------------------|------------------|------------------------------------------|
| authenticate               | Get JWT token                                    | No               | `cmltools authenticate`                  |
| findlab [title]            | Find lab by title or default                     | Optional         | `cmltools findlab "My Lab"`              |
| getlabs                    | List all lab IDs                                 | No               | `cmltools getlabs`                       |
| getdetails `<id>`          | Lab metadata                                     | Yes              | `cmltools getdetails abc-123`            |
| getstate `<id>`            | Lab state                                        | Yes              | `cmltools getstate abc-123`              |
| startlab [id/title]        | Start lab (Free SKU: stops others)               | Optional         | `cmltools startlab`                      |
| stoplab [id/title]         | Stop lab                                         | Optional         | `cmltools stoplab`                       |
| gettestbed [id/title]      | Get PyATS testbed YAML                           | Optional         | `cmltools gettestbed`                    |
| validate [id] --deviceinfo | Validate config                                  | Optional         | See below                                |
| importlab -source URL      | Download & import lab                            | No               | `cmltools importlab -source https://...`|

### Environment Variables

| Variable        | Default           | Description                        |
|----------------|-------------------|------------------------------------|
| CML_ADDRESS     | `https://$CML_IP` | CML API URL                        |
| CML_IP          | Required          | CML server IP                      |
| CML_USERNAME    | Required          | Login user                         |
| CML_PASSWORD    | Required          | Login password                     |
| CML_SKU         | Free              | Enforces single-lab rule           |
| SCRIPT_DEBUG    | false             | Enable debug logs                  |
| RETRY_COUNT     | 30                | Lab start retries                  |
| RETRY_DELAY     | 10                | Seconds between retries            |

### Key Classes & Methods

#### `CMLClient`

Main interface to CML REST API.

| Method                     | Purpose                          |
|---------------------------|----------------------------------|
| `authenticate()`          | Login to JWT                     |
| `findlab(title)`          | Title to UUID                    |
| `startlab(id)`            | Starts lab; stops others in Free SKU |
| `gettestbed(id)`          | Returns PyATS YAML               |
| `validate(id, device_info)` | Runs config checks             |

#### `validate_pattern()`

Supports:

- `match_type: "wildcard"` → `re.escape()` + `*` to `.*`  
- `match_type: "regex"` → raw regex  
- Default: `wildcard`

---

## Validation JSON Schema & Usage

Used with `validate` command via `--deviceinfo`.

### Structure

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
            "match_type": "wildcard|regex"
          }
        ]
      }
    ]
  }
]
```

### Default Behavior (No JSON)

If `--deviceinfo` is omitted, `cmltools` auto-generates:

| OS    | Command        | Pattern               |
|-------|----------------|-----------------------|
| ios   | show version   | Cisco IOS Software    |
| linux | uname -a       | Linux                 |

All devices in testbed (except `terminal_server`) are checked.

### Permutations & Examples

#### 1. Minimal (Rely on Defaults)

```bash
cmltools validate -labid MYLAB
```

#### 2. Single Device, One Check

```json
[
  {
    "device_name": "R1",
    "commands": [
      {
        "command": "show ip interface brief",
        "validations": [
          { "pattern": "GigabitEthernet0/0.*up.*up" }
        ]
      }
    ]
  }
]
```

#### 3. Custom Credentials + Multiple Commands

```json
[
  {
    "device_name": "HOST1",
    "credentials": { "username": "admin", "password": "cisco" },
    "commands": [
      {
        "command": "cat /etc/hostname",
        "validations": [ { "pattern": "host1" } ]
      },
      {
        "command": "ip addr show eth0",
        "validations": [ { "pattern": "192.168.1.10" } ]
      }
    ]
  }
]
```

#### 4. Regex Matching

```json
[
  {
    "device_name": "SW1",
    "commands": [
      {
        "command": "show vlan brief",
        "validations": [
          {
            "pattern": "^10\\s+Data\\s+active",
            "match_type": "regex"
          }
        ]
      }
    ]
  }
]
```

#### 5. Wildcard with Wildcards

```json
[
  {
    "device_name": "R2",
    "commands": [
      {
        "command": "show running-config | include ntp",
        "validations": [
          { "pattern": "ntp server 1.2.3.4" }
        ]
      }
    ]
  }
]
```

#### 6. No Validation (Just Execute)

```json
[
  {
    "device_name": "R3",
    "commands": [
      { "command": "show clock" }
    ]
  }
]
```

### Validation Output Format

```
Correctly Configured - R1 - show version
Incorrectly Configured - R2 - show ip interface brief
True
```

- One line per command  
- Final line: `True` or `False` (overall result)

---

## Validation Script (`validate.sh`)

### Purpose

Container-safe wrapper for scoring systems (e.g., DevNet, Learning@Cisco).

### Features

- Hard-coded `LAB_ID`  
- Embedded JSON via `cat << 'EOF'`  
- Debug control  
- Output filtering  
- Exit-code safe

### Example Snippet

```bash
LAB_ID="LAB2"
device_info=$(cat << 'EOF'
[
  {
    "device_name": "switch1",
    "commands": [ { "command": "show version", "validations": [ { "pattern": "Cisco IOS Software" } ] } ]
  }
]
EOF
)
```

### Control Variables

| Var         | Values       | Effect                         |
|-------------|--------------|--------------------------------|
| scriptDebug | true/false   | Show debug + errors            |
| showDevices | true/false   | Show per-device results        |

---

## Troubleshooting

| Symptom                          | Solution                                      |
|----------------------------------|-----------------------------------------------|
| `cmltools: command not found`    | Run `source ~/.bashrc`                        |
| No valid JWT token               | Check username/password, CML reachable        |
| `not_in_testbed`                | Device name mismatch (case-sensitive in testbed) |
| `connect_failed`                | Wrong credentials or device not started       |
| Pattern not found                | Use `--debug` to see output                   |
| Free SKU: stopping other lab     | Normal in free tier                           |

### Enable Debug

```bash
export SCRIPT_DEBUG=true
cmltools validate --debug
```

Logs to: `/home/labuser/labfiles/script_log.txt`

---

## Summary

| Component         | Role                                |
|------------------|-------------------------------------|
| `setup_cml.sh`    | Bootstrap environment               |
| `cml_env.sh`      | Auto-load `cmltools()`              |
| `cmltools.py`     | Core CML + PyATS automation         |
| `device_info JSON`| Declarative config validation       |
| `validate.sh`     | Scoring-safe execution              |

