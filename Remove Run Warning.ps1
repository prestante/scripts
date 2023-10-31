$address = 'wtlnas1.wtldev.net'
$domain = $address -replace '.*\.(\w+\.\w+$)','$1'
$place = $address -replace '(.*)\.\w+\.\w+$','$1'
$registryPaths = @()
$registryPaths += "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\EscDomains"
$registryPaths += "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains"

$name2 = "file"
$value2 = 1

foreach ($registryPath in $registryPaths) {
  if (!(Test-Path $registryPath)) {New-Item -Path $registryPath -Force}
  if (!(Test-Path "$registryPath\$domain")) {New-Item -Path "$registryPath\$domain" -Force}
  if (!(Test-Path "$registryPath\$domain\$place")) {New-Item -Path "$registryPath\$domain\$place" -Force}
  if ((Get-Item "$registryPath\$domain\$place").property -notcontains $name2) {New-ItemProperty -Path "$registryPath\$domain\$place" -Name $name2 -Value $value2 -PropertyType DWORD -Force}
}
 