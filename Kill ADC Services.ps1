#Stopping all ADC Services except Aggregation

function GD {Get-Date -Format 'yyyy-MM-dd HH:mm:ss - '}

$all_start_types = Get-Service -Name 'ADC*' | %{@{$_.Name  = $_.StartType}}  # store Startup Type of each Service to Hash table

Write-Host "$(GD)Disabling ADC Services" -b Black -f Yellow
Get-Service -Name 'ADC*' | Set-Service -StartupType Disabled
Start-Sleep 1

Write-Host "$(GD)Stopping ADC Services processes" -b Black -f Yellow
Get-Process -Name 'Harris.Automation.ADC.Services*' | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep 1
Get-Process -Name 'Harris.Automation.ADC.Services*' | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep 1

Write-Host "$(GD)Enabling ADC Services" -b Black -f Yellow
#Get-Service -Name 'ADC*' | Set-Service -StartupType Auto
#Get-Service -Name 'ADC*' | Set-Service -StartupType Disabled
$all_start_types | % {Set-Service -name $_.Keys -StartupType $_.Values}  # restore Startup Type of each Service from Hash table
Start-Sleep 1

Write-Host "Done" -b Black -f Green
Sleep 2