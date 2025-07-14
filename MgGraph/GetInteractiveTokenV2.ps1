param (
    [Parameter(Mandatory = $true)]
    $tenant,
    [switch]$ScriptDebug = $False
)

if (-not (Get-Module MSAL.PS -ListAvailable)) {
    Write-Host "Installing the MSAL.PS module."
    Install-Module MSAL.PS -SkipPublisherCheck -Scope AllUsers -Force
}

Write-Host "Authenticating."

# Define scopes
$scopes = @("User.ReadWrite.All", "Group.ReadWrite.All", "AppRoleAssignment.ReadWrite.All", "Application.ReadWrite.All", "DelegatedPermissionGrant.ReadWrite.All", "RoleManagement.ReadWrite.Directory", "Directory.ReadWrite.All")

# Get Graph token via MSAL.PS
try {
    $msalToken = Get-MsalToken -ClientId "1950a258-227b-4e31-a9cf-717495945fc2" -TenantId $tenant -Scopes "https://graph.microsoft.com/.default" -Interactive -ErrorAction Stop
    $accessToken = $msalToken.AccessToken
    if ($ScriptDebug) { Write-Output "Retrieved Graph token via MSAL.PS: $($AccessToken.Substring(0,10))..." }
} catch {
    throw "Failed to retrieve Graph token via MSAL.PS: $_"
}

# Save the Graph Token
$null = New-Item -Path C:\Temp -ItemType Directory -Force -ErrorAction SilentlyContinue
New-Object PSObject -Property @{AccessToken=$accessToken} | ConvertTo-Json | Out-File C:\Temp\AccessToken.json

Write-Host "Finished authentication and created Access Token file."
