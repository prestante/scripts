$CTC = '192.168.13.170','192.168.13.171','192.168.13.172','192.168.13.173','192.168.13.174','192.168.13.175','192.168.13.176','192.168.13.177','192.168.13.178','192.168.13.179','192.168.13.180','192.168.13.181','192.168.13.182','192.168.13.138','192.168.13.139','192.168.13.140','192.168.13.141','192.168.13.142','192.168.13.143','192.168.13.145','192.168.13.161','192.168.13.168','192.168.13.232','192.168.13.191'
#$CTC = '192.168.13.170','192.168.13.171','192.168.13.172','192.168.13.173','192.168.13.174','192.168.13.175','192.168.13.176','192.168.13.177','192.168.13.178','192.168.13.179','192.168.13.180','192.168.13.181'
#$CTC = '192.168.13.182','192.168.13.138','192.168.13.139','192.168.13.140','192.168.13.141','192.168.13.142','192.168.13.143','192.168.13.145','192.168.13.161','192.168.13.168','192.168.13.232','192.168.13.191'
#$CTC = @('192.168.13.170','192.168.13.171')

$DSver = read-host 'Which DS version? Default (empty) is the current desktop shortcut version'

$Login = 'local\Administrator'
$Password = 'Tecom_1!'
$Pass = ConvertTo-SecureString -AsPlainText $Password -Force
$Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Login, $Pass


function get-ipmac {
    write-host "Reading IP's and mac's of each CTC PC's 13th and 90th network adapter..." -fo Yellow -ba Black
    $global:ipmac = @()
    foreach ($PC in $CTC) {
        $result = Invoke-Command -ComputerName $PC -Credential $Creds -ArgumentList $DSver {
            param ($DSver)
#            $wmi = gwmi -Class Win32_NetworkAdapterConfiguration
#            $ip13 = ([System.Net.Dns]::GetHostByName($env:COMPUTERNAME).addresslist | where {$_.IPAddressToString -match '\.168\.13'}).IPAddressToString
#            $mac13 = ($wmi | where {$_.ipaddress -eq $ip13}).macaddress -replace '\:','-'
#            $ip90 = ([System.Net.Dns]::GetHostByName($env:COMPUTERNAME).addresslist | where {$_.IPAddressToString -match '\.168\.90'}).IPAddressToString
#            $mac90 = ($wmi | where {$_.ipaddress -eq $ip90}).macaddress -replace '\:','-'
            $alias13 = (Get-NetIPAddress | where {$_.IPv4Address -match '192\.168\.13\.'}).InterfaceAlias
            $ip13 = (Get-NetIPAddress | where {$_.IPv4Address -match '192\.168\.13\.'}).IPv4Address
            $mac13 = (Get-NetAdapter | where {$_.InterfaceAlias -eq $alias13}).MacAddress
            $alias90 = (Get-NetIPAddress | where {$_.IPv4Address -match '192\.168\.90\.'}).InterfaceAlias
            $ip90 = (Get-NetIPAddress | where {$_.IPv4Address -match '192\.168\.90\.'}).IPv4Address
            $mac90 = (Get-NetAdapter | where {$_.InterfaceAlias -eq $alias90}).MacAddress

    

            if (($DSver -match '\d\d\.(\d|\d\d)\.(\d|\d\d)') -or ($DSver -eq '')) {
                if ($DSver -match '\d\d\.(\d|\d\d)\.(\d|\d\d)') {$currentPath = (Get-ChildItem 'C:\server' | where {$_.FullName -match $DSver} | select -First 1).Name}
                elseif ($DSver -eq '') {$currentPath = (New-Object -ComObject WScript.Shell).CreateShortcut('C:\Users\Public\Desktop\ADC Device Server.lnk').WorkingDirectory -replace 'C:\\server\\'}
                $currentMAC = Get-ChildItem "C:\server\$currentPath" | Get-ChildItem | where {$_.Name -eq 'NETWORK.INI'} | Get-Content | where {$_ -like 'MAC=*'} | % {$_ -replace 'MAC='}
                $currentSub = if ($currentMAC -eq $mac13) {"13"} elseif ($currentMAC -eq $mac90) {"90"} else {$null}
            }
            else {$currentPath = $null ; $currentMAC = $null}

            return [PSCustomObject] @{ip13=$ip13;mac13=$mac13;ip90=$ip90;mac90=$mac90;currentPath=$currentPath;currentMAC=$currentMAC;currentSub=$currentSub}
        }
        $global:ipmac += ($result | select * -ExcludeProperty PSComputerName,RunspaceId)
        
    }
    $global:ipmac | ft
}

get-ipmac

$change = Read-Host "Change MACs to which adapter? (13,90,default is to not change)"
if ($change) {
    foreach ($PC in $CTC) {
        if ($change -match '13') {$newMac = ($ipmac | where {$_.ip13 -eq $PC}).mac13}
        elseif ($change -match '90') {$newMac = ($ipmac | where {$_.ip13 -eq $PC}).mac90}
        else {return}
        $path = ($ipmac | where {$_.ip13 -eq $PC}).currentPath
        if ($path) {
            $file = (Get-ChildItem ("\\$PC\server\$path") | where {$_.Name -eq 'NETWORK.INI'}).FullName
            $content = Get-Content $file
            $content -replace '(MAC)=.*',"`$1=$newMac" | Out-File $file -Encoding ascii
        }
        else {
            Write-Host "There is no server path for $PC" -f Yellow -b Black
        }
    }
}

if ($change) {get-ipmac}
else {Write-Host "No changes." -fo Yellow -ba Black}
