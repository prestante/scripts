#. ".\test.ps1"
Get-Module -ListAvailable "\\wtlnas1\Public\ADC\PS\scripts\test.ps1" -SkipEditionCheck | Import-Module
#Import-Module -Name "\\wtlnas1\Public\ADC\PS\scripts\test.ps1"
funa -arg 'qwe123'
Write-Host "The code from test2.ps1"
Remove-Variable * -ErrorAction SilentlyContinue
