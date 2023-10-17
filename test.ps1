$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut("$env:USERPROFILE\Desktop\//wtlnas5/Public/Releases/ADC.lnk")
$shortcut.TargetPath = "\\wtlnas5\Public\Releases\ADC"
$shortcut.Save()