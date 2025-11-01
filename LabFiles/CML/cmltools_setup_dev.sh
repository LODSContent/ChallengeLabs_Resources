#!/bin/bash
# =============================================================================
# CML Tools Setup Script – FULLY PRESERVED ORIGINAL + NEW EXECUTE
# Creates cml_env.sh and cmltools.py with environment variables
# Parameters:
#   $1: CML_IP         (e.g., 192.168.1.10)
#   $2: CML_USERNAME   (e.g., admin)
#   $3: CML_PASSWORD   (e.g., secret)
# Returns: true on success, false on failure
# =============================================================================

# Validate required parameters
if [ $# -ne 3 ]; then
  echo "Error: Exactly 3 parameters required: CML_IP, CML_USERNAME, CML_PASSWORD" >&2
  echo false
  return 1
fi

CML_IP="$1"
CML_USERNAME="$2"
CML_PASSWORD="$3"

# Ensure labfiles directory exists
mkdir -p "$HOME/labfiles" || { echo "Error: Failed to create $HOME/labfiles" >&2; echo false; return 1; }

# Specify the file path to save the environment variables
OUTPUT_FILE="$HOME/labfiles/cml_env.sh"
export BASH_ENV="$HOME/labfiles/cml_env.sh"

# Check if output file is writable
touch "$OUTPUT_FILE" || { echo "Error: Cannot write to $OUTPUT_FILE" >&2; echo false; return 1; }

# Create or overwrite the output file with environment variables and functions
cat << EOF > "$OUTPUT_FILE" || { echo "Error: Failed to write to $OUTPUT_FILE" >&2; echo false; return 1; }
#!/bin/bash
# Environment variables for CML and PyATS
export BASE_DIRECTORY="$HOME/labfiles"
export CML_IP="$CML_IP"
export CML_ADDRESS="https://\${CML_IP}"
export CML_USERNAME="$CML_USERNAME"
export CML_PASSWORD="$CML_PASSWORD"
export CML_SKU="Free"
export PYTHON_TOOLS_SCRIPT="\${BASE_DIRECTORY}/cmltools.py"
export PYTHON_ENV="\${BASE_DIRECTORY}/.venv/bin/python"
export PYTHON_PATH="\${BASE_DIRECTORY}/.venv/bin/python"
export SCRIPT_DEBUG="false"
export RETRY_COUNT=30
export RETRY_DELAY=10

# Log debug messages to stderr if SCRIPT_DEBUG is true
# Arguments: Message to log
# Returns: None
log_debug() {
  if [[ "\${SCRIPT_DEBUG,,}" == "true" ]]; then
    echo "Debug: \$*" >&2
  fi
}

# Wrapper function to call cmltools.py
# Arguments: Command-line arguments for cmltools.py
# Returns: Output from cmltools.py; exits with 1 on failure
cmltools() {
  if [[ ! -f "\${BASE_DIRECTORY}/cmltools.py" ]]; then
    echo "Error: Python script \${BASE_DIRECTORY}/cmltools.py not found" >&2
    return 1
  fi
  if [[ -z "\${BASE_DIRECTORY}/.venv/bin/python" ]]; then
    echo "Error: PYTHON_PATH not set" >&2
    return 1
  fi
  log_debug "Executing: \${BASE_DIRECTORY}/.venv/bin/python \${BASE_DIRECTORY}/cmltools.py \$@"
  "\${BASE_DIRECTORY}/.venv/bin/python" "\${BASE_DIRECTORY}/cmltools.py" "\$@"
}
EOF

# Make the output file executable and secure
chmod 600 "$OUTPUT_FILE" || { echo "Error: Failed to set permissions on $OUTPUT_FILE" >&2; echo false; return 1; }

# Append source command to ~/.bashrc to load cml_env.sh automatically
BASHRC="$HOME/.bashrc"
SOURCE_LINE="source $OUTPUT_FILE"
if ! grep -q "$SOURCE_LINE" "$BASHRC"; then
  echo "$SOURCE_LINE" >> "$BASHRC" || { echo "Error: Failed to write to $BASHRC" >&2; echo false; return 1; }
  echo "Added 'source $OUTPUT_FILE' to $BASHRC."
else
  echo "'source $OUTPUT_FILE' already exists in $BASHRC. Skipping."
fi

# Notify user of successful setup
echo "Environment variables and functions written to $OUTPUT_FILE."
echo "To apply changes in the current session, run: source $BASHRC"

# Load cml_env.sh now if executed manually
if [[ -f "$OUTPUT_FILE" ]]; then
  source "$OUTPUT_FILE"
else
  echo "Error: Failed to source $OUTPUT_FILE; file does not exist" >&2
  echo false
  return 1
fi

# Path where the Python script will be created
PYTHON_SCRIPT_PATH="$HOME/labfiles/cmltools.py"

# =============================================================================
# FULL ORIGINAL cmltools.py + NEW EXECUTE FUNCTION
# =============================================================================
cat << 'EOF' > "$PYTHON_SCRIPT_PATH" || { echo "Error: Failed to write to $PYTHON_SCRIPT_PATH" >&2; echo false; return 1; }
#!/usr/bin/env python3
# CML Tools v1.20251101.1300
# Script for lab management, import, and validation
# Interacts with Cisco Modeling Labs (CML) to manage labs and validate device configurations
# Supports case-insensitive commands and parameter names
#
# Usage:
#   cmltools.py [FUNCTION] [LABID] [-deviceinfo DEVICEINFO] [-source URL] [--debug]
#   cmltools.py [-function FUNCTION] [-labid LABID] [-deviceinfo DEVICEINFO] [-source URL] [--debug]
#   cmltools.py execute [LABID] -devicename DEV -command "CMD" [-username U] [-password P] [--debug]
#
# Functions:
#   authenticate: Authenticate with CML server and return JWT token
#   findlab: Find a lab by title or return first running/available lab
#   getlabs: Get a list of all lab IDs
#   getdetails: Get detailed information about a specific lab
#   getstate: Get the state of a specific lab
#   startlab: Start a specific lab
#   stoplab: Stop a specific lab
#   gettestbed: Get PyATS testbed YAML for a lab
#   validate: Validate device configurations
#   execute: Execute command(s) on a device and return RAW output (multiline cmds OK)
#   importlab: Download lab from URL, convert, and import into CML (one step)
#
# Environment Variables:
#   CML_ADDRESS: URL of the CML server (e.g., https://192.168.1.10)
#   CML_IP: IP address of the CML server (e.g., 192.168.1.10)
#   CML_USERNAME: Username for CML authentication
#   CML_PASSWORD: Password for CML authentication
#   SCRIPT_DEBUG: Set to 'true' for debug logging (default: false)
#   RETRY_COUNT: Number of retries for lab state checks (default: 30)
#   RETRY_DELAY: Delay between retries in seconds (default: 10)

import argparse
import json
import logging
import os
import sys
import re
import time
import yaml
import ast
import requests
import urllib3
from genie.testbed import load
from unicon.core.errors import SubCommandFailure
from zipfile import ZipFile
from io import BytesIO

# Suppress InsecureRequestWarning from urllib3 due to verify=False in HTTPS requests
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

class CaseInsensitiveArgumentParser(argparse.ArgumentParser):
    # Custom ArgumentParser that makes option names case-insensitive
    # Normalizes option names (e.g., -FUNCTION, -LabID) to lowercase
    def _get_option_tuples(self, option_string):
        # Normalize option string to lowercase for matching
        return super()._get_option_tuples(option_string.lower())

    def parse_known_args(self, args=None, namespace=None):
        # Convert all option names to lowercase before parsing
        args = [arg.lower() if arg.startswith('-') else arg for arg in (args or sys.argv[1:])]
        return super().parse_known_args(args, namespace)

def setup_logging(logfile='/home/labuser/labfiles/script_log.txt', debug=False):
    # Configure logging for the script
    # Args:
    #   logfile: Path to the log file (default: /home/labuser/labfiles/script_log.txt)
    #   debug: Enable console logging if True
    # If debug is True, logs to both file and console at INFO level
    # Otherwise, logs to file only at ERROR level
    # Suppresses verbose logging from requests, genie, and unicon
    logging.basicConfig(
        filename=logfile,
        level=logging.INFO if debug else logging.ERROR,
        format='%(asctime)s - %(levelname)s - %(message)s'
    )
    if debug:
        console = logging.StreamHandler()
        console.setLevel(logging.INFO)
        console.setFormatter(logging.Formatter('%(asctime)s - %(levelname)s - %(message)s'))
        logging.getLogger('').addHandler(console)
    logging.getLogger('requests').setLevel(logging.ERROR)
    logging.getLogger('genie').setLevel(logging.ERROR)
    logging.getLogger('unicon').setLevel(logging.ERROR)

def convert_wildcard_to_regex(pattern):
    # Convert a wildcard pattern to a regex pattern
    # Args:
    #   pattern: Wildcard pattern (e.g., "Cisco*Software")
    # Returns: Regex pattern with '*' replaced by '.*' and '?' by '.'
    escaped_pattern = re.escape(pattern)
    return escaped_pattern.replace('\\*', '.*').replace('\\?', '.')

def validate_pattern(validation, data, device_name, command, debug=False):
    results = []
    if isinstance(validation, str):
        pattern = validation
        match_type = 'regex'
        regex_pattern = pattern
    elif isinstance(validation, dict):
        pattern = validation['pattern']
        match_type = validation.get('match_type', 'wildcard')
        if match_type == 'regex':
            regex_pattern = pattern
        elif match_type == 'wildcard':
            regex_pattern = convert_wildcard_to_regex(pattern)
        else:
            error_msg = f"Invalid match_type '{match_type}' for {device_name}, pattern '{pattern}'"
            logging.error(error_msg)
            if debug:
                results.append(error_msg)
            return False, results
    else:
        error_msg = f"Invalid validation format for {device_name}, validation: {validation}"
        logging.error(error_msg)
        if debug:
            results.append(error_msg)
        return False, results

    # === AUTO-CONVERT DATA TO STRING ===
    if isinstance(data, dict):
        # Convert dict to pretty string
        try:
            data = json.dumps(data, indent=2)
        except:
            data = str(data)
    elif isinstance(data, (list, tuple)):
        # Convert list to newline string
        data = '\n'.join(str(item) for item in data)
    elif not isinstance(data, (str, bytes)):
        data = str(data)

    # Ensure string
    if isinstance(data, bytes):
        data = data.decode('utf-8', errors='ignore')

    # === COMPILE REGEX (CASE-INSENSITIVE) ===
    try:
        regex = re.compile(regex_pattern, re.DOTALL | re.IGNORECASE)
        pattern_match = bool(regex.search(data))
    except re.error as e:
        error_msg = f"Invalid pattern '{pattern}' ({match_type}, regex: '{regex_pattern}') for {device_name}: {e}"
        logging.error(error_msg)
        if debug:
            results.append(error_msg)
        return False, results

    if not pattern_match:
        log_msg = f"Pattern '{pattern}' ({match_type}) not found in output of '{command}' on {device_name}"
        logging.info(log_msg)
        if debug:
            results.append(log_msg)
        return False, results

    return True, results

class CMLClient:
    # Client for interacting with Cisco Modeling Labs (CML) API
    # Attributes:
    #   cml_address: URL of the CML server (e.g., https://192.168.1.10)
    #   cml_ip: IP address of the CML server (e.g., 192.168.1.10)
    #   username: Username for CML authentication
    #   password: Password for CML authentication
    #   jwt: JWT token for authenticated API calls
    #   debug: Enable debug logging if True
    def __init__(self, cml_address, cml_ip, username, password, debug=False):
        self.cml_address = cml_address.rstrip('/')
        self.cml_ip = cml_ip
        self.username = username
        self.password = password
        self.jwt = None
        self.debug = debug
        setup_logging(debug=debug)

    def authenticate(self):
        # Authenticate with CML server and return JWT token
        # Returns: JWT token (str) on success, empty string on failure
        try:
            response = requests.post(
                f"{self.cml_address}/api/v0/authenticate",
                headers={"accept": "application/json", "Content-Type": "application/json"},
                json={"username": self.username, "password": self.password},
                verify=False
            )
            response.raise_for_status()
            jwt = response.json()
            if not jwt or jwt == "null":
                logging.error("Failed to authenticate with CML (empty or null response)")
                print("Error: Failed to authenticate with CML", file=sys.stderr)
                return ""
            self.jwt = jwt
            if self.debug:
                logging.info(f"Authenticated successfully, JWT: {jwt[:20]}...")
            return jwt
        except requests.RequestException as e:
            logging.error(f"Failed to authenticate with CML: {e}")
            print(f"Error: Failed to authenticate with CML: {e}", file=sys.stderr)
            return ""

    def ensure_jwt(self):
        # Ensure a valid JWT token is available
        # Exits with code 1 if authentication fails
        if not self.jwt or self.jwt == "null":
            self.jwt = self.authenticate()
        if not self.jwt or self.jwt == "null":
            logging.error("No valid JWT token available")
            print("Error: No valid JWT token available", file=sys.stderr)
            sys.exit(1)
        return self.jwt

    def get_labs(self):
        # Get list of lab IDs from CML
        # Returns: List of lab IDs, or empty list on failure
        try:
            self.ensure_jwt()
            response = requests.get(
                f"{self.cml_address}/api/v0/labs",
                headers={"accept": "application/json", "Authorization": f"Bearer {self.jwt}"},
                verify=False
            )
            response.raise_for_status()
            lab_ids = response.json()
            if not isinstance(lab_ids, list):
                logging.error(f"Invalid JSON response from get_labs: {lab_ids}")
                print("Error: Invalid JSON response from get_labs", file=sys.stderr)
                return []
            if self.debug:
                logging.info(f"Retrieved lab IDs: {lab_ids}")
            return lab_ids
        except requests.RequestException as e:
            logging.error(f"Failed to get labs: {e}")
            print(f"Error: Failed to get labs: {e}", file=sys.stderr)
            return []

    def get_lab_state(self, lab_id):
        # Get the state of a specific lab
        # Args:
        #   lab_id: UUID of the lab
        # Returns: Lab state (e.g., "STARTED"), or empty string on failure
        try:
            self.ensure_jwt()
            response = requests.get(
                f"{self.cml_address}/api/v0/labs/{lab_id}/state",
                headers={"accept": "application/json", "Authorization": f"Bearer {self.jwt}"},
                verify=False
            )
            response.raise_for_status()
            state = response.json().get("state", "")
            if self.debug:
                logging.info(f"Lab {lab_id} state: {state}")
            return state
        except requests.RequestException as e:
            logging.error(f"Failed to get lab state: {e}")
            return ""

    def startlab(self, lab_id):
        # Start a lab
        # Args:
        #   lab_id: UUID of the lab
        # Returns: True on success, False on failure
        try:
            self.ensure_jwt()
            response = requests.put(
                f"{self.cml_address}/api/v0/labs/{lab_id}/start",
                headers={"Authorization": f"Bearer {self.jwt}"},
                verify=False
            )
            response.raise_for_status()
            print(f"Lab {lab_id} start requested.")
            return True
        except requests.RequestException as e:
            logging.error(f"Failed to start lab {lab_id}: {e}")
            print(f"Error: Failed to start lab {lab_id}", file=sys.stderr)
            return False

    def stoplab(self, lab_id):
        # Stop a lab
        # Args:
        #   lab_id: UUID of the lab
        # Returns: True on success, False on failure
        try:
            self.ensure_jwt()
            response = requests.put(
                f"{self.cml_address}/api/v0/labs/{lab_id}/stop",
                headers={"Authorization": f"Bearer {self.jwt}"},
                verify=False
            )
            response.raise_for_status()
            print(f"Lab {lab_id} stop requested.")
            return True
        except requests.RequestException as e:
            logging.error(f"Failed to stop lab {lab_id}: {e}")
            print(f"Error: Failed to stop lab {lab_id}", file=sys.stderr)
            return False

    def gettestbed(self, lab_id):
        # Get PyATS testbed YAML for a lab
        # Args:
        #   lab_id: UUID of the lab
        # Returns: YAML string on success, empty string on failure
        if not self._is_valid_lab_id(lab_id):
            lab_id = self.findlab(lab_id)
            if not lab_id:
                return ""
        try:
            self.ensure_jwt()
            response = requests.get(
                f"{self.cml_address}/api/v0/labs/{lab_id}/testbed",
                headers={"Authorization": f"Bearer {self.jwt}"},
                verify=False
            )
            response.raise_for_status()
            return response.text
        except requests.RequestException as e:
            logging.error(f"Failed to get testbed for {lab_id}: {e}")
            return ""

    def findlab(self, title=None):
        # Find a lab by title or return first running/available lab
        # Args:
        #   title: Lab title to search for (case-insensitive)
        # Returns: Lab ID (str) or empty string if not found
        labs = self.get_labs()
        if not labs:
            return ""
        if not title:
            for lab_id in labs:
                state = self.get_lab_state(lab_id)
                if state in ["STARTED", "DEFINED"]:
                    return lab_id
            return labs[0]
        title_lower = title.lower()
        for lab_id in labs:
            details = self.get_lab_details(lab_id)
            if details and details.get("lab", {}).get("title", "").lower() == title_lower:
                return lab_id
        return ""

    def get_lab_details(self, lab_id):
        # Get detailed information about a lab
        # Args:
        #   lab_id: UUID of the lab
        # Returns: Dict with lab details or {} on failure
        try:
            self.ensure_jwt()
            response = requests.get(
                f"{self.cml_address}/api/v0/labs/{lab_id}",
                headers={"Authorization": f"Bearer {self.jwt}"},
                verify=False
            )
            response.raise_for_status()
            return response.json()
        except requests.RequestException as e:
            logging.error(f"Failed to get lab details: {e}")
            return {}

    def _is_valid_lab_id(self, lab_id):
        # Check if a lab_id matches the UUID format
        # Args:
        #   lab_id: Lab ID to validate
        # Returns: True if valid UUID, False otherwise
        uuid_pattern = r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
        return bool(re.match(uuid_pattern, lab_id.lower()))

    # =============================================================================
    # NEW: EXECUTE – Run raw command(s) on a device (no validation)
    # =============================================================================
    def execute(self, lab_id, device_name, command_str, username=None, password=None):
        """
        Execute one or more CLI commands on a device and return the merged raw output.
        Supports multiline commands (use \\n). Optional username/password override.
        Returns:
          - Raw output (str) on success
          - "Failed: <dev> <reason>" on error
        """
        # Resolve lab_id
        if not lab_id:
            lab_id = self.findlab()
            if not lab_id:
                return "Failed: no_lab_id"
        if not self._is_valid_lab_id(lab_id):
            lab_id = self.findlab(lab_id)
            if not lab_id:
                return "Failed: no_lab_found"

        # Start lab if needed
        if self.get_lab_state(lab_id) != "STARTED":
            self.startlab(lab_id)
            for _ in range(30):
                time.sleep(10)
                if self.get_lab_state(lab_id) == "STARTED":
                    break
            else:
                return f"Failed: {device_name} lab_not_started"

        # Get testbed
        testbed_yaml = self.gettestbed(lab_id)
        if not testbed_yaml:
            return f"Failed: {device_name} no_testbed"
        try:
            testbed_data = yaml.safe_load(testbed_yaml)
        except Exception:
            return f"Failed: {device_name} invalid_testbed"

        # Device map (case-insensitive)
        device_map = {k.lower(): k for k in testbed_data.get('devices', {}) if k.lower() != 'terminal_server'}
        actual_dev = device_map.get(device_name.lower())
        if not actual_dev:
            return f"Failed: {device_name} not_in_testbed"

        ts = testbed_data['devices'].get('terminal_server')
        if not ts:
            return f"Failed: {device_name} no_terminal_server"

        # Minimal testbed
        minimal = {
            'devices': {
                actual_dev: testbed_data['devices'][actual_dev].copy(),
                'terminal_server': ts.copy()
            }
        }

        # Override credentials if supplied
        if username and password:
            if 'credentials' not in minimal['devices'][actual_dev]:
                minimal['devices'][actual_dev]['credentials'] = {}
            minimal['devices'][actual_dev]['credentials']['default'] = {
                'username': username,
                'password': password
            }

        # Load testbed
        try:
            tb_yaml = yaml.safe_dump(minimal)
            testbed = load(tb_yaml)
        except Exception as e:
            return f"Failed: {device_name} testbed_load: {str(e)[:50]}"

        dev = testbed.devices[actual_dev]
        try:
            dev.connect()
        except Exception as e:
            return f"Failed: {device_name} connect: {str(e)[:50]}"

        # Split and execute commands
        cmds = [c.strip() for c in command_str.splitlines() if c.strip()]
        if not cmds:
            dev.disconnect()
            return f"Failed: {device_name} empty_command"

        raw_output = ''
        for cmd in cmds:
            try:
                out = dev.execute(cmd)
                raw_output += out.text.rstrip() + '\n\n'
            except Exception as e:
                dev.disconnect()
                short_cmd = cmd[:30] + '...' if len(cmd) > 30 else cmd
                return f"Failed: {device_name} '{short_cmd}': {str(e)[:50]}"

        dev.disconnect()
        return raw_output.rstrip('\n')

    # =============================================================================
    # ORIGINAL VALIDATE (unchanged except credential override handling)
    # =============================================================================
    def apply_device_info_credentials(self, testbed_yaml, device_info_list):
        try:
            testbed_data = yaml.safe_load(testbed_yaml)
            for info in device_info_list:
                dev_name = info.get("device_name")
                creds = info.get("credentials", {})
                if not dev_name or not creds:
                    continue
                dev_key = next((k for k in testbed_data['devices'] if k.lower() == dev_name.lower()), None)
                if dev_key:
                    testbed_data['devices'][dev_key].setdefault('credentials', {})['default'] = {
                        'username': creds.get('username', ''),
                        'password': creds.get('password', '')
                    }
            return yaml.safe_dump(testbed_data)
        except Exception as e:
            logging.warning(f"Failed to apply device_info credentials: {e}")
            return testbed_yaml

    def execute_commands_on_device(self, device, testbed, actual_dev):
        dev = testbed.devices[actual_dev]
        results = []
        device_passed = True
        status = "Correctly Configured"

        try:
            dev.connect()
        except Exception as e:
            results.append(f"Incorrectly Configured - {device['device_name']} - connect_failed")
            return results, False

        for cmd_block in device.get('commands', []):
            command = cmd_block['command']
            validations = cmd_block.get('validations', [])
            passed = True
            try:
                output = dev.execute(command)
                data = output.text
            except Exception as e:
                results.append(f"Incorrectly Configured - {device['device_name']} - {command} - exec_failed")
                passed = False
                device_passed = False
                continue

            for validation in validations:
                ok, msgs = validate_pattern(validation, data, device['device_name'], command, self.debug)
                if not ok:
                    passed = False
                    device_passed = False
                results.extend(msgs)

            if not passed:
                status = "Incorrectly Configured"
            results.append(f"{status} - {device['device_name']} - {command}")
            if not passed:
                device_passed = False

        try:
            dev.disconnect()
        except:
            pass

        return results, device_passed

    def validate(self, lab_id, device_info=None):
        # Resolve lab_id
        if not lab_id:
            lab_id = self.findlab()
            if not lab_id:
                msg = "Error: No lab ID provided and no default lab found"
                logging.error(msg)
                print(msg, file=sys.stderr)
                return [msg], False
        if not self._is_valid_lab_id(lab_id):
            lab_id = self.findlab(lab_id)
            if not lab_id:
                msg = "Error: No lab found"
                logging.error(msg)
                print(msg, file=sys.stderr)
                return [msg], False

        # Start lab if needed
        if self.get_lab_state(lab_id) != "STARTED":
            self.startlab(lab_id)
            for _ in range(30):
                time.sleep(10)
                if self.get_lab_state(lab_id) == "STARTED":
                    break

        # Get testbed
        testbed_yaml = self.gettestbed(lab_id)
        if not testbed_yaml:
            msg = "Error: Failed to fetch testbed YAML"
            logging.error(msg)
            print(msg, file=sys.stderr)
            return [msg], False

        # Apply device_info credentials (optional)
        if device_info:
            try:
                device_info_list = ast.literal_eval(device_info)
                if isinstance(device_info_list, list):
                    testbed_yaml = self.apply_device_info_credentials(testbed_yaml, device_info_list)
            except Exception as e:
                logging.warning(f"Failed to parse device_info for credentials: {e}")

        try:
            testbed_data = yaml.safe_load(testbed_yaml)
        except Exception as e:
            msg = "Error: Failed to parse testbed YAML"
            logging.error(msg)
            print(msg, file=sys.stderr)
            return [msg], False

        # Device map from testbed
        device_map = {
            k.lower(): k for k in testbed_data['devices']
            if k != 'terminal_server'
        }

        # Build device_info list
        if not device_info:
            device_info_list = []
            for name in device_map.values():
                os_type = testbed_data['devices'][name].get('os', '').lower()
                cmd = "show version" if os_type == 'ios' else "uname -a"
                pattern = "Cisco IOS Software" if os_type == 'ios' else "Linux"
                device_info_list.append({
                    "device_name": name,
                    "commands": [{
                        "command": cmd,
                        "validations": [{"pattern": pattern, "match_type": "wildcard"}]
                    }]
                })
        else:
            try:
                device_info_list = ast.literal_eval(device_info)
            except Exception as e:
                msg = "Error: Invalid device_info"
                logging.error(msg)
                print(msg, file=sys.stderr)
                return [msg], False

        all_results = []
        overall_result = True

        for device in device_info_list:
            req = device['device_name'].lower()
            actual = device_map.get(req)
            if not actual:
                msg = f"Incorrectly Configured - {device['device_name']} - not_in_testbed"
                all_results.append(msg)
                overall_result = False
                continue

            # Minimal testbed
            minimal = {
                'devices': {
                    actual: testbed_data['devices'][actual],
                    'terminal_server': testbed_data['devices']['terminal_server']
                }
            }
            try:
                testbed = load(yaml.safe_dump(minimal))
            except Exception as e:
                msg = f"Incorrectly Configured - {device['device_name']} - testbed_load_failed"
                all_results.append(msg)
                logging.error(f"Load failed: {e}")
                overall_result = False
                continue

            res, passed = self.execute_commands_on_device(device, testbed, actual)
            all_results.extend(res)
            if not passed:
                overall_result = False

        return all_results, overall_result

    def import_lab(self, source_url):
        # Unified import: download, convert, and upload to CML
        # Now idempotent: if lab with same title exists, return existing ID
        if 'github.com' in source_url and '/blob/' in source_url:
            source_url = source_url.replace('github.com', 'raw.githubusercontent.com').replace('/blob/', '/')
            if self.debug:
                logging.info(f"Converted blob URL to raw: {source_url}")

        try:
            if self.debug:
                logging.info(f"Downloading from {source_url}")
            response = requests.get(source_url, verify=False)
            response.raise_for_status()
            content = response.content
            filename = source_url.split('/')[-1].lower()

            is_zip = (
                filename.endswith('.zip') or
                response.headers.get('Content-Type', '').startswith('application/zip') or
                content[:2] == b'PK'
            )

            if is_zip:
                if self.debug:
                    logging.info("Extracting ZIP...")
                with ZipFile(BytesIO(content)) as z:
                    candidates = [f for f in z.namelist() if f.lower().endswith(('.cml', '.yaml', '.yml'))]
                    if not candidates:
                        print("Error: No lab file in ZIP", file=sys.stderr)
                        return ""
                    file_bytes = z.read(candidates[0])
                    filename = candidates[0]
            else:
                file_bytes = content

            try:
                file_str = file_bytes.decode('utf-8')
            except UnicodeDecodeError:
                print("Error: File is not UTF-8", file=sys.stderr)
                return ""

            # Parse title from YAML or CML
            lab_title = None
            if filename.endswith(('.yaml', '.yml')):
                try:
                    data = yaml.safe_load(file_str)
                    lab_title = data.get("lab", {}).get("title") or data.get("title")
                    lab_json = json.dumps(data, indent=2)
                except yaml.YAMLError as e:
                    print(f"Error: Invalid YAML: {e}", file=sys.stderr)
                    return ""
            else:
                lab_json = file_str
                try:
                    data = json.loads(lab_json)
                    lab_title = data.get("lab", {}).get("title") or data.get("title")
                except json.JSONDecodeError:
                    pass  # fall back to import

            # === IDEMPOTENCY: Check if lab with this title already exists ===
            if lab_title:
                existing_lab_id = self.findlab(lab_title)
                if existing_lab_id:
                    print(existing_lab_id)  # Return existing ID
                    if self.debug:
                        print(f"Lab already exists: '{lab_title}' → {existing_lab_id}", file=sys.stderr)
                    return existing_lab_id

            # === Upload new lab ===
            try:
                self.ensure_jwt()
                if self.debug:
                    logging.info("Uploading lab to CML...")
                response = requests.post(
                    f"{self.cml_address}/api/v0/import",
                    headers={
                        "Authorization": f"Bearer {self.jwt}",
                        "Content-Type": "application/json"
                    },
                    data=lab_json,
                    verify=False
                )
                response.raise_for_status()
                result = response.json()
                lab_id = result.get("id", "unknown")
                print(lab_id)
                if self.debug:
                    print(f"Lab imported: {lab_id}", file=sys.stderr)
                return lab_id

            except requests.RequestException as e:
                print(f"Error: Upload failed: {e}", file=sys.stderr)
                if hasattr(e, 'response') and e.response is not None:
                    print(f"Response: {e.response.text}", file=sys.stderr)
                return ""

        except requests.RequestException as e:
            print(f"Error: Download failed: {e}", file=sys.stderr)
            return ""
        except Exception as e:
            print(f"Error: Import failed: {e}", file=sys.stderr)
            return ""

def main():
    # Main function to handle command-line arguments and dispatch commands
    # Supports positional arguments (FUNCTION, LABID) and named arguments
    # (-function, -labid, -deviceinfo, -devicename, -command, -username, -password, -source, --debug)
    # All parameter names and function values are case-insensitive
    parser = CaseInsensitiveArgumentParser(
        description="CML Tools for lab management, validation, and raw execution",
        usage="%(prog)s [FUNCTION] [LABID] [-deviceinfo INFO] [-source URL] [--debug]\n"
              "       %(prog)s -function FUNCTION [-labid LABID] [-deviceinfo INFO] [-source URL] [--debug]\n"
              "       %(prog)s execute [LABID] -devicename DEV -command \"CMD\" [-username U] [-password P] [--debug]"
    )
    parser.add_argument(
        "function",
        nargs="?",
        help="Function to execute (authenticate, findlab, getlabs, getdetails, getstate, startlab, stoplab, gettestbed, validate, execute, importlab)"
    )
    parser.add_argument(
        "labid",
        nargs="?",
        help="Lab ID or title (required for most functions)"
    )
    parser.add_argument(
        "-function",
        dest="named_function",
        help="Function to execute (alternative to positional argument)"
    )
    parser.add_argument(
        "-labid",
        dest="named_labid",
        help="Lab ID or title (alternative to positional argument)"
    )
    parser.add_argument(
        "-deviceinfo",
        help="Device info JSON (optional for validate; if empty, uses testbed YAML)"
    )
    parser.add_argument(
        "-devicename",
        help="Device name (required for execute)"
    )
    parser.add_argument(
        "-command",
        help="Command(s) to execute (required for execute; use \\n for multiple)"
    )
    parser.add_argument(
        "-username",
        help="Username override (optional for execute/validate)"
    )
    parser.add_argument(
        "-password",
        help="Password override (optional for execute/validate)"
    )
    parser.add_argument(
        "-source",
        help="Public GitHub URL to download a CML lab file for importlab"
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Enable debug logging"
    )
    args = parser.parse_args()

    # Handle positional and named arguments
    function = (args.function or args.named_function or "").lower()
    labid = args.labid or args.named_labid
    if not function:
        parser.print_help()
        sys.exit(1)

    # Validate function
    valid_functions = ["authenticate", "findlab", "getlabs", "getdetails", "getstate", "startlab", "stoplab", "gettestbed", "validate", "execute", "importlab"]
    if function not in valid_functions:
        print(f"Error: Invalid function '{function}'. Valid functions: {', '.join(valid_functions)}", file=sys.stderr)
        sys.exit(1)

    # Initialize CMLClient with environment variables
    cml_address = os.environ.get("CML_ADDRESS", "https://192.168.1.10")
    cml_ip = os.environ.get("CML_IP", "192.168.1.10")
    username = os.environ.get("CML_USERNAME", "")
    password = os.environ.get("CML_PASSWORD", "")
    if not username or not password:
        print("Error: CML_USERNAME and CML_PASSWORD must be set", file=sys.stderr)
        sys.exit(1)

    client = CMLClient(cml_address, cml_ip, username, password, args.debug)

    # Dispatch functions
    if function == "authenticate":
        print(client.authenticate())
    elif function == "findlab":
        print(client.findlab(labid))
    elif function == "getlabs":
        print(json.dumps(client.get_labs(), indent=2))
    elif function == "getdetails":
        if not labid:
            print("Error: -labid or positional LABID required for getdetails", file=sys.stderr)
            sys.exit(1)
        print(json.dumps(client.get_lab_details(labid), indent=2))
    elif function == "getstate":
        if not labid:
            labid = client.findlab()
            if not labid:
                print("Error: No lab ID provided and no default lab found", file=sys.stderr)
                sys.exit(1)
        if not client._is_valid_lab_id(labid):
            labid = client.findlab(labid)
            if not labid:
                print("Error: No lab found", file=sys.stderr)
                sys.exit(1)
        print(client.get_lab_state(labid))
    elif function == "startlab":
        print(client.startlab(labid))
    elif function == "stoplab":
        print(client.stoplab(labid))
    elif function == "gettestbed":
        print(client.gettestbed(labid))
    elif function == "validate":
        results, overall_result = client.validate(labid, args.deviceinfo)
        for result in results:
            print(result)
        print(str(overall_result))
    elif function == "execute":
        if not args.devicename or not args.command:
            print("Error: -devicename and -command required for execute", file=sys.stderr)
            sys.exit(1)
        output = client.execute(labid, args.devicename, args.command, args.username, args.password)
        print(output)
    elif function == "importlab":
        if not args.source:
            print("Error: -source URL required for importlab function", file=sys.stderr)
            sys.exit(1)
        lab_id = client.import_lab(args.source)
        if not lab_id:
            sys.exit(1)
    else:
        parser.print_help()
        sys.exit(1)

if __name__ == "__main__":
    main()
EOF

# Make the Python script executable
chmod +x "$PYTHON_SCRIPT_PATH" || { echo "Error: Failed to set permissions on $PYTHON_SCRIPT_PATH" >&2; echo false; return 1; }

# Confirm successful generation
echo true
