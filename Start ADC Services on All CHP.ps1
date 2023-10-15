$servers = '192.168.13.7','192.168.13.8','192.168.13.146','192.168.13.147'

$Login = 'local\Administrator'
$Password = 'ADC1000hrs'
$Pass = ConvertTo-SecureString -AsPlainText $Password -Force
$Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Login, $Pass

Invoke-Command $servers -Credential $Creds -ScriptBlock {
    #Start-Service -Name 'ADCSecurityService', 'ADCManagerService'
    #Start-Sleep 1

    $services = Get-Service -Name 'ADC*'

    $services | where {$_.DisplayName -notmatch 'Integration'} | where {$_.DisplayName -notmatch 'Aggr'} | sort -Descending | Start-Service -WarningAction SilentlyContinue
    #$services | where {$_.DisplayName -match 'Integration'} | Start-Service -WarningAction SilentlyContinue
    Write-Host "$($env:COMPUTERNAME) - Done." -fo Green -ba Black
}
