# Tenant Pool Staging LCA

Copy and paste this over the existing Tenant Pool Staging LCA

```PowerShell
<#
   Title: Tenant Pool Staging
   Description: Pre-cleans the Tenant before student usage. Recreates App permissions. 
                Creates a new user with a Temporary Access Password and establishes credential variables for the lab.
   Targets: Cloud - PS 7.4.0, Microsoft.Graph 2.25.0
            Custom - PS 7.3.4, Microsoft.Graph 2.25.0, Az 11.1.0
            Future New Target With - PS 7.5.2, Microsoft.Graph 2.35.1 + Az 15.3.0 preinstalled
   Version: 2026.02.16
#>

$BaseURL = 'https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/LCAs'
$StagingScript = "TenantPoolStaging-v3.ps1"
$CleaningScript = "TenantPoolPostCleanup-v3.ps1"

# Define the parameters in a hash table
$params = @{
    TenantName = '@lab.CloudCredential(CredentialPool).TenantName'
    UserName = '@lab.CloudCredential(CredentialPool).UserName'
    Password = '@lab.CloudCredential(CredentialPool).Password'
    ScriptingAppId = '@lab.CloudCredential(CredentialPool).ScriptingAppId'
    ScriptingAppSecret = '@lab.CloudCredential(CredentialPool).ScriptingAppSecret'
    LabInstanceId = '@lab.LabInstance.Id'
    CleaningScriptUrl = ($BaseURL.TrimEnd('/') + '/' + $CleaningScript)
    ScriptDebug = ('@lab.Variable(debug)' -in 'Yes','True' -or '@lab.Variable(Debug)' -in 'Yes','True')
}

# URL of the script on GitHub
$scriptUrl = $BaseURL.TrimEnd('/') + '/' + $StagingScript

# Initialize variables for retry logic
$maxRetries = 10
$retryDelay = 5  # seconds
$attempt = 1
$scriptContent = $null

# Attempt to download the script content with retries
while ($attempt -le $maxRetries -and $null -eq $scriptContent) {
    try {
        $scriptContent = (Invoke-WebRequest -Uri $scriptUrl -UseBasicParsing -ErrorAction Stop).Content
    }
    catch {
        if ($attempt -eq $maxRetries) {
            Throw "Failed to download script: '$scriptUrl' from GitHub after $maxRetries attempts: $_"
        }
        Start-Sleep -Seconds $retryDelay
        $attempt++
    }
}

# Create a script block from the downloaded content
$scriptBlock = [ScriptBlock]::Create($scriptContent)

# Execute the script block with parameters
$result = & $scriptBlock @Params

return $result
```

# Tenant Pool Cleanup LCA

Copy and paste this over the existing Tenant Pool Cleanup LCA

```PowerShell
<#
   Title: Tenant Post-Cleanup
   Description: Cleans up student tenant at lab shutdoown.
   Targets: Cloud - PS 7.4.0, Microsoft.Graph 2.25.0
            Custom - PS 7.3.4, Microsoft.Graph 2.25.0, Az 11.1.0
            Future New Target With - PS 7.5.2, Microsoft.Graph 2.35.1 + Az 15.3.0 preinstalled
   Version: 2026.02.16
#>

$BaseURL = 'https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/LCAs'
$CleaningScript = "TenantPoolPostCleanup-v3.ps1"

# Define the parameters in a hash table
$params = @{
    TenantName = '@lab.CloudCredential(CredentialPool).TenantName'
    Password = '@lab.CloudCredential(CredentialPool).Password'
    ScriptingAppId = '@lab.CloudCredential(CredentialPool).ScriptingAppId'
    ScriptingAppSecret = '@lab.CloudCredential(CredentialPool).ScriptingAppSecret'
    LabInstanceId = '@lab.LabInstance.Id'
    ScriptDebug = ('@lab.Variable(debug)' -in 'Yes','True' -or '@lab.Variable(Debug)' -in 'Yes','True')
}

# URL of the script on GitHub
$scriptUrl = $BaseURL.TrimEnd('/') + '/' + $CleaningScript

# Initialize variables for retry logic
$maxRetries = 10
$retryDelay = 5  # seconds
$attempt = 1
$scriptContent = $null

# Attempt to download the script content with retries
while ($attempt -le $maxRetries -and $null -eq $scriptContent) {
    try {
        $scriptContent = (Invoke-WebRequest -Uri $scriptUrl -UseBasicParsing -ErrorAction Stop).Content
    }
    catch {
        if ($attempt -eq $maxRetries) {
            Throw "Failed to download script: '$scriptUrl' from GitHub after $maxRetries attempts: $_"
        }
        Start-Sleep -Seconds $retryDelay
        $attempt++
    }
}

# Create a script block from the downloaded content
$scriptBlock = [ScriptBlock]::Create($scriptContent)

# Execute the script block with parameters
$result = & $scriptBlock @Params

return $result
```

# Tenant Pool Staging for "Configure Tenant" Activity (Prereq based labs)

```PowerShell
<#
   Title: Tenant Pool Staging for "Configure Tenant" Activity
   Description: Pre-cleans the Tenant before student usage. Recreates App permissions. 
                Creates a new user with a Temporary Access Password and establishes credential variables for the lab.
   Targets: Cloud - PS 7.4.0, Microsoft.Graph 2.25.0
            Custom - PS 7.3.4, Microsoft.Graph 2.25.0, Az 11.1.0
            Future New Target With - PS 7.5.2, Microsoft.Graph 2.35.1 + Az 15.3.0 preinstalled
   Version: 2026.02.16
#>

$BaseURL = 'https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/LCAs'
$StagingScript = "TenantPoolStaging-v3.ps1"
$CleaningScript = "TenantPoolPostCleanup-v3.ps1"

# Define the parameters in a hash table
$params = @{
    TenantName = '@lab.Variable(TenantName)'
    UserName = 'admin@@lab.Variable(TenantName)'
    Password = '@lab.Variable(TenantPassword)'
    ScriptingAppId = '@lab.Variable(ScriptingAppId)'
    ScriptingAppSecret = '@lab.Variable(ScriptingAppSecret)'
    LabInstanceId = '@lab.LabInstance.Id'
    CleaningScriptUrl = ($BaseURL.TrimEnd('/') + '/' + $CleaningScript)
    ScriptDebug = ('@lab.Variable(debug)' -in 'Yes','True' -or '@lab.Variable(Debug)' -in 'Yes','True')
}

# URL of the script on GitHub
$scriptUrl = $BaseURL.TrimEnd('/') + '/' + $StagingScript

# Initialize variables for retry logic
$maxRetries = 10
$retryDelay = 5  # seconds
$attempt = 1
$scriptContent = $null

# Attempt to download the script content with retries
while ($attempt -le $maxRetries -and $null -eq $scriptContent) {
    try {
        $scriptContent = (Invoke-WebRequest -Uri $scriptUrl -UseBasicParsing -ErrorAction Stop).Content
    }
    catch {
        if ($attempt -eq $maxRetries) {
            Throw "Failed to download script: '$scriptUrl' from GitHub after $maxRetries attempts: $_"
        }
        Start-Sleep -Seconds $retryDelay
        $attempt++
    }
}

# Create a script block from the downloaded content
$scriptBlock = [ScriptBlock]::Create($scriptContent)

# Execute the script block with parameters
$result = & $scriptBlock @Params

return $result
```

# Tenant Pool Staging for "Configure Tenant" Activity (SC200.2 labs)

```PowerShell
<#
   Title: Tenant Pool Staging for "Configure Tenant" Activity
   Description: Pre-cleans the Tenant before student usage. Recreates App permissions. 
                Creates a new user with a Temporary Access Password and establishes credential variables for the lab.
   Targets: Cloud - PS 7.4.0, Microsoft.Graph 2.25.0
            Custom - PS 7.3.4, Microsoft.Graph 2.25.0, Az 11.1.0
            Future New Target With - PS 7.5.2, Microsoft.Graph 2.35.1 + Az 15.3.0 preinstalled
   Version: 2026.02.16
#>

$BaseURL = 'https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/LCAs'
$StagingScript = "TenantPoolStaging-v3.ps1"
$CleaningScript = "TenantPoolPostCleanup-v3.ps1"

# Define the parameters in a hash table
$params = @{
    TenantName = '@lab.Variable(TenantName)'
    UserName = 'admin@@lab.Variable(TenantName)'
    Password = '@lab.Variable(TenantPassword)'
    ScriptingAppId = '@lab.Variable(ScriptingAppId)'
    ScriptingAppSecret = '@lab.Variable(ScriptingAppSecret)'
	SubscriptionId = '@lab.Variable(SubscriptionId)'
    LabInstanceId = '@lab.LabInstance.Id'
    CleaningScriptUrl = ($BaseURL.TrimEnd('/') + '/' + $CleaningScript)
    ScriptDebug = ('@lab.Variable(debug)' -in 'Yes','True' -or '@lab.Variable(Debug)' -in 'Yes','True')
}

# URL of the script on GitHub
$scriptUrl = $BaseURL.TrimEnd('/') + '/' + $StagingScript

# Initialize variables for retry logic
$maxRetries = 10
$retryDelay = 5  # seconds
$attempt = 1
$scriptContent = $null

# Attempt to download the script content with retries
while ($attempt -le $maxRetries -and $null -eq $scriptContent) {
    try {
        $scriptContent = (Invoke-WebRequest -Uri $scriptUrl -UseBasicParsing -ErrorAction Stop).Content
    }
    catch {
        if ($attempt -eq $maxRetries) {
            Throw "Failed to download script: '$scriptUrl' from GitHub after $maxRetries attempts: $_"
        }
        Start-Sleep -Seconds $retryDelay
        $attempt++
    }
}

# Create a script block from the downloaded content
$scriptBlock = [ScriptBlock]::Create($scriptContent)

# Execute the script block with parameters
$result = & $scriptBlock @Params

return $result
```

# Resource Group Cleanup for SC200.2 Labs

```PowerShell
### Authentication Block - AZ - Begin
# Targets: Cloud - PS 7.4.0
#          Custom - PS 7.3.4, Az 11.1.0
#          Future New Target With - PS 7.5.2, Az 15.3.0 preinstalled
# Version: 2026.02.16
###
# Tenant App Credentials
$ScriptingAppId     = "@lab.Variable(ScriptingAppId)"
$ScriptingAppSecret = "@lab.Variable(ScriptingAppSecret)"
$SubscriptionId = "@lab.Variable(SubscriptionId)"
$TenantName         = "@lab.Variable(TenantName)"
# Install Az.Accounts v2.13.2 if using PS 7.3.4
$AzAccountsVersion = "2.13.2"
if (-not (Get-InstalledModule Az.Accounts -RequiredVersion $AzAccountsVersion -EA SilentlyContinue) -and ($PSVersionTable.PSVersion -eq [Version]"7.3.4")) {
    If ($scriptDebug) { Write-Output "Installing Az.Accounts 2.13.2." }
    Install-Module Az.Accounts -RequiredVersion $AzAccountsVersion -Scope CurrentUser -Force -AllowClobber
    Remove-Module Az.Accounts -Force -EA SilentlyContinue
    Import-Module Az.Accounts -RequiredVersion $AzAccountsVersion -Force
}    
# Authenticate using Connect-AzAccount
If ($scriptDebug) { Write-Output "Authenticating with Connect-AzAccount" }    
$SecureSecret = ConvertTo-SecureString $ScriptingAppSecret -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential($ScriptingAppId, $SecureSecret)
Connect-AzAccount -ServicePrincipal -Credential $Credential -Tenant $TenantName | Out-Null
# Get the token
$secureToken = (Get-AzAccessToken -ResourceUrl "https://management.azure.com/").Token
$AzToken = [System.Net.NetworkCredential]::new("", $secureToken).Password
# Build the header for Invoke-RestMethod commands
$headers = @{
    "Authorization" = "Bearer $AzToken"
    "Content-Type"  = "application/json"
}
### Authentication Block - End

$rgListUri = "https://management.azure.com/subscriptions/$SubscriptionId/resourcegroups?api-version=2021-04-01"

$rgs = (Invoke-RestMethod -Uri $rgListUri -Headers $headers -Method Get).value

# Remove all Resource Groups
if ($rgs.Count -gt 0) {
    foreach ($rg in $rgs) {
        $rgName = $rg.name
        $deleteRgUri = "https://management.azure.com/subscriptions/$SubscriptionId/resourcegroups/$($rgName)?api-version=2021-04-01"        
        try {
            Invoke-RestMethod -Uri $deleteRgUri -Headers $headers -Method Delete | Out-Null
            if ($scriptDebug) { Write-Output "Removed Resource Group: $rgName" }
        } catch {
            if ($scriptDebug) { Write-Output "Failed to remove Resource Group: $rgName" }
        }
    }
}

# Finished cleanup
return $true
```

# Authentication block for Az and MgGraph scripts

```PowerShell
    ### Authentication Block - AZ + MgGraph - Begin
    # Targets: Cloud - PS 7.4.0, Microsoft.Graph 2.25.0
    #          Custom - PS 7.3.4, Microsoft.Graph 2.25.0, Az 11.1.0
    #          Future New Target With - PS 7.5.2, Microsoft.Graph 2.35.1 + Az 15.3.0 preinstalled
    # Version: 2026.02.16
    ###
    # Tenant App Credentials
    $ScriptingAppId     = "@lab.Variable(ScriptingAppId)"
    $ScriptingAppSecret = "@lab.Variable(ScriptingAppSecret)"
    $TenantName         = "@lab.Variable(TenantName)"
    # Install Az.Accounts v2.13.2 if using PS 7.3.4
    $AzAccountsVersion = "2.13.2"
    if (-not (Get-InstalledModule Az.Accounts -RequiredVersion $AzAccountsVersion -EA SilentlyContinue) -and ($PSVersionTable.PSVersion -eq [Version]"7.3.4")) {
        If ($scriptDebug) { Write-Output "Installing Az.Accounts 2.13.2." }
        Install-Module Az.Accounts -RequiredVersion $AzAccountsVersion -Scope CurrentUser -Force -AllowClobber
        Remove-Module Az.Accounts -Force -EA SilentlyContinue
        Import-Module Az.Accounts -RequiredVersion $AzAccountsVersion -Force
    }    
    # Authenticate using Connect-AzAccount
    If ($scriptDebug) { Write-Output "Authenticating with Connect-AzAccount" }    
    $SecureSecret = ConvertTo-SecureString $ScriptingAppSecret -AsPlainText -Force
    $Credential = New-Object System.Management.Automation.PSCredential($ScriptingAppId, $SecureSecret)
    Connect-AzAccount -ServicePrincipal -Credential $Credential -Tenant $TenantName | Out-Null
    # Authenticate using Connect-MgGraph
    If ($scriptDebug) { Write-Output "Authenticating with Connect-MgGraph" }
    $Body = @{
        Grant_Type    = "client_credentials"
        Scope         = "https://graph.microsoft.com/.default"
        Client_Id     = $ScriptingAppId
        Client_Secret = $ScriptingAppSecret
    }
	$AccessToken = (Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/token" -Body $Body -ContentType "application/x-www-form-urlencoded").access_token
	$SecureToken = ConvertTo-SecureString $AccessToken -AsPlainText -Force
    Connect-MgGraph -AccessToken $SecureToken -NoWelcome
    ### Authentication Block - End
```

# Authentication block for Az only scripts

```PowerShell
    ### Authentication Block - AZ - Begin
    # Targets: Cloud - PS 7.4.0
    #          Custom - PS 7.3.4, Az 11.1.0
    #          Future New Target With - PS 7.5.2, Microsoft.Graph 2.35.1 + Az 15.3.0 preinstalled
    # Version: 2026.02.16
    ###
    # Tenant App Credentials
    $ScriptingAppId     = "@lab.Variable(ScriptingAppId)"
    $ScriptingAppSecret = "@lab.Variable(ScriptingAppSecret)"
    $TenantName         = "@lab.Variable(TenantName)"
    # Install Az.Accounts v2.13.2 if using PS 7.3.4
    $AzAccountsVersion = "2.13.2"
    if (-not (Get-InstalledModule Az.Accounts -RequiredVersion $AzAccountsVersion -EA SilentlyContinue) -and ($PSVersionTable.PSVersion -eq [Version]"7.3.4")) {
        If ($scriptDebug) { Write-Output "Installing Az.Accounts 2.13.2." }
        Install-Module Az.Accounts -RequiredVersion $AzAccountsVersion -Scope CurrentUser -Force -AllowClobber
        Remove-Module Az.Accounts -Force -EA SilentlyContinue
        Import-Module Az.Accounts -RequiredVersion $AzAccountsVersion -Force
    }    
    # Authenticate using Connect-AzAccount
    If ($scriptDebug) { Write-Output "Authenticating with Connect-AzAccount" }    
    $SecureSecret = ConvertTo-SecureString $ScriptingAppSecret -AsPlainText -Force
    $Credential = New-Object System.Management.Automation.PSCredential($ScriptingAppId, $SecureSecret)
    Connect-AzAccount -ServicePrincipal -Credential $Credential -Tenant $TenantName | Out-Null
    ### Authentication Block - End
```

# Authentication block for MgGraph only scripts

```PowerShell
    ### Authentication Block - MgGraph - Begin
    # Targets: Cloud - PS 7.4.0, Microsoft.Graph 2.25.0
    #          Custom - PS 7.3.4, Microsoft.Graph 2.25.0
    #          Future New Target With - PS 7.5.2, Microsoft.Graph 2.35.1 + Az 15.3.0 preinstalled
    # Version: 2026.02.16
    ###
    # Tenant App Credentials
    $ScriptingAppId     = "@lab.Variable(ScriptingAppId)"
    $ScriptingAppSecret = "@lab.Variable(ScriptingAppSecret)"
    $TenantName         = "@lab.Variable(TenantName)"
    # Authenticate using Connect-MgGraph
    If ($scriptDebug) { Write-Output "Authenticating with Connect-MgGraph" }
    $Body = @{
        Grant_Type    = "client_credentials"
        Scope         = "https://graph.microsoft.com/.default"
        Client_Id     = $ScriptingAppId
        Client_Secret = $ScriptingAppSecret
    }
	$AccessToken = (Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/token" -Body $Body -ContentType "application/x-www-form-urlencoded").access_token
	$SecureToken = ConvertTo-SecureString $AccessToken -AsPlainText -Force
    Connect-MgGraph -AccessToken $SecureToken -NoWelcome
    ### Authentication Block - End
```

# Additional Authentication for SC200.2 labs

### For Az commands running through Invoke-RestMethod (After Connect-AzAccount section.)
```PowerShell
    # Get the token
    $secureToken = (Get-AzAccessToken -ResourceUrl "https://management.azure.com/").Token
    $AzToken = [System.Net.NetworkCredential]::new("", $secureToken).Password
    # Build the header for Invoke-RestMethod commands
    $headers = @{
        "Authorization" = "Bearer $AzToken"
        "Content-Type"  = "application/json"
    }
```

### For Exchange Online commands running through Invoke-RestMethod (After Connect-AzAccount section.)
```PowerShell
    # Get the token
	$secureToken = (Get-AzAccessToken -ResourceUrl "https://outlook.office365.com").Token
	$exoToken   = [System.Net.NetworkCredential]::new("", $secureToken).Password
    # Build the header for Invoke-RestMethod commands
	$headers = @{
	    "Authorization" = "Bearer $exoToken"
	    "Content-Type"  = "application/json"
	}
```

# Authentication block for PBI scripts

```PowerShell
    ### Authentication Block - PBI - Begin
    # Targets: Cloud - PS 7.4.0, MicrosoftPowerBIMgmt 1.3.67
    #          Custom - PS 7.3.4, MicrosoftPowerBIMgmt 1.3.67
    #          Future New Target With - PS 7.5.2, Microsoft.Graph 2.35.1 + Az 15.3.0 preinstalled
    # Version: 2026.02.16
    ###
    # Tenant App Credentials
    $ScriptingAppId     = "@lab.Variable(ScriptingAppId)"
    $ScriptingAppSecret = "@lab.Variable(ScriptingAppSecret)"
    $TenantName         = "@lab.Variable(TenantName)"
    # Authenticate using Connect-PowerBIServiceAccount
	If ($scriptDebug) { Write-Output "Authenticating with Connect-PowerBIServiceAccount" }
	$secureSecret = ConvertTo-SecureString $ScriptingAppSecret -AsPlainText -Force
	$credential   = New-Object System.Management.Automation.PSCredential($ScriptingAppId, $secureSecret)
	$Connect1 = Connect-PowerBIServiceAccount -ServicePrincipal -Credential $credential -Tenant $TenantName  -ErrorAction Ignore
    ### Authentication Block - PBI - End 
```

### For PBI scripts, remove the -Scope Organization parameter from commands.

# CLabs Scripting App Permissions for PBI Workspace

```markdown
- Provide +++CLabs Scripting App+++ with Admin rights to the new Workspace.

>[+HELP] Expand this help section for guidance on granting access to the Workspace.
>
>- On the Power BI menu, select **Workspaces**.
>- Select the **Data Model Project 2-@lab.LabInstance.Id** workspace.
>- In the upper-right, select **Manage access**.
>- Select **Add people or groups**.
>- Enter +++CLabs Scripting App+++ and then choose CLabs Scripting App.
>- Select the drop-down list for **Viewer** and then select **Admin**.
>- Select **Add**.
>
> ***Note**: The permission provided to this app is used during the validation process.*
```

# Tenant Logon Sections

Use the following for labs without a VM. (Copy-Text)
(Replace the landing page with the appropriate URL for that point in the lab.)

```PowerShell
:::Staging(StagingComplete=No)
- Sign in to ++https://portal.azure.com++ using the following credentials:

    > **Please wait while your Tenant is being prepared.**
    >
    > *This may take a few minutes...* 
:::

:::Staging(StagingComplete=Yes)
- Sign in to ++https://portal.azure.com++ using the following credentials:

    >    Username: ++@lab.Variable(UserName)++ 
    > 
    >    Temporary Access Pass: ++@lab.Variable(Password)++
:::
```

Use the following for labs WITH a VM. (Type-Text) 
(Replace the landing page with the appropriate URL for that point in the lab.)

```PowerShell
:::Staging(StagingComplete=No)
- Sign in to +++https://portal.azure.com+++ using the following credentials:

    > **Please wait while your Tenant is being prepared.**
    >
    > *This may take a few minutes...* 
:::

:::Staging(StagingComplete=Yes)
- Sign in to +++https://portal.azure.com+++ using the following credentials:

    >    Username: +++@lab.Variable(UserName)+++ 
    > 
    >    Temporary Access Pass: +++@lab.Variable(Password)+++
:::
```

# Updated 'Provide your saved credentials' block

Use the following block at the beginning of student prereq based labs.

```PowerShell
#### Provide your saved credentials

- In the following text boxes, enter the details that you saved for your M365 Tenant:

    **Tenant name**     
    @lab.TextBox(TenantName)

    **Password**       
    @lab.TextBox(TenantPassword)

    **Scripting App ID**       
    @lab.TextBox(ScriptingAppId)

    **Scripting App Secret**       
    @lab.TextBox(ScriptingAppSecret)

>[!Note] Your tenant name is the portion of your Global Administrator account that is after the *@* symbol.
```
