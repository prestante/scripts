$CTC = '192.168.13.170','192.168.13.171','192.168.13.172','192.168.13.173','192.168.13.174','192.168.13.175','192.168.13.176','192.168.13.177','192.168.13.178','192.168.13.179','192.168.13.180','192.168.13.181','192.168.13.182','192.168.13.138','192.168.13.139','192.168.13.140','192.168.13.141','192.168.13.142','192.168.13.143','192.168.13.145','192.168.13.161','192.168.13.168','192.168.13.232','192.168.13.191'
$Login = 'local\Administrator'
$Password = 'Tecom_1!'
$Pass = ConvertTo-SecureString -AsPlainText $Password -Force
$Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Login, $Pass

$newLCNF = 'ListControlNotifyFrames=33'

$time1 = Get-Date
$results = [System.Collections.ArrayList]@()

Invoke-Command -ComputerName $CTC -Credential $Creds -ArgumentList ($newLCNF) {
    param ($newLCNF)
    $buildFolder = Get-ChildItem ('\\localhost\server\') | where {$_.name -match '^12\.\d\d\.\d.*$'} | sort -property LastWriteTime | select -Last 1 -ExpandProperty FullName
    $ListConfINI = $buildFolder + '\LISTCONF.INI'
    $content = Get-Content $ListConfINI
    $content = $content -replace (($newLCNF -replace '=.*$')+'.*$'),$newLCNF
    $content | Out-File $ListConfINI -Encoding ascii
    
    return "$env:COMPUTERNAME - Done"

} | %{$results.Add($_)} | Out-Null

$results | sort

"`n{0:ss}:{0:fff}" -f ((Get-Date) - $time1)


