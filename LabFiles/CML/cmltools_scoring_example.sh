#!/bin/bash
#
# Title: Verify "show version" on SWITCH1 contains Cisco IOS
# Description: Runs command and validates output using wildcard or regex
# Target: PyATS Scoring VM
# Version:  2025.11.02 - Template.v5
#
# Parameters (set in lab definition)
labID="LAB-TOPOLOGY1"
device="switch1"
username=""
password=""
command="show version"
pattern="cisco*ios"
regex=false
timeout=""
clear_screen=true
script_debug=false
cml_debug=false
# ------------------------------------------------------------------
# Update labID with the "Title" of the lab to be evaluated
# Update device with the name of the device for commands to be run on
# Update command with the command to execute
# Add a username and password if the default username and password of cisco/cisco is not used
#    (Leave blank to use the default cisco/cisco credentials)
# Update pattern with the string to find in the return results
#    (Leave pattern blank to return the full response of the command)
# pattern examples:
#   "cisco*ios"          - wildcard (default)
#   "^Version 15\."      - regex (when regex=true)
#   "Cisco.*IOS"         - regex (when regex=true)
# If regex is false, wildcard matching is used with ? for single or * for multiple characters
# If regex is true, full regex matching is performed
# Set timeout to 0 for commands that would hang the interface like 'exit'. Default is 60 when blank.
# Set clear_screen to true to wipe the device screen before and after validation commands.
# Set script_debug to true for verbose output
# Set cml_debug to true for super-verbose cml output
# ------------------------------------------------------------------

# Set default result
result="false"

# === Main routine ===
main() {
    [[ "$script_debug" == "true" ]] && echo "=== Begin validation ==="

    # Source environment
    if ! source "$HOME/labfiles/cml_env.sh" 2>/dev/null; then
        [[ "$script_debug" == "true" ]] && echo "FAIL: cannot source cml_env.sh" >&2
        echo "false"
        return 1
    fi
    [[ "$script_debug" == "true" ]] && echo "cml_env.sh loaded"

    # Build cmltools command(s)
    cmd=(cmltools validate -labid "$labID" -devicename "$device" -command "$command")

    # Add --regex if enabled
    [[ "$regex" == "true" ]] && cmd+=(--regex)
    
    # Add -username only if not empty
    [[ -n "$username" ]] && cmd+=(-username "$username")
    
    # Add -password only if not empty
    [[ -n "$password" ]] && cmd+=(-password "$password")
    
    # Add -pattern only if not empty
    [[ -n "$pattern" ]] && cmd+=(-pattern "$pattern")

    # Add -timeout only if not empty
    [[ -n "$timeout" ]] && cmd+=(-timeout "$timeout")

    # Add --clear if enabled
    [[ "$clear_screen" == "true" ]] && cmd+=(--clear)

    # Add --debug if enabled
    if [[ "$cml_debug" == "true" ]]; then
        cmd+=(--debug)
        script_debug=true
    fi     

    [[ "$script_debug" == "true" ]] && echo "Running: ${cmd[*]}"

    # Execute
    if [[ "$script_debug" == "true" ]]; then
        full_output=$( "${cmd[@]}" )
        exit_code=$?
    else
        full_output=$( "${cmd[@]}" 2>/dev/null )
        exit_code=$?
    fi

    # Debug output
    [[ "$script_debug" == "true" ]] && echo "$full_output"

    # Final result
    if [[ $exit_code -ne 0 ]]; then
        echo "false"
        return 1
    fi

    final_line=$(echo "$full_output" | tail -n1)
    final_line_lower="${final_line,,}"

    if [[ "$final_line_lower" == "true" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# === Execute safely ===
if [[ "$script_debug" == "true" ]]; then
    result=$(main)
else
    result=$(main 2>/dev/null) || result="false"
fi

# Final output: only true or false
echo "$result"
