#!/bin/bash
# =============================================================================
# Download and Execute cmltools_setup.sh with Parameters
# This code will be set up as a Lifecycle Action to run on the pyATS VM
# Source: https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/LabFiles/CML/cmltools_setup.sh
# Parameters:
#   CML_IP, CML_USERNAME, CML_PASSWORD
# Retries: 5 attempts, 5 seconds apart
# Returns: true on success, false on failure
# =============================================================================

# === LAB CONFIGURATION ===
CML_IP="192.168.1.10"
CML_USERNAME="@lab.VirtualMachine(CML-Controller).Endpoints(Dashboard).Username"
CML_PASSWORD="@lab.VirtualMachine(CML-Controller).Endpoints(Dashboard).Password"
# ===========================

# URL of the setup script
URL="https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/LabFiles/CML/cmltools_setup.sh"

# Local temporary path
SCRIPT_PATH="/tmp/cmltools_setup.sh"

# Maximum retry attempts
MAX_RETRIES=5

# Delay between retries in seconds
RETRY_DELAY=5

# Counter for attempts
attempt=1

# Loop with retry logic
while [ $attempt -le $MAX_RETRIES ]; do
  echo "Attempt $attempt of $MAX_RETRIES: Downloading cmltools_setup.sh..."
  if curl -fsSL "$URL" -o "$SCRIPT_PATH"; then
    echo "Download successful."
    break
  else
    echo "Download failed (attempt $attempt)."
    if [ $attempt -eq $MAX_RETRIES ]; then
      echo "Error: Failed to download after $MAX_RETRIES attempts." >&2
      echo false
      return 1
    fi
    sleep $RETRY_DELAY
  fi
  ((attempt++))
done

# Make the script executable
chmod +x "$SCRIPT_PATH" || { echo "Error: Failed to make script executable" >&2; echo false; return 1; }

# Execute the setup script with parameters
echo "Executing cmltools_setup.sh with CML_IP='$CML_IP', CML_USERNAME='$CML_USERNAME', CML_PASSWORD='***'..."
if "$SCRIPT_PATH" "$CML_IP" "$CML_USERNAME" "$CML_PASSWORD"; then
  echo "cmltools_setup.sh executed successfully."
  echo true
else
  echo "Error: cmltools_setup.sh failed to execute." >&2
  echo false
  return 1
fi
