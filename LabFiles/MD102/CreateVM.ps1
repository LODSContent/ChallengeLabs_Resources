<#
   Title: MD-102 Target VM Provisioning (REST API)
   Description: Creates the Azure resources required for the MD-102 Windows 11 target virtual machine.
                Uses direct Azure REST API calls via Invoke-RestMethod - no Az module required.
                Idempotent - reuses existing resources, starts a stopped VM, and resets the lab admin account.
   Target: Azure
   Version: 2026.06.22.0005 - Template.v4.0
#>

# Parameters
$TenantName             = '@lab.Variable(TenantName)'
$ScriptingAppId         = '@lab.Variable(ScriptingAppId)'
$ScriptingAppSecret     = '@lab.Variable(ScriptingAppSecret)'
$SubscriptionId         = '@lab.Variable(SubscriptionId)'
$LabInstanceId          = '@lab.LabInstance.Id'

$ResourceGroupName      = 'RG1'
$Location               = 'eastus'
$FailoverQuery          = $true   # When $true, fails over to $FallbackLocations if no capacity in $Location.
                                  # When $false, only $Location is attempted and network resource names
                                  # have no location suffix (e.g. 'VM1-nsg' instead of 'VM1-nsg-eastus').
$FallbackLocations      = @('eastus2', 'westus', 'westus2', 'westus3', 'centralus', 'northcentralus', 'southcentralus')
$VmName                 = 'VM1'

$BootstrapAdminUserName = 'AzureAdmin'
$BootstrapAdminPassword = 'AdminPassw0rd!'

$DesiredLabAdminUserName = 'LabAdmin'
$DesiredLabAdminPassword = 'AdminPassw0rd!'

$CreatePublicIp         = $true
$OpenRdp                = $true

# Per-VM resource names derived after region selection (see main).
# VNet and Subnet names are derived from address prefixes and are shared across VMs
# in the same address space. NSG, PIP, and NIC remain per-VM.
$OsDiskName             = "$VmName-osdisk"

$VnetAddressPrefix      = '10.102.0.0/16'
$SubnetAddressPrefix    = '10.102.1.0/24'

# Set defaults
$result = $false
$ErrorActionPreference = "Stop"
$wrapperLineCount = 104

# Debug toggle
$scriptDebug = '@lab.Variable(debug)' -in 'Yes','True' -or '@lab.Variable(Debug)' -in 'Yes','True'
$debugLog    = [System.Collections.Generic.List[string]]::new()
if ($scriptDebug) { Write-Output "Debug mode is enabled." }

# ── REST API helpers ────────────────────────────────────────────────────────────

function Get-AzBearerToken {
    param(
        [Parameter(Mandatory)][string] $TenantName,
        [Parameter(Mandatory)][string] $ClientId,
        [Parameter(Mandatory)][string] $ClientSecret
    )
    $tokenUrl = "https://login.microsoftonline.com/$TenantName/oauth2/token"
    $body = @{
        grant_type    = 'client_credentials'
        client_id     = $ClientId
        client_secret = $ClientSecret
        resource      = 'https://management.azure.com/'
    }
    $response = Invoke-RestMethod -Method Post -Uri $tokenUrl -Body $body -ContentType 'application/x-www-form-urlencoded' -ErrorAction Stop
    return $response.access_token
}

function Get-AuthHeader {
    param([Parameter(Mandatory)][string] $Token)
    return @{ Authorization = "Bearer $Token" }
}

function Invoke-ArmGet {
    param(
        [Parameter(Mandatory)][string]    $Uri,
        [Parameter(Mandatory)][hashtable] $Headers
    )
    try {
        return Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers -ErrorAction Stop
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq 404) { return $null }
        throw
    }
}

function Invoke-ArmRequestRaw {
    param(
        [Parameter(Mandatory)][string]    $Method,
        [Parameter(Mandatory)][string]    $Uri,
        [Parameter(Mandatory)][hashtable] $Headers,
        [object]                          $Body        = $null,
        [int]                             $TimeoutSecs = 1800
    )

    $params = @{
        Method      = $Method
        Uri         = $Uri
        Headers     = $Headers
        ContentType = 'application/json'
        ErrorAction = 'Stop'
    }
    if ($null -ne $Body) {
        $params['Body'] = ($Body | ConvertTo-Json -Depth 20 -Compress)
    }

    try {
        $response = Invoke-WebRequest @params
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $armError = $null
        $armCode  = $null
        try {
            $parsed   = $_.ErrorDetails.Message | ConvertFrom-Json
            $armError = $parsed.error.message
            $armCode  = $parsed.error.code
        } catch {}

        Write-Debug "  HTTP $statusCode on $Method $Uri"
        Write-Debug "  ARM error code   : $armCode"
        Write-Debug "  ARM error message: $armError"

        if ($statusCode -eq 409) {
            $existing = Invoke-ArmGet -Uri $Uri -Headers $Headers
            if ($existing) {
                Write-Debug "  409 resolved - returning existing resource."
                return $existing
            }
            throw "ARM 409 Conflict on $Method $Uri (dependency conflict). ARM: [$armCode] $armError"
        }

        if ($armError) {
            throw "ARM $statusCode on $Method $Uri. ARM: [$armCode] $armError"
        }
        throw
    }

    if ($response.StatusCode -notin 201, 202) {
        if ($response.Content) { return ($response.Content | ConvertFrom-Json) }
        return $null
    }

    $pollUrl = $response.Headers['Azure-AsyncOperation']
    if (-not $pollUrl) { $pollUrl = $response.Headers['Location'] }
    if (-not $pollUrl) {
        if ($response.Content) { return ($response.Content | ConvertFrom-Json) }
        return $null
    }
    if ($pollUrl -is [array]) { $pollUrl = $pollUrl[0] }

    $deadline = (Get-Date).AddSeconds($TimeoutSecs)
    $status   = $null

    do {
        Start-Sleep -Seconds 15
        $poll   = Invoke-RestMethod -Method Get -Uri $pollUrl -Headers $Headers -ErrorAction Stop
        $status = if ($poll.PSObject.Properties['status'])               { $poll.status }
                  elseif ($poll.PSObject.Properties['provisioningState']) { $poll.provisioningState }
                  else                                                    { $null }
        Write-Debug "  Async poll status: $status"
        if ($status -in 'Succeeded', 'Canceled', 'Failed') { break }
    } until ((Get-Date) -gt $deadline)

    if ($status -eq 'Failed') {
        $errMsg = $poll.error.message
        throw "Async ARM operation failed: $errMsg"
    }
    if ($status -ne 'Succeeded') {
        throw "Async ARM operation timed out or returned unexpected status: $status"
    }

    $locationHeader = $response.Headers['Location']
    if ($locationHeader) {
        if ($locationHeader -is [array]) { $locationHeader = $locationHeader[0] }
        $final = Invoke-RestMethod -Method Get -Uri $locationHeader -Headers $Headers -ErrorAction Stop
        return $final
    }

    return $poll
}

# ── Step helpers ────────────────────────────────────────────────────────────────

function Write-Step {
    param([Parameter(Mandatory)][string] $Message)
    $line = "[$(Get-Date -Format 'HH:mm:ss')] $Message"
    $script:debugLog.Add($line)
    Write-Output $line
}

function Write-Debug {
    param([Parameter(Mandatory)][string] $Message)
    $script:debugLog.Add($Message)
    if ($script:scriptDebug) { Write-Output $Message }
}

function Assert-ResolvedLabValue {
    param(
        [Parameter(Mandatory)][string] $Name,
        [Parameter(Mandatory)][string] $Value
    )
    if ([string]::IsNullOrWhiteSpace($Value) -or $Value -like '*@lab.*') {
        throw "The lab variable '$Name' was not resolved. Verify that it exists in the lab environment."
    }
}

# Converts an IP address prefix (e.g. '10.102.0.0/16') to a safe Azure resource name
# segment by replacing '.' and '/' with '_' (e.g. '10_102_0_0_16').
function Convert-PrefixToName {
    param([Parameter(Mandatory)][string] $Prefix)
    return $Prefix -replace '\.', '_' -replace '/', '_'
}

# ── Resource helpers ────────────────────────────────────────────────────────────

$ArmBase = 'https://management.azure.com'

function Ensure-ResourceProvider {
    param(
        [Parameter(Mandatory)][string]    $ProviderNamespace,
        [Parameter(Mandatory)][string]    $SubscriptionId,
        [Parameter(Mandatory)][hashtable] $Headers
    )
    Write-Step "Checking resource provider: $ProviderNamespace."
    $uri      = "$ArmBase/subscriptions/$SubscriptionId/providers/$ProviderNamespace`?api-version=2021-04-01"
    $provider = Invoke-RestMethod -Method Get -Uri $uri -Headers $Headers -ErrorAction Stop
    $state    = $provider.registrationState
    if ($state -eq 'Registered') { return }

    Write-Step "Registering resource provider: $ProviderNamespace."
    $regUri = "$ArmBase/subscriptions/$SubscriptionId/providers/$ProviderNamespace/register?api-version=2021-04-01"
    Invoke-RestMethod -Method Post -Uri $regUri -Headers $Headers -ContentType 'application/json' -ErrorAction Stop | Out-Null

    $deadline = (Get-Date).AddMinutes(5)
    do {
        Start-Sleep -Seconds 10
        $provider = Invoke-RestMethod -Method Get -Uri $uri -Headers $Headers -ErrorAction Stop
        $state    = $provider.registrationState
        Write-Step "  $ProviderNamespace registration state: $state."
    }
    until ($state -eq 'Registered' -or (Get-Date) -gt $deadline)
    if ($state -ne 'Registered') { throw "Resource provider $ProviderNamespace did not register within the expected time." }
}

function Ensure-SubscriptionFeature {
    param(
        [Parameter(Mandatory)][string]    $ProviderNamespace,
        [Parameter(Mandatory)][string]    $FeatureName,
        [Parameter(Mandatory)][string]    $SubscriptionId,
        [Parameter(Mandatory)][hashtable] $Headers
    )
    $apiVersion = 'api-version=2021-07-01'
    $uri        = "$ArmBase/subscriptions/$SubscriptionId/providers/Microsoft.Features/providers/$ProviderNamespace/features/$FeatureName`?$apiVersion"
    Write-Step "Checking feature: $ProviderNamespace/$FeatureName."
    $feature = Invoke-RestMethod -Method Get -Uri $uri -Headers $Headers -ErrorAction Stop
    $state   = $feature.properties.state
    if ($state -eq 'Registered') { return }

    Write-Step "Registering feature: $ProviderNamespace/$FeatureName."
    $regUri = "$ArmBase/subscriptions/$SubscriptionId/providers/Microsoft.Features/providers/$ProviderNamespace/features/$FeatureName/register?$apiVersion"
    Invoke-RestMethod -Method Post -Uri $regUri -Headers $Headers -ContentType 'application/json' -ErrorAction Stop | Out-Null

    $deadline = (Get-Date).AddMinutes(5)
    do {
        Start-Sleep -Seconds 10
        $feature = Invoke-RestMethod -Method Get -Uri $uri -Headers $Headers -ErrorAction Stop
        $state   = $feature.properties.state
        Write-Step "  $FeatureName registration state: $state."
    }
    until ($state -eq 'Registered' -or (Get-Date) -gt $deadline)
    if ($state -ne 'Registered') { throw "Feature $ProviderNamespace/$FeatureName did not register within the expected time." }
}

function Get-CandidateVmSizes {
    param(
        [Parameter(Mandatory)][string]    $Location,
        [Parameter(Mandatory)][string[]]  $FallbackLocations,
        [Parameter(Mandatory)][string]    $SubscriptionId,
        [Parameter(Mandatory)][hashtable] $Headers
    )

    $preferredSizes = @(
        'Standard_D2s_v7',
        'Standard_D2as_v7',
        'Standard_D2ds_v7',
        'Standard_D2ls_v7',
        'Standard_D2lds_v7',
        'Standard_D2s_v5',
        'Standard_D2as_v5',
        'Standard_D2ds_v5',
        'Standard_D2ads_v5',
        'Standard_D2s_v4',
        'Standard_D2as_v4',
        'Standard_D2ds_v4',
        'Standard_D2ads_v4',
        'Standard_D2s_v3',
        'Standard_D2ds_v3',
        'Standard_F2s_v2',
        'Standard_B2s_v2',
        'Standard_B2ms_v2',
        'Standard_B2ats_v2'
    )

    $result = [System.Collections.Generic.List[object]]::new()

    Write-Debug "  Querying resource SKUs in '$Location'." | Out-Null
    $uri      = "$ArmBase/subscriptions/$SubscriptionId/providers/Microsoft.Compute/skus?`$filter=location eq '$Location'&api-version=2021-07-01"
    $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $Headers -ErrorAction Stop
    $skus     = $response.value | Where-Object { $_.resourceType -eq 'virtualMachines' }

    foreach ($size in $preferredSizes) {
        $sku = $skus | Where-Object { $_.name -eq $size } | Select-Object -First 1
        if (-not $sku) { continue }
        $blocked = $false
        foreach ($restriction in $sku.restrictions) {
            if ($restriction.reasonCode -eq 'NotAvailableForSubscription') {
                $affectedZones = @($restriction.restrictionInfo.zones)
                if ($affectedZones.Count -eq 0) {
                    $blocked = $true
                    Write-Debug "  Skipping $size in $Location - region-wide capacity restriction." | Out-Null
                    break
                }
            }
        }
        if (-not $blocked) { $result.Add(@{ Size = $size; Location = $Location }) }
    }

    foreach ($loc in $FallbackLocations) {
        foreach ($size in $preferredSizes) {
            $result.Add(@{ Size = $size; Location = $loc })
        }
    }

    if ($result.Count -eq 0) {
        throw "None of the preferred VM sizes passed restriction checks in '$Location' and no fallback locations are configured."
    }

    return ,$result
}

function Resolve-WindowsImage {
    param(
        [Parameter(Mandatory)][string]    $Location,
        [Parameter(Mandatory)][string]    $SubscriptionId,
        [Parameter(Mandatory)][hashtable] $Headers
    )

    $candidates = @(
        [pscustomobject]@{ Publisher = 'MicrosoftWindowsDesktop'; Offer = 'Windows-11';    Sku = 'win11-25h2-ent'               },
        [pscustomobject]@{ Publisher = 'MicrosoftWindowsDesktop'; Offer = 'Windows-11';    Sku = 'win11-25h2-entn'              },
        [pscustomobject]@{ Publisher = 'MicrosoftWindowsDesktop'; Offer = 'Windows-11';    Sku = 'win11-25h2-pro'               },
        [pscustomobject]@{ Publisher = 'MicrosoftWindowsDesktop'; Offer = 'Windows-11';    Sku = 'win11-24h2-ent'               },
        [pscustomobject]@{ Publisher = 'MicrosoftWindowsDesktop'; Offer = 'Windows-11';    Sku = 'win11-24h2-entn'              },
        [pscustomobject]@{ Publisher = 'MicrosoftWindowsDesktop'; Offer = 'Windows-11';    Sku = 'win11-24h2-pro'               },
        [pscustomobject]@{ Publisher = 'MicrosoftWindowsDesktop'; Offer = 'Windows-11';    Sku = 'win11-23h2-ent'               },
        [pscustomobject]@{ Publisher = 'MicrosoftWindowsDesktop'; Offer = 'Windows-11';    Sku = 'win11-23h2-entn'              },
        [pscustomobject]@{ Publisher = 'MicrosoftWindowsServer';  Offer = 'WindowsServer'; Sku = '2025-datacenter-g2'           },
        [pscustomobject]@{ Publisher = 'MicrosoftWindowsServer';  Offer = 'WindowsServer'; Sku = '2025-datacenter-azure-edition'}
    )

    Write-Step "Resolving available Windows image SKUs in $Location."

    foreach ($candidate in $candidates) {
        $uri = "$ArmBase/subscriptions/$SubscriptionId/providers/Microsoft.Compute/locations/$Location/publishers/$($candidate.Publisher)/artifacttypes/vmimage/offers/$($candidate.Offer)/skus/$($candidate.Sku)/versions?`$top=1&api-version=2023-03-01"
        $res = Invoke-ArmGet -Uri $uri -Headers $Headers
        if ($res -and @($res).Count -gt 0) {
            Write-Debug "  Resolved image: $($candidate.Publisher):$($candidate.Offer):$($candidate.Sku)"
            return [pscustomobject]@{
                Publisher = $candidate.Publisher
                Offer     = $candidate.Offer
                Sku       = $candidate.Sku
                Version   = 'latest'
            }
        }
        Write-Debug "  SKU not available: $($candidate.Publisher):$($candidate.Offer):$($candidate.Sku)"
    }

    throw "No preferred Windows image SKU was found in $Location."
}

function Get-VmPublicIpAddress {
    param(
        [Parameter(Mandatory)][string]    $ResourceGroupName,
        [Parameter(Mandatory)][string]    $PublicIpName,
        [Parameter(Mandatory)][string]    $SubscriptionId,
        [Parameter(Mandatory)][hashtable] $Headers
    )
    $uri = "$ArmBase/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Network/publicIPAddresses/$PublicIpName`?api-version=2023-05-01"
    $pip = Invoke-ArmGet -Uri $uri -Headers $Headers
    return $pip.properties.ipAddress
}

function Invoke-LabGuestSetup {
    param(
        [Parameter(Mandatory)][string]    $ResourceGroupName,
        [Parameter(Mandatory)][string]    $VmName,
        [Parameter(Mandatory)][string]    $LabAdminUserName,
        [Parameter(Mandatory)][string]    $LabAdminPassword,
        [Parameter(Mandatory)][string]    $SubscriptionId,
        [Parameter(Mandatory)][hashtable] $Headers
    )

    $guestScriptLines = @(
        'param([string]$LabAdminUserName, [string]$LabAdminPassword)',
        '$ErrorActionPreference = "Stop"',
        '$securePassword = ConvertTo-SecureString $LabAdminPassword -AsPlainText -Force',
        '$existingUser = Get-LocalUser -Name $LabAdminUserName -ErrorAction SilentlyContinue',
        'if ($existingUser) {',
        '    Set-LocalUser -Name $LabAdminUserName -Password $securePassword',
        '    Enable-LocalUser -Name $LabAdminUserName',
        '    try { Set-LocalUser -Name $LabAdminUserName -PasswordNeverExpires $true }',
        '    catch { Write-Warning ("Could not set PasswordNeverExpires: " + $_.Exception.Message) }',
        '} else {',
        '    New-LocalUser -Name $LabAdminUserName -Password $securePassword -FullName "Lab Administrator" -Description "Lab-facing local administrator account." -PasswordNeverExpires -AccountNeverExpires | Out-Null',
        '}',
        '$adminGroup = (Get-LocalGroup | Where-Object { $_.SID.Value -eq "S-1-5-32-544" } | Select-Object -First 1).Name',
        'if ([string]::IsNullOrWhiteSpace($adminGroup)) { $adminGroup = "Administrators" }',
        '$isMember = Get-LocalGroupMember -Group $adminGroup -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $LabAdminUserName -or $_.Name -like ("*\" + $LabAdminUserName) }',
        'if (-not $isMember) { Add-LocalGroupMember -Group $adminGroup -Member $LabAdminUserName }',
        'try {',
        '    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0',
        '    Enable-NetFirewallRule -DisplayGroup "Remote Desktop" | Out-Null',
        '} catch { Write-Warning ("RDP enablement warning: " + $_.Exception.Message) }',
        'Write-Output "Lab local administrator account is ready."'
    )
    $guestScript = $guestScriptLines -join "`n"

    $uri  = "$ArmBase/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Compute/virtualMachines/$VmName/runCommand?api-version=2023-03-01"
    $body = @{
        commandId  = 'RunPowerShellScript'
        script     = @($guestScript)
        parameters = @(
            @{ name = 'LabAdminUserName'; value = $LabAdminUserName },
            @{ name = 'LabAdminPassword'; value = $LabAdminPassword }
        )
    }

    for ($attempt = 1; $attempt -le 10; $attempt++) {
        try {
            Write-Step "Running guest setup on $VmName (attempt $attempt of 10)."
            $runResult = Invoke-ArmRequestRaw -Method Post -Uri $uri -Headers $Headers -Body $body -TimeoutSecs 300
            if ($runResult.value) { Write-Output $runResult.value[0].message }
            return
        }
        catch {
            if ($attempt -eq 10) { throw }
            Write-Output "WARNING: Guest setup not ready yet (attempt $attempt). $($_.Exception.Message)"
            Start-Sleep -Seconds 30
        }
    }
}

# ── Main ────────────────────────────────────────────────────────────────────────

function main {
    Write-Debug "Begin main routine."

    $Tags = @{
        Lab           = 'MD-102'
        Purpose       = 'Windows 11 target virtual machine'
        LabInstanceId = $LabInstanceId
        CreatedBy     = 'Skillable automated activity'
    }

    Assert-ResolvedLabValue -Name 'TenantName'         -Value $TenantName
    Assert-ResolvedLabValue -Name 'ScriptingAppId'     -Value $ScriptingAppId
    Assert-ResolvedLabValue -Name 'ScriptingAppSecret' -Value $ScriptingAppSecret
    Assert-ResolvedLabValue -Name 'SubscriptionId'     -Value $SubscriptionId

    Write-Step "Acquiring Azure bearer token."
    $token   = Get-AzBearerToken -TenantName $TenantName -ClientId $ScriptingAppId -ClientSecret $ScriptingAppSecret
    $headers = Get-AuthHeader -Token $token
    Write-Step "Authentication succeeded."

    $apiCR   = 'api-version=2023-07-01'
    $apiNet  = 'api-version=2023-05-01'
    $apiComp = 'api-version=2023-03-01'
    $rgBase  = "$ArmBase/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName"

    Ensure-ResourceProvider -ProviderNamespace 'Microsoft.Compute' -SubscriptionId $SubscriptionId -Headers $headers
    Ensure-ResourceProvider -ProviderNamespace 'Microsoft.Network'  -SubscriptionId $SubscriptionId -Headers $headers
    Ensure-SubscriptionFeature -ProviderNamespace 'Microsoft.Compute' -FeatureName 'UseStandardSecurityType' -SubscriptionId $SubscriptionId -Headers $headers

    Write-Step "Ensuring resource group '$ResourceGroupName' exists."
    $rgUri  = "$ArmBase/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName`?$apiCR"
    $rgBody = @{ location = $Location; tags = $Tags }
    $rg     = Invoke-ArmRequestRaw -Method Put -Uri $rgUri -Headers $headers -Body $rgBody
    Write-Debug "Resource group provisioning state: $($rg.properties.provisioningState)"

    Write-Step "Checking whether '$VmName' already exists."
    $vmUri      = "$rgBase/providers/Microsoft.Compute/virtualMachines/$VmName`?`$expand=instanceView&$apiComp"
    $existingVm = Invoke-ArmGet -Uri $vmUri -Headers $headers

    if ($existingVm) {
        Write-Step "$VmName already exists. Skipping creation."

        # Derive the PIP name the same way the creation path would have.
        # If the VM exists it was deployed with these names already.
        $locationSuffix   = if ($FailoverQuery) { "-$Location" } else { "" }
        $ExistingPipName  = "$VmName-pip$locationSuffix"

        # If the PIP name doesn't resolve, walk the VM's NIC to find the actual PIP name.
        $existingIp = Get-VmPublicIpAddress -ResourceGroupName $ResourceGroupName `
            -PublicIpName $ExistingPipName -SubscriptionId $SubscriptionId -Headers $headers

        if (-not $existingIp -and $existingVm.properties.networkProfile.networkInterfaces) {
            # Fall back to reading the PIP directly from the attached NIC
            $nicRef   = $existingVm.properties.networkProfile.networkInterfaces[0].id
            $nicParts = $nicRef -split '/'
            $nicRg    = $nicParts[4]
            $nicNm    = $nicParts[-1]
            $nicUri   = "$ArmBase/subscriptions/$SubscriptionId/resourceGroups/$nicRg/providers/Microsoft.Network/networkInterfaces/$nicNm`?api-version=2023-05-01"
            $nic      = Invoke-ArmGet -Uri $nicUri -Headers $headers
            if ($nic -and $nic.properties.ipConfigurations) {
                $pipRef = $nic.properties.ipConfigurations[0].properties.publicIPAddress
                if ($pipRef) {
                    $pipParts = $pipRef.id -split '/'
                    $pipRg    = $pipParts[4]
                    $pipNm    = $pipParts[-1]
                    $pipUri   = "$ArmBase/subscriptions/$SubscriptionId/resourceGroups/$pipRg/providers/Microsoft.Network/publicIPAddresses/$pipNm`?api-version=2023-05-01"
                    $pip      = Invoke-ArmGet -Uri $pipUri -Headers $headers
                    $existingIp = $pip.properties.ipAddress
                }
            }
        }

        $powerState = ($existingVm.properties.instanceView.statuses |
            Where-Object { $_.code -like 'PowerState/*' } |
            Select-Object -First 1).displayStatus

        if ($powerState -ne 'VM running') {
            Write-Step "Starting $VmName. Current state: $powerState."
            $startUri = "$rgBase/providers/Microsoft.Compute/virtualMachines/$VmName/start?$apiComp"
            Invoke-ArmRequestRaw -Method Post -Uri $startUri -Headers $headers | Out-Null
        }

        Invoke-LabGuestSetup -ResourceGroupName $ResourceGroupName -VmName $VmName `
            -LabAdminUserName $DesiredLabAdminUserName -LabAdminPassword $DesiredLabAdminPassword `
            -SubscriptionId $SubscriptionId -Headers $headers

        Write-Output ""
        Write-Output "Target virtual machine is ready (already existed)."
        Write-Output "Resource group : $ResourceGroupName"
        Write-Output "Virtual machine: $VmName"
        Write-Output "Lab admin      : $DesiredLabAdminUserName"
        if ($existingIp) { Write-Output "Public IP      : $existingIp" }

        # Scripter/AI: VM already existed and was successfully confirmed/started
        Write-Debug "End main routine."
        return $true
    }

    $activeFallbacks    = if ($FailoverQuery) { $FallbackLocations } else { @() }
    $candidateSizePairs = Get-CandidateVmSizes -Location $Location -FallbackLocations $activeFallbacks -SubscriptionId $SubscriptionId -Headers $headers
    $image              = Resolve-WindowsImage -Location $Location -SubscriptionId $SubscriptionId -Headers $headers
    $previewPairs = ($candidateSizePairs | ForEach-Object { $_['Size'] } | Select-Object -Unique) -join ', '
    Write-Step "Candidate sizes matched from preferred list ($($candidateSizePairs.Count) total pairs across all regions): $previewPairs"
    Write-Step "Selected image: $($image.Publisher):$($image.Offer):$($image.Sku):$($image.Version)"

    $locationGroups = [System.Collections.Generic.List[object]]::new()
    $seenLocations  = [System.Collections.Generic.List[string]]::new()
    foreach ($pair in $candidateSizePairs) {
        $loc = $pair['Location']
        if (-not $seenLocations.Contains($loc)) {
            $seenLocations.Add($loc)
            $sizes = @($candidateSizePairs | Where-Object { $_['Location'] -eq $loc } | ForEach-Object { $_['Size'] })
            $locationGroups.Add(@{ Location = $loc; Sizes = $sizes })
        }
    }

    $vmSize     = $null
    $vmLocation = $null
    $vmCreated  = $false
    $nicId      = $null
    $newVmUri   = $null

    foreach ($group in $locationGroups) {
        $tryLocation  = $group['Location']
        $trySizes     = $group['Sizes']

        Write-Step "Attempting region '$tryLocation' with $($trySizes.Count) candidate size(s)."

        # Per-VM resource names: NSG, PIP, NIC include VmName and optional location suffix.
        # VNet and Subnet names are derived from address prefixes so they are shared across
        # VMs using the same address space in the same resource group.
        $locationSuffix  = if ($FailoverQuery) { "-$tryLocation" } else { "" }
        $vnetPrefix      = Convert-PrefixToName -Prefix $VnetAddressPrefix
        $subnetPrefix    = Convert-PrefixToName -Prefix $SubnetAddressPrefix
        $VnetName        = "vnet-$vnetPrefix$locationSuffix"
        $SubnetName      = "subnet-$subnetPrefix"
        $NsgName         = "$VmName-nsg$locationSuffix"
        $PublicIpName    = "$VmName-pip$locationSuffix"
        $NicName         = "$VmName-nic$locationSuffix"
        $rgBase          = "$ArmBase/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName"

        # NSG
        Write-Step "Ensuring NSG '$NsgName' exists."
        $nsgUri  = "$rgBase/providers/Microsoft.Network/networkSecurityGroups/$NsgName`?$apiNet"
        $rdpRule = @{
            name       = 'Allow-RDP-3389'
            properties = @{
                description              = 'Allow RDP for lab access.'
                protocol                 = 'Tcp'
                sourcePortRange          = '*'
                destinationPortRange     = '3389'
                sourceAddressPrefix      = 'Internet'
                destinationAddressPrefix = '*'
                access                   = 'Allow'
                priority                 = 1000
                direction                = 'Inbound'
            }
        }
        $nsgBody = @{
            location   = $tryLocation
            tags       = $Tags
            properties = @{ securityRules = @() }
        }
        if ($OpenRdp) { $nsgBody.properties.securityRules += $rdpRule }

        $existingNsg = Invoke-ArmGet -Uri $nsgUri -Headers $headers
        if ($existingNsg) {
            Write-Debug "NSG '$NsgName' already exists. Reusing."
            if ($OpenRdp -and -not ($existingNsg.properties.securityRules | Where-Object { $_.name -eq 'Allow-RDP-3389' })) {
                Write-Step "Adding RDP rule to existing NSG '$NsgName'."
                $existingNsg.properties.securityRules += $rdpRule
                Invoke-ArmRequestRaw -Method Put -Uri $nsgUri -Headers $headers -Body $existingNsg | Out-Null
            }
            $nsgId = $existingNsg.id
        }
        else {
            $nsg   = Invoke-ArmRequestRaw -Method Put -Uri $nsgUri -Headers $headers -Body $nsgBody
            $nsgId = $nsg.id
            if (-not $nsgId) {
                $nsg   = Invoke-RestMethod -Method Get -Uri $nsgUri -Headers $headers -ErrorAction Stop
                $nsgId = $nsg.id
            }
        }

        # VNet - shared across VMs; name is derived from address prefix, not VmName
        Write-Step "Ensuring VNet '$VnetName' exists."
        $vnetUri  = "$rgBase/providers/Microsoft.Network/virtualNetworks/$VnetName`?$apiNet"
        $vnetBody = @{
            location   = $tryLocation
            tags       = $Tags
            properties = @{
                addressSpace = @{ addressPrefixes = @($VnetAddressPrefix) }
                subnets      = @(@{
                    name       = $SubnetName
                    properties = @{
                        addressPrefix        = $SubnetAddressPrefix
                        networkSecurityGroup = @{ id = $nsgId }
                    }
                })
            }
        }

        $existingVnet = Invoke-ArmGet -Uri $vnetUri -Headers $headers
        if ($existingVnet) {
            Write-Debug "VNet '$VnetName' already exists. Reusing."
            $subnetId = ($existingVnet.properties.subnets | Where-Object { $_.name -eq $SubnetName } | Select-Object -First 1).id
            if (-not $subnetId) {
                Write-Step "Adding subnet '$SubnetName' to '$VnetName'."
                $existingVnet.properties.subnets += $vnetBody.properties.subnets[0]
                $vnetResult = Invoke-ArmRequestRaw -Method Put -Uri $vnetUri -Headers $headers -Body $existingVnet
                $subnetId   = ($vnetResult.properties.subnets | Where-Object { $_.name -eq $SubnetName } | Select-Object -First 1).id
            }
        }
        else {
            $vnet     = Invoke-ArmRequestRaw -Method Put -Uri $vnetUri -Headers $headers -Body $vnetBody
            $subnetId = ($vnet.properties.subnets | Where-Object { $_.name -eq $SubnetName } | Select-Object -First 1).id
            if (-not $subnetId) {
                $vnet     = Invoke-RestMethod -Method Get -Uri $vnetUri -Headers $headers -ErrorAction Stop
                $subnetId = ($vnet.properties.subnets | Where-Object { $_.name -eq $SubnetName } | Select-Object -First 1).id
            }
        }

        # Public IP
        $publicIpId = $null
        if ($CreatePublicIp) {
            Write-Step "Ensuring public IP '$PublicIpName' exists."
            $pipUri  = "$rgBase/providers/Microsoft.Network/publicIPAddresses/$PublicIpName`?$apiNet"
            $pipBody = @{
                location   = $tryLocation
                tags       = $Tags
                sku        = @{ name = 'Standard' }
                properties = @{ publicIPAllocationMethod = 'Static' }
            }
            $existingPip = Invoke-ArmGet -Uri $pipUri -Headers $headers
            if ($existingPip) {
                $publicIpId = $existingPip.id
            }
            else {
                $pip        = Invoke-ArmRequestRaw -Method Put -Uri $pipUri -Headers $headers -Body $pipBody
                $publicIpId = $pip.id
                if (-not $publicIpId) {
                    $pip        = Invoke-RestMethod -Method Get -Uri $pipUri -Headers $headers -ErrorAction Stop
                    $publicIpId = $pip.id
                }
            }
        }

        # NIC
        Write-Step "Ensuring NIC '$NicName' exists."
        $nicUri        = "$rgBase/providers/Microsoft.Network/networkInterfaces/$NicName`?$apiNet"
        $ipConfigProps = @{
            subnet                    = @{ id = $subnetId }
            privateIPAllocationMethod = 'Dynamic'
        }
        if ($publicIpId) { $ipConfigProps['publicIPAddress'] = @{ id = $publicIpId } }

        $nicBody = @{
            location   = $tryLocation
            tags       = $Tags
            properties = @{
                ipConfigurations = @(@{
                    name       = 'ipconfig1'
                    properties = $ipConfigProps
                })
            }
        }

        $existingNic = Invoke-ArmGet -Uri $nicUri -Headers $headers
        if ($existingNic) {
            $nicId = $existingNic.id
            Write-Debug "NIC '$NicName' already exists. Reusing."
        }
        else {
            $nic   = Invoke-ArmRequestRaw -Method Put -Uri $nicUri -Headers $headers -Body $nicBody
            $nicId = $nic.id
            if (-not $nicId) {
                $nic   = Invoke-RestMethod -Method Get -Uri $nicUri -Headers $headers -ErrorAction Stop
                $nicId = $nic.id
            }
        }

        # Try each size in this region
        $newVmUri = "$rgBase/providers/Microsoft.Compute/virtualMachines/$VmName`?$apiComp"

        foreach ($trySize in $trySizes) {
            Write-Step "Creating virtual machine '$VmName' with size '$trySize' in '$tryLocation'."

            $vmBody = @{
                location   = $tryLocation
                tags       = $Tags
                properties = @{
                    hardwareProfile = @{ vmSize = $trySize }
                    licenseType     = 'Windows_Client'
                    osProfile       = @{
                        computerName         = $VmName
                        adminUsername        = $BootstrapAdminUserName
                        adminPassword        = $BootstrapAdminPassword
                        windowsConfiguration = @{
                            provisionVMAgent       = $true
                            enableAutomaticUpdates = $true
                        }
                    }
                    storageProfile  = @{
                        imageReference = @{
                            publisher = $image.Publisher
                            offer     = $image.Offer
                            sku       = $image.Sku
                            version   = $image.Version
                        }
                        osDisk         = @{
                            name         = $OsDiskName
                            createOption = 'FromImage'
                            caching      = 'ReadWrite'
                            managedDisk  = @{ storageAccountType = 'StandardSSD_LRS' }
                        }
                    }
                    networkProfile  = @{
                        networkInterfaces = @(@{
                            id         = $nicId
                            properties = @{ primary = $true }
                        })
                    }
                    securityProfile = @{ securityType = 'Standard' }
                }
            }

            try {
                Invoke-ArmRequestRaw -Method Put -Uri $newVmUri -Headers $headers -Body $vmBody | Out-Null
                Write-Step "Virtual machine '$VmName' created with size '$trySize' in '$tryLocation'."
                $vmSize     = $trySize
                $vmLocation = $tryLocation
                $vmCreated  = $true
                break
            }
            catch {
                if ($_ -match 'SkuNotAvailable') {
                    Write-Step "Size '$trySize' has no capacity in '$tryLocation'. Trying next size."
                    continue
                }
                throw
            }
        }

        if ($vmCreated) { break }
        Write-Step "All sizes exhausted in '$tryLocation'. Moving to next region."
    }

    if (-not $vmCreated) {
        $attemptedSizes   = ($candidateSizePairs | ForEach-Object { $_['Size'] }     | Select-Object -Unique) -join ', '
        $attemptedRegions = ($candidateSizePairs | ForEach-Object { $_['Location'] } | Select-Object -Unique) -join ', '
        throw "VM creation failed - no available capacity found. Sizes tried: $attemptedSizes. Regions tried: $attemptedRegions."
    }

    $Location = $vmLocation

    Invoke-LabGuestSetup -ResourceGroupName $ResourceGroupName -VmName $VmName `
        -LabAdminUserName $DesiredLabAdminUserName -LabAdminPassword $DesiredLabAdminPassword `
        -SubscriptionId $SubscriptionId -Headers $headers

    $publicIpAddress = Get-VmPublicIpAddress -ResourceGroupName $ResourceGroupName `
        -PublicIpName $PublicIpName -SubscriptionId $SubscriptionId -Headers $headers

    Write-Output ""
    Write-Output "Target virtual machine created successfully."
    Write-Output "Resource group : $ResourceGroupName"
    Write-Output "Region         : $Location"
    Write-Output "Virtual machine: $VmName"
    Write-Output "VM size        : $vmSize"
    Write-Output "Image SKU      : $($image.Sku)"
    Write-Output "Lab admin      : $DesiredLabAdminUserName"
    if ($publicIpAddress) { Write-Output "Public IP      : $publicIpAddress" }
    else                  { Write-Output "Public IP      : Not assigned or not ready." }

    Write-Debug "End main routine."

    # Scripter/AI: VM was created and guest setup completed successfully
    return $true
}

# Run the main routine
if ($scriptDebug) {
    try {
        $result = main
    } catch {
        Write-Output "ERROR: $($_.Exception.Message)"
        Write-Output "At line $($_.InvocationInfo.ScriptLineNumber - $wrapperLineCount): $($_.InvocationInfo.Line.Trim())"
        $result = $false
    }
} else {
    try {
        $result = main
    } catch {
        $result = $false
    }
}

if ($scriptDebug) {
    Write-Output "--- DEBUG LOG ---"
    $debugLog | ForEach-Object { Write-Output $_ }
    Write-Output "--- END DEBUG LOG ---"
    Write-Output "The result returned is: $result"
}
return $result
