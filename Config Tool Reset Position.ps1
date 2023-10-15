if (Get-Process ADC1000NTCFG -ea SilentlyContinue) {
    Write-Host "Stopping ADC1000NTCFG..." -fo Yellow -ba Black
    Get-Process ADC1000NTCFG | Stop-Process -Force
    do {} while (Get-Process ADC1000NTCFG -ea SilentlyContinue)
}

$regPath = 'HKCU:\Software\Louth\ADC1000NTCFG\'

$DevicePaths = @(Get-ChildItem $regPath | where {($_.name -match 'LSODevices') -and ($_.Name -notmatch 'Splitter')} | % {$_.pspath -replace 'Microsoft\.PowerShell\.Core\\'})
$ListPaths = @(Get-ChildItem $regPath | where {($_.name -match 'List') -and ($_.Name -notmatch 'Splitter')} | % {$_.pspath -replace 'Microsoft\.PowerShell\.Core\\'})
$StatusPaths = @(Get-ChildItem $regPath | where {($_.name -match 'DeviceStatus') -and ($_.Name -notmatch 'Splitter')} | % {$_.pspath -replace 'Microsoft\.PowerShell\.Core\\'})

for ($i=0; $i -lt $DevicePaths.length; $i++) {Set-ItemProperty -path $DevicePaths[$i] -Name FormSize -Value ((0+$i*5),0,0,0,(0+$i*10),0,0,0,200,1,0,0,255,1,0,0,0)}
for ($i=0; $i -lt $ListPaths.length; $i++) {Set-ItemProperty -path $ListPaths[$i] -Name FormSize -Value ((200+$i*5),1,0,0,(0+$i*10),0,0,0,200,1,0,0,100,1,0,0,0)}
for ($i=0; $i -lt $StatusPaths.length; $i++) {Set-ItemProperty -path $StatusPaths[$i] -Name FormSize -Value ((200+$i*5),1,0,0,(100+$i*10),1,0,0,200,1,0,0,100,1,0,0,0)}

