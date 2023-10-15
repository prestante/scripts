$regPathDevices = 'HKCU:\Software\Louth\ADC1000NTCFG\LSODevicesForm'
$regPathDevStatus = 'HKCU:\Software\Louth\ADC1000NTCFG\DeviceStatusForm'
$regPathLists = 'HKCU:\Software\Louth\ADC1000NTCFG\ListAssignmentsForm'

Set-ItemProperty -path $regPathDevices -Name FormSize -Value (0,0,0,0,0,0,0,0,200,1,0,0,255,1,0,0,0)
Set-ItemProperty -path $regPathLists -Name FormSize -Value (200,1,0,0,0,0,0,0,200,1,0,0,100,1,0,0,0)
Set-ItemProperty -path $regPathDevStatus -Name FormSize -Value (200,1,0,0,100,1,0,0,200,1,0,0,100,1,0,0,0)

#$Devices = (Get-ItemProperty -path $regPathDevices -Name FormSize).formsize
#$DevStatus = (Get-ItemProperty -path $regPathDevStatus -Name FormSize).formsize
#$Lists = (Get-ItemProperty -path $regPathLists -Name FormSize).formsize
