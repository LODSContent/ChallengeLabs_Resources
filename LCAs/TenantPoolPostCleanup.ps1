<#
   Title: Tenant Post-Cleanup
   Description: Cleans up student tenant at lab shutdoown.
   Target: Cloud Subscription - PowerShell - 7.4.0 | Az 11.1.0 (RC) - Microsoft.Graph - 2.26.0
#>

param (
    $TenantName,
    $Password,
    [switch]$ScriptDebug    
)

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

if ($TenantName -eq $null -or $TenantName -eq "" -or $TenantName -like "@lab.Variable*") {
    if ($ScriptDebug) { Send-NtryDebug "Tenant name required for cleanup. Tenant is currently: $TenantName - Exiting cleanup process." }
    Throw "Tenant name required for cleanup. Tenant is currently: $TenantName - Exiting cleanup process."
} 

# MgGraph Authentication block (Cloud Subscription Target)
$AccessToken = (Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com" -TenantId $TenantName).Token
$SecureToken = ConvertTo-Securestring $AccessToken -AsPlainText -Force
Connect-MgGraph -AccessToken $SecureToken -NoWelcome

# Create a random password for new admins and password resets
if ($Password -eq $null -or $Password -eq "" -or $Password -like "@lab.Variable*") {
    $RandomHex = -join (Get-Random ((0..9) + (97..105 | %{[char]$_})) -Count 12)
    $newAdminPassword = "Pw1@$RandomHex"   # Can't use random until I figure out how to update the pool
} else {
    $newAdminPassword = $Password
}
if ($ScriptDebug) { Send-DebugMessage  "$TenantName - New Password for admin accounts: $newAdminPassword" }

try {
    # Get the current authenticated user's ID (works in delegated context)
    $currentUserId = (Get-MgContext).Account

    # Preserve user "admin" (by displayName and UPN) and first user
    $preserveUser = "admin"
    $preserveFirstUserUpn = "admin@$TenantName.onmicrosoft.com"  # Adjust if different
    $preserveAdminUpn = "admin@$TenantName.onmicrosoft.com"      # Explicitly preserve admin UPN

    # Remove users (except "admin", first user, ExternalAzureAD identities, and current user)
    try {
        Get-MgUser -All | Where-Object { 
            $_.DisplayName -ne $preserveUser -and 
            $_.UserPrincipalName -ne $preserveFirstUserUpn -and 
            $_.UserPrincipalName -ne $preserveAdminUpn -and 
            $_.UserType -ne "Guest" -and  # Preserve all Guest users (covers most ExternalAzureAD cases)
            $_.Id -ne $currentUserId
        } | ForEach-Object {
            # Remove role assignments for the user
            $userId = $_.Id
            Get-MgDirectoryRole -All | ForEach-Object {
                $roleId = $_.Id
                $members = Get-MgDirectoryRoleMember -DirectoryRoleId $roleId | Where-Object { $_.Id -eq $userId }
                if ($members) {
                    Remove-MgDirectoryRoleMemberByRef -DirectoryRoleId $roleId -DirectoryObjectId $userId -ErrorAction SilentlyContinue
                    if ($ScriptDebug) {Send-DebugMessage "Removed role '$($_.DisplayName)' from user '$($_.DisplayName)'"}
                }
            }
            # Now delete the user
            Remove-MgUser -UserId $userId -Confirm:$false -ErrorAction SilentlyContinue
        }
        if ($ScriptDebug) {Send-DebugMessage "Removed Users"}
    } catch {
        if ($ScriptDebug) {Send-DebugMessage "Users could not be removed."}
    }

    # Purge all deleted users
    try {
        Get-MgDirectoryDeletedItemAsUser | ForEach-Object {
            Remove-MgDirectoryDeletedItem -DirectoryObjectId $_.Id -Confirm:$false -ErrorAction SilentlyContinue
        }
        if ($ScriptDebug) {Send-DebugMessage "Purged all deleted users"}
    } catch {
        if ($ScriptDebug) {Send-DebugMessage "Some or all deleted users could not be purged."}
    }

    # Remove groups
    try {
        Get-MgGroup -All | ForEach-Object {
            Remove-MgGroup -GroupId $_.Id -Confirm:$false -ErrorAction SilentlyContinue
        }
        if ($ScriptDebug) {Send-DebugMessage "Removed Groups"}
    } catch {
        if ($ScriptDebug) {Send-DebugMessage "Groups could not be removed."}
    }        

    <# Too many unknowns with the existing SPs and Apps. Let's keep them for now.

    # Preserve service principal "cloud-slice-app" and skip apps/SPs starting with "Scripting"
    $preserveSp = "cloud-slice-app"
    try {
        $spToKeep = Get-MgServicePrincipal -Filter "displayName eq '$preserveSp'"
        if (-not $spToKeep) { Send-DebugMessage "Service principal 'cloud-slice-app' not found." }
        Send-DebugMessage "Service principal 'cloud-slice-app' preserved."
    } catch {
        Send-DebugMessage "Service principal 'cloud-slice-app' could not be preserved."
    }

    # Remove applications (except "cloud-slice-app" and those starting with "Scripting")
    try {
        Get-MgApplication -All | Where-Object { 
            $_.AppId -ne $spToKeep.AppId -and 
            $_.DisplayName -notlike "Scripting*" 
        } | ForEach-Object {
            Remove-MgApplication -ApplicationId $_.Id -Confirm:$false -ErrorAction SilentlyContinue
        }
        if ($ScriptDebug) {Send-DebugMessage "Removed Applications"}
    } catch {
        if ($ScriptDebug) {Send-DebugMessage "Applications could not be removed."}
    }

    # Remove service principals (except "cloud-slice-app" and those starting with "Scripting")
    try {
        Get-MgServicePrincipal -All | Where-Object { 
            $_.DisplayName -ne $preserveSp -and 
            $_.DisplayName -notlike "Scripting*" 
        } | ForEach-Object {
            Remove-MgServicePrincipal -ServicePrincipalId $_.Id -Confirm:$false -ErrorAction SilentlyContinue
        }
        if ($ScriptDebug) {Send-DebugMessage "Removed Service Principals"}
    } catch {
        if ($ScriptDebug) {Send-DebugMessage "Service principals could not be removed."}
    }
    
    #>

    # Remove all Entra ID Administrative Units
    try {
        Get-MgDirectoryAdministrativeUnit -All | foreach {Remove-MgDirectoryAdministrativeUnit -AdministrativeUnitId $_.Id -Confirm:$false  -ErrorAction SilentlyContinue}
        if ($ScriptDebug) { Send-DebugMessage "Removed Administrative Units" }
    } catch {
        if ($ScriptDebug) { Send-DebugMessage "Administrative Units could not be removed: $([string]$_.Exception.Message)" }
    }
   
    # Remove terms and conditions
    try {
        Get-MgAgreement | foreach {Remove-mgagreement -AgreementId $_.id -ErrorAction SilentlyContinue} 
        if ($ScriptDebug) {Send-DebugMessage "Removed terms and conditions"}
    } catch {
        if ($ScriptDebug) {Send-DebugMessage "Terms and conditions could not be removed."}
    }

    # Remove Device Registrations
    try {
        Get-MgDevice -All | Remove-MgDevice -Confirm:$false -ErrorAction SilentlyContinue
        if ($ScriptDebug) {Send-DebugMessage "Removed Devices"}
    } catch {
        if ($ScriptDebug) {Send-DebugMessage "Devices could not be removed."}
    }

    # Reset authorization policy
    try {
      $params = @{AllowInvitesFrom = "everyone"}
      Update-mgpolicyauthorizationpolicy -BodyParameter $params -erroraction ignore
      if ($ScriptDebug) {Send-DebugMessage "Reset authorization policy"}
    } catch {
      if ($ScriptDebug) {Send-DebugMessage "Failed to reset authorization policy"}
    }

   # Remove Deviceregistrationpolicy settings via direct mggraph request
   try {   
      $uri = "https://graph.microsoft.com/beta/policies/deviceRegistrationPolicy"
      $body = '{
      "@odata.context":"https://graph.microsoft.com/beta/$metadata#policies/deviceRegistrationPolicy/$entity",
      "multiFactorAuthConfiguration":"notRequired",
      "id":"deviceRegistrationPolicy",
      "displayName":"Device Registration Policy",
      "description":"Tenant-wide policy that manages initial provisioning controls using quota restrictions, additional authentication and authorization checks",
      "userDeviceQuota":50,
      "azureADRegistration":{
      	"isAdminConfigurable":false,
      	"allowedToRegister":{
      		"@odata.type":"#microsoft.graph.allDeviceRegistrationMembership",
      		"users": null,
      		"groups": null
      		}
      	},
      "azureADJoin":{
      	"isAdminConfigurable":true,
      	"allowedToJoin":{
      		"@odata.type":"#microsoft.graph.allDeviceRegistrationMembership",
      		"users":null,
      		"groups": null
      		},
      	"localAdmins":{
      		"enableGlobalAdmins":true,
      		"registeringUsers":{
      			"@odata.type":"#microsoft.graph.allDeviceRegistrationMembership"
      			}
      		}
      	},
      "localAdminPassword":{
      	"isEnabled": false
      	}
      }'      
      
      Invoke-MgGraphRequest -uri $uri -body $body -contenttype "application/json" -method PUT | Out-Null
      if ($ScriptDebug) {Send-DebugMessage "Reset Device Registration Policy"}
   } catch {
      if ($ScriptDebug) {Send-DebugMessage "Device Registration Policy could not be reset."}
   }

    # Remove custom domains
    try {
        Get-MgDomain | Where-Object { $_.IsDefault -eq $false } | Remove-MgDomain -Confirm:$false -ErrorAction SilentlyContinue
        if ($ScriptDebug) {Send-DebugMessage "Removed Custom Domains"}
    } catch {
        if ($ScriptDebug) {Send-DebugMessage "Custom domains could not be removed."}
    }

    # Set passwords to never expire for all domains
    try {
        Get-MgDomain | ForEach-Object { 
            Update-MgDomain -DomainId $_.Id -PasswordValidityPeriodInDays 2147483647 
        }
        if ($ScriptDebug) {Send-DebugMessage "Set password validity to never expire for all domains"}
    } catch {
        if ($ScriptDebug) {Send-DebugMessage "Failed to set password validity to never expire"}
    }    

   # Remove technical contact and reset notification email and privacy statement from Entra ID tenant
   try {
      $orgId = (Get-MgOrganization).Id
      $bodyTech = @{ privacyProfile = @{contactEmail = $null};technicalNotificationMails = @() } | ConvertTo-Json
      $techResponse = Invoke-MgGraphRequest -Method PATCH -Uri "v1.0/organization/$orgId" -Body $bodyTech -ContentType "application/json" -OutputType Http -ErrorAction Stop
      if ($ScriptDebug) {Send-DebugMessage "Cleared technical contact, notification email and privacy statement."}
   } catch {
       if ($ScriptDebug) {Send-DebugMessage "Error cleaning technical contact info: $_"}
   }

    # Delete Conditional Access policies
    try{ 
        Get-MgIdentityConditionalAccessPolicy -All | Remove-MgIdentityConditionalAccessPolicy -Confirm:$false -ErrorAction SilentlyContinue
        if ($ScriptDebug) {Send-DebugMessage "Removed Conditional Access policies"}
    } catch {
        if ($ScriptDebug) {Send-DebugMessage "Conditional Access policies could not be removed."}
    } 

    # Reset security defaults (commented out)
    # Update-MgPolicyAuthorizationPolicy -DefaultUserRolePermissions @{"securityDefaultEnforced" = $true} -ErrorAction SilentlyContinue

    # Reset the password of the user named "admin" and create new Global Administrator accounts
    try {
        $adminUser = Get-MgUser -Filter "UserPrincipalName eq 'admin@$TenantName'"
        if ($adminUser) {
            $globalAdmins = "LabAdmin","LODAdmin"
            $passwordBody = @{
                "passwordProfile" = @{
                    "password" = $newAdminPassword
                    "forceChangePasswordNextSignIn" = $false
                }
            } | ConvertTo-Json -Depth 10
        
            Invoke-MgGraphRequest `
                -Method PATCH `
                -Uri "https://graph.microsoft.com/v1.0/users/$($adminUser.Id)" `
                -Body $passwordBody `
                -ContentType "application/json"
        
            if ($ScriptDebug) {Send-DebugMessage "Reset 'admin' user password."}     
        } else {
            $globalAdmins = "admin","LabAdmin","LODAdmin"
            if ($ScriptDebug) {Send-DebugMessage "User 'admin' not found. Creating with new Global Administrators."}
        } 
    } catch {
        if ($ScriptDebug) {Send-DebugMessage "Attempt to reset Admin Password Failed."}
    }

    foreach ($globalAdmin in $globalAdmins) {
        # Create Global Administrator
        $userBody = @{
            "displayName" = $globalAdmin
            "mailNickname" = $globalAdmin
            "usageLocation" = "US"
            "userPrincipalName" = "$globalAdmin@$TenantName"
            "accountEnabled" = $true
            "passwordProfile" = @{
                "password" = $newAdminPassword
                "forceChangePasswordNextSignIn" = $false
            }
        } | ConvertTo-Json -Depth 10

        # Create the user via Graph API
        $user = Invoke-MgGraphRequest `
            -Method POST `
            -Uri "https://graph.microsoft.com/v1.0/users" `
            -Body $userBody `
            -ContentType "application/json"

        # Assign the role via Graph API with explicit URI encoding
        $userRef = @{ "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($user.id)" } | ConvertTo-Json -Depth 10
    
        $role = Get-MgDirectoryRole | Where-Object { $_.DisplayName -eq "Global Administrator" }
    
        $roleUri = "https://graph.microsoft.com/v1.0/directoryRoles/$($role.Id)/members/`$ref"
        Invoke-MgGraphRequest `
            -Method POST `
            -Uri $roleUri `
            -Body $userRef `
            -ContentType "application/json"
          
        if ($scriptDebug) { Send-DebugMessage "Created: $globalAdmin" }
    }

    if ($ScriptDebug) {Send-DebugMessage "Success: Tenant resources and settings cleared (preserved 'admin', first user '$preserveFirstUserUpn', 'cloud-slice-app', apps/SPs starting with 'Scripting', and ExternalAzureAD users)."}

    Return $newAdminPassword

} catch {
    if ($ScriptDebug) {Send-DebugMessage "Cleanup failed."}
}
