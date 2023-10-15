$servers = '192.168.13.7','192.168.13.8','192.168.13.146','192.168.13.147'

$Login = 'local\Administrator'
$Password = 'ADC1000hrs'
$Pass = ConvertTo-SecureString -AsPlainText $Password -Force
$Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Login, $Pass

Invoke-Command $servers -Credential $Creds -ScriptBlock {
    #Stop-Service -Name ADC* -NoWait
    Write-Host "Disabling ADC Services on $env:COMPUTERNAME" -fo Cyan -ba Black
    Get-Service -Name 'ADC*' | Set-Service -StartupType Disabled
    Start-Sleep 1
    Write-Host "Stopping their processes on $env:COMPUTERNAME" -fo yellow -ba Black
    Get-Process -Name 'Harris.Automation.ADC.Services*' | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep 1
    Write-Host "Enabling ADC Services on $env:COMPUTERNAME" -fo green -ba Black
    Get-Service -Name 'ADC*' | Set-Service -StartupType Manual
    Start-Sleep 1
}