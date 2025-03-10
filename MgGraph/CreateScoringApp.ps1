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

# Connect to Microsoft Graph using the MSAL token
try {
    Connect-MgGraph -AccessToken $secureGraphToken -ErrorAction Stop -NoWelcome
    if ($ScriptDebug) { Write-Output "Successfully connected to Microsoft Graph with MSAL token" }
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

    Write-Host "Application created."

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
        if ($ScriptDebug) { Write-Output "Created service principal for app: $($servicePrincipal.Id)" }

        $graphSpId = $graphSP.Id

        # Grant delegated permissions (Scopes)
        $existingGrants = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/oauth2PermissionGrants?`$filter=clientId eq '$($servicePrincipal.Id)' and resourceId eq '$graphSpId'" | Select-Object -ExpandProperty value
        $desiredScopes = $delegatedPermissions -join " "
        if ($existingGrants) {
            $existingGrant = $existingGrants[0]
            $currentScopes = $existingGrant.scope
            if ($currentScopes -ne $desiredScopes) {
                $grantBody = @{
                    "scope" = $desiredScopes
                }
                $null = Invoke-MgGraphRequest -Method PATCH -Uri "https://graph.microsoft.com/v1.0/oauth2PermissionGrants/$($existingGrant.id)" -Body ($grantBody | ConvertTo-Json) -ContentType "application/json"
                if ($ScriptDebug) { Write-Output "Updated existing admin consent with scopes: $desiredScopes" }
            } else {
                if ($ScriptDebug) { Write-Output "Admin consent already granted with correct scopes: $currentScopes" }
            }
        } else {
            $grantBody = @{
                "clientId" = $servicePrincipal.Id
                "consentType" = "AllPrincipals"
                "principalId" = $null
                "resourceId" = $graphSpId
                "scope" = $desiredScopes
            }
            $null = Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/oauth2PermissionGrants" -Body ($grantBody | ConvertTo-Json) -ContentType "application/json"
            if ($ScriptDebug) { Write-Output "Created new admin consent with scopes: $desiredScopes" }
        }

        # Grant application permissions (Roles)
        $existingAppRoles = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/servicePrincipals/$($servicePrincipal.Id)/appRoleAssignments" | Select-Object -ExpandProperty value
        $existingAppRoleIds = $existingAppRoles | Select-Object -ExpandProperty appRoleId

        Write-Host "Granting app roles" -NoNewline
        foreach ($resource in $requiredResourceAccess) {
            foreach ($access in $resource.resourceAccess) {
                if ($access.type -eq "Role" -and $access.id -notin $existingAppRoleIds) {
                    $roleBody = @{
                        "principalId" = $servicePrincipal.Id
                        "resourceId" = $graphSpId
                        "appRoleId" = $access.id
                    }
                    try {
                        $null = Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/servicePrincipals/$($servicePrincipal.Id)/appRoleAssignments" -Body ($roleBody | ConvertTo-Json) -ContentType "application/json"
                        $roleValue = ($sp.AppRoles | Where-Object { $_.Id -eq $access.id }).Value
                        if ($ScriptDebug) { Write-Output "Granted app role: $roleValue" }
                        Write-Host "." -NoNewline
                    } catch {
                        if ($ScriptDebug) { Write-Output "Failed to grant approle: $roleValue" }
                    }
                }
            }
        }
        Write-Host ""

        if ($ScriptDebug) { Write-Output "Admin consent completed for all permissions" }
    } catch {
        if ($ScriptDebug) { Write-Output "Failed to grant admin consent via Graph: $_" }
        throw "Consent process failed: $_"
    }
} else {
    if ($ScriptDebug) { Write-Output "Scripting Engine application already exists" }
}

# Give time for the consent to settle
Write-Host "Waiting for the Scripting Engine Application to become ready."
#Start-Sleep -Seconds 60
60..1 | ForEach-Object { Write-Host "$_ seconds remaining" -NoNewline; Start-Sleep -Seconds 1; Write-Host "`r" -NoNewline }

# Save the AppId and Secret
$null = New-Item -Path C:\Temp -ItemType Directory -Force -ErrorAction SilentlyContinue
New-Object PSObject -Property @{AppId=$app.AppId;SecretText=$secret.SecretText} | ConvertTo-Json | Out-File C:\Temp\ScriptingApp.json

Write-Host "Script complete. AppId and Secret saved."
