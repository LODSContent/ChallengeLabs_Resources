param (
        $tenant
      )

# Creates a new application for scoring (old method)

Connect-MgGraph -Tenant "$tenant" -Scopes "User.ReadWrite.All","Group.ReadWrite.All","AppRoleAssignment.ReadWrite.All","Application.ReadWrite.All","DelegatedPermissionGrant.ReadWrite.All","RoleManagement.ReadWrite.Directory","Directory.ReadWrite.All"

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
    $appPermissions += 'Application.ReadWrite.All'
    $appPermissions += 'User.ReadWrite.All'
    $appPermissions += 'Group.ReadWrite.All'
    $appPermissions += 'Policy.ReadWrite.ConditionalAccess'
    $appPermissions += 'Policy.ReadWrite.Security'
    $appPermissions += 'Directory.ReadWrite.All'
    $appPermissions += 'RoleManagement.ReadWrite.All'
    $appPermissions += 'RoleManagement.ReadWrite.Directory'
    $appPermissions += 'Files.ReadWrite.All'
    $appPermissions += 'Files.ReadWrite.AppFolder'

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

    # Get current Graph token
    $context = Get-MgContext
    $graphToken = (Get-MgContext).AccessToken

    # Exchange Graph token for AD management token (OBO flow)
    $consentBody = @{
        "grant_type" = "urn:ietf:params:oauth:grant-type:jwt-bearer"
        "client_id" = "1950a258-227b-4e31-a9cf-717495945fc2"  # Azure PowerShell client ID
        "assertion" = $graphToken
        "requested_token_use" = "on_behalf_of"
        "resource" = "74658136-14ec-4630-ad9b-26e160ff0fc6"  # Azure AD management resource
    }
    
    $consentResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenant/oauth2/token" -Method Post -Body $consentBody -ContentType "application/x-www-form-urlencoded"
    $token = $consentResponse.access_token

    # Headers for consent request
    $headers = @{
        'Authorization'          = "Bearer $token"
        'X-Requested-With'       = 'XMLHttpRequest'
        'x-ms-client-request-id' = [guid]::NewGuid().ToString()
        'x-ms-correlation-id'    = [guid]::NewGuid().ToString()
    }

    # Consent endpoint
    $url = "https://main.iam.ad.ext.azure.com/api/RegisteredApplications/$appId/Consent?onBehalfOfAll=true"
    $retries = 0
    do {
        try {
            Invoke-RestMethod -Uri $url -Headers $headers -Method POST -ErrorAction Stop | Out-Null
            $ConsentFinished = $True
        } catch {
            $ConsentFinished = $false
            if ($scriptDebug) {Write-Output "Failed to Consent to all permissions"}
        }
        $retries++
        if ($scriptDebug) {Write-Output "Retry #$retries"}
    } until ($ConsentFinished -or $retries -ge 3)


    if ($scriptDebug) { Write-Output "Created the Scripting Engine application" }
} else {
    if ($scriptDebug) { Write-Output "Scripting Engine application already exists" }
}

# Give time for the consent to settle
Start-Sleep 60

# Save the AppId and Secret
MD C:\Temp -ErrorAction SilentlyContinue | Out-Null
New-Object PSObject -Property @{AppId=$newApp.AppId;SecretText=$secret.SecretText} | ConvertTo-Json | Out-File C:\Temp\ScriptingApp.json
