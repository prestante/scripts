$addresses = @('wtlnas1','wtlnas5')
$registryPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\EscDomains"

$name = "*"
$value = 1

foreach ($address in $addresses) {
    if (-not (Test-Path "$registryPath\$address")) {New-Item -Path "$registryPath\$address" -Force}
    if (-not (Get-Item "$registryPath\$address" -ea SilentlyContinue).Property -contains $name) {New-ItemProperty -Path "$registryPath\$address" -Name $name -Value $value -PropertyType DWORD -Force}
    Get-Item "$registryPath\$address" -ea SilentlyContinue}
 