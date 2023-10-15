[System.Collections.Generic.List[PSObject]]$services = Get-Service -Name 'ADC*' | where {
    $_.Name -match 'ADCAsRun' -or
    $_.Name -match 'ADCDeviceService' -or
    $_.Name -match 'ADCErrorReportingService' -or
    $_.Name -match 'ADCListService' -or
    $_.Name -match 'ADCTimecodeService'
}
[System.Collections.Generic.List[PSObject]]$processes = Get-Process -Name '*ADC.Services*' | where {
    $_.ProcessName -match 'AsRunServiceHost' -or
    $_.ProcessName -match 'DeviceServiceHost' -or
    $_.ProcessName -match 'ErrorReportingServiceHost' -or
    $_.ProcessName -match 'ListServiceHost' -or
    $_.ProcessName -match 'TimecodeServiceHost'
}

$services | % {Set-Service -Name $_.Name -StartupType Disabled; Write-Host "Disabling $($_.Name)" -f Yellow -b Black}
sleep 1
$processes | % {Stop-Process -Name $_.Name -Force -ea SilentlyContinue; Write-Host "Stopping $($_.Name -replace '^.*\.')" -f Red -b Black}
$processes | % {Stop-Process -Name $_.Name -Force -ea SilentlyContinue} | Out-Null
sleep 1
$services | % {Set-Service -Name $_.Name -StartupType Manual; Write-Host "Enabling $($_.Name)" -f Green -b Black}
