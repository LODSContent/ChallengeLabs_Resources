# CML Tools Manual

## Purpose

The \[`cmltools.py`\]\(http://cmltools.py\) script is a command-line tool for interacting with Cisco Modeling Labs \(CML\) to manage labs and validate network device configurations using PyATS. It provides a unified interface for tasks such as authenticating with the CML server, managing labs \(starting, stopping, retrieving details\), fetching testbed configurations, and validating device outputs against expected patterns. The script is designed to be run in a Linux environment, typically within a PyATS scoring VM, and supports both positional and named arguments with case-insensitive command and parameter names.

---

## Installation and Setup

### Prerequisites

- CML Host
- pyATS server

- **Environment Variables**: Set in `$HOME/labfiles/cml_env.sh` \(automatically sourced via `~/.bashrc`\):
    - `CML_ADDRESS`: URL of the CML server \(e.g., `https://192.168.1.10`\).
    - `CML_IP`: IP address of the CML server \(e.g., `192.168.1.10`\).
    - `CML_USERNAME`: Username for CML authentication.
    - `CML_PASSWORD`: Password for CML authentication.
    - `SCRIPT_DEBUG`: Set to `true` for debug logging \(default: `false`\).
    - `RETRY_COUNT`: Number of retries for lab state checks \(default: `30`\).
    - `RETRY_DELAY`: Delay between retries in seconds \(default: `10`\).
    - `PYTHON_PATH`: Path to Python executable \(e.g., `$HOME/labfiles/.venv/bin/python`\).
    - `PYTHON_TOOLS_SCRIPT`: Path to `cmltools.py` \(e.g., `$HOME/labfiles/cmltools.py`\).

### Setup

1. Add the script as an LCA to a Cisco lab with a PyATS server.

2. Source the environment variables at the beginning of any Validation script:

    ```
    source $HOME/labfiles/cml_env.sh
    ```

3. Ensure dependencies are installed \(see above\).

---

## Usage

The script supports two invocation styles:

- **Positional Arguments**:

    ```
    cmltools [COMMAND] [LABID] [--deviceinfo DEVICEINFO] [--debug]
    ```

- **Named Arguments**:

    ```
    cmltools [-command COMMAND] [-labid LABID] [--deviceinfo DEVICEINFO] [--debug]
    ```

- **Command and Parameter Case**: All commands \(e.g., `validate`, `VALIDATE`\) and parameter names \(e.g., `-command`, `-COMMAND`, `-LabID`, `-DeviceInfo`\) are case-insensitive.
- **Output**: Results are printed to stdout, errors to stderr. Debug logs \(if `--debug` or `SCRIPT_DEBUG=true`\) go to `/home/labuser/labfiles/script_log.txt` and console.

---

## Commands and Parameters

- **authenticate**: Authenticate with CML server and return JWT token.
    - Parameters: None.
    - Output: JWT token \(string\) or empty string.

- **findlab**: Find a lab by title or return first running/available lab.
    - Parameters: \[LABID\] \(optional, UUID or title\).
    - Output: Lab ID \(UUID\) or empty string.

- **getlabs**: Get a list of all lab IDs.
    - Parameters: None.
    - Output: JSON array of lab IDs.

- **getdetails**: Get detailed information about a lab.
    - Parameters: LABID \(required, UUID or title\).
    - Output: JSON object with lab details.

- **getstate**: Get the state of a lab \(e.g., "STARTED"\).
    - Parameters: \[LABID\] \(optional, UUID or title\).
    - Output: Lab state \(string\) or empty string.

- **startlab**: Start a lab.
    - Parameters: \[LABID\] \(optional, UUID or title\).
    - Output: Lab ID on success, empty string on failure.

- **stoplab**: Stop a lab.
    - Parameters: \[LABID\] \(optional, UUID or title\).
    - Output: Lab ID on success, empty string on failure.

- **gettestbed**: Get PyATS testbed YAML for a lab.
    - Parameters: \[LABID\] \(optional, UUID or title\).
    - Output: YAML string or empty string.

- **validate**: Validate device configurations using PyATS.
    - Parameters: \[LABID\] \(optional, UUID or title\), \[--deviceinfo DEVICEINFO\] \(optional, JSON string\).
    - Output: Validation results \(lines\) + True/False.

### Parameters

- **COMMAND**: The command to execute \(e.g., validate, getlabs\). Case-insensitive.
- **LABID**: Lab UUID or title. If omitted, defaults to the first running lab or first available lab. Required for getdetails.
- `--deviceinfo DEVICEINFO`: JSON string specifying devices and commands for validate. Optional; if empty or omitted, uses testbed YAML to validate linux and ios devices.
- `--debug`: Enable debug logging to console and file. Can also be enabled by setting `SCRIPT_DEBUG=true`.

---

## Examples

1. **Authenticate**:

    ```
    cmltools authenticate
    cmltools -command AUTHENTICATE
    ```
    Output: <JWT token> or Error: Failed to authenticate with CML

2. **Find a Lab**:

    ```
    cmltools findlab MyLab
    cmltools -command findlab -labid MyLab
    ```
    Output: <lab_id> or Error: No lab found with title 'MyLab'

3. **Get Labs**:

    ```
    cmltools getlabs
    ```
    Output: ["lab1", "lab2"] or Error: Failed to get labs

4. **Get Details**:

    ```
    cmltools getdetails lab1
    cmltools -command GETDETAILS -LABID lab1
    ```
    Output: {"lab_title": "MyLab", ...} or Error: Invalid details response for lab lab1

5. **Get State**:

    ```
    cmltools getstate lab1
    cmltools getstate # Uses default lab
    ```
    Output: STARTED or Error: No lab found

6. **Start a Lab**:

    ```
    cmltools startlab MyLab
    cmltools -command STARTLAB -labid MyLab
    ```
    Output: <lab_id> or Error: Failed to start lab <lab_id>

7. **Stop a Lab**:

    ```
    cmltools stoplab lab1
    ```
    Output: <lab_id> or Error: Failed to stop lab <lab_id>

8. **Get Testbed**:

    ```
    cmltools gettestbed MyLab
    ```
    Output: YAML string or Error: Invalid testbed YAML for lab <lab_id>

9. **Validate with Provided device_info**:

    ```
    device_info='[{"device_name": "sw01", "commands": [{"command": "show version", "validations": [{"pattern": "Cisco IOS Software", "match_type": "wildcard"}]}]}]'
    cmltools validate MyLab --deviceinfo "$device_info"
    cmltools -command VALIDATE -labid MyLab -DEVICEINFO "$device_info"
    ```
    Output:
    Correctly Configured - sw01 - show version
    True

10. **Validate with Empty device_info**:

    ```
    cmltools validate MyLab
    cmltools -command validate -labid MyLab -deviceinfo ""
    ```
    Output \(for a testbed with netadmin \(linux\), outside-host \(linux\), rtr01 \(ios\), sw01 \(ios\)\):
    Correctly Configured - netadmin - uname -a
    Correctly Configured - outside-host - uname -a
    Correctly Configured - rtr01 - show version
    Correctly Configured - sw01 - show version
    True

11. **Debug Logging**:

    ```
    export SCRIPT_DEBUG=true
    cmltools validate MyLab --debug
    ```
    Output: Validation results plus debug logs to /home/labuser/labfiles/script_log.txt and console.

---

## Writing Validation Scripts with device_info

The validate command uses a device_info JSON string to specify devices, commands, and validation patterns. If omitted or empty, it automatically generates a device_info structure from the testbed YAML, validating linux devices with uname -a and ios devices with show version.

### device_info Structure

The device_info is a JSON array of device objects, each containing:

- device_name: The name of the device \(e.g., sw01, rtr01\).
- commands: A list of command objects, each with:
    - command: The command to execute \(e.g., show version\).
    - validations \(optional\): A list of validation objects, each with:
        - pattern: The pattern to match in the command output \(e.g., Cisco IOS Software\).
        - match_type: Either wildcard \(supports \* and ?\) or regex \(default: wildcard\).

#### Variations of device_info

1. **Single Device, Single Command with Validation**:

    ```
    device_info='[{"device_name": "sw01", "commands": [{"command": "show version", "validations": [{"pattern": "Cisco IOS Software", "match_type": "wildcard"}]}]}]'
    ```
    Validates that sw01 outputs "Cisco IOS Software" for show version.

2. **Multiple Devices, Multiple Commands**:

    ```
    device_info='[
      {
        "device_name": "rtr01",
        "commands": [
          {"command": "show version", "validations": [{"pattern": "Cisco IOS Software", "match_type": "wildcard"}]},
          {"command": "show ip interface brief", "validations": [{"pattern": "Ethernet0/0.*up.*up", "match_type": "regex"}]}
        ]
      },
      {
        "device_name": "netadmin",
        "commands": [{"command": "uname -a", "validations": [{"pattern": "Linux", "match_type": "wildcard"}]}]
      }
    ]'
    ```
    Validates multiple commands on rtr01 and one on netadmin.

3. **Command Without Validation**:

    ```
    device_info='[{"device_name": "sw01", "commands": [{"command": "show version"}]}]'
    ```
    Executes show version on sw01 without validation, always returning "Correctly Configured".

4. **Empty device_info**:

    ```
    device_info=''
    cmltools validate MyLab --deviceinfo "$device_info"
    ```
    Automatically generates device_info from the testbed YAML, e.g.:

    ```
    [
      {"device_name": "netadmin", "commands": [{"command": "uname -a", "validations": [{"pattern": "Linux", "match_type": "wildcard"}]}]},
      {"device_name": "outside-host", "commands": [{"command": "uname -a", "validations": [{"pattern": "Linux", "match_type": "wildcard"}]}]},
      {"device_name": "rtr01", "commands": [{"command": "show version", "validations": [{"pattern": "Cisco IOS Software", "match_type": "wildcard"}]}]},
      {"device_name": "sw01", "commands": [{"command": "show version", "validations": [{"pattern": "Cisco IOS Software", "match_type": "wildcard"}]}]}
    ]
    ```

---

## Tips for Writing device_info

- **JSON Syntax**: Ensure valid JSON \(use single quotes in Bash to avoid escaping issues\).
- **Pattern Matching**:
    - Use wildcard for simple patterns \(e.g., Cisco\*Software matches any string containing "Cisco" and "Software"\).
    - Use regex for complex patterns \(e.g., Ethernet0/0.\*up.\*up matches an interface status\).
- **Device Names**: Must match names in the testbed YAML \(case-sensitive\).
- **Validation Optional**: Omit validations for commands that don’t require output checking.
- **Debugging**: Use --debug or SCRIPT_DEBUG=true to log the generated device_info and validation details.

---

## Troubleshooting

- **Environment Variables Missing**:

    ```
    Error: CML_USERNAME and CML_PASSWORD must be set
    ```
    Ensure CML_USERNAME and CML_PASSWORD are set in cml_env.sh or the environment.

- **Invalid device_info JSON**:

    ```
    Error: Invalid device_info JSON
    ```
    Check JSON syntax \(e.g., use single quotes, validate with echo "$device_info" | jq .\).

- **Lab Not Found**:

    ```
    Error: No lab found with title 'MyLab'
    ```
    Verify the lab title or UUID using cmltools getlabs.

- **Lab Not Started**:

    ```
    Error: Lab <lab_id> failed to start after 30 retries
    ```
    Check CML server status or increase RETRY_COUNT/RETRY_DELAY.

---

## Notes

- **Logging**: Debug logs are written to /home/labuser/labfiles/script_log.txt when --debug or SCRIPT_DEBUG=true is set.
- **Security**: The script uses verify=False for HTTPS requests, matching the original curl -k behavior. For production, consider enabling certificate verification.
- **Extensibility**: The script can be extended with additional commands or custom validation patterns by modifying CMLClient methods.

---
