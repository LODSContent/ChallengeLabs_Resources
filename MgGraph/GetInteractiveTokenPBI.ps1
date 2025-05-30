<#
   Title: Generate Interactive Power BI Token
   Description: Authenticates interactively to Power BI and saves the access token to a JSON file and lab variable.
   Target: Power BI Service, Skillable Lab Environment
   Version: 2025.05.30 - Template.v4.0
   Converted by: Grok using New Script Format
#>

param (
    [Parameter(Mandatory = $true)]
    $tenant,
    [switch]$ScriptDebug = $True
)

# Set default return value
$result = $false

# Debug toggle
$scriptDebug = '@lab.Variable(debug)' -in 'Yes','True' -or '@lab.Variable(Debug)' -in 'Yes','True' -or $ScriptDebug
if ($scriptDebug) { $ErrorActionPreference = "Continue"; Write-Output "Debug mode is enabled." }

# Main function for token generation
function main {
    if ($scriptDebug) { Write-Output "Begin main routine." }

    # Authenticate interactively
    $accessToken = $null
    try {
        $scopes = "https://analysis.windows.net/powerbi/api/.default"
        $clientId = "1950a258-227b-4e31-a9cf-717495945fc2"  # Azure PowerShell client ID
        Connect-MgGraph -ClientId $clientId -Scopes $scopes -TenantId $tenant -UseDeviceAuthentication -NoWelcome -ErrorAction Stop
        if ($scriptDebug) { Write-Output "Authenticated to Power BI" }
        
        $accessToken = (Get-AzAccessToken -ResourceUrl "https://analysis.windows.net/powerbi/api" -TenantId $tenant).Token
        if (-not $accessToken) {
            throw "Failed to retrieve access token"
        }
        if ($scriptDebug) { Write-Output "Retrieved Power BI token: $($accessToken.Substring(0,10))..." }
    }
    catch {
        if ($scriptDebug) { Write-Output "Authentication failed: $($_.Exception.Message)" }
        return $false
    }

    # Save token to file and lab variable
    try {
        $null = New-Item -Path C:\Temp -ItemType Directory -Force -ErrorAction SilentlyContinue
        @{ AccessToken = $accessToken } | ConvertTo-Json | Out-File -FilePath C:\Temp\AccessToken.json -Force
        Set-LabVariable -Name AccessToken -Value $accessToken
        if ($scriptDebug) { Write-Output "Saved token to C:\Temp\AccessToken.json and set lab variable" }
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
