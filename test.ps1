Remove-Module Get-ADC, Remove-ADC -ErrorAction SilentlyContinue
Import-Module "\\wtlnas1\Public\ADC\PS\scripts\Get-ADC.psm1", "\\wtlnas1\Public\ADC\PS\scripts\Remove-ADC.psm1"

get-ADC | ForEach-Object { $AllDS = $_.AllDS }
#$AllDS.DisplayVersion

$str = Remove-ADC -app 'ds 12.28.1'
