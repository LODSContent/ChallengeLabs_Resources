#!/bin/bash
# Title: Device Configuration Validation (Container-Safe)
# Description: Validates CML lab devices - safe for textbox injection
# Target: PyATS scoring VM
# Version: 2025.10.28 - Container.v6.0

# ==== LAB-SPECIFIC VALUES ====
LAB_ID="Lab"

device_info=$(cat << 'EOF'
[
    {
        "device_name": "sw1",
        "commands": [
            {
                "command": "show version",
                "validations": [
                    {
                        "pattern": "Cisco IOS Software",
                        "match_type": "wildcard"
                    }
                ]
            }
        ]
    },
    {
        "device_name": "rtr",
        "commands": [
            {
                "command": "show version",
                "validations": [
                    {
                        "pattern": "Cisco IOS Software",
                        "match_type": "wildcard"
                    }
                ]
            }
        ]
    }
]
EOF
)
# =======================================================

# === CONTROL VARIABLES (hard-coded) ===
scriptDebug="false"    # "true" = show debug + errors
showDevices="true"     # "true" = show device lines (unless debug off)

# Normalize
scriptDebug="${scriptDebug,,}"
showDevices="${showDevices,,}"

# === Main routine ===
main() {
    # Debug header
    [[ "$scriptDebug" == "true" ]] && echo "=== Begin validation ==="

    # 1. Source environment
    if ! source "$HOME/labfiles/cml_env.sh" 2>/dev/null; then
        [[ "$scriptDebug" == "true" ]] && echo "FAIL: cannot source cml_env.sh" >&2
        echo "false"
        return
    fi
    [[ "$scriptDebug" == "true" ]] && echo "cml_env.sh loaded"

    # 2. Run cmltools - redirect stderr based on debug
    if [[ "$scriptDebug" == "true" ]]; then
        full_output=$(cmltools validate -labid "$LAB_ID" -deviceinfo "$device_info")
        exit_code=$?
    else
        full_output=$(cmltools validate -labid "$LAB_ID" -deviceinfo "$device_info" 2>/dev/null)
        exit_code=$?
    fi

    # 3. Show device lines if allowed
    if [[ "$showDevices" == "true" || "$scriptDebug" == "true" ]]; then
        echo "$full_output" | grep -E "(Correctly|Incorrectly) Configured" || true
    fi

    # 4. Final result: check both output and exit code
    final_line=$(echo "$full_output" | tail -n1)
    final_line_lower="${final_line,,}"

    # If cmltools failed (non-zero exit), force false
    if [[ $exit_code -ne 0 ]]; then
        echo "false"
        return
    fi

    # Otherwise, use the actual result
    if [[ "$final_line_lower" == "true" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# === Execute ===
main
