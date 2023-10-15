$ifi13 = (Get-NetIPAddress -AddressFamily IPv4 | where {$_.IPAddress -match '192.168.13.*'}).InterfaceIndex
$ifi90 = (Get-NetIPAddress -AddressFamily IPv4 | where {$_.IPAddress -match '192.168.90.*'}).InterfaceIndex
if (($ifi90) -and ($ifi13)) {
    Set-NetIPInterface -InterfaceIndex $ifi13 -AddressFamily IPv4 -InterfaceMetric 1
    Set-NetIPInterface -InterfaceIndex $ifi90 -AddressFamily IPv4 -InterfaceMetric 25
    $ip13 = (Get-NetIPAddress -InterfaceIndex $ifi13 -AddressFamily IPv4).IPAddress
    $ip90 = (Get-NetIPAddress -InterfaceIndex $ifi90 -AddressFamily IPv4).IPAddress
    Write-Host "InterfaceMetric for $ip13 is set to 1" -f Yellow -b Black
    Write-Host "InterfaceMetric for $ip90 is set to 25" -f Yellow -b Black
    if ((Get-Service -Name ADCDataService -ea SilentlyContinue).Status -match 'Running') {
        Write-Host "Stopping ADCDataService..." -f Yellow -b Black
        Set-Service -Name ADCDataService -StartupType Disabled
        Stop-Process -Name Harris.Automation.ADC.Services.ADCDataServiceHost -Force
        Sleep 2
        Write-Host "Starting ADCDataService..." -f Yellow -b Black
        Set-Service -Name ADCDataService -StartupType Manual
        Start-Service -Name ADCDataService
    }
    Write-Host "Done" -f Green -b Black
    Sleep 3
} else {Write-Host "IPv4 Network Interface of 13th and/or 90th subnet is not found. Please turn it on and restart the script." -f Red -b Black ; Sleep 3}