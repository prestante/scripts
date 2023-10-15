$ifi13 = (Get-NetIPAddress -AddressFamily IPv4 | where {$_.IPAddress -match '192.168.13.*'}).InterfaceIndex
$adp13 = Get-NetAdapter -InterfaceIndex $ifi13 #| Restart-NetAdapter

#Get-NetTCPConnection -OwningProcess (get-process adc1000nt).Id
#Get-NetTCPConnection -RemotePort 61966

$rnd = Get-Random 30
Write-Host $rnd

$adp13 | Get-NetAdapterBinding | Set-NetAdapterBinding -Enabled:$false -ComponentID ms_tcpip6
sleep -Milliseconds ($rnd)
$adp13 | Get-NetAdapterBinding | Set-NetAdapterBinding -Enabled:$true -ComponentID ms_tcpip6
sleep -Milliseconds ($rnd)
$adp13 | Get-NetAdapterBinding | Set-NetAdapterBinding -Enabled:$false -ComponentID ms_tcpip6
sleep -Milliseconds ($rnd)
$adp13 | Get-NetAdapterBinding | Set-NetAdapterBinding -Enabled:$true -ComponentID ms_tcpip6
sleep -Milliseconds ($rnd)
$adp13 | Get-NetAdapterBinding | Set-NetAdapterBinding -Enabled:$false -ComponentID ms_tcpip6
sleep -Milliseconds ($rnd)
$adp13 | Get-NetAdapterBinding | Set-NetAdapterBinding -Enabled:$true -ComponentID ms_tcpip6
