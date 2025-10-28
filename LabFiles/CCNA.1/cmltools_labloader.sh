#!/bin/bash
# =============================================================================
# CML Lab Import Script
# Description: Imports a CML lab from GitHub with retry logic
# Target: PyATS + CML
# Version: 2025.10.17 - Template.v1.0
# Retries: 5 attempts, 5 seconds apart
# Returns: true on success, false on failure
# =============================================================================

# Source cml_env.sh to load cmltools and environment
if ! source "$HOME/labfiles/cml_env.sh" 2>/dev/null; then
  echo "Error: Failed to source $HOME/labfiles/cml_env.sh" >&2
  echo false
  exit 1
fi

# Lab URL (change as needed)
LAB_URL="https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/LabFiles/CCNA.1/Sample_Lab_1.yaml"

# Maximum retry attempts
MAX_RETRIES=5

# Delay between retries in seconds
RETRY_DELAY=5

# Counter for attempts
attempt=1

# Retry loop
while [ $attempt -le $MAX_RETRIES ]; do
  echo "Attempt $attempt of $MAX_RETRIES: Importing lab from $LAB_URL..."

  # Capture ONLY the lab ID (first non-empty line after possible debug)
  IMPORTED_ID=$(cmltools importlab -source "$LAB_URL" 2>/dev/null | head -n1)

  if [[ -n "$IMPORTED_ID" && "$IMPORTED_ID" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
    echo "Lab imported successfully on attempt $attempt: $IMPORTED_ID"
    echo true
    exit 0
  else
    echo "Import failed (attempt $attempt)."
    ((attempt++))
    [ $attempt -le $MAX_RETRIES ] && sleep $RETRY_DELAY
  fi
done

echo "Error: Failed to import lab after $MAX_RETRIES attempts." >&2
echo false
exit 1
