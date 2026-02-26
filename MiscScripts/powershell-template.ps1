# The script template below should be used for any labs that involve the validation of lab tasks for a cloud platform like AWS or Azure or for local Windows Client and Server validations.

<#
   Title: <Title>
   Description: Brief summary of what the script does.
   Target: <Target>
   Version: <YYYY.MM.DD> - Template.v4.0
#>

# Set default return value
$result = $false

# Debug toggle
$scriptDebug = '@lab.Variable(debug)' -in 'Yes','True' -or '@lab.Variable(Debug)' -in 'Yes','True'
if ($scriptDebug) { $ErrorActionPreference="Continue"; Write-Output "Debug mode is enabled." }

# Main function body for all validation code
function main {
    # Modify the code below to suit the needs of the validation being performed.
    # The scripting environment has $ErrorActionPreference = "Stop" by default.
    # Only use try/catch inside the main routine for something that is expected to fail and should not exit main.
    # There is a global try/catch at the end of the script that will handle error suppression for terminating errors.

    If ($scriptDebug) {Write-Output "Begin main routine."}

    # Parameters: Modify these to match the requirements of the lab environment
    $file = 'C:\LabFiles\SomeFileName.txt'
    $queryString = '*string to find in file*'
   
    # Add the commands for your scenario here
    $fileContent = [string](Get-Content $file)
    if ($scriptDebug -and $fileContent) {Write-Output "Found file."}

    # Perform your validation testing here
    if ($fileContent -like $queryString) {
        $result = $true
        if ($scriptDebug) {Write-Output "Validation successful."}
    } else {
        $result = $false
        if ($scriptDebug) {Write-Output "Validation failed."}
    }

    if ($scriptDebug) {Write-Output "End main routine."}
    
    # Return the result from the main function
    return $Result
}

# Run the main routine - When debugging, no Try/Catch is used. Any Errors or debug messages will display.
if ($scriptDebug) {
    $result = main
} else {
    try {
        $result = main
    } catch {
        $result = $false
    }
}

return $result
