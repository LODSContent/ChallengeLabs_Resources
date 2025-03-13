param (
    [Parameter(Mandatory = $true)]
    $tenant,
    [switch]$ScriptDebug = $False
)

if (-not (Get-Module MSAL.PS -ListAvailable)) {
    Write-Host "Installing the MSAL.PS module."
    Install-Module MSAL.PS -SkipPublisherCheck -AcceptLicense -Scope AllUsers -Force
}

Write-Host "Authenticating."

# Define scopes
$scopes = @("User.ReadWrite.All", "Group.ReadWrite.All", "AppRoleAssignment.ReadWrite.All", "Application.ReadWrite.All", "DelegatedPermissionGrant.ReadWrite.All", "RoleManagement.ReadWrite.Directory", "Directory.ReadWrite.All")

# Get Graph token via MSAL.PS
try {
    $msalToken = Get-MsalToken -ClientId "1950a258-227b-4e31-a9cf-717495945fc2" -TenantId $tenant -Scopes "https://graph.microsoft.com/.default" -Interactive -ErrorAction Stop
    $graphToken = $msalToken.AccessToken
    if ($ScriptDebug) { Write-Output "Retrieved Graph token via MSAL.PS: $($graphToken.Substring(0,10))..." }
} catch {
    throw "Failed to retrieve Graph token via MSAL.PS: $_"
}

# Convert the token string to SecureString
$secureGraphToken = ConvertTo-SecureString -String $graphToken -AsPlainText -Force

Set-LabVariable -Name GraphToken -Value $graphToken
Set-LabVariable -Name SecureGraphToken -Value $SecureGraphToken

Write-Host "Finished authentication and created Graph Token lab variables."
