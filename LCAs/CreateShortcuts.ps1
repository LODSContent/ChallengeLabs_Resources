$shortcuts = @(
    @{ Name = "Remote Desktop"; Target = "C:\Windows\System32\mstsc.exe";    Location = "Desktop" },
    @{ Name = "Remote Desktop"; Target = "C:\Windows\System32\mstsc.exe";    Location = "Start Menu" },
    @{ Name = "Notepad";        Target = "C:\Windows\System32\notepad.exe";   Location = "Desktop" }
)

$locations = @{
    "Desktop"    = "C:\Users\Labuser\Desktop"
    "Start Menu" = "C:\Users\Labuser\AppData\Roaming\Microsoft\Windows\Start Menu\Programs"
}

$WshShell = New-Object -ComObject WScript.Shell

foreach ($s in $shortcuts) {
    try {
        $destPath = $locations[$s.Location]
        if (-not $destPath) {
            Write-Warning "Unknown location '$($s.Location)' for '$($s.Name)' - skipping"
            continue
        }
        $Shortcut = $WshShell.CreateShortcut("$destPath\$($s.Name).lnk")
        $Shortcut.TargetPath = $s.Target
        $Shortcut.Save()
        Write-Host "Created '$($s.Name)' in $($s.Location)"
    } catch {
        Write-Warning "Failed to create '$($s.Name)': $_"
    }
}
