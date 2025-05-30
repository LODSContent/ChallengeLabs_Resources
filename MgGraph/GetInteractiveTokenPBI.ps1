<#
   Title: Validate Power BI Workspace Using Access Token
   Description: Validates the existence of a Power BI workspace named 'My workspace' using an imported access token via REST API.
   Target: Power BI Service, Skillable Lab Environment
   Version: 2025.05.30 - Template.v4.0
   Converted by: Grok using New Script Format
#>

# Set default return value
$result = $false

# Debug toggle
if ($scriptDebug) { $ErrorActionPreference = "Continue"; Write-Output "Debug mode is enabled." }

# Main function for all validation code
function main {
    if ($scriptDebug) { Write-Output "Begin main routine." }

    # Import and validate access token
    $accessToken = $null
    try {
        $secureToken = ConvertTo-SecureString '@lab.Variable(AccessToken)' -AsPlainText -Force
        $accessToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken))
        if (-not $accessToken) {
            throw "Access token is empty"
        }
        if ($scriptDebug) { Write-Output "Imported access token: $($accessToken.Substring(0,10))..." }
    }
    catch {
        if ($scriptDebug) { Write-Output "Failed to import access token: $($_.Exception.Message)" }
        return $false
    }

    # Validate Power BI workspace using REST API
    try {
        $headers = @{
            "Authorization" = "Bearer $accessToken"
        }
        $workspaceName = "My workspace"
        $uri = "https://api.powerbi.com/v1.0/myorg/admin/groups?`$filter=name eq '$workspaceName'"
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get -ErrorAction Stop
        
        if ($response.value -and $response.value.Count -gt 0) {
            if ($scriptDebug) { Write-Output "Found workspace: $workspaceName" }
            $result = $true
        }
        else {
            if ($scriptDebug) { Write-Output "Workspace '$workspaceName' not found" }
            $result = $false
        }
    }
    catch {
        if ($scriptDebug) { 
            Write-Output "Power BI REST API call failed: $($_.Exception.Message)"
            Write-Output "Response: $($_.Exception.Response | ConvertTo-Json -Depth 5 -ErrorAction SilentlyContinue)"
        }
        return $false
    }

    if ($scriptDebug) { Write-Output "End main routine." }
    
    # Return the result
    return $result
}

# Run the main routine
if ($scriptDebug) {
    $result = main
}
else {
    try {
        $result = main
    }
    catch {
        $result = $false
    }
}

return $result
