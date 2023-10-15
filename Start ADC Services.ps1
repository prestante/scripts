#Starting all ADC Services except Aggregation

function GD {Get-Date -Format 'yyyy-MM-dd HH:mm:ss - '}

#Start-Service -Name 'ADCSecurityService', 'ADCManagerService'

[System.Collections.Generic.List[PSObject]]$services = Get-Service -Name 'ADC*' | where {$_.DisplayName -notmatch 'Aggregation'}
[System.Collections.Generic.List[PSObject]]$servicesInOrder = @()

$services | where {$_.DisplayName -match 'Security'} | % {$servicesInOrder.Add($_)}
$services | where {$_.DisplayName -match 'Data'} | % {$servicesInOrder.Add($_)}
$services | where {$_.DisplayName -match 'Timecode'} | % {$servicesInOrder.Add($_)}
$services | where {$_.DisplayName -match 'AsRun'} | % {$servicesInOrder.Add($_)}
$services | where {$_.DisplayName -match 'Device'} | % {$servicesInOrder.Add($_)}
$services | where {$_.DisplayName -match 'List'} | % {$servicesInOrder.Add($_)}
$services | where {$_.DisplayName -match 'Error'} | % {$servicesInOrder.Add($_)}
$services | 
 where {$_.DisplayName -notmatch 'Data'} |
 where {$_.DisplayName -notmatch 'Timecode'} |
 where {$_.DisplayName -notmatch 'AsRun'} | 
 where {$_.DisplayName -notmatch 'Device'} | 
 where {$_.DisplayName -notmatch 'List'} | 
 where {$_.DisplayName -notmatch 'Error'} | 
 where {$_.DisplayName -notmatch 'Synchro'} | 
 where {$_.DisplayName -notmatch 'Integra'} | 
 where {$_.DisplayName -notmatch 'Manager'} | 
 where {$_.DisplayName -notmatch 'Security'} | 
% {$servicesInOrder.Add($_)}
$services | where {$_.DisplayName -match 'Integra'} | % {$servicesInOrder.Add($_)}
$services | where {$_.DisplayName -match 'Synchro'} | % {$servicesInOrder.Add($_)}
$services | where {$_.DisplayName -match 'Manager'} | % {$servicesInOrder.Add($_)}

$servicesInOrder | % {
    Write-Host "$(GD)Starting $($_.name -replace '(ADC)(.*)(Service)','$1 $2 $3')" -b Black -f Yellow
    Start-Service $_.name -WarningAction SilentlyContinue
}

Write-Host "Done" -b Black -f Green
Sleep 2

<#Write-Host "$(GD)Disabling Integration Service" -b Black -f Yellow
Get-Service -Name 'ADCIntegrationService' | Set-Service -StartupType Disabled
Start-Sleep 1

Write-Host "$(GD)Stopping Integration Service process" -b Black -f Yellow
Get-Process -Name 'Harris.Automation.ADC.Services.IntegrationServiceHost' -ea SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep 1
Get-Process -Name 'Harris.Automation.ADC.Services.IntegrationServiceHost' -ea SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep 1

Write-Host "$(GD)Enabling Integration Service" -b Black -f Yellow
Get-Service -Name 'ADCIntegrationService' | Set-Service -StartupType Manual
Start-Sleep 1

Write-Host "Done" -b Black -f Green
Sleep 2
#>
