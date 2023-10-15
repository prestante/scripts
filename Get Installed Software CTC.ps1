$CTC = '192.168.13.170','192.168.13.171','192.168.13.172','192.168.13.173','192.168.13.174','192.168.13.175','192.168.13.176','192.168.13.177','192.168.13.178','192.168.13.179','192.168.13.180','192.168.13.181','192.168.13.182','192.168.13.138','192.168.13.139','192.168.13.140','192.168.13.141','192.168.13.142','192.168.13.143','192.168.13.145','192.168.13.161','192.168.13.168','192.168.13.232','192.168.13.191'
#$CTC = @('192.168.13.170','192.168.13.171')

$Login = 'local\Administrator'
$Password = 'Tecom_1!'
$Pass = ConvertTo-SecureString -AsPlainText $Password -Force
$Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Login, $Pass

$results = Invoke-Command $CTC -Credential $Creds {
    $allSoft = @()
    $allSoft += Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*
    $allSoft += Get-ItemProperty HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*
    $allSoft | Add-Member NoteProperty Computer $env:COMPUTERNAME

    #$allSoft | ?{($_.DisplayName -match 'Aggreg') -or ($_.DisplayName -match 'Playlist')} | Select-Object -Property DisplayName,DisplayVersion,Computer | Sort-Object DisplayName | ft -AutoSize
    return $allSoft | ?{($_.DisplayName -match 'Aggreg') -or ($_.DisplayName -match 'Playlist')} | Select-Object -Property Computer,DisplayName,DisplayVersion
}

$results | select Computer,DisplayName,DisplayVersion | Sort-Object Computer,DisplayName | ft