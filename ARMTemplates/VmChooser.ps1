param(
    [string]$location = "eastus2",
    [string]$preferredSize = "",
    [string]$allowedSizes = "",
    [int]$cpu = 0,
    [int]$memory = 0
)

Write-Output "[INFO] Starting VM size selection for location: $location"

# Authenticate with current identity
Connect-AzAccount -Identity | Out-Null

# === GET ALLOWED SIZES ===
if ([string]::IsNullOrWhiteSpace($allowedSizes)) {
    Write-Output "[INFO] Downloading allowed sizes from GitHub..."
    try {
        $raw = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/ARMTemplates/AllowedVmSizes.txt" -TimeoutSec 15
        $allowedSizes = $raw -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ }
        Write-Output "[INFO] Downloaded $($allowedSizes.Count) allowed sizes."
    }
    catch {
        Write-Output "[ERROR] Failed to download allowed sizes: $($_.Exception.Message)"
        throw "Cannot proceed without allowed sizes list."
    }
}
else {
    $allowedSizes = $allowedSizes -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    Write-Output "[INFO] Using provided allowedSizes ($($allowedSizes.Count) sizes)."
}

if ($allowedSizes.Count -eq 0) {
    Write-Output "[ERROR] No allowed VM sizes found."
    throw "No allowed sizes available."
}

# Test Break:
# === OUTPUT ===
$DeploymentScriptOutputs = @{
    vmSize   = "Standard_B1ls"
    zone     = "3"
    vCPUs    = 0
    memoryGB = 0
}
Return


# === GET ZONAL + QUOTA-FREE SKUs ===
Write-Output "[INFO] Querying zonal VM sizes in $location..."
$allSkus = Get-AzComputeResourceSku -Location $location | Where-Object {
    $_.ResourceType -eq 'virtualMachines' -and
    $_.Name -in $allowedSizes -and
    $_.LocationInfo[0].Zones.Count -gt 0 -and
    (-not ($_.Restrictions | Where-Object {
        $_.ReasonCode -eq 'NotAvailableForSubscription' -and
        $_.RestrictionInfo.Locations -contains $location -and
        ($null -eq $_.RestrictionInfo.Zones -or $_.RestrictionInfo.Zones.Count -eq 0)
    }))
}

if (-not $allSkus) {
    Write-Output "[ERROR] No zonal sizes found matching allowed list."
    throw "No zonal VM sizes available."
}

# === PER-ZONE QUOTA FILTERING ===
Write-Output "[INFO] Filtering $($allSkus.Count) SKUs for per-zone quota blocks..."
$skusWithStats = $allSkus | ForEach-Object {
    $allZones = $_.LocationInfo[0].Zones
    $blockedZones = @()

    $_.Restrictions | ForEach-Object {
        if ($_.ReasonCode -eq 'NotAvailableForSubscription' -and
            $_.RestrictionInfo.Locations -contains $location -and
            $null -ne $_.RestrictionInfo.Zones) {
            $blockedZones += $_.RestrictionInfo.Zones
        }
    }

    $availableZones = $allZones | Where-Object { $_ -notin $blockedZones }
    if ($availableZones.Count -eq 0) {
        Write-Output "[WARN] $($_.Name) has no available zones — excluded."
        return $null
    }

    $vcpus = ($_.Capabilities | Where-Object Name -eq 'vCPUs').Value
    $memgb = ($_.Capabilities | Where-Object Name -eq 'MemoryGB').Value

    [PSCustomObject]@{
        Sku            = $_
        Name           = $_.Name
        vCPUs          = if ($vcpus) { [int]$vcpus } else { 0 }
        MemoryGB       = if ($memgb) { [double]$memgb } else { 0 }
        AvailableZones = $availableZones
    }
} | Where-Object { $null -ne $_ }

if (-not $skusWithStats) {
    Write-Output "[ERROR] No VM sizes have free zones after quota filtering."
    throw "All sizes blocked by per-zone quota."
}

Write-Output "[INFO] $($skusWithStats.Count) deployable SKUs with free zones."

# === SELECTION LOGIC ===
$selected = $null

if (![string]::IsNullOrWhiteSpace($preferredSize)) {
    $match = $skusWithStats | Where-Object Name -eq $preferredSize.Trim() | Select-Object -First 1
    if ($match) {
        $selected = $match
        Write-Output "[INFO] Using preferred size: $($selected.Name) ($($selected.vCPUs)vCPU / $($selected.MemoryGB)GB) — zones: $($selected.AvailableZones -join ', ')"
    }
    else {
        Write-Output "[WARN] Preferred size '$preferredSize' not available or blocked."
    }
}

if (-not $selected -and ($cpu -gt 0 -or $memory -gt 0)) {
    Write-Output "[INFO] Finding match: CPU >= $cpu, Memory >= $memory GB"
    $targetV = if ($cpu -gt 0) { $cpu } else { 1 }
    $targetM = if ($memory -gt 0) { $memory } else { 1 }

    $candidate = $skusWithStats | Where-Object {
        $_.vCPUs -ge $targetV -and $_.MemoryGB -ge $targetM
    } | Sort-Object { [math]::Abs($_.vCPUs - $targetV) + [math]::Abs($_.MemoryGB - $targetM) } | Select-Object -First 1

    if ($candidate) {
        $selected = $candidate
        Write-Output "[INFO] Selected CPU/Memory match: $($selected.Name) — zones: $($selected.AvailableZones -join ', ')"
    }
}

if (-not $selected) {
    $fallback = $skusWithStats | Sort-Object vCPUs, MemoryGB | Select-Object -First 1
    if (-not $fallback) {
        Write-Output "[ERROR] No deployable size found."
        throw "Deployment failed: no VM size available."
    }
    $selected = $fallback
    Write-Output "[INFO] Fallback to smallest: $($selected.Name) — zones: $($selected.AvailableZones -join ', ')"
}

# === FINAL ZONE PICK ===
$zone = ($selected.AvailableZones | Get-Random)
Write-Output "[SUCCESS] Selected: $($selected.Name) in Zone $zone"

# === OUTPUT ===
$DeploymentScriptOutputs = @{
    vmSize   = $selected.Name
    zone     = $zone
    vCPUs    = $selected.vCPUs
    memoryGB = $selected.MemoryGB
}
