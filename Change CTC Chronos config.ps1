$CTC = '192.168.13.170','192.168.13.171','192.168.13.172','192.168.13.173','192.168.13.174','192.168.13.175','192.168.13.176','192.168.13.177','192.168.13.178','192.168.13.179','192.168.13.180','192.168.13.181','192.168.13.182','192.168.13.138','192.168.13.139','192.168.13.140','192.168.13.141','192.168.13.142','192.168.13.143','192.168.13.145','192.168.13.161','192.168.13.168','192.168.13.232','192.168.13.191'

$Login = 'local\Administrator'
$Password = 'Tecom_1!'
$Pass = ConvertTo-SecureString -AsPlainText $Password -Force
$Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Login, $Pass



Invoke-Command -ComputerName $CTC -Credential $Creds {

    $chronosConfigFile = 'C:\ProgramData\Imagine Communications\Chronos\chronossettings.json'
    $interfaceAlias = (Get-NetIPAddress | where {$_.IPv4Address -match '192\.168\.13\.'}).InterfaceAlias
    $InterfaceDescription = (Get-NetAdapter | where {$_.InterfaceAlias -eq $interfaceAlias}).InterfaceDescription
    $json = Get-Content $chronosConfigFile | ConvertFrom-Json
    $oldAdapterName = $json.ptpSettings.adaptername
    $json.ptpSettings.adaptername = $InterfaceDescription
    $json | ConvertTo-Json | Set-Content $chronosConfigFile
    
    "$env:COMPUTERNAME | oldAdapterName: $oldAdapterName | newAdapterName: $InterfaceDescription"
    
    Get-Service -Name ChronosServer | Restart-Service -Force
}


