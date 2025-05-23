# Create TAP enabled user and establish credential variables
<#
   Title: Create TAP enabled user and establish credential variables
   Description: Creates a new user with a Temporary Access Password and establishes credential variables for the lab.
   Target: Cloud Subscription - PowerShell - 7.4.0 | Az 11.1.0 (RC)
#>

param (
    $TenantName,
    $AppID,
    $AppSecret,
    $UserName,
    $Password,
    $ScriptingAppId,
    $ScriptingAppSecret,
    [switch]$ScriptDebug
)

$PoolUserName = $UserName
$PoolPassword = $Password
$TapUser = "LabAdmin@$TenantName"
$LegacyPassword = $Password
$Lifetime = 120

function Send-DebugMessage {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Message,
        [string]$DebugUrl = "https://ntfy.sh/PSO78HOMAXEXKSaQ"
    )

    if ($global:DebugUrl) {
      $DebugUrl = $global:DebugUrl
    }
    
    if ($DebugUrl) {
       try {
           Invoke-WebRequest -Uri $DebugUrl -Method Post -Body $Message -ErrorAction Stop | Out-Null
       } catch {
           # Silently fail to avoid disrupting the script; optionally log locally if desired
           Write-Warning "Failed to send debug message: $_"
       }
   }
   Write-Output $Message
}

# Check for credential pool and set variables
if ($UserName -ne $null -or $UserName -ne '') {

    # Authenticate to get access token
    $azureUri = "https://login.microsoftonline.com/$TenantName/oauth2/token"
    $body = @{
        "grant_type"    = "client_credentials"
        "client_id"     = "$AppID"
        "client_secret" = "$AppSecret"
        "resource"      = "https://graph.microsoft.com/"
    }

    try {
        $AuthRequest = Invoke-RestMethod -Uri $azureUri -Method Post -Body $body -ErrorAction Stop
        $token = $AuthRequest.access_token
        if ($ScriptDebug) { Send-DebugMessage "Successfully acquired access token" }
    } catch {
        if ($ScriptDebug) { Send-DebugMessage "Failed to acquire access token: $($_.Exception.Message)" }
        return $false
    }

    # Define headers for all Graph API calls
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type"  = "application/json"
    }

    # Check if user exists; create if not
    try {
        $createUserResponse = Invoke-RestMethod -Method GET `
            -Uri "https://graph.microsoft.com/v1.0/users/$TapUser" `
            -Headers $headers `
            -ErrorAction Stop
        if ($ScriptDebug) { Send-DebugMessage "User $TapUser exists" }
    } catch {
        if ($_.Exception.Response.StatusCode -eq 404) {
            if ($ScriptDebug) { Send-DebugMessage "User $TapUser does not exist, creating..." }
            $userDetails = @{
                "accountEnabled"    = $true
                "displayName"       = $TapUser.Split('@')[0]
                "mailNickname"      = $TapUser.Split('@')[0]
                "userPrincipalName" = $TapUser
                "usageLocation"     = "US"
                "passwordProfile"   = @{
                    "forceChangePasswordNextSignIn" = $false
                    "password"                      = $LegacyPassword
                }
            }
            try {
                $createUserResponse = Invoke-RestMethod -Method POST `
                    -Uri "https://graph.microsoft.com/v1.0/users" `
                    -Headers $headers `
                    -Body ($userDetails | ConvertTo-Json) `
                    -ErrorAction Stop
                if ($ScriptDebug) { Send-DebugMessage "User $TapUser created successfully" }
            } catch {
                if ($ScriptDebug) { Send-DebugMessage "Failed to create user $TapUser : $($_.Exception.Message)" }
            }
        } else {
            if ($ScriptDebug) { Send-DebugMessage "Error checking user $TapUser : $($_.Exception.Message)" }
        }
    }

    $userId = $createUserResponse.id

    # Assign Global Administrator role (ignore if exists)
    $globalAdminRoleId = "62e90394-69f5-4237-9190-012177145e10"
    $roleAssignmentBody = @{
        "@odata.type"      = "#microsoft.graph.unifiedRoleAssignment"
        "principalId"      = $userId
        "roleDefinitionId" = $globalAdminRoleId
        "directoryScopeId" = "/"
    }

    try {
        Invoke-RestMethod -Method POST `
            -Uri "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignments" `
            -Headers $headers `
            -Body ($roleAssignmentBody | ConvertTo-Json) `
            -ErrorAction Stop | Out-Null
        if ($ScriptDebug) { Send-DebugMessage "Global Administrator role assigned to $TapUser" }
    } catch {
        if ($_.Exception.Response.StatusCode -eq 409) {
            if ($ScriptDebug) { Send-DebugMessage "Global Administrator role already exists for $TapUser" }
        } else {
            if ($ScriptDebug) { Send-DebugMessage "Failed to assign Global Administrator role to $TapUser or it already exists: $($_.Exception.Message)" }
        }
    }

    # Get available licenses (SKUs)
    try {
        $skusResponse = Invoke-RestMethod -Method GET `
            -Uri "https://graph.microsoft.com/v1.0/subscribedSkus" `
            -Headers $headers `
            -ErrorAction Stop
        $availableSkus = @($skusResponse.value | Where-Object { ($_.prepaidUnits.enabled - $_.consumedUnits) -gt 0 })
        if ($availableSkus.Count -eq 0 -and $ScriptDebug) { Send-DebugMessage "No available licenses found in tenant" }
    } catch {
        if ($ScriptDebug) { Send-DebugMessage "Failed to retrieve SKUs: $($_.Exception.Message)" }
    }

    # Assign licenses (ignore if exists)
    if ($availableSkus.Count -gt 0) {
        $licenseAssignmentBody = @{
            "addLicenses"    = @($availableSkus | ForEach-Object {
                @{
                    "disabledPlans" = @()
                    "skuId"         = $_.skuId
                }
            })
            "removeLicenses" = @()
        }
        try {
            Invoke-RestMethod -Method POST `
                -Uri "https://graph.microsoft.com/v1.0/users/$userId/assignLicense" `
                -Headers $headers `
                -Body ($licenseAssignmentBody | ConvertTo-Json -Depth 3) `
                -ErrorAction Stop | Out-Null
            if ($ScriptDebug) { Send-DebugMessage "Licenses assigned to $TapUser" }
        } catch {
            if ($_.Exception.Response.StatusCode -eq 400 -and $_.Exception.Message -match "already assigned") {
                if ($ScriptDebug) { Send-DebugMessage "Licenses already assigned to $TapUser" }
            } else {
                if ($ScriptDebug) { Send-DebugMessage "Failed to assign licenses to $TapUser : $($_.Exception.Message)" }
            }
        }
    }

    # Enable TAP policy with multiple-use configuration
    $tapPolicyUri = "https://graph.microsoft.com/beta/policies/authenticationMethodsPolicy/authenticationMethodConfigurations/TemporaryAccessPass"
    $policyPayload = @{
        "@odata.type"           = "#microsoft.graph.temporaryAccessPassAuthenticationMethodConfiguration"
        "id"                    = "TemporaryAccessPass"
        "state"                 = "enabled"
        "includeTargets"        = @(
            @{
                "targetType"           = "group"
                "id"                   = "all_users"  # Use a specific group ID if needed
                "isRegistrationRequired" = $false
            }
        )
        "defaultLifetimeInMinutes" = 60
        "defaultLength"         = 8
        "minimumLifetimeInMinutes" = 60
        "maximumLifetimeInMinutes" = 480
        "isUsableOnce"          = $false  # Allow multiple uses
    }

    try {
        Invoke-RestMethod -Method PATCH `
            -Uri $tapPolicyUri `
            -Headers $headers `
            -Body ($policyPayload | ConvertTo-Json) `
            -ErrorAction Stop
        if ($ScriptDebug) { Send-DebugMessage "TAP policy updated to allow multiple uses" }
    } catch {
        if ($ScriptDebug) { Send-DebugMessage "Failed to update TAP policy: $($_.Exception.Message)" }
    }

    # Define TAP details
    $tapDetails = @{
        "lifetimeInMinutes" = $Lifetime
        "isUsableOnce"      = $false  # Multi-use TAP
    }

    # Create TAP for the user
    try {
        $TAP = Invoke-RestMethod -Method POST `
            -Uri "https://graph.microsoft.com/beta/users/$userId/authentication/temporaryAccessPassMethods" `
            -Headers $headers `
            -Body ($tapDetails | ConvertTo-Json) `
            -ErrorAction Stop
        $TapPassword = $TAP.temporaryAccessPass
        if ($ScriptDebug) { Send-DebugMessage "TAP Password: $TapPassword created for: $TapUser" }
    } catch {
        if ($ScriptDebug) { Send-DebugMessage "Failed to create TAP for $TapUser : $($_.Exception.Message)" }
    }

    # Update lab variables based on TAP success
    if ($TapPassword) {
         Set-LabVariable -Name UserName -Value $TapUser
         Set-LabVariable -Name Password -Value $TapPassword
         Set-LabVariable -Name TenantName -Value $TenantName
         Set-LabVariable -Name PoolUserName -Value $PoolUserName
         Set-LabVariable -Name PoolPassword -Value $PoolPassword
         Set-LabVariable -Name TAPLifetime -Value $Lifetime
         Set-LabVariable -Name ScriptingAppId -Value $ScriptingAppId
         Set-LabVariable -Name ScriptingAppSecret -Value $ScriptingAppSecret
         Set-LabVariable -Name CredentialPool -Value 'Yes'
        if ($ScriptDebug) { Send-DebugMessage "TAP User setup complete" }
    } else {
         Set-LabVariable -Name UserName -Value $UserName
         Set-LabVariable -Name Password -Value $Password
         Set-LabVariable -Name TenantName -Value $TenantName
         Set-LabVariable -Name ScriptingAppId -Value $ScriptingAppId
         Set-LabVariable -Name ScriptingAppSecret -Value $ScriptingAppSecret
         Set-LabVariable -Name TAPLifetime -Value "Error"
         Set-LabVariable -Name CredentialPool -Value 'Yes'
        if ($ScriptDebug) { Send-DebugMessage "TAP user setup failed. Falling back on default Pool credentials." }
    }
} else {
    Set-LabVariable -Name CredentialPool -Value 'No'
    if ($ScriptDebug) { Send-DebugMessage "Credential Pool not available. Falling back on manual credentials." }
}

return $true
