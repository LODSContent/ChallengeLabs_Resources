param (
    [Parameter(Mandatory = $true)]
    $tenant,
    [switch]$Debug=$False
)

$ScriptDebug = $Debug

# Ensure required modules are imported
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
try {
    Import-Module MSAL.PS -ErrorAction Stop
} catch {
    throw "MSAL.PS module is required. Install it with: Install-Module MSAL.PS"
}

# Define scopes
$scopes = @("User.ReadWrite.All", "Group.ReadWrite.All", "AppRoleAssignment.ReadWrite.All", "Application.ReadWrite.All", "DelegatedPermissionGrant.ReadWrite.All", "RoleManagement.ReadWrite.Directory", "Directory.ReadWrite.All")

# Get Graph token via MSAL.PS
try {
    $msalToken = Get-MsalToken -ClientId "1950a258-227b-4e31-a9cf-717495945fc2" -TenantId $tenant -Scopes "https://graph.microsoft.com/.default" -Interactive -ErrorAction Stop
    $graphToken = $msalToken.AccessToken
    if ($scriptDebug) { Write-Output "Retrieved Graph token via MSAL.PS: $($graphToken.Substring(0,10))..." }
} catch {
    throw "Failed to retrieve Graph token via MSAL.PS: $_"
}

# Convert the token string to SecureString
$secureGraphToken = ConvertTo-SecureString -String $graphToken -AsPlainText -Force

# Connect to Microsoft Graph using the MSAL token
try {
    Connect-MgGraph -AccessToken $secureGraphToken -ErrorAction Stop
    if ($scriptDebug) { Write-Output "Successfully connected to Microsoft Graph with MSAL token" }
} catch {
    throw "Failed to connect to Microsoft Graph: $_"
}

# Check if app exists
$existingApp = Get-MgApplication -Filter "displayName eq 'Scripting Engine'"
if (-not $existingApp) {
    # Get Microsoft Graph service principal
    $graphSP = Get-MgServicePrincipal -Filter "displayName eq 'Microsoft Graph'"
    if (-not $graphSP) { throw "Microsoft Graph service principal not found" }

    # Define required permissions
    $requiredResourceAccess = @(
        @{
            "resourceAppId" = $graphSP.AppId
            "resourceAccess" = @()
        }
    )

    # Application permissions
    $sp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"  # Graph AppId
    $appPermissions = $sp.AppRoles | Where-Object { $_.Value -like "*.read.*" -or $_.Value -like "*security*" -or $_.Value -like "Policy*" } | Select-Object -ExpandProperty Value
    $appPermissions += 'Application.ReadWrite.All', 'User.ReadWrite.All', 'Group.ReadWrite.All', 'Policy.ReadWrite.ConditionalAccess', 'Policy.ReadWrite.Security', 'Directory.ReadWrite.All', 'RoleManagement.ReadWrite.All', 'RoleManagement.ReadWrite.Directory', 'Files.ReadWrite.All', 'Files.ReadWrite.AppFolder'

    foreach ($permission in $appPermissions) {
        $reqPermission = $sp.AppRoles | Where-Object { $_.Value -eq $permission }
        if ($reqPermission) {
            $requiredResourceAccess[0].resourceAccess += @{
                "id" = $reqPermission.Id
                "type" = "Role"
            }
        }
    }

    # Delegated permissions
    $delegatedPermissions = @('Directory.ReadWrite.All', 'Group.ReadWrite.All')
    foreach ($permission in $delegatedPermissions) {
        $reqPermission = $sp.OAuth2PermissionScopes | Where-Object { $_.Value -eq $permission }
        if ($reqPermission) {
            $requiredResourceAccess[0].resourceAccess += @{
                "id" = $reqPermission.Id
                "type" = "Scope"
            }
        }
    }

    # Create the application
    $appBody = @{
        "displayName" = "Scripting Engine"
        "Description" = "Scripting Engine app for tenant: $tenant"
        "signInAudience" = "AzureADMyOrg"
        "web" = @{
            "redirectUris" = @("http://localhost")
        }
        "requiredResourceAccess" = $requiredResourceAccess
    } | ConvertTo-Json -Depth 10

    $app = Invoke-MgGraphRequest `
        -Method POST `
        -Uri "https://graph.microsoft.com/v1.0/applications" `
        -Body $appBody `
        -ContentType "application/json"

    # Add password credential
    Start-Sleep -Seconds 10
    $secretBody = @{
        "passwordCredential" = @{
            "displayName" = "Script Secret"
            "endDateTime" = (Get-Date).AddDays(90).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        }
    } | ConvertTo-Json -Depth 10

    $secret = Invoke-MgGraphRequest `
        -Method POST `
        -Uri "https://graph.microsoft.com/v1.0/applications/$($app.id)/addPassword" `
        -Body $secretBody `
        -ContentType "application/json"

    $appId = $app.AppId

    # Grant admin consent via Graph
    try {
        $servicePrincipal = New-MgServicePrincipal -AppId $appId -ErrorAction Stop
        if ($scriptDebug) { Write-Output "Created service principal for app: $($servicePrincipal.Id)" }

        $graphSpId = $graphSP.Id
        $existingGrants = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/oauth2PermissionGrants?`$filter=clientId eq '$($servicePrincipal.Id)' and resourceId eq '$graphSpId'" | Select-Object -ExpandProperty value

        $desiredScopes = $delegatedPermissions -join " "
        if ($existingGrants) {
            # Update existing grant if scopes differ
            $existingGrant = $existingGrants[0]  # Assuming one grant per clientId/resourceId pair
            $currentScopes = $existingGrant.scope
            if ($currentScopes -ne $desiredScopes) {
                $grantBody = @{
                    "scope" = $desiredScopes
                }
                Invoke-MgGraphRequest -Method PATCH -Uri "https://graph.microsoft.com/v1.0/oauth2PermissionGrants/$($existingGrant.id)" -Body ($grantBody | ConvertTo-Json) -ContentType "application/json"
                if ($scriptDebug) { Write-Output "Updated existing admin consent with scopes: $desiredScopes" }
            } else {
                if ($scriptDebug) { Write-Output "Admin consent already granted with correct scopes: $currentScopes" }
            }
        } else {
            # Create new grant
            $grantBody = @{
                "clientId" = $servicePrincipal.Id
                "consentType" = "AllPrincipals"
                "principalId" = $null
                "resourceId" = $graphSpId
                "scope" = $desiredScopes
            }
            Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/oauth2PermissionGrants" -Body ($grantBody | ConvertTo-Json) -ContentType "application/json"
            if ($scriptDebug) { Write-Output "Created new admin consent with scopes: $desiredScopes" }
        }
    } catch {
        if ($scriptDebug) { Write-Output "Failed to grant admin consent via Graph: $_" }
        throw "Consent process failed: $_"
    }

    if ($scriptDebug) { Write-Output "Created the Scripting Engine application" }
} else {
    if ($scriptDebug) { Write-Output "Scripting Engine application already exists" }
}

# Give time for the consent to settle
Start-Sleep -Seconds 60

# Save the AppId and Secret
$null = New-Item -Path C:\Temp -ItemType Directory -Force -ErrorAction SilentlyContinue
New-Object PSObject -Property @{AppId=$app.AppId;SecretText=$secret.SecretText} | ConvertTo-Json | Out-File C:\Temp\ScriptingApp.json
