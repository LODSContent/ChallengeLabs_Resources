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

if (($Password -in '',$Null -or $Password -like '*@lab*') -or ($TenantName -in '',$Null -or $TenantName -like '*@lab*')) {
    Return $False
}

$Password = $Password.trim(" ")
$TenantName = $TenantName.trim(" ")

function Send-DebugMessage {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Message,
        [string]$DebugUrl = "http://zombie.cyberjunk.com:2025/ABACAB81"
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
   #Write-Host $Message
}

if ($TenantName -eq $null -or $TenantName -eq "" -or $TenantName -like "@lab.Variable*") {
    if ($ScriptDebug) { Send-DebugMessage "Tenant name required for cleanup. Tenant is currently: $TenantName - Exiting cleanup process." }
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
    if ($ScriptDebug) { Send-DebugMessage  "$TenantName - New Password for admin accounts: $newAdminPassword" }
} else {
    $newAdminPassword = $Password
    if ($ScriptDebug) { Send-DebugMessage  "$TenantName - Existing Password for admin accounts: $newAdminPassword" }
}

try {
    # Get the current authenticated user's ID (works in delegated context)
    $currentUserId = (Get-MgContext).Account

   # Preserve user "admin" (by displayName and UPN) and first user
   $preserveUser = "admin"
   $preserveFirstUserUpn = "admin@$TenantName.onmicrosoft.com"  # Adjust if different
   $preserveAdminUpn = "admin@$TenantName.onmicrosoft.com"      # Explicitly preserve admin UPN
   
   # Remove users (except "admin", first user, ExternalAzureAD identities, and current user)
   try {
       $usersToDelete = Get-MgUser -All | Where-Object { 
           $_.DisplayName -ne $preserveUser -and 
           $_.UserPrincipalName -ne $preserveFirstUserUpn -and 
           $_.UserPrincipalName -ne $preserveAdminUpn -and 
           $_.UserType -ne "Guest" -and  # Preserve all Guest users (covers most ExternalAzureAD cases)
           $_.Id -ne $currentUserId
       }
       $failedUsers = @()
       foreach ($user in $usersToDelete) {
           $userId = $user.Id
           $userDisplayName = $user.DisplayName
           try {
               # Remove directory role assignments
               $roleAssignments = Invoke-MgGraphRequest -Method GET -Uri "v1.0/roleManagement/directory/roleAssignments?`$filter=principalId eq '$userId'" -ErrorAction Stop
               foreach ($assignment in $roleAssignments.value) {
                   try {
                       Invoke-MgGraphRequest -Method DELETE -Uri "v1.0/roleManagement/directory/roleAssignments/$($assignment.id)" -ErrorAction Stop
                       #if ($ScriptDebug) {Send-DebugMessage "Removed role assignment '$($assignment.roleDefinitionId)' for user '$userDisplayName'"}
                   } catch {
                       #if ($ScriptDebug) {Send-DebugMessage "Failed to remove role assignment '$($assignment.roleDefinitionId)' for user '$userDisplayName': $_"}
                       $failedUsers += $user
                       continue
                   }
               }
   
               # Remove PIM role eligibility (if applicable)
               $pimAssignments = Invoke-MgGraphRequest -Method GET -Uri "v1.0/roleManagement/directory/roleEligibilitySchedules?`$filter=principalId eq '$userId'" -ErrorAction SilentlyContinue
               foreach ($pimAssignment in $pimAssignments.value) {
                   try {
                       Invoke-MgGraphRequest -Method DELETE -Uri "v1.0/roleManagement/directory/roleEligibilitySchedules/$($pimAssignment.id)" -ErrorAction Stop
                       #if ($ScriptDebug) {Send-DebugMessage "Removed PIM role eligibility '$($pimAssignment.roleDefinitionId)' for user '$userDisplayName'"}
                   } catch {
                       #if ($ScriptDebug) {Send-DebugMessage "Failed to remove PIM role eligibility '$($pimAssignment.roleDefinitionId)' for user '$userDisplayName': $_"}
                       $failedUsers += $user
                       continue
                   }
               }
   
               # Delete the user if no role removal failures
               if ($failedUsers -notcontains $user) {
                   Remove-MgUser -UserId $userId -Confirm:$false -ErrorAction Stop
                   #if ($ScriptDebug) {Send-DebugMessage "Deleted user '$userDisplayName'"}
               } else {
                   #if ($ScriptDebug) {Send-DebugMessage "Skipped deletion of user '$userDisplayName' due to role assignment issues"}
               }
           } catch {
               #if ($ScriptDebug) {Send-DebugMessage "Failed to process user '$userDisplayName': $_"}
           }
       }
       if ($failedUsers) {
           if ($ScriptDebug) {Send-DebugMessage "Users with role assignment issues (skipped deletion): $($failedUsers.DisplayName -join ', ')"}
       } else {
           if ($ScriptDebug) {Send-DebugMessage "Removed all eligible users in: $($usersToDelete.DisplayName -join ', ')"}
       }
   } catch {
       if ($ScriptDebug) {Send-DebugMessage "Critical failure in user removal: $_"}
   }
   
   # Purge all deleted users
   try {
       Get-MgDirectoryDeletedItemAsUser | ForEach-Object {
           Remove-MgDirectoryDeletedItem -DirectoryObjectId $_.Id -Confirm:$false -ErrorAction SilentlyContinue
       }
       if ($ScriptDebug) {Send-DebugMessage "Purged all deleted users"}
   } catch {
       if ($ScriptDebug) {Send-DebugMessage "Some or all deleted users could not be purged: $_"}
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

    # Remove applications (only those listed)
    try {
        Get-MgApplication -All | Where-Object { 
            $_.DisplayName -like "CorpPartsDepot*" -or
            $_.DisplayName -like "InventoryTracker*" -or
            $_.DisplayName -like "Demo app*" -or
            $_.DisplayName -like "Adobe Sign*" -or 
            $_.DisplayName -like "Microsoft Entra SAML Toolkit"
        } | ForEach-Object {
            Remove-MgApplication -ApplicationId $_.Id -Confirm:$false -ErrorAction SilentlyContinue
        }
        if ($ScriptDebug) {Send-DebugMessage "Removed Applications"}
    } catch {
        if ($ScriptDebug) {Send-DebugMessage "Applications could not be removed."}
    }

    # Remove all Entra ID Administrative Units
    try {
        Get-MgDirectoryAdministrativeUnit -All | foreach {Remove-MgDirectoryAdministrativeUnit -AdministrativeUnitId $_.Id -Confirm:$false  -ErrorAction SilentlyContinue}
        if ($ScriptDebug) { Send-DebugMessage "Removed Administrative Units" }
    } catch {
        if ($ScriptDebug) { Send-DebugMessage "Administrative Units could not be removed." }
    }

    # Remove Access Packages
    try {
        get-mgentitlementmanagementaccesspackage | ForEach-Object {Remove-MgEntitlementManagementAccessPackage -AccessPackageId $_.Id}
        if ($ScriptDebug) { Send-DebugMessage "Removed Access Packages" }
    } catch {
        if ($ScriptDebug) { Send-DebugMessage "Access Packages could not be removed." }
    }

   # Remove Entra ID Access Reviews
   try {
       $accessReviews = Invoke-MgGraphRequest -Method GET -Uri "v1.0/identityGovernance/accessReviews/definitions" -ErrorAction Stop
       foreach ($review in $accessReviews.value) {
           Invoke-MgGraphRequest -Method DELETE -Uri "v1.0/identityGovernance/accessReviews/definitions/$($review.id)" -ErrorAction Stop
       }
       if ($ScriptDebug) {Send-DebugMessage "Removed all Entra ID Access Reviews"}
   } catch {
       if ($ScriptDebug) {Send-DebugMessage "Failed to remove Entra ID Access Reviews."}
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
        Get-MgDevice -All | foreach {Remove-MgDevice -DeviceId $_.Id -Confirm:$false -ErrorAction SilentlyContinue}
        if ($ScriptDebug) {Send-DebugMessage "Removed Devices"}
    } catch {
        if ($ScriptDebug) {Send-DebugMessage "Devices could not be removed."}
    }

   # Remove all Autopilot Deployment Profiles
   try {
       $profiles = Invoke-MgGraphRequest -Method GET -Uri "beta/deviceManagement/windowsAutopilotDeploymentProfiles" -ErrorAction Stop
       foreach ($profile in $profiles.value) {
           Invoke-MgGraphRequest -Method DELETE -Uri "beta/deviceManagement/windowsAutopilotDeploymentProfiles/$($profile.id)" -ErrorAction Stop
       }
       if ($ScriptDebug) {Send-DebugMessage "Removed all Autopilot Deployment Profiles"}
   } catch {
       if ($ScriptDebug) {Send-DebugMessage "Failed to remove Autopilot Deployment Profiles"}
   }  
   
   # Remove all Enrollment Status Pages
   try {
       $espConfigs = Invoke-MgGraphRequest -Method GET -Uri "beta/deviceManagement/deviceEnrollmentConfigurations" -ErrorAction Stop
       $espProfiles = $espConfigs.value | Where-Object { $_.'@odata.type' -eq '#microsoft.graph.windows10EnrollmentCompletionPageConfiguration' -and $_.DisplayName -ne "All users and all devices"}
       if ($espProfiles -and $espProfiles.Count -gt 0) {
           foreach ($profile in $espProfiles) {
               Invoke-MgGraphRequest -Method DELETE -Uri "beta/deviceManagement/deviceEnrollmentConfigurations/$($profile.id)" -ErrorAction SilentlyContinue
               if ($ScriptDebug) {Send-DebugMessage "Removed Enrollment Status Page '$($profile.displayName)'"}
           }
           if ($ScriptDebug) {Send-DebugMessage "Removed all Enrollment Status Pages ($($espProfiles.Count))"}
       } else {
           if ($ScriptDebug) {Send-DebugMessage "No Enrollment Status Pages found in tenant; skipping deletion"}
       }
   } catch {
       if ($ScriptDebug) {Send-DebugMessage "Failed to remove Enrollment Status Pages"}
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

   # Disable MFA registration enforcement and set SSPR to None
   try {
       $body = @{
           registrationEnforcement = @{
               authenticationMethodsRegistrationCampaign = @{
                   snoozeDurationInDays = 0
                   state = "disabled"
                   includeTargets = @()
               }
           }
       } | ConvertTo-Json -Depth 10
       Invoke-MgGraphRequest -Method PATCH -Uri "v1.0/policies/authenticationMethodsPolicy" -Body $body -ContentType "application/json" -ErrorAction Stop
       if ($ScriptDebug) {Send-DebugMessage "Disabled MFA registration enforcement and set SSPR to None"}
   } catch {
       if ($ScriptDebug) {Send-DebugMessage "Failed to disable MFA registration enforcement or SSPR."}
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
        try {
           $user = Invoke-MgGraphRequest `
               -Method POST `
               -Uri "https://graph.microsoft.com/v1.0/users" `
               -Body $userBody `
               -ContentType "application/json"
           if ($scriptDebug) { Send-DebugMessage "Created user: $globalAdmin" }
         } catch {
           if ($scriptDebug) { Send-DebugMessage "Failed to create user: $globalAdmin" }
         }
        # Assign the role via Graph API with explicit URI encoding
        $userRef = @{ "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($user.id)" } | ConvertTo-Json -Depth 10

        try {
           $role = Get-MgDirectoryRole -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq "Global Administrator" }
        } catch {}
        
        $roleUri = "https://graph.microsoft.com/v1.0/directoryRoles/$($role.Id)/members/`$ref"
        try {
           Invoke-MgGraphRequest `
               -Method POST `
               -Uri $roleUri `
               -Body $userRef `
               -ContentType "application/json"
           if ($scriptDebug) { Send-DebugMessage "Added Global Administrator role to: $globalAdmin" }
         } catch {
           if ($scriptDebug) { Send-DebugMessage "Failed to add Global Administrator role to: $globalAdmin" }
         }
    }

    if ($ScriptDebug) {Send-DebugMessage "Success: Tenant resources and settings cleared (preserved 'admin', first user '$preserveFirstUserUpn', 'cloud-slice-app', apps/SPs starting with 'Scripting', and ExternalAzureAD users)."}

    Return $newAdminPassword

} catch {
    if ($ScriptDebug) {Send-DebugMessage "Cleanup failed."}
}
