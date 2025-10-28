#!/bin/bash
# =============================================================================
# CML Lab Import Script - Silent, Sourced-Safe, Outputs ONLY true/false
# =============================================================================

# Source environment
source "$HOME/labfiles/cml_env.sh" 2>/dev/null || { echo false; return; }

LAB_URL="https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/LabFiles/CCNA.1/Sample_Lab_1.yaml"
MAX_RETRIES=3
RETRY_DELAY=5
attempt=1

main() {
  while [ $attempt -le $MAX_RETRIES ]; do
    # Run import, capture ONLY stdout, suppress ALL stderr
    LAB_ID=$(cmltools importlab -source "$LAB_URL" 2>/dev/null | head -n1)

    # Validate UUID
    if [[ "$LAB_ID" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
      return 0  # Success
    fi

    ((attempt++))
    [ $attempt -le $MAX_RETRIES ] && sleep $RETRY_DELAY
  done

  return 1  # Failure
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
