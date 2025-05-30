<#
   Title: Generate Interactive Power BI Token
   Description: Authenticates interactively to Power BI and saves the access token to a JSON file and lab variable.
   Target: Power BI Service, Skillable Lab Environment
   Version: 2025.05.30 - Template.v4.0
   Converted by: Grok using New Script Format
#>

# Set default return value
$result = $false

# Debug toggle
if ($scriptDebug) { $ErrorActionPreference = "Continue"; Write-Output "Debug mode is enabled." }

# Main function for token generation
function main {
    param (
        [Parameter(Mandatory)]
        [string]$TenantName
    )

    if ($scriptDebug) { Write-Output "Begin main routine." }

    # Authenticate interactively
    $accessToken = $null
    try {
        $scopes = "https://analysis.windows.net/powerbi/api/.default"
        $clientId = "1950a258-227b-4e31-a9cf-717495945fc2"  # Azure PowerShell client ID
        Connect-MgGraph -ClientId $clientId -Scopes $scopes -TenantId $TenantName
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
    $result = main -TenantName "hexelo48429792x1.onmicrosoft.com"
}
else {
    try {
        $result = main -TenantName "hexelo48429792x1.onmicrosoft.com"
    }
    catch {
        $result = $false
    }
}

return $result
