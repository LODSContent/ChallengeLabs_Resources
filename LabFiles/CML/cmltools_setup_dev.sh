#!/bin/bash
# =============================================================================
# CML Tools Setup Script
# Creates cml_env.sh and cmltools.py with environment variables
# Will be downloaded and executed automatically on the pyATS VM from a Lifecycle Action
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
  if [[ "${SCRIPT_DEBUG,,}" == "true" ]]; then
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

# Generate the Python script file
cat << 'EOF' > "$PYTHON_SCRIPT_PATH" || { echo "Error: Failed to write to $PYTHON_SCRIPT_PATH" >&2; echo false; return 1; }
#!/usr/bin/env python3
# CML Tools v1.20251105.1838
# Script for lab management, import, and validation
# Interacts with Cisco Modeling Labs (CML) to manage labs and validate device configurations
# Supports case-insensitive commands and parameter names
#
# Usage:
#   cmltools.py [FUNCTION] [LABID] [-deviceinfo JSON] [-source URL] [--debug] [--clear]
#   cmltools.py [-function FUNCTION] [-labid LABID] [-devicename NAME] [-command CMD] [-pattern PAT] [-timeout SEC] [--debug] [--regex] [--clear]
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
#   validate: Validate device configurations or return raw command output
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
    # Normalizes option names (e.g., -COMMAND, -LabID) to lowercase
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
        try:
            data = json.dumps(data, indent=2)
        except:
            data = str(data)
    elif isinstance(data, (list, tuple)):
        data = '\n'.join(str(item) for item in data)
    elif not isinstance(data, (str, bytes)):
        data = str(data)

    if isinstance(data, bytes):
        data = data.decode('utf-8', errors='ignore')

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
            state = response.json()
            if not state or state == "null":
                logging.error(f"Invalid state response for lab {lab_id}")
                print(f"Error: Invalid state response for lab {lab_id}", file=sys.stderr)
                return ""
            if self.debug:
                logging.info(f"Lab {lab_id} state: {state}")
            return state
        except requests.RequestException as e:
            logging.error(f"Failed to get state for lab {lab_id}: {e}")
            print(f"Error: Failed to get state for lab {lab_id}: {e}", file=sys.stderr)
            return ""

    def get_lab_details(self, lab_id):
        # Get detailed information about a lab
        # Args:
        #   lab_id: UUID of the lab
        # Returns: Dict with lab details, or empty dict on failure
        try:
            self.ensure_jwt()
            response = requests.get(
                f"{self.cml_address}/api/v0/labs/{lab_id}",
                headers={"accept": "application/json", "Authorization": f"Bearer {self.jwt}"},
                verify=False
            )
            response.raise_for_status()
            details = response.json()
            if not details or details == "null":
                logging.error(f"Invalid details response for lab {lab_id}")
                print(f"Error: Invalid details response for lab {lab_id}", file=sys.stderr)
                return {}
            if self.debug:
                logging.info(f"Retrieved details for lab {lab_id}: {json.dumps(details, indent=2)[:100]}...")
            return details
        except requests.RequestException as e:
            logging.error(f"Failed to get details for lab {lab_id}: {e}")
            print(f"Error: Failed to get details for lab {lab_id}: {e}", file=sys.stderr)
            return {}

    def get_default_lab_id(self, lab_ids):
        # Find the first started lab or first available lab
        # Args:
        #   lab_ids: List of lab IDs
        # Returns: Lab ID, or empty string if none available
        for lab_id in lab_ids:
            state = self.get_lab_state(lab_id)
            if state == "STARTED":
                if self.debug:
                    logging.info(f"Found started lab: {lab_id}")
                return lab_id
        return lab_ids[0] if lab_ids else ""

    def findlab(self, lab_title=None):
        # Find a lab by title or return the first running/available lab
        # Args:
        #   lab_title: Title of the lab to find (optional, case-insensitive, whitespace-tolerant)
        # Returns: Lab ID, or empty string if not found
        lab_ids = self.get_labs()
        if not lab_ids:
            logging.error("No labs found")
            print("Error: No labs found", file=sys.stderr)
            return ""
        if lab_title:
            search_title = lab_title.strip().lower()
            for lab_id in lab_ids:
                details = self.get_lab_details(lab_id)
                lab_name = details.get("lab_title", "").strip().lower()
                if lab_name == search_title:
                    if self.debug:
                        logging.info(f"Found lab with title '{lab_title}' (normalized: '{lab_name}'): {lab_id}")
                    return lab_id
            logging.error(f"No lab found with title '{lab_title}' (searched as '{search_title}')")
            print(f"Error: No lab found with title '{lab_title}'", file=sys.stderr)
            return ""
        lab_id = self.get_default_lab_id(lab_ids)
        if not lab_id:
            logging.error("No labs available")
            print("Error: No labs available", file=sys.stderr)
            return ""
        if self.debug:
            logging.info(f"Selected default lab: {lab_id}")
        return lab_id

    def startlab(self, lab_id=None):
        # Start a specific lab or the first available lab
        # Args:
        #   lab_id: UUID or title of the lab (optional)
        # Returns: Lab ID on success, empty string on failure
        if not lab_id:
            lab_id = self.findlab()
            if not lab_id:
                logging.error("No lab ID provided and no default lab found")
                print("Error: No lab ID provided and no default lab found", file=sys.stderr)
                return ""
        if not self._is_valid_lab_id(lab_id):
            lab_id = self.findlab(lab_id)
            if not lab_id:
                return ""
        sku = os.environ.get("CML_SKU", "").strip().lower()
        if sku == "free":
            all_lab_ids = self.get_labs()
            for lid in all_lab_ids:
                if lid == lab_id:
                    continue
                cur_state = self.get_lab_state(lid)
                if cur_state == "STARTED":
                    if self.debug:
                        logging.info(f"Free SKU: stopping other lab {lid}")
                    try:
                        requests.put(
                            f"{self.cml_address}/api/v0/labs/{lid}/stop",
                            headers={
                                "accept": "application/json",
                                "Authorization": f"Bearer {self.jwt}",
                                "Content-Type": "application/json"
                            },
                            verify=False
                        )
                    except requests.RequestException as e:
                        logging.error(f"Failed to stop lab {lid}: {e}")
        try:
            self.ensure_jwt()
            response = requests.put(
                f"{self.cml_address}/api/v0/labs/{lab_id}/start",
                headers={
                    "accept": "application/json",
                    "Authorization": f"Bearer {self.jwt}",
                    "Content-Type": "application/json"
                },
                verify=False
            )
            response.raise_for_status()
            if self.debug:
                logging.info(f"Started lab {lab_id}")
            return lab_id
        except requests.RequestException as e:
            logging.error(f"Failed to start lab {lab_id}: {e}")
            print(f"Error: Failed to start lab {lab_id}: {e}", file=sys.stderr)
            return ""

    def stoplab(self, lab_id=None):
        # Stop a specific lab or the first available lab
        # Args:
        #   lab_id: UUID or title of the lab (optional)
        # Returns: Lab ID on success, empty string on failure
        if not lab_id:
            lab_id = self.findlab()
            if not lab_id:
                logging.error("No lab ID provided and no default lab found")
                print("Error: No lab ID provided and no default lab found", file=sys.stderr)
                return ""
        if not self._is_valid_lab_id(lab_id):
            lab_id = self.findlab(lab_id)
            if not lab_id:
                return ""
        try:
            self.ensure_jwt()
            response = requests.put(
                f"{self.cml_address}/api/v0/labs/{lab_id}/stop",
                headers={
                    "accept": "application/json",
                    "Authorization": f"Bearer {self.jwt}",
                    "Content-Type": "application/json"
                },
                verify=False
            )
            response.raise_for_status()
            if self.debug:
                logging.info(f"Stopped lab {lab_id}")
            return lab_id
        except requests.RequestException as e:
            logging.error(f"Failed to stop lab {lab_id}: {e}")
            print(f"Error: Failed to stop lab {lab_id}: {e}", file=sys.stderr)
            return ""

    def gettestbed(self, lab_id=None):
        # Get PyATS testbed YAML for a lab
        # Args:
        #   lab_id: UUID or title of the lab (optional)
        # Returns: Testbed YAML (str), or empty string on failure
        if not lab_id:
            lab_id = self.findlab()
            if not lab_id:
                logging.error("No lab ID provided and no default lab found")
                print("Error: No lab ID provided and no default lab found", file=sys.stderr)
                return ""
        if not self._is_valid_lab_id(lab_id):
            lab_id = self.findlab(lab_id)
            if not lab_id:
                return ""
        try:
            self.ensure_jwt()
            response = requests.get(
                f"{self.cml_address}/api/v0/labs/{lab_id}/pyats_testbed?hostname={self.cml_ip}",
                headers={"accept": "application/x-yaml", "Authorization": f"Bearer {self.jwt}"},
                verify=False
            )
            response.raise_for_status()
            testbed_yaml = response.text
            if not testbed_yaml or testbed_yaml in ["false", "null"] or "testbed:" not in testbed_yaml:
                logging.error(f"Invalid testbed YAML for lab {lab_id}")
                print(f"Error: Invalid testbed YAML for lab {lab_id}", file=sys.stderr)
                return ""
            testbed_yaml = self.update_testbed_device_credentials(testbed_yaml, "terminal_server", self.username, self.password)
            if self.debug:
                logging.info(f"Retrieved testbed YAML for lab {lab_id}: {testbed_yaml[:100]}...")
            return testbed_yaml
        except requests.RequestException as e:
            logging.error(f"Failed to fetch testbed YAML for lab {lab_id}: {e}")
            print(f"Error: Failed to fetch testbed YAML for lab {lab_id}: {e}", file=sys.stderr)
            return ""

    def update_testbed_device_credentials(self, testbed_yaml, device_name, username, password):
        # Update device credentials in a testbed YAML
        # Args:
        #   testbed_yaml: YAML string of the testbed
        #   device_name: Device to update (e.g., terminal_server)
        #   username: Username to set
        #   password: Password to set
        # Returns: Updated YAML string, or original YAML on failure
        try:
            data = yaml.safe_load(testbed_yaml)
            if not data or 'devices' not in data or device_name not in data['devices']:
                logging.error(f"Invalid testbed YAML structure for device {device_name}")
                print(f"Error: Invalid testbed YAML structure for device {device_name}", file=sys.stderr)
                return testbed_yaml
            data['devices'][device_name]['credentials']['default']['username'] = username
            data['devices'][device_name]['credentials']['default']['password'] = password
            return yaml.safe_dump(data)
        except yaml.YAMLError as e:
            logging.error(f"Failed to update testbed YAML: {e}")
            print(f"Error: Failed to update testbed YAML: {e}", file=sys.stderr)
            return testbed_yaml

    def apply_device_info_credentials(self, testbed_yaml, device_info_list):
        # Apply optional username/password from device_info to the testbed
        # Only touches devices that have a 'credentials' block
        try:
            data = yaml.safe_load(testbed_yaml)
            if not data or 'devices' not in data:
                return testbed_yaml
            cred_map = {}
            for dev in device_info_list:
                name = dev.get('device_name')
                creds = dev.get('credentials')
                if name and creds and isinstance(creds, dict):
                    cred_map[name.lower()] = {
                        'username': creds.get('username', 'cisco'),
                        'password': creds.get('password', 'cisco')
                    }
            if not cred_map:
                return testbed_yaml
            for dev_name, dev in data['devices'].items():
                override = cred_map.get(dev_name.lower())
                if override:
                    creds = dev.setdefault('credentials', {}).setdefault('default', {})
                    creds['username'] = override['username']
                    creds['password'] = override['password']
                    if self.debug:
                        logging.info(f"Applied device_info credentials to {dev_name}: {override['username']}/***")
            return yaml.safe_dump(data)
        except Exception as e:
            logging.error(f"Failed to apply device_info credentials: {e}")
            return testbed_yaml

    def send_clear_sequence(self, dev, os_type, wait_for_prompt=False):
        # Send Ctrl-Z and clear/exit sequence to escape editors and clear screen
        # Hides output from raw results by not capturing response
        try:
            dev.sendline('\x1A')  # Ctrl-Z
            time.sleep(0.2)
            if os_type == 'ios':
                dev.sendline('exit')
                time.sleep(0.1)
                if wait_for_prompt:
                    dev.sendline('')  # Enter to get prompt
                    time.sleep(0.3)
            else:
                dev.sendline('clear')
                time.sleep(0.1)
        except:
            pass  # Best effort

    def execute_commands_on_device(self, device, testbed, actual_name, timeout=60, clear_screen=False):
        results = []
        raw_outputs = []
        device_passed = True
        dev_name = device['device_name']
        dev = testbed.devices.get(actual_name)
        if not dev:
            msg = f"Incorrectly Configured - {dev_name} - not_in_testbed"
            results.append(msg)
            return results, False, raw_outputs
        try:
            connect_kwargs = {
                'mit': True,
                'hostkey_verify': False,
                'allow_agent': False,
                'look_for_keys': False,
                'timeout': 60
            }
            init_cmds = ['\r'] if getattr(dev, 'os', '').lower() == 'ios' else []
            dev.connect(init_exec_commands=init_cmds, **connect_kwargs)
            if self.debug:
                logging.info(f"Connected to {actual_name}")
        except Exception as e:
            msg = f"Incorrectly Configured - {dev_name} - connect_failed"
            results.append(msg)
            logging.error(f"Connect failed for {actual_name}: {e}")
            return results, False, raw_outputs

        os_type = getattr(dev, 'os', '').lower()
        merged_output = []

        # === CLEAR BEFORE FIRST COMMAND (if --clear) ===
        if clear_screen:
            self.send_clear_sequence(dev, os_type, wait_for_prompt=True)

        for cmd_info in device['commands']:
            cmd = cmd_info['command']
            # === MERGE COMMAND: validate once on all output ===
            if cmd == "__MERGE_FOR_VALIDATION__":
                combined = "\n\n".join(merged_output)
                passed = True
                for val in cmd_info.get('validations', []):
                    ok, _ = validate_pattern(val, combined, dev_name, "MERGED", self.debug)
                    if not ok:
                        passed = False
                status = "Correctly Configured" if passed else "Incorrectly Configured"
                results.append(f"{status} - {dev_name} - {cmd_info.get('original_cmd', 'UNKNOWN')}")
                device_passed = passed
                continue
            # === NORMAL COMMAND: collect output ===
            try:
                if timeout == 0:
                    dev.sendline(cmd)
                    merged_output.append("")
                else:
                    output = dev.execute(cmd, timeout=timeout)
                    merged_output.append(output)
            except Exception as e:
                merged_output.append("")
                logging.error(f"Command failed: {cmd} – {e}")
                device_passed = False

            # === CLEAR AFTER EACH COMMAND (if --clear) ===
            if clear_screen:
                self.send_clear_sequence(dev, os_type, wait_for_prompt=True)

        # === FINAL CLEAR AFTER LAST COMMAND (if --clear) ===
        if clear_screen:
            self.send_clear_sequence(dev, os_type, wait_for_prompt=False)

        try:
            dev.disconnect()
        except:
            pass
        return results, device_passed, merged_output

    def validate(self, lab_id, device_info=None, timeout=60, clear_screen=False):
        # Validate device configurations
        # Args:
        #   lab_id: Lab ID or title
        #   device_info: JSON string of device info (or None for default)
        #   timeout: Per-command timeout in seconds (default: 60)
        #   clear_screen: If True, send clear sequence before, after each, and after all commands
        # Returns: results (list), overall_result (bool), raw_output (str if no validation)
        if not lab_id:
            lab_id = self.findlab()
            if not lab_id:
                msg = "Error: No lab ID provided and no default lab found"
                logging.error(msg)
                print(msg, file=sys.stderr)
                return [msg], False, ""
        if not self._is_valid_lab_id(lab_id):
            lab_id = self.findlab(lab_id)
            if not lab_id:
                msg = "Error: No lab found"
                logging.error(msg)
                print(msg, file=sys.stderr)
                return [msg], False, ""
        if self.get_lab_state(lab_id) != "STARTED":
            self.startlab(lab_id)
            for _ in range(30):
                time.sleep(10)
                if self.get_lab_state(lab_id) == "STARTED":
                    break
        testbed_yaml = self.gettestbed(lab_id)
        if not testbed_yaml:
            msg = "Error: Failed to fetch testbed YAML"
            logging.error(msg)
            print(msg, file=sys.stderr)
            return [msg], False, ""
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
            return [msg], False, ""
        device_map = {
            k.lower(): k for k in testbed_data['devices']
            if k != 'terminal_server'
        }
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
                return [msg], False, ""
        has_validations = any(
            any("validations" in cmd_info for cmd_info in dev.get("commands", []))
            for dev in device_info_list
        )
        all_results = []
        all_raw_outputs = []
        overall_result = True
        for device in device_info_list:
            req = device['device_name'].lower()
            actual = device_map.get(req)
            if not actual:
                msg = f"Incorrectly Configured - {device['device_name']} - not_in_testbed"
                all_results.append(msg)
                overall_result = False
                continue
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
            res, passed, raw_out = self.execute_commands_on_device(
                device, testbed, actual, timeout=timeout, clear_screen=clear_screen
            )
            all_results.extend(res)
            all_raw_outputs.extend(raw_out)
            if not passed:
                overall_result = False
        if has_validations:
            return all_results, overall_result, ""
        else:
            merged_raw = "\n\n".join(all_raw_outputs)
            return all_results, overall_result, merged_raw

    def _is_valid_lab_id(self, lab_id):
        # Check if a lab_id matches the UUID format
        # Args:
        #   lab_id: Lab ID to validate
        # Returns: True if valid UUID, False otherwise
        uuid_pattern = r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
        return bool(re.match(uuid_pattern, lab_id.lower()))

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
                    pass
            if lab_title:
                existing_lab_id = self.findlab(lab_title)
                if existing_lab_id:
                    print(existing_lab_id)
                    if self.debug:
                        print(f"Lab already exists: '{lab_title}' → {existing_lab_id}", file=sys.stderr)
                    return existing_lab_id
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
    # All parameter names and command values are case-insensitive
    parser = CaseInsensitiveArgumentParser(
        description="CML Tools for lab management and validation",
        usage="\n%(prog)s [FUNCTION] [LABID] [-deviceinfo JSON] [-source URL] [--debug] [--clear]\n%(prog)s [-function FUNCTION] [-labid LABID] [-devicename NAME] [-command CMD] [-pattern PAT] [-timeout SEC] [--debug] [--regex] [--clear]"
    )
    parser.add_argument("function", nargs="?", help="Function to execute")
    parser.add_argument("labid", nargs="?", help="Lab ID or title")
    parser.add_argument("-function", dest="named_function", help="Function to execute (alternative)")
    parser.add_argument("-labid", dest="named_labid", help="Lab ID or title (alternative)")
    parser.add_argument("-deviceinfo", help="Device info JSON")
    parser.add_argument("-devicename", help="Single device name")
    parser.add_argument("-username", help="Override username")
    parser.add_argument("-password", help="Override password")
    parser.add_argument("-command", help="Command(s) to run (\\n for newlines). Without -pattern, returns raw output.")
    parser.add_argument("-pattern", help="Validation pattern (wildcard or regex with --regex)")
    parser.add_argument("-timeout", type=int, default=60, help="Per-command timeout in seconds (default: 60). Use 0 to send command without waiting.")
    parser.add_argument("-source", help="Lab source URL for importlab")
    parser.add_argument("--debug", action="store_true", help="Enable debug logging")
    parser.add_argument("--regex", action="store_true", help="Use regex instead of wildcard for -pattern (default: wildcard)")
    parser.add_argument("--clear", action="store_true", help="Escape editors and clear screen before, after each, and after all commands")

    args = parser.parse_args()
    function = (args.function or args.named_function or "").lower()
    labid = args.labid or args.named_labid
    if not function:
        parser.print_help()
        sys.exit(1)

    valid_functions = ["authenticate", "findlab", "getlabs", "getdetails", "getstate", "startlab", "stoplab", "gettestbed", "validate", "importlab"]
    if function not in valid_functions:
        print(f"Error: Invalid function '{function}'. Valid: {', '.join(valid_functions)}", file=sys.stderr)
        sys.exit(1)

    cml_address = os.environ.get("CML_ADDRESS", "https://192.168.1.10")
    cml_ip = os.environ.get("CML_IP", "192.168.1.10")
    username = os.environ.get("CML_USERNAME", "")
    password = os.environ.get("CML_PASSWORD", "")
    if not username or not password:
        print("Error: CML_USERNAME and CML_PASSWORD must be set", file=sys.stderr)
        sys.exit(1)

    client = CMLClient(cml_address, cml_ip, username, password, args.debug)

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
        device_info = args.deviceinfo
        original_cmd = ""
        # === SINGLE DEVICE MODE ===
        if args.devicename:
            if device_info:
                print("Error: Cannot use both -deviceinfo and -devicename", file=sys.stderr)
                sys.exit(1)
            device = {"device_name": args.devicename, "commands": []}
            if args.username or args.password:
                device["credentials"] = {}
                if args.username:
                    device["credentials"]["username"] = args.username
                if args.password:
                    device["credentials"]["password"] = args.password
            if args.command:
                original_cmd = args.command
                processed = args.command.replace('\\n', '\n')
                raw_cmds = [c.strip() for c in processed.split('\n') if c.strip()]
            else:
                raw_cmds = []
            for cmd in raw_cmds:
                device["commands"].append({"command": cmd})
            if args.pattern and raw_cmds:
                device["commands"].append({
                    "command": "__MERGE_FOR_VALIDATION__",
                    "validations": [{
                        "pattern": args.pattern,
                        "match_type": "regex" if args.regex else "wildcard"
                    }],
                    "original_cmd": original_cmd
                })
            device_info = json.dumps([device])
        # === CALL VALIDATE WITH CLEAR OPTION ===
        results, overall_result, merged_raw = client.validate(
            labid, device_info, timeout=args.timeout, clear_screen=args.clear
        )
        # === OUTPUT HANDLING ===
        if args.pattern:
            for result in results:
                print(result)
            print(str(overall_result).lower())
        else:
            if merged_raw:
                print(merged_raw.rstrip())
    elif function == "importlab":
        if not args.source:
            print("Error: -source URL required for importlab", file=sys.stderr)
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
