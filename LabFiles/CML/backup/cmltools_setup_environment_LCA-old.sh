#!/bin/bash
# =============================================================================
# Download the cmltools.py file and create the cml_env.sh file.
# Returns: true on success, false on failure
# =============================================================================

# Lab Configuration Variables - Adjust based upon the CML setup
CML_IP="192.168.1.10"
CML_USERNAME="@lab.VirtualMachine(CML-Controller).Endpoints(Dashboard).Username"
CML_PASSWORD="@lab.VirtualMachine(CML-Controller).Endpoints(Dashboard).Password"


### Download the cmltools.py tools library ###

# Python Script download variables
URL="https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/LabFiles/CML/cmltools.py"
TEMP_FILE="/tmp/cmltools.py.$$"
PYTHON_SCRIPT_PATH="$HOME/labfiles/cmltools.py"
MAX_RETRIES=5
RETRY_DELAY=5
attempt=1

# Ensure labfiles directory exists
mkdir -p "$HOME/labfiles" || { echo "Error: Failed to create $HOME/labfiles" >&2; echo false; return 1; }

# Loop with retry logic
while [ $attempt -le $MAX_RETRIES ]; do
  echo "Attempt $attempt of $MAX_RETRIES: Downloading cmltools.py..."
  if curl -fsSL "$URL" -o "$TEMP_FILE"; then
    echo "Download successful."
    mv "$TEMP_FILE" "$PYTHON_SCRIPT_PATH" || { echo "Error: Failed to move $TEMP_FILE to $PYTHON_SCRIPT_PATH" >&2; echo false; return 1; }
    break
  else
    echo "Download failed (attempt $attempt)."
    if [ $attempt -eq $MAX_RETRIES ]; then
      echo "Error: Failed to download after $MAX_RETRIES attempts." >&2
      rm -f "$TEMP_FILE"
      echo false
      return 1
    fi
    sleep $RETRY_DELAY
  fi
  ((attempt++))
done

# Make the script executable
chmod +x "$PYTHON_SCRIPT_PATH" || { echo "Error: Failed to make script executable" >&2; echo false; return 1; }


### Create the cml_env.sh environment file ###

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

echo true
