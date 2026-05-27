<#
   Title: Download & Extract Lab Files from GitHub (Clean Final Folders)
   Description: Downloads files from GitHub. If UnZip = "True", downloads to temp, extracts to final destination folder, then deletes the zip. Returns $true only on full success.
   Target: Windows PowerShell 5.1+ (Lab Environments)
   Version: 2025.12.03 - Template.v4.2
#>

# === FILE DOWNLOAD LIST ===
# Source      = raw GitHub URL
# Destination = final location:
#               • If UnZip = "True"  → folder where contents will be extracted
#               • If UnZip ≠ "True"  → full file path, or a folder path
#                                        (folder path auto-appends source filename)
# UnZip       = "True" → extract only (zip goes to temp and is deleted)
$manifest = @(
    @{
        Source      = "https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/LabFiles/MADDSO/LabUsers/LabUsers.csv"
        Destination = "D:\LabFiles\LabUsers.csv"
        UnZip       = "False"
    }
    @{
        Source      = "https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/LabFiles/MADDSO/LabUsers/New-ADUsers.ps1"
        Destination = "D:\LabFiles\New-ADUsers.ps1"
        UnZip       = "False"
    }
    @{
        Source      = "https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/LabFiles/MADDSO/TestFiles.zip"
        Destination = "D:\LabFiles\TestFiles"           # ← Folder only! Contents go here
        UnZip       = "True"
    }
    # Add more as needed
)

# Set default return value
$result = $false
$maxRetries = 10

# Debug toggle - lab platform compatible
$scriptDebug = '@lab.Variable(debug)' -in 'Yes','True' -or '@lab.Variable(Debug)' -in 'Yes','True'
if ($scriptDebug) {
    $ErrorActionPreference = "Continue"
    Write-Output "Debug mode is enabled."
}

function main {
    if ($scriptDebug) { Write-Output "Begin main routine." }

    $allSuccess = $true

    foreach ($file in $manifest) {
        $uri         = $file.Source
        $finalPath   = $file.Destination
        $shouldUnzip = $file.UnZip -eq "True"
        $downloadPath = $finalPath

        # Determine final destination folder and create it
        if ($shouldUnzip) {
            $destFolder = $finalPath                    # FinalPath is the folder when unzipping
            $tempZip    = Join-Path $env:TEMP ("LabDownload_{0}.zip" -f [guid]::NewGuid())
        } else {
            $pathExists          = Test-Path -Path $finalPath
            $pathIsFolder        = Test-Path -Path $finalPath -PathType Container
            $hasTrailingSlash    = $finalPath.EndsWith('\\') -or $finalPath.EndsWith('/')
            $pathHasExtension    = -not [string]::IsNullOrWhiteSpace([System.IO.Path]::GetExtension($finalPath))
            $nonExistingNoExtDir = (-not $pathExists) -and (-not $pathHasExtension)
            $destinationIsFolder = $pathIsFolder -or $hasTrailingSlash -or $nonExistingNoExtDir

            if ($destinationIsFolder) {
                if (-not (Test-Path -Path $finalPath)) {
                    New-Item -Path $finalPath -ItemType Directory -Force | Out-Null
                    if ($scriptDebug) { Write-Output "Created folder: $finalPath" }
                }

                $sourceFileName = [System.IO.Path]::GetFileName(([System.Uri]$uri).AbsolutePath)
                $downloadPath   = Join-Path -Path $finalPath -ChildPath $sourceFileName
                $destFolder     = $finalPath
            } else {
                $downloadPath = $finalPath
                $destFolder   = Split-Path -Path $downloadPath -Parent
            }

            $tempZip = $downloadPath                    # Direct download → no temp
        }

        # Ensure destination folder exists
        if (-not (Test-Path -Path $destFolder)) {
            try {
                New-Item -Path $destFolder -ItemType Directory -Force | Out-Null
                if ($scriptDebug) { Write-Output "Created folder: $destFolder" }
            }
            catch {
                if ($scriptDebug) { Write-Error "Failed to create folder '$destFolder': $_" }
                $allSuccess = $false
                continue
            }
        }

        # === Download with retry ===
        $downloaded = $false
        $attempt    = 0

        while (-not $downloaded -and $attempt -lt $maxRetries) {
            $attempt++
            try {
                if ($scriptDebug) { Write-Output "Downloading to temp/final: $tempZip [Attempt $attempt/$maxRetries]" }
                Invoke-WebRequest -Uri $uri -OutFile $tempZip -ErrorAction Stop -UseBasicParsing | Out-Null

                if ((Get-Item $tempZip).Length -gt 0) {
                    $downloaded = $true
                    if ($scriptDebug) { Write-Output "Downloaded successfully ($((Get-Item $tempZip).Length) bytes)" }
                }
            }
            catch {
                if ($scriptDebug) { Write-Warning "Attempt $attempt failed: $($_.Exception.Message)" }
                if ($attempt -lt $maxRetries) { Start-Sleep -Seconds 5 }
            }
        }

        if (-not $downloaded) {
            if ($scriptDebug) { Write-Error "PERMANENT FAILURE: $uri" }
            $allSuccess = $false
            if (Test-Path $tempZip) { Remove-Item $tempZip -Force -ErrorAction SilentlyContinue }
            continue
        }

        # === Extract if needed ===
        if ($shouldUnzip) {
            try {
                if ($scriptDebug) { Write-Output "Extracting $tempZip → $destFolder" }
                Expand-Archive -Path $tempZip -DestinationPath $destFolder -Force -ErrorAction Stop
                if ($scriptDebug) { Write-Output "Extraction successful." }
            }
            catch {
                if ($scriptDebug) { Write-Error "Extraction failed: $_" }
                $allSuccess = $false
            }
            finally {
                if (Test-Path $tempZip) {
                    Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
                    if ($scriptDebug) { Write-Output "Deleted temporary zip." }
                }
            }
        }
        else {
            # Non-zip file: move from temp only if we used a real temp file (shouldn't happen)
            if ($tempZip -ne $downloadPath -and (Test-Path $tempZip)) {
                Move-Item -Path $tempZip -Destination $downloadPath -Force
            }
        }
    }

    if ($allSuccess) {
        if ($scriptDebug) { Write-Output "All operations completed successfully." }
        return $true
    } else {
        if ($scriptDebug) { Write-Output "One or more operations failed." }
        return $false
    }
}

# Execute main routine
if ($scriptDebug) {
    $result = main
} else {
    try {
        $ErrorActionPreference = "Stop"
        $result = main
    } catch {
        $result = $false
    }
}

return $result