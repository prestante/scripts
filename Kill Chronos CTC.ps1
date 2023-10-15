$CTC = '192.168.13.170','192.168.13.171','192.168.13.172','192.168.13.173','192.168.13.174','192.168.13.175','192.168.13.176','192.168.13.177','192.168.13.178','192.168.13.179','192.168.13.180','192.168.13.181','192.168.13.182','192.168.13.138','192.168.13.139','192.168.13.140','192.168.13.141','192.168.13.142','192.168.13.143','192.168.13.145','192.168.13.161','192.168.13.168','192.168.13.232','192.168.13.191'
$CTC = '192.168.13.143','192.168.13.145','192.168.13.161','192.168.13.168','192.168.13.232','192.168.13.191'


#credentials for operating CTC PCs
$Login = 'local\Administrator'
$Password = 'Tecom_1!'
$Pass = ConvertTo-SecureString -AsPlainText $Password -Force
$Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Login, $Pass

Invoke-Command -ComputerName $CTC -Credential $Creds -ScriptBlock {
    Get-Service -Name '*chronos*' | Stop-Service

    function GD {Get-Date -Format 'yyyy-MM-dd HH:mm:ss - '}

    Write-Host "$($env:COMPUTERNAME):$(GD)Disabling Imagine Communications Chronos Server" -b Black -f Yellow
    Get-Service -Name '*chronos*' | Set-Service -StartupType Disabled
    Start-Sleep 1

    Write-Host "$($env:COMPUTERNAME):$(GD)Stopping Chronos process" -b Black -f Yellow
    Get-Process -Name 'ChronosExe' -ea SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep 1
    Get-Process -Name 'ChronosExe' -ea SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep 1

    Write-Host "$($env:COMPUTERNAME):$(GD)Enabling Imagine Communications Chronos Server" -b Black -f Yellow
    Get-Service -Name '*chronos*' | Set-Service -StartupType Automatic
    Start-Sleep 1

    Write-Host "$($env:COMPUTERNAME):Done" -b Black -f Green
    Sleep 2
}

