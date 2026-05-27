<#
   Title: DynamicVMSizer-v2.ps1
   Description: Finds a VM size (SKU) that is available based upon constraints passed in the parameters.
                This version adds quota-aware filtering so SKUs without remaining quota are skipped
                before selection. The quota snapshot is fetched once per location and then reused for
                the full candidate list.
   Version: 2026.05.27
#>

param (
    # Target VM Size - Format: c<cpu>r<ram>g<gen>p<price-0.00> e.g. c2r4g2p0.20, c4r16g1p0.70
    $TargetSpec = 'c2r4g2p0.50',
    # Name of the @lab variable to return
    $VMSizeLabVariable = 'VMSize1',
    # Default size to use if automatic selection fails
    $DefaultSize = 'Standard_B4as_v2',
    # Location (from the resource group)
    $Location,
    # URL for allowed list of VM sizes (SKUs)
    $allowedSizesURL = 'https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/LCAs/AzureVMSizes.csv',
    # Maximum allowed vCPUs
    $MaxCPU = '16',
    # Maximum allowed RAM in GB
    $MaxRAM = '64',
    # Enable script debugging by setting the debug lab variable to True
    $ScriptDebug,
    # Enable detailed debugging
    $VerboseDebug
)

$ScriptTitle = "Dynamic VM Sizer v2: $VMSizeLabVariable"
$Global:MessageBuffer = ''

function Send-DebugMessage {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Message
    )

    $Global:MessageBuffer += "`n`n$Message"
    if ($VerboseDebug) {
        Write-Host $Message
    }
}

function Send-LabNotificationChunks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptTitle,
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [Parameter(Mandatory = $false)]
        [int]$MaxLength = 2048,
        [Parameter(Mandatory = $false)]
        [int]$DelayBetweenChunksSec = 3
    )

    $buffer = $Message.TrimEnd()
    if ([string]::IsNullOrWhiteSpace($buffer)) { return }

    $dateStamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $baseHeaderNoPart = "[$dateStamp Debug] $ScriptTitle :`n---------`n"
    $baseHeaderLength = $baseHeaderNoPart.Length
    $available = $MaxLength - $baseHeaderLength - 10

    if ($buffer.Length -le $available) {
        Send-LabNotification -Message "$baseHeaderNoPart$buffer"
        return
    }

    $chunks = [System.Collections.Generic.List[string]]::new()
    $pos = 0

    while ($pos -lt $buffer.Length) {
        $remaining = $buffer.Length - $pos
        $take = [Math]::Min($available, $remaining)

        if ($take -lt $remaining) {
            $lookback = [Math]::Min(400, $take)
            $lastNL = $buffer.LastIndexOf("`n", $pos + $take - 1, $lookback)
            if ($lastNL -ge $pos) {
                $take = $lastNL - $pos + 1
            }
        }

        $chunk = $buffer.Substring($pos, $take).TrimEnd()
        if ($chunk.Length -gt 0) {
            $chunks.Add($chunk)
        }

        $pos += $take
    }

    for ($i = 0; $i -lt $chunks.Count; $i++) {
        $part = $i + 1
        $totalParts = $chunks.Count
        $header = "[$dateStamp Debug Part$part/$totalParts] $ScriptTitle :`n---------`n"
        $fullMsg = $header + $chunks[$i]

        if ($fullMsg.Length -gt $MaxLength) {
            $fullMsg = $fullMsg.Substring(0, $MaxLength - 4) + ' ...'
        }

        Send-LabNotification -Message $fullMsg

        if ($i -lt ($chunks.Count - 1)) {
            Start-Sleep -Seconds $DelayBetweenChunksSec
        }
    }
}

function Fail-Selection {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Send-DebugMessage $Message
    if ($ScriptDebug) {
        Send-LabNotificationChunks -ScriptTitle $ScriptTitle -Message $Global:MessageBuffer
    }

    throw "[Debug] $ScriptTitle:`n---------`n$Global:MessageBuffer"
}

function Get-NormalizedText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    return (($Text -replace '[^A-Za-z0-9]', '').ToLowerInvariant())
}

function Get-SkuCapabilitiesMap {
    param(
        [Parameter(Mandatory = $true)]
        $Sku
    )

    $caps = @{}
    foreach ($cap in $Sku.Capabilities) {
        $caps[$cap.Name] = $cap.Value
    }

    return $caps
}

function Get-SkuFamilyTokens {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SkuName,
        [Parameter(Mandatory = $false)]
        [hashtable]$Capabilities
    )

    $tokens = [System.Collections.Generic.List[string]]::new()

    if ($Capabilities) {
        foreach ($key in @('Family', 'FamilyName', 'VmFamily', 'SizeFamily')) {
            if ($Capabilities.ContainsKey($key) -and $Capabilities[$key]) {
                $token = Get-NormalizedText -Text ([string]$Capabilities[$key])
                if ($token.Length -gt 0) {
                    $tokens.Add($token)
                }
            }
        }
    }

    $raw = $SkuName -replace '^Standard[_-]?', ''
    if ($raw.Length -gt 0) {
        $tokens.Add((Get-NormalizedText -Text $raw))

        if ($raw -match '^(?<base>.+?)_v(?<ver>\d+)$') {
            $baseToken = Get-NormalizedText -Text ($Matches.base -replace '\d+', '')
            if ($baseToken.Length -gt 0) {
                $tokens.Add($baseToken + 'v' + $Matches.ver)
            }
        }

        $compact = Get-NormalizedText -Text ($raw -replace '\d+', '')
        if ($compact.Length -gt 0) {
            $tokens.Add($compact)
        }
    }

    return $tokens | Select-Object -Unique
}

function Get-QuotaSnapshot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Location
    )

    $usages = @(Get-AzVMUsage -Location $Location)
    if (-not $usages -or $usages.Count -eq 0) {
        return $null
    }

    return [pscustomobject]@{
        Location = $Location
        Usages   = $usages
    }
}

function Get-QuotaRemaining {
    param(
        [Parameter(Mandatory = $true)]
        $Usage
    )

    $currentValue = [int]$Usage.CurrentValue
    $limit = [int64]$Usage.Limit
    return ($limit - $currentValue)
}

function Find-UsageByMatcher {
    param(
        [Parameter(Mandatory = $true)]
        [array]$Usages,
        [Parameter(Mandatory = $true)]
        [scriptblock]$Predicate
    )

    foreach ($usage in $Usages) {
        if (& $Predicate $usage) {
            return $usage
        }
    }

    return $null
}

function Test-SkuQuotaAvailability {
    param(
        [Parameter(Mandatory = $true)]
        $Sku,
        [Parameter(Mandatory = $true)]
        [pscustomobject]$QuotaSnapshot,
        [Parameter(Mandatory = $true)]
        [int]$RequiredVcpus
    )

    $caps = Get-SkuCapabilitiesMap -Sku $Sku
    $familyTokens = Get-SkuFamilyTokens -SkuName $Sku.Name -Capabilities $caps
    $usageList = @($QuotaSnapshot.Usages)

    $regionalUsage = Find-UsageByMatcher -Usages $usageList -Predicate {
        param($usage)
        $nameText = Get-NormalizedText -Text (@($usage.Name.Value, $usage.Name.LocalizedValue) -join ' ')
        return ($nameText -match 'vcpus' -and $nameText -match 'regional' -and $nameText -notmatch 'family' -and $nameText -notmatch 'spot' -and $nameText -notmatch 'lowpriority')
    }

    if ($null -eq $regionalUsage) {
        return [pscustomobject]@{
            Available = $true
            Reason    = 'No regional quota usage entry could be matched; proceeding with size check only.'
        }
    }

    $regionalRemaining = Get-QuotaRemaining -Usage $regionalUsage
    if ($regionalRemaining -lt $RequiredVcpus) {
        return [pscustomobject]@{
            Available = $false
            Reason    = "Regional quota remaining ($regionalRemaining) is below required vCPUs ($RequiredVcpus). Usage: $($regionalUsage.Name.LocalizedValue)"
        }
    }

    $familyUsage = $null
    foreach ($token in $familyTokens) {
        $familyUsage = Find-UsageByMatcher -Usages $usageList -Predicate {
            param($usage)
            $nameText = Get-NormalizedText -Text (@($usage.Name.Value, $usage.Name.LocalizedValue) -join ' ')
            return ($nameText -match 'vcpus' -and $nameText -match 'family' -and $nameText -like "*$token*")
        }

        if ($null -ne $familyUsage) {
            break
        }
    }

    if ($null -eq $familyUsage) {
        return [pscustomobject]@{
            Available = $true
            Reason    = "Regional quota is sufficient and no family quota entry could be matched for $($Sku.Name)."
        }
    }

    $familyRemaining = Get-QuotaRemaining -Usage $familyUsage
    if ($familyRemaining -lt $RequiredVcpus) {
        return [pscustomobject]@{
            Available = $false
            Reason    = "Family quota remaining ($familyRemaining) is below required vCPUs ($RequiredVcpus). Usage: $($familyUsage.Name.LocalizedValue)"
        }
    }

    return [pscustomobject]@{
        Available = $true
        Reason    = "Regional quota remaining ($regionalRemaining) and family quota remaining ($familyRemaining) both support $RequiredVcpus vCPUs."
    }
}

Send-DebugMessage "[INFO] Starting VM size selection in location: $Location"
Send-DebugMessage "[INFO] Target spec: $TargetSpec | MaxCPU: $MaxCPU vCPU | MaxRAM: $MaxRAM GB"

$targetCPU = 2
$targetRAM = 4.0
$requiredGen = '2'
$maxPrice = '0.50'

if ($TargetSpec -match '^c(\d+)r(\d+(?:\.\d+)?)g([12])p(\d+\.\d{2})$') {
    $targetCPU = [int]$Matches[1]
    $targetRAM = [double]$Matches[2]
    $requiredGen = $Matches[3]
    $maxPrice = $Matches[4]
    Send-DebugMessage "[INFO] '$TargetSpec' decoded to CPU=$targetCPU RAM=$targetRAM GB Gen=$requiredGen MaxPrice=`$$maxPrice/hr"
}
else {
    Send-DebugMessage "[WARN] Invalid TargetSpec format: '$TargetSpec'. Falling back to c2r4g2p0.50"
    $TargetSpec = 'c2r4g2p0.50'
}

$minVCPU = $targetCPU
$minMemoryGB = $targetRAM
$maxVCPUNum = if ([int]::TryParse($MaxCPU, [ref]$null)) { [int]$MaxCPU } else { 9999 }
$maxRAMNum = if ([double]::TryParse($MaxRAM, [ref]$null)) { [double]$MaxRAM } else { 9999.0 }

Send-DebugMessage "[INFO] Parsed constraints: >= $minVCPU vCPU / >= $minMemoryGB GB (Gen $requiredGen) | <= $maxVCPUNum vCPU / <= $maxRAMNum GB | <= $maxPrice /hr"

$allowedSizes = @()
$maxRetries = 4
$baseDelaySeconds = 2
$attempt = 0
$success = $false

while (-not $success -and $attempt -lt $maxRetries) {
    $attempt++
    Send-DebugMessage "[INFO] Attempt $attempt/$maxRetries to fetch allowed VM sizes from: $allowedSizesURL"

    try {
        $allowedSizes = Invoke-RestMethod -Uri $allowedSizesURL -Method Get -TimeoutSec 15 -ErrorAction Stop |
            ConvertFrom-Csv -Header Name |
            Select-Object -ExpandProperty Name -Unique

        if ($allowedSizes.Count -gt 0) {
            Send-DebugMessage "[INFO] Loaded $($allowedSizes.Count) allowed VM sizes from CSV"
            $success = $true
        }
        else {
            Fail-Selection "[ERROR] Empty or invalid CSV content after cleaning. Falling back to default size: $DefaultSize"
            return $true
        }
    }
    catch {
        Send-DebugMessage "[WARN] Fetch attempt $attempt failed: $($_.Exception.Message)"
        if ($attempt -lt $maxRetries) {
            $delay = [Math]::Min(30, $baseDelaySeconds * [Math]::Pow(2, $attempt - 1))
            Start-Sleep -Seconds $delay
        }
    }
}

if (-not $success) {
    Send-DebugMessage '[WARN] All retries failed. Proceeding without CSV size filtering.'
    $allowedSizes = @()
}

$allSkus = Get-AzComputeResourceSku -Location $Location | Where-Object {
    $_.ResourceType -eq 'virtualMachines' -and
    (
        $_.Restrictions.Count -eq 0 -or
        $_.Restrictions.Where({
            $_.ReasonCode -eq 'NotAvailableForSubscription' -and
            $_.Type -eq 'Location'
        }).Count -eq 0
    )
}

if (-not $allSkus) {
    Fail-Selection "[ERROR] No VM sizes available in location $Location. Falling back to default size: $DefaultSize"
    Set-LabVariable -Name $VMSizeLabVariable -Value $DefaultSize
    return $true
}

Send-DebugMessage "[INFO] Retrieved $($allSkus.Count) VM sizes from Azure"

if ($allowedSizes.Count -gt 0) {
    $allSkus = $allSkus | Where-Object { $allowedSizes -contains $_.Name }
    Send-DebugMessage "[INFO] After CSV filter: $($allSkus.Count) sizes remain"
}

$allSkus = $allSkus | Where-Object {
    $caps = Get-SkuCapabilitiesMap -Sku $_
    $cpuArch = if ($caps.ContainsKey('CpuArchitectureType')) { $caps['CpuArchitectureType'] } else { 'x64' }
    $cpuArch -eq 'x64'
}

if (-not $allSkus) {
    Fail-Selection "[ERROR] No x64-compatible VM sizes remain after filtering. Falling back to default size: $DefaultSize"
    Set-LabVariable -Name $VMSizeLabVariable -Value $DefaultSize
    return $true
}

Send-DebugMessage "[INFO] After x64 filter: $($allSkus.Count) sizes remain eligible"

$quotaSnapshot = $null
try {
    Send-DebugMessage "[INFO] Fetching quota usage snapshot for $Location"
    $quotaSnapshot = Get-QuotaSnapshot -Location $Location
    if ($null -ne $quotaSnapshot) {
        Send-DebugMessage "[INFO] Quota snapshot loaded with $(@($quotaSnapshot.Usages).Count) usage entries"
    }
}
catch {
    Send-DebugMessage "[WARN] Quota snapshot could not be loaded: $($_.Exception.Message). Continuing without quota gating."
}

$priceDict = @{}
try {
    Send-DebugMessage "[INFO] Fetching bulk VM prices for $Location"
    $bulkFilter = "serviceName eq 'Virtual Machines' and armRegionName eq '$Location' and priceType eq 'Consumption'"
    $bulkUri = "https://prices.azure.com/api/retail/prices?api-version=2023-01-01-preview&`$filter=$([uri]::EscapeDataString($bulkFilter))"
    $response = Invoke-RestMethod -Uri $bulkUri -Method Get -TimeoutSec 30

    foreach ($item in $response.Items) {
        $sku = $item.armSkuName
        $priceRaw = $item.unitPrice
        if ($priceRaw -and $priceRaw -gt 0.05 -and $priceRaw -lt 2 -and $item.meterName -notmatch 'Spot|Low Priority|LowPriority|Partial|Reservation') {
            $price = [double]$priceRaw
            if (-not $priceDict.ContainsKey($sku) -or $price -lt $priceDict[$sku]) {
                $priceDict[$sku] = $price
            }
        }
    }

    Send-DebugMessage "[INFO] Bulk price fetch complete - $($priceDict.Count) SKU prices loaded"
}
catch {
    Send-DebugMessage "[WARN] Bulk price fetch failed: $($_.Exception.Message). Falling back to per-SKU lookups."
}

function Get-VMHourlyPrice {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SkuName,
        [Parameter(Mandatory = $true)]
        [string]$Region
    )

    if ($priceDict -and $priceDict.ContainsKey($SkuName)) {
        return $priceDict[$SkuName]
    }

    Start-Sleep -Milliseconds 250
    $filter = "serviceName eq 'Virtual Machines' and armRegionName eq '$Region' and armSkuName eq '$SkuName' and priceType eq 'Consumption'"
    $uri = "https://prices.azure.com/api/retail/prices?api-version=2023-01-01-preview&`$filter=$([uri]::EscapeDataString($filter))"

    try {
        $response = Invoke-RestMethod -Uri $uri -Method Get -TimeoutSec 15
        $validItems = $response.Items | Where-Object {
            $_.unitPrice -gt 0.05 -and $_.unitPrice -lt 2 -and
            $_.meterName -notmatch 'Spot|Low Priority|LowPriority|Partial|Reservation'
        }

        if ($validItems.Count -gt 0) {
            $price = [double]($validItems | Sort-Object unitPrice -Descending | Select-Object -First 1).unitPrice
            $priceDict[$SkuName] = $price
            return $price
        }
    }
    catch {
        return $null
    }

    return $null
}

$candidates = @()
Send-DebugMessage '[INFO] Evaluating candidate SKUs.'

foreach ($sku in $allSkus) {
    $caps = Get-SkuCapabilitiesMap -Sku $sku

    # Skip known specialized families that are not appropriate for most lab deployments.
    $excludedPrefixes = @('DC', 'EC', 'HB', 'HC', 'HX', 'ND', 'NC', 'NV', 'NP', 'H')
    $excluded = $false
    foreach ($prefix in $excludedPrefixes) {
        if ($sku.Name -like "*_$prefix*") {
            $excluded = $true
            break
        }
    }

    if ($excluded) {
        continue
    }

    $hyperV = if ($caps.ContainsKey('HyperVGenerations')) { $caps['HyperVGenerations'] } else { 'V1' }
    $supportsGen = if ($requiredGen -eq '1') { $hyperV -match 'V1' } else { $hyperV -match 'V2' }
    if (-not $supportsGen) {
        continue
    }

    $vcpus = if ($caps.ContainsKey('vCPUs') -and $caps['vCPUs']) { [int]$caps['vCPUs'] } else { 0 }
    $memoryGB = if ($caps.ContainsKey('MemoryGB') -and $caps['MemoryGB']) { [double]$caps['MemoryGB'] } else { 0.0 }

    if ($vcpus -lt $minVCPU -or $vcpus -gt $maxVCPUNum) { continue }
    if ($memoryGB -lt $minMemoryGB -or $memoryGB -gt $maxRAMNum) { continue }

    if ($null -ne $quotaSnapshot) {
        $quotaCheck = Test-SkuQuotaAvailability -Sku $sku -QuotaSnapshot $quotaSnapshot -RequiredVcpus $vcpus
        if (-not $quotaCheck.Available) {
            if ($VerboseDebug) { Send-DebugMessage "[SKIP-QUOTA] $($sku.Name) - $($quotaCheck.Reason)" }
            continue
        }
        elseif ($VerboseDebug) {
            Send-DebugMessage "[QUOTA] $($sku.Name) - $($quotaCheck.Reason)"
        }
    }

    $price = Get-VMHourlyPrice -SkuName $sku.Name -Region $Location
    if ($null -eq $price) {
        continue
    }

    if ($price -gt [double]$maxPrice) {
        continue
    }

    $candidates += [pscustomobject]@{
        Name              = $sku.Name
        vCPUs             = $vcpus
        MemoryGB          = $memoryGB
        PricePerHourUSD   = $price
        HyperVGenerations = $hyperV
    }
}

Send-DebugMessage "[INFO] Found $($candidates.Count) candidates after quota, spec, and price filtering."

if ($candidates.Count -gt 0) {
    $selected = $candidates | Sort-Object PricePerHourUSD, vCPUs, MemoryGB | Select-Object -First 1
    Send-DebugMessage "[SUCCESS] Selected VM size: $($selected.Name) at $($selected.PricePerHourUSD)/hr"
    Set-LabVariable -Name $VMSizeLabVariable -Value $selected.Name
    Set-LabVariable -Name VMPrice -Value $selected.PricePerHourUSD
}
else {
    Send-DebugMessage "[WARN] No VM size met all constraints. Falling back to default size: $DefaultSize"
    Set-LabVariable -Name $VMSizeLabVariable -Value $DefaultSize
    Set-LabVariable -Name VMPrice -Value 0
}

if ($ScriptDebug) {
    Send-LabNotificationChunks -ScriptTitle $ScriptTitle -Message $Global:MessageBuffer
}

return $true
