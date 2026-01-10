param(
    [string]$TargetSpec   = '@lab.Variable(VMTargetSpec)',          # Format: c<cpu>r<ram>g<gen>  e.g. c2r4g2, c4r16g1
    [string]$MaxPrice     = '0.20',            # Max on-demand price per hour (USD)
    [string]$MaxCPU       = '4',               # Maximum allowed vCPUs
    [string]$MaxRAM       = '32',              # Maximum allowed RAM in GB
    [string]$Location     = '@lab.CloudResourceGroup(RG1).Location',  # Location
    [switch]$Debug
)

# Authentication & Location
$context = Get-AzContext

$TargetSpec = if ([string]::IsNullOrWhiteSpace($TargetSpec) -or $TargetSpec -eq '@lab.Variable(VMTargetSpec)') {
    'c2r4g1'
} else {
    $TargetSpec
}

<#
$location = if ([string]::IsNullOrWhiteSpace($Location) -or $Location -eq '@lab.CloudResourceGroup(RG1).Location') {
    $context.Location
} else {
    $Location
}
#>

if ($Debug) {
    Write-Output "[INFO] Starting VM size selection in location: $location"
    Write-Output "[INFO] Target spec: $TargetSpec | MaxPrice: $MaxPrice | MaxCPU: $MaxCPU vCPU | MaxRAM: $MaxRAM GB"
}

# Parse TargetSpec: c<cpu>r<ram>g<gen>
$targetCPU   = 2
$targetRAM   = 4.0
$requiredGen = '1'

if ($TargetSpec -match '^c(\d+)r(\d+(?:\.\d+)?)g([12])$') {
    $targetCPU   = [int]$Matches[1]
    $targetRAM   = [double]$Matches[2]
    $requiredGen = $Matches[3]
} else {
    if ($Debug) {
        Write-Output "[WARN] Invalid TargetSpec format '$TargetSpec'. Using defaults: c2r4g1"
    }
}

$minVCPU     = $targetCPU
$minMemoryGB = $targetRAM

$maxVCPUNum = if ([int]::TryParse($MaxCPU,   [ref]$null)) { [int]$MaxCPU   } else { 9999 }
$maxRAMNum  = if ([double]::TryParse($MaxRAM, [ref]$null)) { [double]$MaxRAM } else { 9999.0 }

if ($Debug) {
    Write-Output "[INFO] Parsed → Min: ≥ $minVCPU vCPU / ≥ $minMemoryGB GB (Gen $requiredGen)"
    Write-Output "[INFO] Max limits → ≤ $maxVCPUNum vCPU / ≤ $maxRAMNum GB | ≤ $$MaxPrice/hr"
}

# Get available VM SKUs
$allSkus = Get-AzComputeResourceSku -Location $location | Where-Object {
    $_.ResourceType -eq 'virtualMachines' -and
    ($_.Restrictions.Count -eq 0 -or -not ($_.Restrictions.ReasonCode -contains 'NotAvailableForSubscription'))
}

if (-not $allSkus) {
    throw "[ERROR] No VM sizes available in location $location"
}

# Bulk price fetch - primary method
$priceDict = @{}

try {
    if ($Debug) {
        Write-Output "[INFO] Fetching bulk VM prices for $location..."
    }
    $bulkFilter = "serviceName eq 'Virtual Machines' and armRegionName eq '$location' and priceType eq 'Consumption'"
    $bulkUri = "https://prices.azure.com/api/retail/prices?api-version=2023-01-01-preview&`$filter=$([uri]::EscapeDataString($bulkFilter))"

    $response = Invoke-RestMethod -Uri $bulkUri -Method Get -TimeoutSec 30

    foreach ($item in $response.Items) {
        $sku = $item.armSkuName
        $priceRaw = $item.unitPrice

        # Only accept reasonable prices and exclude Spot/Low Priority
        if ($priceRaw -and $priceRaw -gt 0.01 -and $priceRaw -lt 5 -and
            $item.meterName -notmatch 'Spot|Low Priority|LowPriority') {
            
            $price = [double]$priceRaw  # Force conversion to double
            
            if (-not $priceDict.ContainsKey($sku) -or $price -lt $priceDict[$sku]) {
                $priceDict[$sku] = $price
            }
        }
    }

    if ($Debug) {
        if ($priceDict.Count -gt 0) {
            Write-Output "[SUCCESS] Bulk fetch complete - $($priceDict.Count) VM prices loaded"
        } else {
            Write-Output "[WARN] Bulk response empty - will try per-SKU fallback"
        }
    }
}
catch {
    if ($Debug) {
        Write-Output "[WARN] Bulk price fetch failed: $($_.Exception.Message) → using per-SKU fallback"
    }
}

# Price lookup function
function Get-VMHourlyPrice {
    param(
        [string]$skuName,
        [string]$region
    )

    # Prefer bulk dictionary
    if ($priceDict -and $priceDict.ContainsKey($skuName)) {
        return $priceDict[$skuName]
    }

    # Fallback single query (rare)
    if ($Debug) {
        Write-Output "[FALLBACK] Single price query for $skuName"
    }

    Start-Sleep -Milliseconds 400

    $filter = "serviceName eq 'Virtual Machines' and armRegionName eq '$region' and armSkuName eq '$skuName' and priceType eq 'Consumption'"
    $uri = "https://prices.azure.com/api/retail/prices?api-version=2023-01-01-preview&`$filter=$([uri]::EscapeDataString($filter))"

    try {
        $response = Invoke-RestMethod -Uri $uri -Method Get -TimeoutSec 15
        $validItems = $response.Items | Where-Object {
            $_.unitPrice -gt 0.01 -and $_.unitPrice -lt 5 -and
            $_.meterName -notmatch 'Spot|Low Priority|LowPriority'
        }
        
        if ($validItems.Count -gt 0) {
            $lowest = ($validItems | Sort-Object unitPrice | Select-Object -First 1).unitPrice
            $price = [double]$lowest
            $priceDict[$skuName] = $price
            return $price
        }
    }
    catch {
        if ($Debug) {
            Write-Output "[WARN] Single price query failed for $skuName → $($_.Exception.Message)"
        }
    }

    return $null
}

# Collect candidates
$candidates = @()
$fallbackCandidates = @()

foreach ($sku in $allSkus) {
    $caps = @{}
    foreach ($cap in $sku.Capabilities) { $caps[$cap.Name] = $cap }

    # x86 only
    $cpuArch = if ($caps.ContainsKey('CpuArchitectureType')) { $caps['CpuArchitectureType'].Value } else { 'x64' }
    if ($cpuArch -ne 'x64') { continue }

    # Exclude confidential, GPU, HPC, etc.
    $excludedPrefixes = @('DC', 'EC', 'HB', 'HC', 'HX', 'ND', 'NC', 'NV', 'NP', 'H')
    $excluded = $false
    foreach ($prefix in $excludedPrefixes) {
        if ($sku.Name -like "*_$prefix*") {
            $excluded = $true
            break
        }
    }
    if ($excluded) {
        if ($Debug) { Write-Output "[EXCLUDE] Skipping specialized size: $($sku.Name)" }
        continue
    }

    # Generation check
    $hyperV = if ($caps.ContainsKey('HyperVGenerations')) { $caps['HyperVGenerations'].Value } else { 'V1' }
    $supportsGen = if ($requiredGen -eq '1') { $hyperV -match 'V1' } else { $hyperV -match 'V2' }
    if (-not $supportsGen) { continue }

    # Specs
    $vcpus = if ($caps.ContainsKey('vCPUs') -and $caps['vCPUs'].Value) { [int]$caps['vCPUs'].Value } else { 0 }
    $memoryGB = if ($caps.ContainsKey('MemoryGB') -and $caps['MemoryGB'].Value) { [double]$caps['MemoryGB'].Value } else { 0.0 }

    # Apply min + max filters
    if ($vcpus -lt $minVCPU -or $vcpus -gt $maxVCPUNum) { continue }
    if ($memoryGB -lt $minMemoryGB -or $memoryGB -gt $maxRAMNum) { continue }

    $price = Get-VMHourlyPrice -skuName $sku.Name -region $location

    $obj = New-Object PSObject -Property @{
        Name              = $sku.Name
        vCPUs             = $vcpus
        MemoryGB          = $memoryGB
        PricePerHourUSD   = $price
        HyperVGenerations = $hyperV
    }

    if ($null -ne $price -and $price -le [double]$MaxPrice) {
        $candidates += $obj
    }
    else {
        if ($vcpus -eq $targetCPU -and $memoryGB -ge $targetRAM) {
            $fallbackCandidates += $obj
            if ($Debug) {
                Write-Output "[FALLBACK POOL] Added $($sku.Name) ($vcpus vCPU / $memoryGB GB)"
            }
        }
    }
}

# Select final size
$selected = $null

if ($candidates.Count -gt 0) {
    $sorted = $candidates | Sort-Object PricePerHourUSD, vCPUs, MemoryGB
    $selected = $sorted[0]
    
    $priceValue = if ($null -ne $selected.PricePerHourUSD -and $selected.PricePerHourUSD -gt 0) {
        [math]::Round([double]$selected.PricePerHourUSD, 4)
    } else {
        "unknown"
    }
    $priceDisplay = if ($priceValue -ne "unknown") { "`$${priceValue}" } else { $priceValue }

    if ($Debug) {
        Write-Output "[SUCCESS] Selected (normal path): $($selected.Name)"
        Write-Output ("         → {0} vCPU / {1} GB @ {2}/hr" -f $selected.vCPUs, $selected.MemoryGB, $priceDisplay)
    }
}
elseif ($fallbackCandidates.Count -gt 0) {
    $sortedFallback = $fallbackCandidates | Sort-Object vCPUs, MemoryGB
    $selected = $sortedFallback[0]
    
    $priceValue = if ($null -ne $selected.PricePerHourUSD -and $selected.PricePerHourUSD -gt 0) {
        [math]::Round([double]$selected.PricePerHourUSD, 4)
    } else {
        "unknown"
    }
    $priceDisplay = if ($priceValue -ne "unknown") { "`$${priceValue}" } else { $priceValue }

    if ($Debug) {
        Write-Output "[FALLBACK] Price issues → selected closest to target: $($selected.Name)"
        Write-Output ("         → {0} vCPU / {1} GB @ {2}/hr" -f $selected.vCPUs, $selected.MemoryGB, $priceDisplay)
    }
}
else {
    throw "[ERROR] No suitable VM size found matching constraints in $location"
}

# Output for deployment (always shown, even without Debug)
$DeploymentScriptOutputs = @{
    vmSize       = $selected.Name
    pricePerHour = if ($null -ne $selected.PricePerHourUSD -and $selected.PricePerHourUSD -gt 0) {
        [math]::Round([double]$selected.PricePerHourUSD, 4)
    } else {
        "unknown"
    }
}

if ($Debug) {
    Write-Output "[FINAL] VM Size selected: $($selected.Name)"
}

Set-LabVariable -Name VMSize -Value $selected.Name
Set-LabVariable -Name VMPrice -Value $selected.PricePerHourUSD

Return $True
