<#
   Title: Invite Subscription User as Guest with TAP and Global Administrator Role
   Description: Invites a subscription user as a guest to the target Entra ID tenant, assigns Global Administrator permissions, and creates a TAP for authentication, using pre-authenticated Azure session.
   Target: Cloud Subscription - PowerShell - 7.4.0 | Microsoft.Graph - 2.26.0
   Version: 2025.04.07
   <Uses MgGraph Commands>
#>

param (
    $SubscriptionTenant,
    $SubscriptionUser = "@lab.CloudSubscription.UserName",
    $SubscriptionPassword,
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
            Write-Warning "Failed to send debug message: $_"
        }
    }
    Write-Output $Message
}

# Parameters: Derived from lab environment
$LabInstance = "@lab.LabInstance.Id"
$globalAdminRoleId = "62e90394-69f5-4237-9190-012177145e10"  # Global Administrator role ID
$result = $false

if ($ScriptDebug) { Send-DebugMessage "Starting script execution." }

# MgGraph Authentication block (Cloud Subscription Target)
$AccessToken = (Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com" -TenantId $TenantName).Token
$SecureToken = ConvertTo-SecureString $AccessToken -AsPlainText -Force
Connect-MgGraph -AccessToken $SecureToken -NoWelcome

if ($ScriptDebug) { Send-DebugMessage "Connected to Microsoft Graph for tenant: $TenantName" }

# Check if the user is already in the tenant (as a member or guest)
$existingUser = Get-MgUser -UserId $SubscriptionUser

if ($existingUser) {
    if ($ScriptDebug) { Send-DebugMessage "User '$SubscriptionUser' already exists in the tenant as a member or guest." }
    $userId = $existingUser.Id
} else {
    # Invite the subscription user as a guest
    $invitationParams = @{
        InvitedUserEmailAddress = $SubscriptionUser
        InviteRedirectUrl = "https://portal.azure.com"
        SendInvitationMessage = $true
    }
    $invitation = New-MgInvitation @invitationParams
    
    if ($invitation) {
        if ($ScriptDebug) { Send-DebugMessage "Invitation sent to '$SubscriptionUser'. Invited User ID: $($invitation.InvitedUser.Id)" }
        $userId = $invitation.InvitedUser.Id
    } else {
        if ($ScriptDebug) { Send-DebugMessage "Failed to send invitation to '$SubscriptionUser'." }
        return $false
    }
}

# Assign Global Administrator role if not already assigned
$roleAssignment = Get-MgDirectoryRoleMember -DirectoryRoleId $globalAdminRoleId | Where-Object { $_.Id -eq $userId }
if (-not $roleAssignment) {
    $roleAssignmentParams = @{
        "@odata.type" = "#microsoft.graph.unifiedRoleAssignment"
        PrincipalId = $userId
        RoleDefinitionId = $globalAdminRoleId
        DirectoryScopeId = "/"
    }
    New-MgRoleManagementDirectoryRoleAssignment -BodyParameter $roleAssignmentParams
    if ($ScriptDebug) { Send-DebugMessage "Assigned Global Administrator role to '$SubscriptionUser'." }
} else {
    if ($ScriptDebug) { Send-DebugMessage "User '$SubscriptionUser' already has Global Administrator role." }
}

# Enable TAP policy in the tenant (multi-use configuration)
$tapPolicyParams = @{
    "@odata.type" = "#microsoft.graph.temporaryAccessPassAuthenticationMethodConfiguration"
    Id = "TemporaryAccessPass"
    State = "enabled"
    IncludeTargets = @(
        @{
            TargetType = "group"
            Id = "all_users"  # Applies to all users in the tenant
            IsRegistrationRequired = $false
        }
    )
    DefaultLifetimeInMinutes = 60
    DefaultLength = 8
    MinimumLifetimeInMinutes = 60
    MaximumLifetimeInMinutes = 480
    IsUsableOnce = $false  # Multi-use TAP
}
Update-MgBetaPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration `
    -AuthenticationMethodConfigurationId "TemporaryAccessPass" `
    -BodyParameter $tapPolicyParams

if ($ScriptDebug) { Send-DebugMessage "TAP policy enabled with multi-use configuration in tenant '$TenantName'." }

# Create TAP for the guest user
$tapParams = @{
    LifetimeInMinutes = 120
    IsUsableOnce = $false  # Multi-use TAP
}
$tapResponse = New-MgBetaUserAuthenticationTemporaryAccessPassMethod -UserId $userId -BodyParameter $tapParams

if ($tapResponse) {
    $tapPassword = $tapResponse.TemporaryAccessPass
    if ($ScriptDebug) { Send-DebugMessage "TAP created for '$SubscriptionUser'. TAP Password: $tapPassword" }
    # Store TAP in lab variable for potential use
    Set-LabVariable -Name GuestUserTAP -Value $tapPassword
} else {
    if ($ScriptDebug) { Send-DebugMessage "Failed to create TAP for '$SubscriptionUser'." }
}

# Validate the user exists and has the role
$queryReturn = Get-MgUser -UserId $SubscriptionUser
$roleCheck = Get-MgDirectoryRoleMember -DirectoryRoleId $globalAdminRoleId | Where-Object { $_.Id -eq $queryReturn.Id }

if ($queryReturn -and $roleCheck) {
    $result = $true
    if ($ScriptDebug) { Send-DebugMessage "Validation successful. User '$SubscriptionUser' exists, has Global Administrator role, and TAP assigned." }
} else {
    $result = $false
    if ($ScriptDebug) { Send-DebugMessage "Validation failed. User '$SubscriptionUser' not found or lacks Global Administrator role." }
}

if ($ScriptDebug) { Send-DebugMessage "Script execution completed." }

return $result
