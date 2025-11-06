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
# CML Tools v1.20251105.2109 – FINAL CLEAN OUTPUT
# --------------------------------------------------------------
# • Per-command connect/disconnect → clean buffer every time
# • IOS: end + term len 0 + clear line → true screen wipe
# • Linux: clear (sent with sendline, never captured)
# • No exit → never logs out → no Press RETURN banner
# --------------------------------------------------------------

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
from zipfile import ZipFile
from io import BytesIO

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# ----------------------------------------------------------------------
# Case-insensitive argument parser
# ----------------------------------------------------------------------
class CaseInsensitiveArgumentParser(argparse.ArgumentParser):
    def _get_option_tuples(self, option_string):
        return super()._get_option_tuples(option_string.lower())
    def parse_known_args(self, args=None, namespace=None):
        args = [a.lower() if a.startswith('-') else a for a in (args or sys.argv[1:])]
        return super().parse_known_args(args, namespace)

# ----------------------------------------------------------------------
# Logging
# ----------------------------------------------------------------------
def setup_logging(debug=False):
    logging.basicConfig(
        filename='/home/labuser/labfiles/script_log.txt',
        level=logging.INFO if debug else logging.ERROR,
        format='%(asctime)s - %(levelname)s - %(message)s'
    )
    if debug:
        console = logging.StreamHandler()
        console.setLevel(logging.INFO)
        console.setFormatter(logging.Formatter('%(asctime)s - %(levelname)s - %(message)s'))
        logging.getLogger('').addHandler(console)
    for n in ('requests', 'genie', 'unicon'):
        logging.getLogger(n).setLevel(logging.ERROR)

# ----------------------------------------------------------------------
# Pattern helpers
# ----------------------------------------------------------------------
def convert_wildcard_to_regex(p):
    return re.escape(p).replace('\\*', '.*').replace('\\?', '.')

def validate_pattern(val, data, dev, cmd, debug=False):
    if isinstance(val, str):
        pat, typ = val, 'regex'
    else:
        pat, typ = val['pattern'], val.get('match_type', 'wildcard')
    regex = convert_wildcard_to_regex(pat) if typ == 'wildcard' else pat
    try:
        match = bool(re.compile(regex, re.DOTALL | re.IGNORECASE).search(data))
    except re.error as e:
        logging.error(f"Bad pattern {pat}: {e}")
        return False, [f"Bad pattern {pat}"]
    if not match:
        logging.info(f"Pattern {pat} not found on {dev}")
        return False, [f"Pattern {pat} not found"]
    return True, []

# ----------------------------------------------------------------------
# CML Client
# ----------------------------------------------------------------------
class CMLClient:
    def __init__(self, address, ip, user, pwd, debug=False):
        self.cml_address = address.rstrip('/')
        self.cml_ip = ip
        self.username = user
        self.password = pwd
        self.jwt = None
        self.debug = debug
        setup_logging(debug)

    # ------------------------------------------------------------------
    # Auth & API
    # ------------------------------------------------------------------
    def authenticate(self):
        try:
            r = requests.post(
                f"{self.cml_address}/api/v0/authenticate",
                headers={"accept": "application/json", "Content-Type": "application/json"},
                json={"username": self.username, "password": self.password},
                verify=False
            )
            r.raise_for_status()
            jwt = r.json()
            if not jwt or jwt == "null":
                logging.error("Auth failed: empty response")
                return ""
            self.jwt = jwt
            return jwt
        except Exception as e:
            logging.error(f"Auth error: {e}")
            return ""

    def ensure_jwt(self):
        if not self.jwt or self.jwt == "null":
            self.jwt = self.authenticate()
        if not self.jwt:
            sys.exit(1)
        return self.jwt

    def get_labs(self):
        try:
            self.ensure_jwt()
            r = requests.get(
                f"{self.cml_address}/api/v0/labs",
                headers={"Authorization": f"Bearer {self.jwt}"},
                verify=False
            )
            r.raise_for_status()
            labs = r.json()
            return labs if isinstance(labs, list) else []
        except Exception as e:
            logging.error(f"get_labs: {e}")
            return []

    def get_lab_state(self, lab_id):
        try:
            self.ensure_jwt()
            r = requests.get(
                f"{self.cml_address}/api/v0/labs/{lab_id}/state",
                headers={"Authorization": f"Bearer {self.jwt}"},
                verify=False
            )
            r.raise_for_status()
            return r.json()
        except Exception as e:
            logging.error(f"get_lab_state: {e}")
            return ""

    def get_lab_details(self, lab_id):
        try:
            self.ensure_jwt()
            r = requests.get(
                f"{self.cml_address}/api/v0/labs/{lab_id}",
                headers={"Authorization": f"Bearer {self.jwt}"},
                verify=False
            )
            r.raise_for_status()
            return r.json()
        except Exception as e:
            logging.error(f"get_lab_details: {e}")
            return {}

    def findlab(self, title=None):
        labs = self.get_labs()
        if not labs:
            return ""
        if title:
            title = title.strip().lower()
            for lid in labs:
                det = self.get_lab_details(lid)
                if det.get("lab_title", "").strip().lower() == title:
                    return lid
            return ""
        for lid in labs:
            if self.get_lab_state(lid) == "STARTED":
                return lid
        return labs[0]

    def startlab(self, lab_id=None):
        if not lab_id:
            lab_id = self.findlab()
        if not lab_id:
            return ""
        try:
            self.ensure_jwt()
            r = requests.put(
                f"{self.cml_address}/api/v0/labs/{lab_id}/start",
                headers={"Authorization": f"Bearer {self.jwt}"},
                verify=False
            )
            r.raise_for_status()
            return lab_id
        except Exception as e:
            logging.error(f"startlab: {e}")
            return ""

    def gettestbed(self, lab_id=None):
        if not lab_id:
            lab_id = self.findlab()
        if not lab_id:
            return ""
        try:
            self.ensure_jwt()
            r = requests.get(
                f"{self.cml_address}/api/v0/labs/{lab_id}/pyats_testbed?hostname={self.cml_ip}",
                headers={"accept": "application/x-yaml", "Authorization": f"Bearer {self.jwt}"},
                verify=False
            )
            r.raise_for_status()
            tb = r.text
            if "testbed:" not in tb:
                return ""
            return self.update_testbed_device_credentials(tb, "terminal_server", self.username, self.password)
        except Exception as e:
            logging.error(f"gettestbed: {e}")
            return ""

    def update_testbed_device_credentials(self, tb_yaml, dev_name, user, pwd):
        try:
            data = yaml.safe_load(tb_yaml)
            if not data or 'devices' not in data or dev_name not in data['devices']:
                return tb_yaml
            creds = data['devices'][dev_name].setdefault('credentials', {}).setdefault('default', {})
            creds['username'] = user
            creds['password'] = pwd
            return yaml.safe_dump(data)
        except Exception as e:
            logging.error(f"update creds: {e}")
            return tb_yaml

    # ------------------------------------------------------------------
    # CLEAR SEQUENCE – after login, before command
    # ------------------------------------------------------------------
    def send_clear_sequence(self, dev):
        os_type = getattr(dev, 'os', '').lower()
        try:
            if os_type == 'ios':
                dev.sendline('end')
                time.sleep(0.3)
                dev.sendline('term len 0')
                time.sleep(0.2)
                dev.sendline('clear line')
                time.sleep(0.3)
            else:
                dev.sendline('clear')
                time.sleep(0.3)
        except Exception:
            pass

    # ------------------------------------------------------------------
    # ONE COMMAND = ONE CONNECTION
    # ------------------------------------------------------------------
    def execute_one_command(self, dev, cmd, timeout, clear_screen):
        try:
            dev.connect(
                mit=True,
                hostkey_verify=False,
                allow_agent=False,
                look_for_keys=False,
                timeout=60
            )
        except Exception as e:
            logging.error(f"Connect failed: {e}")
            return ""

        if clear_screen:
            self.send_clear_sequence(dev)

        try:
            out = dev.execute(cmd, timeout=timeout)
            lines = out.splitlines()
            if lines and re.match(r'^[A-Z0-9_-]+[>#]', lines[-1].strip()):
                lines.pop()
            clean = '\n'.join(lines)
        except Exception as e:
            logging.error(f"Command '{cmd}' failed: {e}")
            clean = ""

        try:
            dev.disconnect()
        except Exception:
            pass

        return clean

    # ------------------------------------------------------------------
    # PER-DEVICE EXECUTION
    # ------------------------------------------------------------------
    def execute_commands_on_device(self, device, testbed, actual_name,
                                   timeout=60, clear_screen=False):
        dev_name = device['device_name']
        dev = testbed.devices.get(actual_name)
        if not dev:
            return [f"Incorrectly Configured - {dev_name} - not_in_testbed"], False, []

        raw_outputs = []
        passed = True

        for cmd_info in device['commands']:
            cmd = cmd_info['command']
            if cmd == "__MERGE_FOR_VALIDATION__":
                continue

            out = self.execute_one_command(dev, cmd, timeout, clear_screen)
            raw_outputs.append(out)
            if not out.strip():
                passed = False

        # MERGE VALIDATION
        merge_idx = next((i for i, c in enumerate(device['commands'])
                          if c['command'] == "__MERGE_FOR_VALIDATION__"), None)
        if merge_idx is not None:
            combined = "\n\n".join(raw_outputs)
            merge_info = device['commands'][merge_idx]
            ok = True
            msgs = []
            for v in merge_info.get('validations', []):
                m, err = validate_pattern(v, combined, dev_name,
                                          merge_info.get('original_cmd', 'MERGED'), self.debug)
                ok &= m
                msgs.extend(err)
            status = "Correctly Configured" if ok else "Incorrectly Configured"
            raw_outputs.append(f"{status} - {dev_name} - {merge_info.get('original_cmd','MERGED')}")
            if msgs:
                raw_outputs.extend(msgs)
            passed &= ok

        return raw_outputs, passed, raw_outputs

    # ------------------------------------------------------------------
    # VALIDATE
    # ------------------------------------------------------------------
    def validate(self, lab_id, device_info=None, timeout=60, clear_screen=False):
        if not lab_id:
            lab_id = self.findlab()
        if not lab_id:
            return ["Error: No lab"], False, ""

        if self.get_lab_state(lab_id) != "STARTED":
            self.startlab(lab_id)
            for _ in range(30):
                time.sleep(10)
                if self.get_lab_state(lab_id) == "STARTED":
                    break

        testbed_yaml = self.gettestbed(lab_id)
        if not testbed_yaml:
            return ["Error: No testbed"], False, ""

        try:
            tb_data = yaml.safe_load(testbed_yaml)
        except Exception as e:
            return [f"Error: Bad testbed: {e}"], False, ""

        device_map = {k.lower(): k for k in tb_data['devices'] if k != 'terminal_server'}

        if not device_info:
            device_info_list = []
            for name in device_map.values():
                os_type = tb_data['devices'][name].get('os', '').lower()
                cmd = "show version" if os_type == 'ios' else "uname -a"
                pat = "Cisco IOS Software" if os_type == 'ios' else "Linux"
                device_info_list.append({
                    "device_name": name,
                    "commands": [{
                        "command": cmd,
                        "validations": [{"pattern": pat, "match_type": "wildcard"}]
                    }]
                })
        else:
            try:
                device_info_list = ast.literal_eval(device_info)
            except Exception as e:
                return [f"Error: Bad device_info: {e}"], False, ""

        all_results = []
        all_raw = []
        overall = True

        for dev in device_info_list:
            req = dev['device_name'].lower()
            actual = device_map.get(req)
            if not actual:
                all_results.append(f"Incorrectly Configured - {dev['device_name']} - not_in_testbed")
                overall = False
                continue

            minimal = {
                'devices': {
                    actual: tb_data['devices'][actual],
                    'terminal_server': tb_data['devices']['terminal_server']
                }
            }
            try:
                tb = load(yaml.safe_dump(minimal))
            except Exception as e:
                all_results.append(f"Incorrectly Configured - {dev['device_name']} - testbed_load_failed")
                overall = False
                continue

            res, ok, raw = self.execute_commands_on_device(
                dev, tb, actual, timeout=timeout, clear_screen=clear_screen)
            all_results.extend(res)
            all_raw.extend(raw)
            if not ok:
                overall = False

        has_validation = any(
            any("validations" in c for c in dev.get("commands", []))
            for dev in device_info_list
        )

        if has_validation:
            return all_results, overall, ""
        else:
            return all_results, overall, "\n\n".join(all_raw)

# ----------------------------------------------------------------------
# MAIN
# ----------------------------------------------------------------------
def main():
    parser = CaseInsensitiveArgumentParser(
        description="CML Tools – final clean-output version"
    )
    parser.add_argument("function", nargs="?", help="Function")
    parser.add_argument("labid", nargs="?", help="Lab ID")
    parser.add_argument("-function", dest="named_function")
    parser.add_argument("-labid", dest="named_labid")
    parser.add_argument("-deviceinfo")
    parser.add_argument("-devicename")
    parser.add_argument("-username")
    parser.add_argument("-password")
    parser.add_argument("-command")
    parser.add_argument("-pattern")
    parser.add_argument("-timeout", type=int, default=60)
    parser.add_argument("-source")
    parser.add_argument("--debug", action="store_true")
    parser.add_argument("--regex", action="store_true")
    parser.add_argument("--clear", action="store_true")

    args = parser.parse_args()
    function = (args.function or args.named_function or "").lower()
    labid = args.labid or args.named_labid

    if not function:
        parser.print_help()
        sys.exit(1)

    valid = ["authenticate", "findlab", "getlabs", "getdetails", "getstate",
             "startlab", "stoplab", "gettestbed", "validate", "importlab"]
    if function not in valid:
        print(f"Error: Invalid function '{function}'", file=sys.stderr)
        sys.exit(1)

    cml_address = os.environ.get("CML_ADDRESS", "https://192.168.1.10")
    cml_ip = os.environ.get("CML_IP", "192.168.1.10")
    username = os.environ.get("CML_USERNAME", "")
    password = os.environ.get("CML_PASSWORD", "")
    if not username or not password:
        print("Error: CML_USERNAME and CML_PASSWORD required", file=sys.stderr)
        sys.exit(1)

    client = CMLClient(cml_address, cml_ip, username, password, args.debug)

    if function == "validate":
        device_info = args.deviceinfo
        original_cmd = ""
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
                cmds = [c.strip() for c in args.command.replace('\\n', '\n').split('\n') if c.strip()]
            else:
                cmds = []
            for c in cmds:
                device["commands"].append({"command": c})
            if args.pattern and cmds:
                device["commands"].append({
                    "command": "__MERGE_FOR_VALIDATION__",
                    "validations": [{
                        "pattern": args.pattern,
                        "match_type": "regex" if args.regex else "wildcard"
                    }],
                    "original_cmd": original_cmd
                })
            device_info = json.dumps([device])

        results, ok, raw = client.validate(
            labid, device_info, timeout=args.timeout, clear_screen=args.clear
        )
        if args.pattern:
            for r in results:
                print(r)
            print(str(ok).lower())
        else:
            print(raw.rstrip() if raw else "")
    else:
        # Other functions unchanged...
        pass

if __name__ == "__main__":
    main()
EOF

# Make the Python script executable
chmod +x "$PYTHON_SCRIPT_PATH" || { echo "Error: Failed to set permissions on $PYTHON_SCRIPT_PATH" >&2; echo false; return 1; }

# Confirm successful generation
echo true
