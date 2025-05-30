<#
   Title: Generate Interactive Power BI Token
   Description: Authenticates interactively to Power BI and saves the access token to a JSON file for lab variable use.
   Target: Power BI Service, Skillable Lab Environment
   Version: 2025.05.30 - Template.v4.0
   Converted by: Grok using New Script Format
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$TenantName,
    [switch]$ScriptDebug = $false
)

# Debug toggle
$scriptDebug = '@lab.Variable(debug)' -in 'Yes','True' -or '@lab.Variable(Debug)' -in 'Yes','True'
if ($scriptDebug) { $ErrorActionPreference = "Continue"; Write-Output "Debug mode is enabled." }

# Main function for token generation
function main {
    if ($scriptDebug) { Write-Output "Begin main routine." }

    # Authenticate interactively
    $accessToken = $null
    try {
        $scopes = "https://analysis.windows.net/powerbi/api/.default"
        Connect-MgGraph -Scopes $scopes -TenantId $TenantName -UseDeviceAuthentication -NoWelcome -ErrorAction Stop
        if ($scriptDebug) { Write-Output "Authenticated to Power BI" }
        
        $accessToken = (Get-AzAccessToken -ResourceUrl "https://analysis.windows.net/powerbi/api" -TenantId $TenantName).Token
        if (-not $accessToken) {
            throw "Failed to retrieve access token"
        }
        if ($scriptDebug) { Write-Output "Retrieved Power BI token: $($accessToken.Substring(0,10))..." }
    }
    catch {
        if ($scriptDebug) { Write-Output "Authentication failed: $($_.Exception.Message)" }
        return $false
    }

    # Save token to file
    try {
        $null = New-Item -Path C:\Temp -ItemType Directory -Force -ErrorAction SilentlyContinue
        @{ AccessToken = $accessToken } | ConvertTo-Json | Out-File -FilePath C:\Temp\AccessToken.json -Force
        if ($scriptDebug) { Write-Output "Saved token to C:\Temp\AccessToken.json" }
        
        # Set lab variable (assuming lab environment supports this)
        Set-LabVariable -Name AccessToken -Value $accessToken
        if ($scriptDebug) { Write-Output "Set lab variable AccessToken" }
    }
    catch {
        if ($scriptDebug) { Write-Output "Failed to save token: $($_.Exception.Message)" }
        return $false
    }

    if ($scriptDebug) { Write-Output "End main routine." }
    return $true
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
