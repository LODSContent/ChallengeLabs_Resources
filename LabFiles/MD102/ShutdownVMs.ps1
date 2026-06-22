<#
   Title: Shut Down All Running VMs
   Description: Authenticates using a service principal and deallocates all running virtual
                machines across the entire subscription. Skips VMs already stopped/deallocated.
   Target: Azure
   Version: 2026.06.22.0004 - Template.v4.0
#>

# Parameters
$TenantName         = '@lab.Variable(TenantName)'
$ScriptingAppId     = '@lab.Variable(ScriptingAppId)'
$ScriptingAppSecret = '@lab.Variable(ScriptingAppSecret)'
$SubscriptionId     = '@lab.Variable(SubscriptionId)'

# Set defaults
$result = $false
$ErrorActionPreference = "Stop"
$wrapperLineCount = 104

# Debug toggle
$scriptDebug = '@lab.Variable(debug)' -in 'Yes','True' -or '@lab.Variable(Debug)' -in 'Yes','True'
$debugLog    = [System.Collections.Generic.List[string]]::new()
if ($scriptDebug) { Write-Output "Debug mode is enabled." }

# ── Helpers ─────────────────────────────────────────────────────────────────────

# Write-Step and Write-Debug append to $debugLog only - no Write-Output inside
# functions that return values, to prevent pipeline contamination.
function Write-Step {
    param([Parameter(Mandatory)][string] $Message)
    $line = "[$(Get-Date -Format 'HH:mm:ss')] $Message"
    $script:debugLog.Add($line)
}

function Write-Debug {
    param([Parameter(Mandatory)][string] $Message)
    $script:debugLog.Add($Message)
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

function Get-AzBearerToken {
    param(
        [Parameter(Mandatory)][string] $TenantName,
        [Parameter(Mandatory)][string] $ClientId,
        [Parameter(Mandatory)][string] $ClientSecret
    )
    $body = @{
        grant_type    = 'client_credentials'
        client_id     = $ClientId
        client_secret = $ClientSecret
        resource      = 'https://management.azure.com/'
    }
    $response = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantName/oauth2/token" -Body $body -ContentType 'application/x-www-form-urlencoded' -ErrorAction Stop
    return $response.access_token
}

function Get-AuthHeader {
    param([Parameter(Mandatory)][string] $Token)
    return @{ Authorization = "Bearer $Token" }
}

# Performs a POST ARM call that may return 202 for a long-running operation and polls to completion.
function Invoke-ArmPost {
    param(
        [Parameter(Mandatory)][string]    $Uri,
        [Parameter(Mandatory)][hashtable] $Headers,
        [int]                             $TimeoutSecs = 300
    )

    $response = Invoke-WebRequest -Method Post -Uri $Uri -Headers $Headers -ContentType 'application/json' -ErrorAction Stop

    if ($response.StatusCode -notin 201, 202) { return }

    $pollUrl = $response.Headers['Azure-AsyncOperation']
    if (-not $pollUrl) { $pollUrl = $response.Headers['Location'] }
    if (-not $pollUrl) { return }
    if ($pollUrl -is [array]) { $pollUrl = $pollUrl[0] }

    $deadline = (Get-Date).AddSeconds($TimeoutSecs)
    $status   = $null

    do {
        Start-Sleep -Seconds 10
        $poll   = Invoke-RestMethod -Method Get -Uri $pollUrl -Headers $Headers -ErrorAction Stop
        $status = if ($poll.PSObject.Properties['status']) { $poll.status }
                  elseif ($poll.PSObject.Properties['provisioningState']) { $poll.provisioningState }
                  else { $null }
        Write-Debug "  Deallocate poll status: $status"
    }
    until ($status -in 'Succeeded', 'Canceled', 'Failed' -or (Get-Date) -gt $deadline)

    if ($status -eq 'Failed')    { throw "Deallocate operation failed for $Uri" }
    if ($status -ne 'Succeeded') { throw "Deallocate operation timed out for $Uri" }
}

# ── Main ─────────────────────────────────────────────────────────────────────────

function main {
    Write-Debug "Begin main routine."

    Assert-ResolvedLabValue -Name 'TenantName'         -Value $TenantName
    Assert-ResolvedLabValue -Name 'ScriptingAppId'     -Value $ScriptingAppId
    Assert-ResolvedLabValue -Name 'ScriptingAppSecret' -Value $ScriptingAppSecret
    Assert-ResolvedLabValue -Name 'SubscriptionId'     -Value $SubscriptionId

    Write-Step "Acquiring Azure bearer token."
    $token   = Get-AzBearerToken -TenantName $TenantName -ClientId $ScriptingAppId -ClientSecret $ScriptingAppSecret
    $headers = Get-AuthHeader -Token $token
    Write-Step "Authentication succeeded."

    $ArmBase = 'https://management.azure.com'
    $apiComp = 'api-version=2023-03-01'

    # Enumerate all VMs in the subscription.
    # instanceView expand is not supported at subscription scope - power state is fetched per VM below.
    Write-Step "Enumerating all VMs in subscription."
    $uri    = "$ArmBase/subscriptions/$SubscriptionId/providers/Microsoft.Compute/virtualMachines?$apiComp"
    $page   = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ErrorAction Stop
    $allVms = [System.Collections.Generic.List[object]]::new()
    foreach ($v in $page.value) { $allVms.Add($v) }

    while ($page.nextLink) {
        $page = Invoke-RestMethod -Method Get -Uri $page.nextLink -Headers $headers -ErrorAction Stop
        foreach ($v in $page.value) { $allVms.Add($v) }
    }

    Write-Step "Found $($allVms.Count) VM(s) in subscription. Checking power state of each."

    $running = [System.Collections.Generic.List[object]]::new()

    foreach ($vm in $allVms) {
        $vmName = $vm.name
        # Resource ID format: /subscriptions/{sub}/resourceGroups/{rg}/providers/...
        # Split on '/' yields: ['', 'subscriptions', '{sub}', 'resourceGroups', '{rg}', ...]
        $rgName = ($vm.id -split '/')[4]
        Write-Debug "  Discovered VM: '$vmName' in resource group '$rgName' (id: $($vm.id))"

        $ivUri = "$ArmBase/subscriptions/$SubscriptionId/resourceGroups/$rgName/providers/Microsoft.Compute/virtualMachines/$vmName/instanceView?$apiComp"

        try {
            $iv          = Invoke-RestMethod -Method Get -Uri $ivUri -Headers $headers -ErrorAction Stop
            $powerStatus = $iv.statuses | Where-Object { $_.code -like 'PowerState/*' } | Select-Object -First 1
            $powerState  = if ($powerStatus) { $powerStatus.code } else { 'PowerState/unknown' }
            Write-Debug "  $vmName ($rgName): $powerState"

            if ($powerState -eq 'PowerState/running') {
                $running.Add(@{ Name = $vmName; ResourceGroup = $rgName })
            }
        }
        catch {
            Write-Step "  WARNING: Could not get instance view for '$vmName' in '$rgName'. Skipping. $($_.Exception.Message)"
        }
    }

    if ($running.Count -eq 0) {
        Write-Step "No running VMs found. Nothing to do."
        # Scripter/AI: No running VMs - subscription already quiesced
        Write-Debug "End main routine."
        return $true
    }

    Write-Step "$($running.Count) running VM(s) found. Deallocating."

    $failed = 0

    foreach ($vm in $running) {
        $vmName = $vm['Name']
        $rgName = $vm['ResourceGroup']

        Write-Step "Deallocating '$vmName' in resource group '$rgName'."
        $deallocUri = "$ArmBase/subscriptions/$SubscriptionId/resourceGroups/$rgName/providers/Microsoft.Compute/virtualMachines/$vmName/deallocate?$apiComp"

        try {
            Invoke-ArmPost -Uri $deallocUri -Headers $headers
            Write-Step "  '$vmName' deallocated successfully."
            # Scripter/AI: VM was successfully deallocated
        }
        catch {
            Write-Step "  ERROR deallocating '$vmName': $($_.Exception.Message)"
            # Scripter/AI: VM failed to deallocate - logged but continuing to next VM
            $failed++
        }
    }

    if ($failed -gt 0) {
        Write-Step "$failed VM(s) failed to deallocate. Check debug log for details."
        # Scripter/AI: Partial failure - some VMs did not deallocate
        Write-Debug "End main routine."
        return $false
    }

    Write-Step "All running VMs deallocated successfully."
    # Scripter/AI: All VMs successfully deallocated
    Write-Debug "End main routine."
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
