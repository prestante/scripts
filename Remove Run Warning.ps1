$domains = @('wtldev.net')
$registryPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains"

$name = "*"
$value = 1

foreach ($domain in $domains) {
    if (-not (Test-Path "$registryPath\$domain")) {New-Item -Path "$registryPath\$domain" -Force}
    if (-not (Get-Item "$registryPath\$domain" -ea SilentlyContinue).Property -contains $name) {New-ItemProperty -Path "$registryPath\$domain" -Name $name -Value $value -PropertyType DWORD -Force}
    #Get-Item "$registryPath\$domain" -ea SilentlyContinue
}
 