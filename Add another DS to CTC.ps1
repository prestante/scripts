$CTC = '192.168.13.170','192.168.13.171','192.168.13.172','192.168.13.173','192.168.13.174','192.168.13.175','192.168.13.176','192.168.13.177','192.168.13.178','192.168.13.179','192.168.13.180','192.168.13.181','192.168.13.182','192.168.13.138','192.168.13.139','192.168.13.140','192.168.13.141','192.168.13.142','192.168.13.143','192.168.13.145','192.168.13.161','192.168.13.168','192.168.13.232','192.168.13.191'

$Login = 'local\Administrator'
$Password = 'Tecom_1!'
$Pass = ConvertTo-SecureString -AsPlainText $Password -Force
$Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Login, $Pass



Invoke-Command -ComputerName $CTC -Credential $Creds {
    
    $rLogin = 'TECOM\adcqauser'
    $rPassword = 'Tecom_123!'
    $rPass = ConvertTo-SecureString -AsPlainText $rPassword -Force
    $rCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $rLogin, $rPass

    New-PSDrive -Name S -PSProvider FileSystem -Root \\fs\change\romashev.s\ADC -Credential $rCreds #creating temporary network drive S: 
    Get-Item 'C:\server\12.29.2.2' -ea SilentlyContinue | Remove-Item -Force -Recurse    
    Copy-Item 'C:\server\12.29.2.1' 'C:\server\12.29.2.2' -Recurse -Force
    Copy-Item 's:\ADC1000NT.exe' 'C:\server\12.29.2.2' -Force
    Remove-Item 'C:\server\12.29.2.2\HANDLES.INI' -Force
    (Get-Content 'C:\server\12.29.2.2\NETWORK.INI') -replace 'Server Port=47125','Server Port=47126' | Set-Content 'C:\server\12.29.2.2\NETWORK.INI'
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("C:\Users\Public\Desktop\ADC Device Server.lnk")
    $Shortcut2 = $WshShell.CreateShortcut("C:\Users\Public\Desktop\ADC Device Server2.lnk")
    $Shortcut2.TargetPath = "C:\server\12.29.2.2\ADC1000NT.exe"
    $Shortcut2.Arguments = "$($Shortcut.Arguments)a"
    $Shortcut2.Save()

}


