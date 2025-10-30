#!/bin/bash
# =============================================================================
# CML Multi-Lab Import Script - Silent, Sourced-Safe, Outputs ONLY true/false
# Imports multiple labs from array of URLs. All must succeed → true
# =============================================================================

# Source environment
source "$HOME/labfiles/cml_env.sh" 2>/dev/null || { echo false; return; }

# === DEFINE YOUR LAB URLS HERE ===
LAB_URLS=(
  "https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/LabFiles/CCNA.1/Sample_Lab_1.yaml"
  "https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/LabFiles/CCNA.1/CCNA.1-LAB2.yaml"
  # Add more URLs as needed
)

MAX_RETRIES=3
RETRY_DELAY=5

# Function: Import one lab, return 0 on success, 1 on failure
import_single_lab() {
  local url="$1"
  local attempt=1

  while [ $attempt -le $MAX_RETRIES ]; do
    LAB_ID=$(cmltools importlab -source "$url" 2>/dev/null | head -n1)

    if [[ "$LAB_ID" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
      return 0  # Success (new or reused)
    fi

    ((attempt++))
    [ $attempt -le $MAX_RETRIES ] && sleep $RETRY_DELAY
  done

  return 1  # All retries failed
}

# Main: Try to import ALL labs
main() {
  for url in "${LAB_URLS[@]}"; do
    if ! import_single_lab "$url"; then
      return 1  # Any failure → overall failure
    fi
  done
  return 0  # All succeeded
}

# Run and capture result
main
result=$?

# Output ONLY true or false
if [ $result -eq 0 ]; then
  echo "true"
else
  echo "false"
fi
