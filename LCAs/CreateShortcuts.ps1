$shortcuts = @(
    @{ Name = "Remote Desktop"; Target = "C:\Windows\System32\mstsc.exe" },
    @{ Name = "Notepad";        Target = "C:\Windows\System32\notepad.exe" }
)

$desktopPath = "C:\Users\Labuser\Desktop"
$WshShell = New-Object -ComObject WScript.Shell

foreach ($s in $shortcuts) {
    $Shortcut = $WshShell.CreateShortcut("$desktopPath\$($s.Name).lnk")
    $Shortcut.TargetPath = $s.Target
    $Shortcut.Save()
}
