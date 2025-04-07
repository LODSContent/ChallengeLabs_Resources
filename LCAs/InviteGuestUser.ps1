<#
   Title: Invite Subscription User as Global Administrator in Entra ID Tenant
   Description: Invites an existing subscription user as a guest to the Entra ID tenant and assigns Global Administrator permissions, using pre-authenticated Azure session.
   Target: Cloud Subscription - PowerShell - 7.4.0 | Microsoft.Graph - 2.26.0
   Version: 2025.04.07 - Template.v4.0
   <Converted by Grok using New Script Format>
   <Uses MgGraph Commands>
#>

param (
    $SubscriptionTenant,
    $SubscriptionUser,
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
           # Silently fail to avoid disrupting the script; optionally log locally if desired
           Write-Warning "Failed to send debug message: $_"
       }
   }
   Write-Output $Message
}

# Parameters: Derived from lab environment
$LabInstance = "@lab.LabInstance.Id"
$globalAdminRoleId = "62e90394-69f5-4237-9190-012177145e10"  # Global Administrator role ID

# MgGraph Authentication block (Cloud Subscription Target)
$AccessToken = (Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com" -TenantId $TenantName).Token
$SecureToken = ConvertTo-Securestring $AccessToken -AsPlainText -Force
Connect-MgGraph -AccessToken $SecureToken -NoWelcome

if ($scriptDebug) {Write-Output "Connected to Microsoft Graph."}

# Check if the user is already in the tenant (as a member or guest)
$existingUser = Get-MgUser -UserId $subscriptionUser

if ($existingUser) {
    if ($scriptDebug) {Write-Output "User '$subscriptionUser' already exists in the tenant as a member or guest."}
    $userId = $existingUser.Id
} else {
    # Invite the subscription user as a guest
    $invitationParams = @{
        InvitedUserEmailAddress = $subscriptionUser
        InviteRedirectUrl = "https://portal.azure.com"  # Redirect after acceptance
        SendInvitationMessage = $true  # Sends an email invitation
    }
    $invitation = New-MgInvitation @invitationParams
    
    if ($scriptDebug -and $invitation) {Write-Output "Invitation sent to '$subscriptionUser'. Invited User ID: $($invitation.InvitedUser.Id)"}
    $userId = $invitation.InvitedUser.Id
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
    if ($scriptDebug) {Write-Output "Assigned Global Administrator role to '$subscriptionUser'."}
} else {
    if ($scriptDebug) {Write-Output "User '$subscriptionUser' already has Global Administrator role."}
}

# Validate the user exists and has the role
$queryReturn = Get-MgUser -UserId $subscriptionUser
$roleCheck = Get-MgDirectoryRoleMember -DirectoryRoleId $globalAdminRoleId | Where-Object { $_.Id -eq $queryReturn.Id }

if ($queryReturn -and $roleCheck) {
    $result = $true
    if ($scriptDebug) {Write-Output "Validation successful. User '$subscriptionUser' exists and has Global Administrator role."}
} else {
    $result = $false
    if ($scriptDebug) {Write-Output "Validation failed. User '$subscriptionUser' not found or lacks Global Administrator role."}
}

if ($scriptDebug) {Write-Output "End main routine."}

# Return the result from the main function
return $result
