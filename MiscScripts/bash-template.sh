
#!/bin/bash
# Title: Lab Environment Validation
# Description: Validates lab environment by checking file content
# Target: Linux lab environment
# Version: 2025.10.22 - Template.v4.0

# Validation parameters
# The file we check for and the string to query for:
file="$HOME/nmap.txt"
queryString="Starting Nmap"

# Set default return value (0 for success, 1 for failure in Bash)
result=1

# Debug toggle (checking environment variable LAB_DEBUG)
if [[ "@lab.Variable(debug)" == "Yes" || "@lab.Variable(debug)" == "True" || "@lab.Variable(Debug)" == "Yes" || "@lab.Variable(Debug)" == "True" ]]; then
    scriptDebug=1
    echo "Debug mode is enabled."
else
    scriptDebug=0
fi

# Main function body for all validation code
main() {
if [ $scriptDebug -eq 1 ]; then
        echo "Begin main routine."
    fi

    # Check if file exists
    if [ ! -f "$file" ]; then
        if [ $scriptDebug -eq 1 ]; then
            echo "File not found: $file"
        fi
        return 1
    fi

    # Read file content
    fileContent=$(cat "$file" 2>/dev/null)
    if [ $? -ne 0 ]; then
        if [ $scriptDebug -eq 1 ]; then
            echo "Failed to read file: $file"
        fi
        return 1
    fi

    if [ $scriptDebug -eq 1 ] && [ -n "$fileContent" ]; then
        echo "Found file."
    fi

    # Perform validation testing
    if echo "$fileContent" | grep -q "$queryString"; then
        result=0
        if [ $scriptDebug -eq 1 ]; then
            echo "Validation successful"
        fi
    else
        result=1
        if [ $scriptDebug -eq 1 ]; then
            echo "Validation failed"
        fi
    fi

    if [ $scriptDebug -eq 1 ]; then
        echo "End main routine."
    fi

    return $result
}
# Run the main routine
if [ $scriptDebug -eq 1 ]; then
    main
    result=$?
else
    main 2>/dev/null
    result=$?
fi

if [ $result -eq 0 ]; then
    echo true
else
    echo false
fi
