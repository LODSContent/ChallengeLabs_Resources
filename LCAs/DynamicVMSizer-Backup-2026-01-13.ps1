# Script Title
$ScriptTitle = "Dynamic VM Sizer"

# Target VM Size - Format: c<cpu>r<ram>g<gen>p<price-0.00> e.g. c2r4g2p0.20, c4r16g1p0.70
$TargetSpec = '@lab.Variable(VMTargetSpec)'

# Maximum allowed vCPUs - HARD CAP
$MaxCPU = '16'

# Maximum allowed RAM in GB - HARD CAP
$MaxRAM = '64'

# Location (from the resource group)
$Location = '@lab.CloudResourceGroup(RG1).Location'

# URL for allowed list of VM sizes (SKUs)
$allowedSizesURL = "https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/LCAs/AzureVMSizes.csv"

# Default size to use if automatic selection fails
$defaultSize = 'Standard_B4as_v2'

# Enable script debugging by setting the debug lab variable to True
$ScriptDebug = '@lab.Variable(debug)' -in 'Yes','True' -or '@lab.Variable(Debug)' -in 'Yes','True'

# Enable detailed debugging when ScriptDebug is on
$VerboseDebug = $false

# Debug function
function Send-DebugMessage {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Message
    )
  
    if ($ScriptDebug) { 
        $Global:MessageBuffer += "`n`n$Message"
    }
}

Send-DebugMessage "[INFO] Starting VM size selection in location: $Location"
Send-DebugMessage "[INFO] Target spec: $TargetSpec | MaxPrice: $MaxPrice | MaxCPU: $MaxCPU vCPU | MaxRAM: $MaxRAM GB"

# Parse TargetSpec (unchanged)
$targetCPU    = 2
$targetRAM    = 4.0
$requiredGen  = '2'
$maxPrice     = '0.50'
if ($TargetSpec -match '^c(\d+)r(\d+(?:\.\d+)?)g([12])p(\d+\.\d{2})$') {
    $targetCPU = [int]$Matches[1]
    $targetRAM = [double]$Matches[2]
    $requiredGen = $Matches[3]
    $maxPrice    = $Matches[4]
    Send-DebugMessage "[INFO] '$TargetSpec' decoded to: CPU: $targetCPU, RAM: $targetRAM, Gen: $requiredGen, MaxPrice: `$$maxPrice/hr"
} 
elseif ($TargetSpec -match '^c(\d+)r(\d+(?:\.\d+)?)g([12])$') {
    # Backward compatibility - old format without price
    $targetCPU   = [int]$Matches[1]
    $targetRAM   = [double]$Matches[2]
    $requiredGen = $Matches[3]
    Send-DebugMessage "[WARN] Old TargetSpec format detected (no price). Using default MaxPrice: `$$maxPrice"
} 
else {
    Send-DebugMessage "[ERROR] Invalid TargetSpec format: '$TargetSpec'. Using defaults: c2r4g1p0.50"
    $TargetSpec = 'c2r4g2p0.50'
}

$minVCPU = $targetCPU
$minMemoryGB = $targetRAM
$maxVCPUNum = if ([int]::TryParse($MaxCPU, [ref]$null)) { [int]$MaxCPU } else { 9999 }
$maxRAMNum = if ([double]::TryParse($MaxRAM, [ref]$null)) { [double]$MaxRAM } else { 9999.0 }

Send-DebugMessage "[INFO] Parsed constraints: >= $minVCPU vCPU / >= $minMemoryGB GB (Gen $requiredGen) | <= $maxVCPUNum vCPU / <= $maxRAMNum GB | <= $MaxPrice /hr"

# Fetch allowed VM sizes from GitHub CSV with retry (unchanged, but fixed variable $csvUrl -> $allowedSizesURL)
$allowedSizes = @()
$maxRetries = 4
$baseDelaySeconds = 2
$useExponentialBackoff = $true
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
            Send-DebugMessage "[SUCCESS] Loaded $($allowedSizes.Count) allowed VM sizes from CSV (first clean: $($allowedSizes[0]))"
            $success = $true
        } else {
            throw "Empty or invalid CSV content after cleaning"
        }
    }
    catch {
        $errorMsg = $_.Exception.Message
        Send-DebugMessage "[ERROR] Fetch attempt $attempt failed: $errorMsg"
        if ($attempt -lt $maxRetries) {
            $delay = if ($useExponentialBackoff) { [math]::Min(30, $baseDelaySeconds * [math]::Pow(2, $attempt - 1)) } else { $baseDelaySeconds }
            Send-DebugMessage "[RETRY] Waiting $delay seconds before next attempt..."
            Start-Sleep -Seconds $delay
        }
    }
}

if (-not $success) {
    Send-DebugMessage "[WARN] All retries failed. Proceeding with NO size filtering."
    $allowedSizes = @()
}

# Get available VM SKUs (unchanged)
$allSkus = Get-AzComputeResourceSku -Location $Location | Where-Object {
    $_.ResourceType -eq 'virtualMachines' -and
    $_.Restrictions.Count -eq 0 -and ($_.LocationInfo.Zones.Count -gt 0 -or $_.Restrictions.Reasoncode -ne "NotAvailableForSubscription")
}

if (-not $allSkus) {
    Send-DebugMessage "[ERROR] No VM sizes available in location $Location. Setting size to default: $defaultSize"
    Set-LabVariable -Name VMSize -Value $defaultSize
    return $true
}

Send-DebugMessage "[INFO] Found $($allSkus.Count) available VM sizes in location $Location"

# Apply allowed sizes filter
if ($allowedSizes.Count -gt 0) {
    $allSkus = $allSkus | Where-Object { $allowedSizes -contains $_.Name }
    Send-DebugMessage "[INFO] After CSV allowed sizes filter: $($allSkus.Count) sizes remain"
}

# Enforce x64 (unchanged)
$allSkus = $allSkus | Where-Object {
    $caps = @{}
    foreach ($cap in $_.Capabilities) { $caps[$cap.Name] = $cap }
    
    $cpuArch = if ($caps.ContainsKey('CpuArchitectureType')) { $caps['CpuArchitectureType'].Value } else { 'x64' }
    if ($cpuArch -ne 'x64') {
        if ($VerboseDebug) {Send-DebugMessage "[EXCLUDE-ARCH] Dropped ARM64 size: $($_.Name)"}
        $false
    } else { $true }
}

if ($allSkus.Count -eq 0) {
    Send-DebugMessage "[ERROR] No x64-compatible VM sizes remain after filtering. Setting size to default: $defaultSize"
    Set-LabVariable -Name VMSize -Value $defaultSize
    return $true
}

Send-DebugMessage "[INFO] After x64 filter: $($allSkus.Count) sizes remain eligible"

# Bulk price fetch (increase upper sanity bound to <2 for larger sizes)
$priceDict = @{}
try {
    Send-DebugMessage "[INFO] Fetching bulk VM prices for $Location..."
    $bulkFilter = "serviceName eq 'Virtual Machines' and armRegionName eq '$Location' and priceType eq 'Consumption'"
    $bulkUri = "https://prices.azure.com/api/retail/prices?api-version=2023-01-01-preview&`$filter=$([uri]::EscapeDataString($bulkFilter))"
    $response = Invoke-RestMethod -Uri $bulkUri -Method Get -TimeoutSec 30
    foreach ($item in $response.Items) {
        $sku = $item.armSkuName
        $priceRaw = $item.unitPrice
        if ($priceRaw -and $priceRaw -gt 0.05 -and $priceRaw -lt 2 -and
            $item.meterName -notmatch 'Spot|Low Priority|LowPriority|Partial|Reservation') {
            $price = [double]$priceRaw
            if (-not $priceDict.ContainsKey($sku) -or $price -lt $priceDict[$sku]) {
                $priceDict[$sku] = $price
            }
        }
    }
    Send-DebugMessage "[SUCCESS] Bulk fetch complete - $($priceDict.Count) VM prices loaded"
}
catch {
    Send-DebugMessage "[WARN] Bulk price fetch failed: $($_.Exception.Message) - using per-SKU fallback"
}

# Price lookup function (unchanged, but same bound increase)
function Get-VMHourlyPrice {
    param(
        [string]$skuName,
        [string]$region
    )
    if ($priceDict -and $priceDict.ContainsKey($skuName)) {
        return $priceDict[$skuName]
    }
    Start-Sleep -Milliseconds 400
    $filter = "serviceName eq 'Virtual Machines' and armRegionName eq '$region' and armSkuName eq '$skuName' and priceType eq 'Consumption'"
    $uri = "https://prices.azure.com/api/retail/prices?api-version=2023-01-01-preview&`$filter=$([uri]::EscapeDataString($filter))"
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Get -TimeoutSec 15
        $validItems = $response.Items | Where-Object {
            $_.unitPrice -gt 0.05 -and $_.unitPrice -lt 2 -and
            $_.meterName -notmatch 'Spot|Low Priority|LowPriority|Partial|Reservation'
        }
        if ($validItems.Count -gt 0) {
            $price = [double]($validItems | Sort-Object unitPrice -Descending | Select-Object -First 1).unitPrice
            $priceDict[$skuName] = $price
            return $price
        }
    }
    catch { }
    return $null
}

# Collect candidates - STRICT price enforcement
$candidates = @()

Send-DebugMessage "[INFO] Examining SKUs for candidates."
foreach ($sku in $allSkus) {
    $caps = @{}
    foreach ($cap in $sku.Capabilities) { $caps[$cap.Name] = $cap }
    
    # Exclude specialized + L-series (expensive storage-optimized)
    $excludedPrefixes = @('DC', 'EC', 'HB', 'HC', 'HX', 'ND', 'NC', 'NV', 'NP', 'H')
    $excluded = $false
    foreach ($prefix in $excludedPrefixes) {
        if ($sku.Name -like "*_$prefix*") {  # Changed to *prefix* for better match
            $excluded = $true
            if ($VerboseDebug) {Send-DebugMessage "[EXCLUDE-SPECIAL] Skipping: $($sku.Name)"}
            break
        }
    }
    if ($excluded) { continue }
    
    # Generation check
    $hyperV = if ($caps.ContainsKey('HyperVGenerations')) { $caps['HyperVGenerations'].Value } else { 'V1' }
    $supportsGen = if ($requiredGen -eq '1') { $hyperV -match 'V1' } else { $hyperV -match 'V2' }
    if (-not $supportsGen) { 
        if ($VerboseDebug) {Send-DebugMessage "[SKIP-GEN] $($sku.Name) does not support Gen $requiredGen"}
        continue 
    }
    
    # Specs - strict caps
    $vcpus = if ($caps.ContainsKey('vCPUs') -and $caps['vCPUs'].Value) { [int]$caps['vCPUs'].Value } else { 0 }
    $memoryGB = if ($caps.ContainsKey('MemoryGB') -and $caps['MemoryGB'].Value) { [double]$caps['MemoryGB'].Value } else { 0.0 }
    
    if ($vcpus -lt $minVCPU) { 
        if ($VerboseDebug) {Send-DebugMessage "[SKIP-LOWCPU] $($sku.Name) $vcpus vCPU < min $minVCPU"}
        continue 
    }
    if ($vcpus -gt $maxVCPUNum) { 
        if ($VerboseDebug) {Send-DebugMessage "[SKIP-HIGHCPU] $($sku.Name) $vcpus vCPU > max $maxVCPUNum"}
        continue 
    }
    if ($memoryGB -lt $minMemoryGB) { 
        if ($VerboseDebug) {Send-DebugMessage "[SKIP-LOWRAM] $($sku.Name) $memoryGB GB < min $minMemoryGB"}
        continue 
    }
    if ($memoryGB -gt $maxRAMNum) { 
        if ($VerboseDebug) {Send-DebugMessage "[SKIP-HIGHRAM] $($sku.Name) $memoryGB GB > max $maxRAMNum"}
        continue 
    }
    
    $price = Get-VMHourlyPrice -skuName $sku.Name -region $Location
    
    if ($null -eq $price) { 
        if ($VerboseDebug) {Send-DebugMessage "[SKIP-NOPRICE] $($sku.Name) - no price found"}
        continue 
    }
    
    if ($price -gt [double]$MaxPrice) { 
        if ($VerboseDebug) {Send-DebugMessage "[SKIP-PRICE] $($sku.Name) at $price > $MaxPrice"}
        continue 
    }
    
    $obj = New-Object PSObject -Property @{
        Name              = $sku.Name
        vCPUs             = $vcpus
        MemoryGB          = $memoryGB
        PricePerHourUSD   = $price
        HyperVGenerations = $hyperV
    }
    
    $candidates += $obj
    if ($VerboseDebug) {Send-DebugMessage "[CANDIDATE] Added $($sku.Name) - $vcpus vCPU / $memoryGB GB @ $price/hr"}
}

Send-DebugMessage "[INFO] Found $($candidates.count) candidates."

# Select final size - only from candidates (price-respecting)
$selected = $null

if ($candidates.Count -gt 0) {
    $sorted = $candidates | Sort-Object PricePerHourUSD, vCPUs, MemoryGB
    $selected = $sorted[0]
    
    $priceValue = if ($null -ne $selected.PricePerHourUSD -and $selected.PricePerHourUSD -gt 0) {
        [math]::Round([double]$selected.PricePerHourUSD, 4)
    } else { "unknown" }
    $priceDisplay = if ($priceValue -ne "unknown") { "`$${priceValue}" } else { $priceValue }
    
    Send-DebugMessage "[SUCCESS] Selected cheapest valid: $($selected.Name) - $($selected.vCPUs) vCPU / $($selected.MemoryGB) GB @ $($priceDisplay)/hr"
} else {
    Send-DebugMessage "[ERROR] No VM size found meeting ALL constraints (incl. price <= $MaxPrice/hr) in $Location for TargetSpec: $TargetSpec out of $($allSkus.Count) eligible sizes. Setting size to default: $defaultSize"
    Set-LabVariable -Name VMSize -Value $defaultSize
    return $true
}

# Output for deployment
$DeploymentScriptOutputs = @{
    vmSize = $selected.Name
    pricePerHour = if ($null -ne $selected.PricePerHourUSD -and $selected.PricePerHourUSD -gt 0) {
        [math]::Round([double]$selected.PricePerHourUSD, 4)
    } else { "unknown" }
}

Set-LabVariable -Name VMSize -Value $selected.Name
Set-LabVariable -Name VMPrice -Value $selected.PricePerHourUSD

Send-DebugMessage "[FINAL] VM Size selected: $($selected.Name)"

if ($ScriptDebug) {
    Send-LabNotification -Message "[Debug] $($ScriptTitle):`n-------`n$($Global:MessageBuffer)"
}

Return $True
