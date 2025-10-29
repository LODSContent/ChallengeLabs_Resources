#!/bin/bash
# =============================================================================
# CML Tools Setup Script v1.10292025.0010
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
  if [[ "${SCRIPT_DEBUG,,}" == "true" ]]; then
    echo "Debug: $*" >&2
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
# CML Tools v1.10292025.0022
# For lab management, import, and validation
# Interacts with Cisco Modeling Labs (CML) to manage labs and validate device configurations
# Supports case-insensitive commands and parameter names
#
# Usage:
#   cmltools.py [COMMAND] [LABID] [--deviceinfo DEVICEINFO] [-source URL] [--debug]
#   cmltools.py [-command COMMAND] [-labid LABID] [--deviceinfo DEVICEINFO] [-source URL] [--debug]
#
# Commands:
#   authenticate: Authenticate with CML server and return JWT token
#   findlab: Find a lab by title or return first running/available lab
#   getlabs: Get a list of all lab IDs
#   getdetails: Get detailed information about a specific lab
#   getstate: Get the state of a specific lab
#   startlab: Start a specific lab
#   stoplab: Stop a specific lab
#   gettestbed: Get PyATS testbed YAML for a lab
#   validate: Validate device configurations
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
from pyats.topology import loader
from pyats.topology import Device, Testbed
from pyats.topology.connection import Connection
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
    # Validate a single pattern against command output
    # Args:
    #   validation: Validation pattern (str) or dict with pattern and match_type
    #   data: Command output to validate
    #   device_name: Name of the device
    #   command: Command being validated
    #   debug: Log detailed messages if True
    # Returns: Tuple (bool indicating if pattern matched, list of debug messages)
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

    try:
        regex = re.compile(regex_pattern, re.DOTALL)
        pattern_match = bool(regex.search(data))
    except re.error as e:
        error_msg = f"Invalid pattern '{pattern}' ({match_type}, regex: '{regex_pattern}') for {device_name}: {e}"
        logging.error(error_msg)
        if debug:
            results.append(error_msg)
        return False, results

    if not pattern_match:
        log_msg = f"Pattern '{pattern}' ({match_type}, regex: '{regex_pattern}') not found in output of '{command}' on {device_name}"
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
            # Normalize the search title: strip and lowercase
            search_title = lab_title.strip().lower()
            for lab_id in lab_ids:
                details = self.get_lab_details(lab_id)
                # Safely get and normalize lab title
                lab_name = details.get("lab_title", "").strip().lower()
                if lab_name == search_title:
                    if self.debug:
                        logging.info(f"Found lab with title '{lab_title}' (normalized: '{lab_name}'): {lab_id}")
                    return lab_id
            logging.error(f"No lab found with title '{lab_title}' (searched as '{search_title}')")
            print(f"Error: No lab found with title '{lab_title}'", file=sys.stderr)
            return ""

        # No title provided: fallback to first STARTED or first lab
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

        # Resolve title → UUID if needed
        if not self._is_valid_lab_id(lab_id):
            lab_id = self.findlab(lab_id)
            if not lab_id:
                return ""

        # ------------------------------------------------------------------
        # FREE SKU ENFORCEMENT
        # ------------------------------------------------------------------
        sku = os.environ.get("CML_SKU", "").strip().lower()
        if sku == "free":
            # Stop every lab *except* the one we are about to start
            all_lab_ids = self.get_labs()
            for lid in all_lab_ids:
                if lid == lab_id:
                    continue                     # keep the target lab
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

        # ------------------------------------------------------------------
        # START THE REQUESTED LAB
        # ------------------------------------------------------------------
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
        # Check if lab_id is a title and convert to ID
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
        # Check if lab_id is a title and convert to ID
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
            # Update terminal server credentials
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
            updated_yaml = yaml.safe_dump(data)
            return updated_yaml
        except yaml.YAMLError as e:
            logging.error(f"Failed to update testbed YAML: {e}")
            print(f"Error: Failed to update testbed YAML: {e}", file=sys.stderr)
            return testbed_yaml

    def build_default_device_info(self, testbed_yaml):
        try:
            data = yaml.safe_load(testbed_yaml)
            if not data or 'devices' not in data:
                logging.error("Invalid testbed YAML structure")
                return []
            device_info = []
            for device_name, device_data in data['devices'].items():
                if device_name == "terminal_server":
                    continue
                os_type = device_data.get('os')
                if os_type == "ios":
                    device_info.append({
                        "device_name": device_name,
                        "commands": [{
                            "command": "show version",
                            "validations": [{"pattern": "Cisco IOS Software", "match_type": "wildcard"}]
                        }]
                    })
                elif os_type == "linux":
                    device_info.append({
                        "device_name": device_name,
                        "commands": [{
                            "command": "uname -a",
                            "validations": [{"pattern": "Linux", "match_type": "wildcard"}]
                        }]
                    })
            if self.debug:
                logging.info(f"Built default device_info: {len(device_info)} devices")
            return device_info
        except yaml.YAMLError as e:
            logging.error(f"Failed to parse testbed YAML for device_info: {e}")
            return []

    def get_lab_credentials(self, lab_id):
        try:
            self.ensure_jwt()
            response = requests.get(
                f"{self.cml_address}/api/v0/labs/{lab_id}",
                headers={"Authorization": f"Bearer {self.jwt}"},
                verify=False
            )
            response.raise_for_status()
            lab_data = response.json()

            creds = {}
            for node in lab_data.get('nodes', []):
                label = node.get('label')
                if not label:
                    continue
                username = 'cisco'
                password = 'cisco'
                for cfg in node.get('configuration', []):
                    if cfg.get('name') == 'node.cfg':
                        content = cfg.get('content', '')
                        for line in content.splitlines():
                            if line.strip().startswith('USERNAME='):
                                username = line.split('=', 1)[1].strip().strip('"\'')
                            elif line.strip().startswith('PASSWORD='):
                                password = line.split('=', 1)[1].strip().strip('"\'')
                        break
                creds[label] = {'username': username, 'password': password}
            return creds
        except Exception as e:
            logging.error(f"Failed to fetch lab credentials: {e}")
            return {}

    def execute_commands_on_device(self, device, testbed, actual_name):
        results = []
        device_passed = True
        dev_name = device['device_name']

        dev = testbed.devices.get(actual_name)
        if not dev:
            msg = f"Incorrectly Configured - {dev_name} - not_in_testbed"
            results.append(msg)
            logging.error(msg)
            return results, False

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
            # RESILIENT: Log and continue
            msg = f"Incorrectly Configured - {dev_name} - connect_failed"
            results.append(msg)
            logging.error(f"Connect failed for {actual_name}: {e}")
            return results, False

        for cmd_info in device['commands']:
            cmd = cmd_info['command']
            try:
                output = dev.execute(cmd)
            except Exception as e:
                msg = f"Incorrectly Configured - {dev_name} - {cmd}"
                results.append(msg)
                logging.error(f"Command failed: {e}")
                device_passed = False
                continue

            validations = cmd_info.get('validations', [])
            if not validations:
                results.append(f"Correctly Configured - {dev_name} - {cmd}")
                continue

            passed = True
            for val in validations:
                match, _ = validate_pattern(val, output, dev_name, cmd, self.debug)
                if not match:
                    passed = False
            status = "Correctly Configured" if passed else "Incorrectly Configured"
            results.append(f"{status} - {dev_name} - {cmd}")
            if not passed:
                device_passed = False

        try:
            dev.disconnect()
        except:
            pass

        return results, device_passed

    def validate(self, lab_id, device_info):
        # Validate using gettestbed() + manual testbed construction
        # No load(), dynamic credentials, resilient, case-insensitive

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

        # Ensure lab is started
        state = self.get_lab_state(lab_id)
        if state != "STARTED":
            if self.debug:
                logging.info(f"Lab {lab_id} is in state {state}, attempting to start")
            self.startlab(lab_id)
            retries = int(os.environ.get("RETRY_COUNT", 30))
            delay = int(os.environ.get("RETRY_DELAY", 10))
            for _ in range(retries):
                time.sleep(delay)
                if self.get_lab_state(lab_id) == "STARTED":
                    break
            else:
                msg = f"Error: Lab {lab_id} failed to start after {retries} retries"
                logging.error(msg)
                print(msg, file=sys.stderr)
                return [msg], False

        # Get raw testbed YAML
        testbed_yaml = self.gettestbed(lab_id)
        if not testbed_yaml:
            msg = "Error: Failed to fetch testbed YAML"
            logging.error(msg)
            print(msg, file=sys.stderr)
            return [msg], False

        # Parse testbed YAML
        try:
            full_testbed_data = yaml.safe_load(testbed_yaml)
            if not full_testbed_data or 'devices' not in full_testbed_data:
                raise ValueError("Invalid testbed structure")
        except Exception as e:
            msg = f"Error: Failed to parse testbed YAML: {e}"
            logging.error(msg)
            print(msg, file=sys.stderr)
            return [msg], False

        # Case-insensitive device map (exclude terminal_server)
        device_map = {
            name.lower(): name for name in full_testbed_data['devices']
            if name != 'terminal_server'
        }

        # Fetch real credentials from CML lab definition
        lab_creds = self.get_lab_credentials(lab_id)

        # Build default device_info if not provided
        if not device_info:
            device_info = []
            for name in device_map.values():
                os_type = full_testbed_data['devices'][name].get('os', '').lower()
                if os_type == 'ios':
                    device_info.append({
                        "device_name": name,
                        "commands": [{
                            "command": "show version",
                            "validations": [{"pattern": "Cisco IOS Software", "match_type": "wildcard"}]
                        }]
                    })
                elif os_type == 'linux':
                    device_info.append({
                        "device_name": name,
                        "commands": [{
                            "command": "uname -a",
                            "validations": [{"pattern": "Linux", "match_type": "wildcard"}]
                        }]
                    })
        else:
            try:
                device_info = ast.literal_eval(device_info)
            except (ValueError, SyntaxError) as e:
                msg = f"Error: Invalid device_info JSON: {e}"
                logging.error(msg)
                print(msg, file=sys.stderr)
                return [msg], False

        all_results = []
        overall_result = True

        # Import required classes
        from pyats.topology import Device, Testbed, Connection

        for device in device_info:
            req_name = device['device_name']
            req_lower = req_name.lower()
            actual_name = device_map.get(req_lower)

            if not actual_name:
                msg = f"Incorrectly Configured - {req_name} - not_in_testbed"
                all_results.append(msg)
                logging.error(msg)
                overall_result = False
                continue

            try:
                # === BUILD MINIMAL TESTBED ===
                testbed = Testbed(name=f"validate-{lab_id}")

                # Device
                dev_data = full_testbed_data['devices'][actual_name]
                dev = Device(name=actual_name)
                dev.os = dev_data.get('os')
                dev.type = dev_data.get('type')
                dev.platform = dev_data.get('platform')

                # Connection 'a'
                conn_data = dev_data.get('connections', {}).get('a', {})
                if conn_data:
                    conn = Connection(
                        alias='a',
                        protocol=conn_data.get('protocol'),
                        command=conn_data.get('command'),
                        proxy=conn_data.get('proxy', 'terminal_server')
                    )
                    dev.connections[conn.alias] = conn

                # Apply real credentials
                if actual_name in lab_creds:
                    real = lab_creds[actual_name]
                    dev.credentials = {'default': real}
                else:
                    dev.credentials = dev_data.get('credentials', {})

                testbed.add_device(dev)

                # Terminal Server
                ts_data = full_testbed_data['devices']['terminal_server']
                ts = Device(name='terminal_server')
                ts.os = ts_data.get('os')

                ts_conn_data = ts_data.get('connections', {}).get('cli', {})
                if ts_conn_data:
                    ts_conn = Connection(
                        alias='cli',
                        protocol=ts_conn_data.get('protocol'),
                        ip=ts_conn_data.get('ip'),
                        port=ts_conn_data.get('port')
                    )
                    ts.connections[ts_conn.alias] = ts_conn

                ts.credentials = {
                    'default': {
                        'username': self.username,
                        'password': self.password
                    }
                }
                testbed.add_device(ts)

            except Exception as e:
                msg = f"Incorrectly Configured - {req_name} - testbed_build_failed"
                all_results.append(msg)
                logging.error(f"Failed to build testbed for {actual_name}: {e}")
                overall_result = False
                continue

            # === EXECUTE VALIDATION ===
            dev_results, dev_passed = self.execute_commands_on_device(device, testbed, actual_name)
            all_results.extend(dev_results)
            if not dev_passed:
                overall_result = False

        return all_results, overall_result

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
    # Supports positional arguments (COMMAND, LABID) and named arguments
    # (-command, -labid, -deviceinfo, -source, --debug)
    # All parameter names and command values are case-insensitive
    parser = CaseInsensitiveArgumentParser(
        description="CML Tools for lab management and validation",
        usage="%(prog)s [COMMAND] [LABID] [--deviceinfo DEVICEINFO] [-source URL] [--debug]"
    )
    parser.add_argument(
        "command",
        nargs="?",
        help="Command to execute (authenticate, findlab, getlabs, getdetails, getstate, startlab, stoplab, gettestbed, validate, importlab)"
    )
    parser.add_argument(
        "labid",
        nargs="?",
        help="Lab ID or title (required for findlab, getdetails, getstate, startlab, stoplab, gettestbed, validate if searching by title)"
    )
    parser.add_argument(
        "-command",
        dest="named_command",
        help="Command to execute (alternative to positional argument)"
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
        "-source",
        help="Public GitHub URL to download a CML lab file (.cml, .yaml, .yml, or .zip) for importlab"
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Enable debug logging"
    )
    args = parser.parse_args()

    # Handle positional and named arguments
    command = (args.command or args.named_command or "").lower()
    labid = args.labid or args.named_labid
    if not command:
        parser.print_help()
        sys.exit(1)

    # Validate command
    valid_commands = ["authenticate", "findlab", "getlabs", "getdetails", "getstate", "startlab", "stoplab", "gettestbed", "validate", "importlab"]
    if command not in valid_commands:
        print(f"Error: Invalid command '{command}'. Valid commands: {', '.join(valid_commands)}", file=sys.stderr)
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

    # Dispatch commands
    if command == "authenticate":
        print(client.authenticate())
    elif command == "findlab":
        print(client.findlab(labid))
    elif command == "getlabs":
        print(json.dumps(client.get_labs(), indent=2))
    elif command == "getdetails":
        if not labid:
            print("Error: -labid or positional LABID required for getdetails", file=sys.stderr)
            sys.exit(1)
        print(json.dumps(client.get_lab_details(labid), indent=2))
    elif command == "getstate":
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
    elif command == "startlab":
        print(client.startlab(labid))
    elif command == "stoplab":
        print(client.stoplab(labid))
    elif command == "gettestbed":
        print(client.gettestbed(labid))
    elif command == "validate":
        results, overall_result = client.validate(labid, args.deviceinfo)
        for result in results:
            print(result)
        print(str(overall_result))
    elif command == "importlab":
        if not args.source:
            print("Error: -source URL required for importlab command", file=sys.stderr)
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
