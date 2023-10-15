#Stopping Aggregation Service

function GD {Get-Date -Format 'yyyy-MM-dd HH:mm:ss - '}

Write-Host "$(GD)Disabling ADC Aggregation Service" -b Black -f Yellow
Get-Service -Name '*aggregation*' | Set-Service -StartupType Disabled
Start-Sleep 1

Write-Host "$(GD)Stopping ADC Aggregation Service process" -b Black -f Yellow
Get-Process -Name '*aggregation*' | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep 1
Get-Process -Name '*aggregation*' | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep 1

Write-Host "$(GD)Enabling ADC Aggregation Service" -b Black -f Yellow
Get-Service -Name 'ADC*' | Set-Service -StartupType Manual
Start-Sleep 1

Write-Host "Done" -b Black -f Green
Sleep 2