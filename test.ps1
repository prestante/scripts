Import-Module "\\wtlnas1\public\ADC\PS\scripts\Get-ADC.psm1", "\\wtlnas1\public\ADC\PS\scripts\Remove-ADC.psm1"

Get-ADC | Select-Object -ExpandProperty AllDS
