# This module compares two given ADC versions like 12.29.1 or 5.10.4.1 and returns True if a first one is newer
function Compare-ADCVersions {
    param (
        [Parameter(Mandatory=$true)][string]$Version1,
        [Parameter(Mandatory=$true)][string]$Version2
    )

    if ($Version1 -match '^(\d{1,2}\.){2,3}\d{1,2}$' -and $Version2 -match '^(\d{1,2}\.){2,3}\d{1,2}$') {
        $Multiplier = 99*99*99*99
        $IntVersion1 = ( $Version1 -split '\.' | ForEach-Object { [int]$_ * $Multiplier ; $Multiplier /= 100 } | Measure-Object -Sum ).Sum
        $Multiplier = 99*99*99*99
        $IntVersion2 = ( $Version2 -split '\.' | ForEach-Object { [int]$_ * $Multiplier ; $Multiplier /= 100 } | Measure-Object -Sum ).Sum
        return $IntVersion1 -gt $IntVersion2
    } else { throw "Wrong ADC Version format. It should be like 12.29.12 or 5.10.4.1"}
}