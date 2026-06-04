# The script template below should be used for any labs that involve the validation of lab tasks for a cloud platform like AWS or Azure or for local Windows Client and Server validations.

<#
   Title: <Title>
   Description: Brief summary of what the script does.
   Target: <Target>
   Version: <YYYY.MM.DD.hhmm> - Template.v4.0
#>

# Parameters: Modify these to match the requirements of the lab environment
$queryVariable = '@lab.Variable(Req1Check1)'
<#
The queryVariable will be populated from an @lab.Variable that is established as an @lab.TextBox in the lab markdown with the same name. Below is an example of the Markdown:

- Enter the name of the first service in the list on the screen into the following textbox:

   @lab.TextBox(Req1Check1)
#>
$queryString = '*string to match from the variable*'
# For the queryString, use * as a wildcard at the beginning and end to account for extra spaces.
#    Use * as a wildcard in between words when the string content may vary.

# Set defaults
$result = $false
$ErrorActionPreference = "Stop"  # Always stop on errors. Override with -SilentlyContinue per command.
$wrapperLineCount = 104  # Line offset added by the lab platform's script runner preamble.

# Debug toggle
$scriptDebug = '@lab.Variable(debug)' -in 'Yes','True' -or '@lab.Variable(Debug)' -in 'Yes','True'
if ($scriptDebug) { Write-Output "Debug mode is enabled." }

# Main function body for all validation code
function main {
    # Modify the code below to suit the needs of the validation being performed.
    # The scripting environment has $ErrorActionPreference = "Stop" by default.
    # Only use try/catch inside the main routine for something that is expected to fail and should not exit main.
    # There is a global try/catch at the end of the script that will handle error suppression for terminating errors.

    If ($scriptDebug) {Write-Output "Begin main routine."}

    # Perform your validation testing here
    if ($queryVariable -like $queryString) {
        $result = $true
        # Scripter/AI: Provide detail about the successful result
        if ($scriptDebug) {Write-Output "Validation successful. Found:`n$queryString `nin: `n$queryVariable"}
    } else {
        $result = $false
        # Scripter/AI: Provide detail about the failed result
        if ($scriptDebug) {Write-Output "Validation failed. Could not find:`n$queryString `nin: `n$queryVariable"}
    }

    if ($scriptDebug) {Write-Output "End main routine."}
    
    # Return the result from the main function
    return $result
}

# Run the main routine - When debugging, no Try/Catch is used. Any Errors or debug messages will display.
if ($scriptDebug) {
    try {
        $result = main
    } catch {
        Write-Output "ERROR: $($_.Exception.Message)"
        Write-Output "At line $($_.InvocationInfo.ScriptLineNumber - $wrapperLineCount): $($_.InvocationInfo.Line.Trim())"
        $result = $false
    }
} else {
    try {
        $result = main
    } catch {
        $result = $false
    }
}

if ($scriptDebug) {Write-Output "The result returned is: $result"}
return $result
