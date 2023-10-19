New-PSDrive -Name "Z" -PSProvider FileSystem -Root "\\wtlnas1\Public\"
Get-ChildItem "Z:\ADC\PS\resources"
Remove-PSDrive "Z"