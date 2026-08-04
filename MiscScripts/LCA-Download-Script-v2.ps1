<#
   Title: Download & Extract Lab Files from GitHub (Clean Final Folders)
   Description: Downloads files from GitHub. If UnZip = "True", downloads to temp, extracts to
                 final destination folder, then deletes the zip. If UnZip <> "True", downloads to
                 temp first, then moves into place (never partially overwrites a good existing file).
                 Optional SkipIfExists = "True" skips re-downloading if the destination already
                 has content. Returns $true only on full success.
   Target: Windows PowerShell 5.1+ (Lab Environments)
   Version: 2025.12.03 - Template.v5.0
#>

# === FILE DOWNLOAD LIST ===
# Source        = raw GitHub URL
# Destination   = final location:
#                 - If UnZip = "True"  -> folder where contents will be extracted
#                 - If UnZip <> "True" -> full file path, or a folder path
#                                          (folder path auto-appends source filename)
# UnZip         = "True" -> extract only (zip goes to temp and is deleted)
# SkipIfExists  = "True" (optional) -> skip download entirely if the destination already
#                 has content (file exists for non-zip, folder is non-empty for zip)
$manifest = @(
    @{
        Source       = "https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/LabFiles/MADDSO/LabUsers/LabUsers.csv"
        Destination  = "D:\LabFiles\LabUsers.csv"
        UnZip        = "False"
        SkipIfExists = "False"
    }
    @{
        Source       = "https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/LabFiles/MADDSO/LabUsers/New-ADUsers.ps1"
        Destination  = "D:\LabFiles\New-ADUsers.ps1"
        UnZip        = "False"
        SkipIfExists = "False"
    }
    @{
        Source       = "https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/LabFiles/MADDSO/TestFiles.zip"
        Destination  = "D:\LabFiles\TestFiles"           # Folder only! Contents go here
        UnZip        = "True"
        SkipIfExists = "False"
    }
    # Add more as needed
)

# === CONFIG ===
# Retries are primarily here for lab-boot conditions where networking isn't fully up yet
# by the time this script runs. Delay ramps (5s, 10s, 15s...) up to $maxRetryDelaySeconds,
# giving a generous overall window for the network stack to come online, while permanent
# HTTP errors (bad path, auth, etc.) skip the remaining retries immediately - see
# Test-PermanentHttpFailure below.
$maxRetries           = 20
$initialRetryDelaySeconds = 5
$maxRetryDelaySeconds     = 30
$downloadTimeoutSec   = 60
$LogFolder            = "C:\LabLogs"          # Deliberately independent of the file Destinations
                                               # above, so log location stays stable even if
                                               # those destinations change. Falls back to
                                               # $env:TEMP if this folder can't be created.
$logFileName          = "lca_status.log"

# Debug toggle - lab platform compatible
$scriptDebug = '@lab.Variable(debug)' -in 'Yes','True' -or '@lab.Variable(Debug)' -in 'Yes','True'

# === STATUS BUFFER / LOGGING ===
# Every status line is (1) appended to an in-memory buffer that gets dumped in a single
# Write-Output/Write-Error call at the very end, and (2) appended to disk immediately, so
# the log survives even if the script terminates unexpectedly before that final dump.
# NOTE: Write-Error is intentionally never called mid-script - the platform stops capturing
# any further output once an error is thrown, so all Write-Error usage is deferred to the
# single call at the end of the script.
$script:statusBuffer = New-Object System.Collections.Generic.List[string]

try {
    if (-not (Test-Path -Path $LogFolder)) {
        New-Item -Path $LogFolder -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
    $script:logFile = Join-Path $LogFolder $logFileName
    # Prove the log file is writable now, before we rely on it throughout the run
    Add-Content -Path $script:logFile -Value "" -ErrorAction Stop
}
catch {
    $script:logFile = Join-Path $env:TEMP $logFileName
}

function Write-Status {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet("Info","Warning","Error")][string]$Level = "Info"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] [$Level] $Message"

    $script:statusBuffer.Add($line)

    try {
        Add-Content -Path $script:logFile -Value $line -ErrorAction Stop
    } catch {
        # Logging failure should never take down the script itself
    }

    if ($scriptDebug) {
        switch ($Level) {
            "Warning" { Write-Warning $line }
            "Error"   { Write-Warning $line }   # deliberately Write-Warning, not Write-Error - see note above
            default   { Write-Output $line }
        }
    }
}

function Get-RemoteFileSize {
    # Returns [int64] Content-Length if the server provided one, otherwise $null
    param($Response)
    try {
        $headerValue = $Response.Headers["Content-Length"]
        if ($headerValue) { return [int64]$headerValue }
    } catch {}
    return $null
}

function Test-PermanentHttpFailure {
    # 4xx client errors (other than 429 rate-limit) are treated as permanent - retrying is
    # pointless for a bad path/auth failure. IMPORTANT: connection-level failures (DNS not
    # resolving, network unreachable, connection refused/timed out - the classic "lab VM's
    # networking isn't fully up yet" case) throw exceptions with NO .Response object at all,
    # so this function returns $null for those and they correctly fall through to the
    # normal retry path below.
    param($Exception)
    try {
        $statusCode = [int]$Exception.Response.StatusCode
        if ($statusCode -ge 400 -and $statusCode -lt 500 -and $statusCode -ne 429) {
            return $statusCode
        }
    } catch {}
    return $null
}

function main {
    Write-Status "=== LCA run started ==="

    # Safety-net cleanup of any orphaned temp files from a prior run that terminated abnormally
    try {
        Get-ChildItem -Path $env:TEMP -Filter "LCA_*" -ErrorAction SilentlyContinue |
            Remove-Item -Force -ErrorAction SilentlyContinue
    } catch {}

    $allSuccess = $true

    foreach ($file in $manifest) {
        $uri          = $file.Source
        $finalPath    = $file.Destination
        $shouldUnzip  = $file.UnZip -eq "True"
        $skipIfExists = $file.SkipIfExists -eq "True"
        $downloadPath = $finalPath

        Write-Status "--- Processing: $uri ---"

        # Determine final destination folder / path
        if ($shouldUnzip) {
            $destFolder = $finalPath
        } else {
            $pathExists          = Test-Path -Path $finalPath
            $pathIsFolder        = Test-Path -Path $finalPath -PathType Container
            $hasTrailingSlash    = $finalPath.EndsWith('\') -or $finalPath.EndsWith('/')
            $pathHasExtension    = -not [string]::IsNullOrWhiteSpace([System.IO.Path]::GetExtension($finalPath))
            $nonExistingNoExtDir = (-not $pathExists) -and (-not $pathHasExtension)
            $destinationIsFolder = $pathIsFolder -or $hasTrailingSlash -or $nonExistingNoExtDir

            if ($destinationIsFolder) {
                $sourceFileName = [System.IO.Path]::GetFileName(([System.Uri]$uri).AbsolutePath)
                $downloadPath   = Join-Path -Path $finalPath -ChildPath $sourceFileName
                $destFolder     = $finalPath
            } else {
                $downloadPath = $finalPath
                $destFolder   = Split-Path -Path $downloadPath -Parent
            }
        }

        # Ensure destination folder exists
        if (-not (Test-Path -Path $destFolder)) {
            try {
                New-Item -Path $destFolder -ItemType Directory -Force -ErrorAction Stop | Out-Null
                Write-Status "Created folder: $destFolder"
            }
            catch {
                Write-Status "Failed to create folder '$destFolder': $($_.Exception.Message)" "Error"
                $allSuccess = $false
                continue
            }
        }

        # === SkipIfExists check ===
        if ($skipIfExists) {
            $alreadyPresent = $false
            if ($shouldUnzip) {
                $alreadyPresent = (Test-Path $destFolder) -and
                    ((Get-ChildItem -Path $destFolder -Force -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0)
            } else {
                $alreadyPresent = Test-Path -Path $downloadPath -PathType Leaf
            }

            if ($alreadyPresent) {
                Write-Status "SkipIfExists = True and destination already has content - skipping $uri"
                continue
            }
        }

        # === Download to a real temp file first (never write directly to the final path) ===
        $sourceExtension = [System.IO.Path]::GetExtension(([System.Uri]$uri).AbsolutePath)
        if ([string]::IsNullOrWhiteSpace($sourceExtension)) { $sourceExtension = ".tmp" }
        $tempFile = Join-Path $env:TEMP ("LCA_{0}{1}" -f ([guid]::NewGuid().ToString()), $sourceExtension)

        $downloaded = $false
        $permanentFailureCode = $null
        $attempt = 0

        while (-not $downloaded -and -not $permanentFailureCode -and $attempt -lt $maxRetries) {
            $attempt++
            try {
                Write-Status "Downloading [Attempt $attempt/$maxRetries]: $uri -> $tempFile"

                $response = Invoke-WebRequest -Uri $uri -OutFile $tempFile -PassThru `
                    -UseBasicParsing -TimeoutSec $downloadTimeoutSec -ErrorAction Stop

                $actualSize   = (Get-Item $tempFile).Length
                $expectedSize = Get-RemoteFileSize -Response $response

                if ($actualSize -le 0) {
                    throw "Downloaded file is empty."
                }

                # Minimal validation: if the server told us the expected size, it must match.
                if ($expectedSize -and ($actualSize -ne $expectedSize)) {
                    throw "Size mismatch - expected $expectedSize bytes, got $actualSize bytes."
                }

                $downloaded = $true
                Write-Status "Downloaded successfully ($actualSize bytes)"
            }
            catch {
                $permanentFailureCode = Test-PermanentHttpFailure -Exception $_.Exception

                if ($permanentFailureCode) {
                    Write-Status "Permanent HTTP $permanentFailureCode for $uri - not retrying." "Error"
                } else {
                    $hasHttpResponse = $null -ne $_.Exception.Response
                    $failureKind = if ($hasHttpResponse) { "HTTP error" } else { "connection/network error (e.g. networking not yet ready)" }
                    Write-Status "Attempt $attempt failed - $failureKind`: $($_.Exception.Message)" "Warning"

                    if (Test-Path $tempFile) { Remove-Item $tempFile -Force -ErrorAction SilentlyContinue }

                    if ($attempt -lt $maxRetries) {
                        $retryDelay = [Math]::Min($initialRetryDelaySeconds * $attempt, $maxRetryDelaySeconds)
                        Write-Status "Waiting $retryDelay second(s) before retry $($attempt + 1)/$maxRetries..."
                        Start-Sleep -Seconds $retryDelay
                    }
                }
            }
        }

        if (-not $downloaded) {
            if ($permanentFailureCode) {
                Write-Status "PERMANENT FAILURE (HTTP $permanentFailureCode): $uri" "Error"
            } else {
                Write-Status "PERMANENT FAILURE after $maxRetries attempts: $uri" "Error"
            }
            $allSuccess = $false
            if (Test-Path $tempFile) { Remove-Item $tempFile -Force -ErrorAction SilentlyContinue }
            continue
        }

        # === Move into place / extract ===
        if ($shouldUnzip) {
            try {
                Write-Status "Extracting $tempFile -> $destFolder"
                Expand-Archive -Path $tempFile -DestinationPath $destFolder -Force -ErrorAction Stop
                Write-Status "Extraction successful."
            }
            catch {
                Write-Status "Extraction failed: $($_.Exception.Message)" "Error"
                $allSuccess = $false
            }
            finally {
                if (Test-Path $tempFile) {
                    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
                    Write-Status "Deleted temporary zip."
                }
            }
        }
        else {
            try {
                Move-Item -Path $tempFile -Destination $downloadPath -Force -ErrorAction Stop
                Write-Status "Moved into place: $downloadPath"
            }
            catch {
                Write-Status "Failed to move '$tempFile' to '$downloadPath': $($_.Exception.Message)" "Error"
                $allSuccess = $false
                if (Test-Path $tempFile) { Remove-Item $tempFile -Force -ErrorAction SilentlyContinue }
            }
        }
    }

    if ($allSuccess) {
        Write-Status "=== All operations completed successfully. ==="
    } else {
        Write-Status "=== One or more operations failed. ===" "Error"
    }

    return $allSuccess
}

# === Execute main routine ===
# $ErrorActionPreference is set to Stop so any unexpected non-terminating-turned-terminating
# error inside main() is still caught here rather than silently continuing.
$ErrorActionPreference = "Stop"
$result = $false

try {
    $result = main
}
catch {
    Write-Status "UNHANDLED EXCEPTION: $($_.Exception.Message)" "Error"
    $result = $false
}

# === Final output ===
# Exactly one Write-Output OR Write-Error call, dumping the full buffered history.
# This guarantees the platform captures everything on failure (since nothing was written
# via Write-Error earlier in the run to prematurely cut off subsequent messaging), and
# on success the full log is still emitted via Write-Output for local/manual debugging
# even though the platform itself does nothing with it.
$fullLog = $script:statusBuffer -join "`n"

if ($result) {
    Write-Output $fullLog
} else {
    Write-Error $fullLog
}

return $result
