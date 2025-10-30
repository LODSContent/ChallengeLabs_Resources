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

---

### 2. **Lifecycle Action: Lab Import**

```bash
cmltools importlab -source "https://github.com/..."
```

- Downloads `.yaml`, `.cml`, or `.zip`
- Converts GitHub blob to raw URL
- Imports into CML
- **Idempotent**: reuses existing lab by title
- Returns lab UUID

---

### 3. **Validation Script**

```bash
cmltools validate -labid "LAB_ID" -deviceinfo "$device_info"
```

- Starts lab if stopped
- Fetches PyATS testbed
- Applies optional credential overrides from `device_info`
- Runs commands and validates output
- Prints `Correctly/Incorrectly Configured` lines
- Final line: `True` or `False`

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
| `validate` | labid, --deviceinfo | **Scoring** |
| `importlab` | -source URL | Import lab |

Use `--debug` for verbose logs.

---

## `device_info` JSON Format

A **list** of device validation objects.

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

```json
"validations": [
  "*Linux*",
  "*x86_64*"
]
```

→ Each string is **wildcard**  
→ `match_type` **optional**, defaults to `wildcard`

**Option 2: Dict with Explicit `match_type`**

```json
"validations": [
  { "pattern": "^Linux.*x86_64", "match_type": "regex" },
  { "pattern": "HOST1", "match_type": "exact" }
]
```

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

```json
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
```

---

### 2. **Linux Host with Custom Creds**

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
          "*Linux*"
        ]
      }
    ]
  }
]
```

---

### 3. **EtherChannel (Your Style)**

```json
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
```

---

### 4. **Multi-Device, Multi-Command**

```json
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
```

---

### 5. **Auto Mode (No `device_info`)**

```bash
cmltools validate -labid Lab2
```

→ Auto-generates:
- IOS: `show version` → `"Cisco IOS Software"`
- Linux: `uname -a` → `"Linux"`

---

## Best Practices

| Do | Don't |
|----|-------|
| Use **string list** for 95% of cases | Overuse `regex` |
| Use **exact** `device_name` | Guess names |
| Test with `--debug` | Run blind |
| Use `r"...` in bash for backslashes | Escape manually |

---

## Debug Tips

```bash
# See testbed
cmltools gettestbed Lab2 --debug > testbed.yaml

# See validation
cmltools validate -labid Lab2 -deviceinfo "$device_info" --debug
```

Look for:
