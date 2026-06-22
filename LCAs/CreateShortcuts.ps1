$shortcuts = @(
    @{ Name = "Remote Desktop"; Target = "C:\Windows\System32\mstsc.exe";    Location = "Desktop" },
    @{ Name = "Remote Desktop"; Target = "C:\Windows\System32\mstsc.exe";    Location = "Start Menu" },
    @{ Name = "Remote Desktop"; Target = "C:\Windows\System32\mstsc.exe";    Location = "Taskbar" },
    @{ Name = "Notepad";        Target = "C:\Windows\System32\notepad.exe";   Location = "Desktop" }
)

$locations = @{
    "Desktop"    = "C:\Users\Labuser\Desktop"
    "Start Menu" = "C:\Users\Labuser\AppData\Roaming\Microsoft\Windows\Start Menu\Programs"
}

$WshShell = New-Object -ComObject WScript.Shell

foreach ($s in $shortcuts) {
    if ($s.Location -eq "Taskbar") {
        $tempLnk = "$env:TEMP\$($s.Name).lnk"
        $Shortcut = $WshShell.CreateShortcut($tempLnk)
        $Shortcut.TargetPath = $s.Target
        $Shortcut.Save()
        $shell = New-Object -ComObject Shell.Application
        $shell.Namespace("shell:::{4234d49b-0245-4df3-b780-3893943456e1}").ParseName($tempLnk).InvokeVerb("taskbarpin")
    } else {
        $destPath = $locations[$s.Location]
        $Shortcut = $WshShell.CreateShortcut("$destPath\$($s.Name).lnk")
        $Shortcut.TargetPath = $s.Target
        $Shortcut.Save()
    }
}
