
<#
   Title: Tenant Post-Cleanup
   Description: Cleans up student tenant at lab shutdoown.
   Target: Cloud Subscription - PowerShell - 7.4.0 | Az 11.1.0 (RC) - Microsoft.Graph - 2.26.0
#>

param (
    $TenantName,
    $Password,
    $ScriptingAppId,
    $ScriptingAppSecret,
    $LabInstanceId,
	[switch]$CustomTarget,	
    [switch]$ScriptDebug
)

# Script Title
$ScriptTitle = "Post Cleanup for: $TenantName"

# Lab Notification function
function Send-LabNotificationChunks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptTitle,

        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [int]$MaxLength = 2048
    )

    # Clean up the buffer
    $buffer = $Message.TrimEnd()

    # Base header without part number
    $baseHeader = "[Debug] $ScriptTitle :`n---------`n"
    $baseHeaderLength = $baseHeader.Length

    # Available space per chunk after header
    $availablePerChunk = $MaxLength - $baseHeaderLength

    if ($buffer.Length -le $availablePerChunk) {
        # Short message - send as one piece with normal header
        $fullMessage = "$baseHeader$buffer"
		try {
        	Send-LabNotification -Message $fullMessage
        } catch {
			Write-Output $fullMessage
		}	
        return
    }

    # Long message - need to split
    $chunks = @()
    $position = 0

    while ($position -lt $buffer.Length) {
        $remaining = $buffer.Length - $position
        $take = [Math]::Min($availablePerChunk, $remaining)

        # Try to end on a line break when possible (look back max ~300 chars)
        if ($take -lt $remaining) {
            $lookback = [Math]::Min(300, $take)
            $lastNewLine = $buffer.LastIndexOf("`n", $position + $take - 1, $lookback)
            if ($lastNewLine -ge $position) {
                $take = $lastNewLine - $position + 1   # include newline
            }
        }

        $chunkText = $buffer.Substring($position, $take).TrimEnd()
        $chunks += $chunkText

        $position += $take
    }

    # Send each chunk with numbered debug header
    for ($i = 0; $i -lt $chunks.Count; $i++) {
        $partNumber = $i + 1
        $chunkHeader = "[Debug Part$partNumber] $ScriptTitle :`n---------`n"

        $chunkMessage = "$chunkHeader$($chunks[$i])"

        # Ultra-safety: truncate if something weird happened (very rare)
        if ($chunkMessage.Length -gt $MaxLength) {
            $chunkMessage = $chunkMessage.Substring(0, $MaxLength - 3) + "..."
        }

		try {
        	Send-LabNotification -Message $chunkMessage
        } catch {
			Write-Output $fullMessage
		}		
		Start-Sleep -Seconds 2
    }
}

# Debug function
function Send-DebugMessage {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Message
    )
    $Global:MessageBuffer += "`n`n$Message"
}

# Error function
function Throw-Error {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Message
    )
    Send-DebugMessage $Message
    if ($ScriptDebug) {
        #Send-LabNotification -Message "[Debug] $($ScriptTitle):`n---------`n$($Global:MessageBuffer)"
		Send-LabNotificationChunks -ScriptTitle $ScriptTitle -Message $Global:MessageBuffer
    }
    throw "[Debug] $($ScriptTitle):`n---------`n$($Global:MessageBuffer)"
}

if ($ScriptingAppId.Length -gt 10 -and $ScriptingAppSecret.Length -gt 10) {
	if ($ScriptDebug) { Send-DebugMessage "Received ScriptingAppId: $ScriptingAppId - and ScriptingAppSecret: $ScriptingAppSecret" }	
} else {
	if ($ScriptDebug) { Send-DebugMessage "ScriptingAppId and/or ScriptingAppSecret invalid." }
	Throw-Error "ScriptingAppId and/or ScriptingAppSecret invalid."
}

if (($Password -in '',$Null -or $Password -like '*@lab*') -or ($TenantName -in '',$Null -or $TenantName -like '*@lab*')) {
    if ($ScriptDebug) { Send-DebugMessage "Tenant Name or Password are blank. Cannot configure tenant." }
    Throw-Error "Tenant name or password are blank."
}

if ($LabInstanceId -in '',$Null -or $LabInstanceId -like '*@lab*') {
	$LabInstanceId = "NoID"
}
if ($ScriptDebug) { Send-DebugMessage "Lab Instance ID is: $LabInstanceId" }

$Password = $Password.trim(" ")
$TenantName = $TenantName.trim(" ")

if ($TenantName -eq $null -or $TenantName -eq "" -or $TenantName -like "@lab.Variable*") {
    if ($ScriptDebug) { Send-DebugMessage "Tenant name required for cleanup. Tenant is currently: $TenantName - Exiting cleanup process." }
    Throw-Error "Tenant name required for cleanup. Tenant is currently: $TenantName - Exiting cleanup process."
} 

# Install Az.Accounts version 2.13.2
try {
    $AzAccountsVersion = "2.13.2"
    if (-not (Get-InstalledModule Az.Accounts -RequiredVersion $AzAccountsVersion -EA SilentlyContinue) -and ($PSVersionTable.PSVersion -eq [Version]"7.3.4")) {
        If ($scriptDebug) { Send-DebugMessage "Installing Az.Accounts 2.13.2." }
        Install-Module Az.Accounts -RequiredVersion $AzAccountsVersion -Scope CurrentUser -Force -AllowClobber
        Remove-Module Az.Accounts -Force -EA SilentlyContinue
        Import-Module Az.Accounts -RequiredVersion $AzAccountsVersion -Force
        if ($ScriptDebug) { Send-DebugMessage "Successfully installed Az.Accounts version $AzAccountsVersion" }
    }
} catch {
    if ($ScriptDebug) { Send-DebugMessage "Failed to install/import Az.Accounts: $($_.Exception.Message)" }
}

try {
	if ($ScriptDebug) { Send-DebugMessage "Attempting Authentication to: $TenantName using AppId: $ScriptingAppId in the TenantPoolPostCleanup script." }
	# Authenticate using Connect-AzAccount
	If ($scriptDebug) { Send-DebugMessage "Authenticating with Connect-AzAccount" }    
	$SecureSecret = ConvertTo-SecureString $ScriptingAppSecret -AsPlainText -Force
	$Credential = New-Object System.Management.Automation.PSCredential($ScriptingAppId, $SecureSecret)
	Connect-AzAccount -ServicePrincipal -Credential $Credential -Tenant $TenantName | Out-Null
	# Authenticate using Connect-MgGraph
	If ($scriptDebug) { Send-DebugMessage "Authenticating with Connect-MgGraph" }
	$Body = @{
	  Grant_Type    = "client_credentials"
	  Scope         = "https://graph.microsoft.com/.default"
	  Client_Id     = $ScriptingAppId
	  Client_Secret = $ScriptingAppSecret
	}
	$AccessToken = (Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/token" -Body $Body -ContentType "application/x-www-form-urlencoded").access_token
	$SecureToken = ConvertTo-SecureString $AccessToken -AsPlainText -Force
	Connect-MgGraph -AccessToken $SecureToken -NoWelcome  
	$Context = Get-MgContext
	$AppName = $Context.AppName
	if ($ScriptDebug) { Send-DebugMessage "Successfully authenticated to: $TenantName using AppId: $ScriptingAppId" }
} catch {
   if ($ScriptDebug) { Send-DebugMessage "Failed to authenticate to: $TenantName using AppId: $ScriptingAppId due to error:`n $($_.Exception.Message)" }
   Throw-Error "Failed to authenticate to: $TenantName using AppId: $ScriptingAppId"
}

# Create fingerprint group
try {
	if ($ScriptDebug) { Send-DebugMessage "Creating Fingerprint Group" }
	$TimeStamp = (Get-Date).DateTime
	$FileTime = (get-date).ToFileTime()
	New-MgGroup -DisplayName "zChallenge Labs Cleanup - $LabInstanceId - $TimeStamp"  -MailNickname "zchallengelabscleanup$FileTime" -MailEnabled:$False -SecurityEnabled:$True | Out-Null
} catch {
	if ($ScriptDebug) { Send-DebugMessage "Failed to create Fingerprint Group" }
}

# Tenant validation to ensure script is running in the proper Tenant
$VerifiedDomain = (Get-MgOrganization).VerifiedDomains.Name
if ($VerifiedDomain -Like "*Hexelo*") {
	if ($ScriptDebug) { Send-DebugMessage "$VerifiedDomain contains 'Hexelo'. Continuing script." }
} else {
	if ($ScriptDebug) { Send-DebugMessage "$VerifiedDomain does not contain 'Hexelo'. Exiting script." }
	Throw-Error "$VerifiedDomain does not contain 'Hexelo'. Exiting script."
}

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
           $_.UserPrincipalName -notLike "*LodSupport*" -and
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
               <#   
               # Remove PIM role eligibility (not currently working and it doesn't appear to prevent deletions. Remove this block if all seems to be going well.)
               try {
                  $pimAssignments = Invoke-MgGraphRequest -Method GET -Uri "v1.0/roleManagement/directory/roleEligibilitySchedules?`$filter=principalId eq '$userId'" -ErrorAction Stop
               } catch {}
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
               #>
               # Attempt to delete the user
               Remove-MgUser -UserId $userId -Confirm:$false -ErrorAction Stop
           } catch {
               #if ($ScriptDebug) {Send-DebugMessage "Failed to process user '$userDisplayName': $_"}
           }
       }
       if ($failedUsers) {
           if ($ScriptDebug) {Send-DebugMessage "Users with role assignment issues (may have failed deletion): $($failedUsers.DisplayName -join ', ')"}
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

   # Get and remove all Intune-managed devices
   try {
       Get-MgDeviceManagementManagedDevice -All -ErrorAction Stop | ForEach-Object {Remove-MgDeviceManagementManagedDevice -ManagedDeviceId $_.Id -ErrorAction SilentlyContinue}
       if ($ScriptDebug) {Send-DebugMessage "Removed Intune-managed devices"}
   } catch {
       if ($ScriptDebug) {Send-DebugMessage "Failed to remove Intune-managed devices"}
   }

   # Remove all Autopilot Device Identities
   try {
       Get-MgDeviceManagementWindowsAutopilotDeviceIdentity | ForEach-Object {Remove-MgDeviceManagementWindowsAutopilotDeviceIdentity -WindowsAutopilotDeviceIdentityId $_.Id}
       if ($ScriptDebug) {Send-DebugMessage "Removed all Autopilot Device Identities"}
   } catch {
       if ($ScriptDebug) {Send-DebugMessage "Failed to remove Autopilot Device Identities"}
   } 

   # Remove all Autopilot Deployment Profiles
   try {
       $profiles = Invoke-MgGraphRequest -Method GET -Uri "beta/deviceManagement/windowsAutopilotDeploymentProfiles" -ErrorAction Stop
       if ($profiles.value -and $profiles.value.Count -gt 0) {
           foreach ($profile in $profiles.value) {
               $profileId = $profile.id
               $profileDisplayName = $profile.displayName
               try {
                   # Remove assignments for the Autopilot Deployment Profile
                   try {
                       $assignments = Invoke-MgGraphRequest -Method GET -Uri "beta/deviceManagement/windowsAutopilotDeploymentProfiles/$profileId/assignments" -ErrorAction Stop
                       foreach ($assignment in $assignments.value) {
                           $assignmentId = $assignment.id
                           try {
                               Invoke-MgGraphRequest -Method DELETE -Uri "beta/deviceManagement/windowsAutopilotDeploymentProfiles/$profileId/assignments/$assignmentId" -ErrorAction Stop
                               if ($ScriptDebug) {Send-DebugMessage "Removed assignment '$assignmentId' from Autopilot Deployment Profile '$profileDisplayName'"}
                           } catch {
                               if ($ScriptDebug) {Send-DebugMessage "Failed to remove assignment '$assignmentId' from Autopilot Deployment Profile '$profileDisplayName': $_"}
                           }
                       }
                   } catch {
                       if ($ScriptDebug) {Send-DebugMessage "Failed to retrieve or remove assignments for Autopilot Deployment Profile '$profileDisplayName': $_"}
                   }
   
                   # Check for associated devices (optional, for diagnostics)
                   try {
                       $devices = Invoke-MgGraphRequest -Method GET -Uri "beta/deviceManagement/windowsAutopilotDeploymentProfiles/$profileId/assignedDevices" -ErrorAction SilentlyContinue
                       if ($devices.value -and $devices.value.Count -gt 0) {
                           if ($ScriptDebug) {Send-DebugMessage "Warning: Autopilot Deployment Profile '$profileDisplayName' has $($devices.value.Count) associated devices, which may need manual removal"}
                       }
                   } catch {
                       if ($ScriptDebug) {Send-DebugMessage "Failed to check associated devices for Autopilot Deployment Profile '$profileDisplayName': $_"}
                   }
   
                   # Delete the Autopilot Deployment Profile
                   Invoke-MgGraphRequest -Method DELETE -Uri "beta/deviceManagement/windowsAutopilotDeploymentProfiles/$profileId" -ErrorAction Stop
                   if ($ScriptDebug) {Send-DebugMessage "Removed Autopilot Deployment Profile '$profileDisplayName'"}
               } catch {
                   if ($ScriptDebug) {Send-DebugMessage "Failed to remove Autopilot Deployment Profile '$profileDisplayName'"}
               }
           }
           if ($ScriptDebug) {Send-DebugMessage "Completed removal of $($profiles.value.Count) Autopilot Deployment Profiles"}
       } else {
           if ($ScriptDebug) {Send-DebugMessage "No Autopilot Deployment Profiles found in tenant; skipping deletion"}
       }
   } catch {
       if ($ScriptDebug) {Send-DebugMessage "Failed removing Autopilot Deployment Profiles."}
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

   # Remove all Intune Device Compliance and Configuration Policies
   try {
       $totalPolicies = 0
       foreach ($endpoint in @("deviceCompliancePolicies", "deviceConfigurations", "intents", "configurationPolicies")) {
           try {
               $policies = Invoke-MgGraphRequest -Method GET -Uri "beta/deviceManagement/$endpoint"
               if ($policies.value -and $policies.value.Count -gt 0) {
                   foreach ($policy in $policies.value) {
                       $policyId = $policy.id
                       try {
                           $assignments = Invoke-MgGraphRequest -Method GET -Uri "beta/deviceManagement/$endpoint/$policyId/assignments"
                           foreach ($assignment in $assignments.value) {
                               try { Invoke-MgGraphRequest -Method DELETE -Uri "beta/deviceManagement/$endpoint/$policyId/assignments/$($assignment.id)" } catch {}
                           }
                       } catch {}
                       try { Invoke-MgGraphRequest -Method DELETE -Uri "beta/deviceManagement/$endpoint/$policyId" } catch {}
                   }
                   $totalPolicies += $policies.value.Count
               }
           } catch {}
       }
       if ($ScriptDebug) {
           if ($totalPolicies -gt 0) { Send-DebugMessage "Processed $totalPolicies Device Policies" }
           else { Send-DebugMessage "No Device Policies found" }
       }
   } catch {
       if ($ScriptDebug) { Send-DebugMessage "Critical failure in Device Policy removal: $_" }
   }

   # Remove all Intune App Protection Policies and their assignments
   try {
       # Remove Managed App Policies
       $managedAppPolicies = Invoke-MgGraphRequest -Method GET -Uri "beta/deviceAppManagement/managedAppPolicies" -ErrorAction Stop
       if ($managedAppPolicies.value -and $managedAppPolicies.value.Count -gt 0) {
           foreach ($policy in $managedAppPolicies.value) {
               $policyId = $policy.id
               try {
                   # Remove assignments
                   $assignments = Invoke-MgGraphRequest -Method GET -Uri "beta/deviceAppManagement/managedAppPolicies/$policyId/assignments" -ErrorAction Stop
                   foreach ($assignment in $assignments.value) {
                       Invoke-MgGraphRequest -Method DELETE -Uri "beta/deviceAppManagement/managedAppPolicies/$policyId/assignments/$($assignment.id)" -ErrorAction Stop
                   }
                   # Delete the policy
                   Invoke-MgGraphRequest -Method DELETE -Uri "beta/deviceAppManagement/managedAppPolicies/$policyId" -ErrorAction Stop
               } catch {
                   # Silent catch for individual policy failures
               }
           }
           if ($ScriptDebug) {Send-DebugMessage "Removed $($managedAppPolicies.value.Count) Managed App Protection Policies"}
       } else {
           if ($ScriptDebug) {Send-DebugMessage "No Managed App Protection Policies found in tenant"}
       }

      # Remove all Intune Notification Message Templates
      try {
          $notifications = Invoke-MgGraphRequest -Method GET -Uri "beta/deviceManagement/notificationMessageTemplates"
          if ($notifications.value -and $notifications.value.Count -gt 0) {
              foreach ($notification in $notifications.value) {
                  $notificationId = $notification.id
                  try { Invoke-MgGraphRequest -Method DELETE -Uri "beta/deviceManagement/notificationMessageTemplates/$notificationId" } catch {}
              }
              if ($ScriptDebug) { Send-DebugMessage "Processed $($notifications.value.Count) Notification Message Templates" }
          } else {
              if ($ScriptDebug) { Send-DebugMessage "No Notification Message Templates found" }
          }
      } catch {
          if ($ScriptDebug) { Send-DebugMessage "Failure in Notification Message Template removal" }
      }       
   
       # Remove Mobile App Configurations
       $appConfigurations = Invoke-MgGraphRequest -Method GET -Uri "beta/deviceAppManagement/mobileAppConfigurations" -ErrorAction Stop
       if ($appConfigurations.value -and $appConfigurations.value.Count -gt 0) {
           foreach ($config in $appConfigurations.value) {
               $configId = $config.id
               try {
                   # Remove assignments
                   $assignments = Invoke-MgGraphRequest -Method GET -Uri "beta/deviceAppManagement/mobileAppConfigurations/$configId/assignments" -ErrorAction Stop
                   foreach ($assignment in $assignments.value) {
                       Invoke-MgGraphRequest -Method DELETE -Uri "beta/deviceAppManagement/mobileAppConfigurations/$configId/assignments/$($assignment.id)" -ErrorAction Stop
                   }
                   # Delete the configuration
                   Invoke-MgGraphRequest -Method DELETE -Uri "beta/deviceAppManagement/mobileAppConfigurations/$configId" -ErrorAction Stop
               } catch {
                   # Silent catch for individual config failures
               }
           }
           if ($ScriptDebug) {Send-DebugMessage "Removed $($appConfigurations.value.Count) Mobile App Configurations"}
       } else {
           if ($ScriptDebug) {Send-DebugMessage "No Mobile App Configurations found in tenant"}
       }
   } catch {
       if ($ScriptDebug) {Send-DebugMessage "Failure in Intune App Protection Policy removal"}
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
        Get-MgIdentityConditionalAccessPolicy -All | ForEach-Object {Remove-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $_.Id -Confirm:$false -ErrorAction SilentlyContinue}
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
            $globalAdmins = "LabAdmin","Office365Admin"
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
            $globalAdmins = "admin","LabAdmin","Office365Admin"
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

    if ($ScriptDebug) {Send-DebugMessage "Finished cleaning Tenant resources and settings."}

    Return $newAdminPassword

} catch {
    if ($ScriptDebug) {Send-DebugMessage "Cleanup failed."}
}

if ($ScriptDebug) {
	#Send-LabNotification -Message "[Debug] $($ScriptTitle):`n---------`n$($Global:MessageBuffer)"
	Send-LabNotificationChunks -ScriptTitle $ScriptTitle -Message $Global:MessageBuffer
}
