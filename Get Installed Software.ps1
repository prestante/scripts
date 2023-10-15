#getting all installed software (32 and 64 bit)
Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object -Property DisplayName,DisplayVersion | Sort-Object DisplayName | ft -AutoSize
Get-ItemProperty HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object -Property DisplayName,DisplayVersion | Sort-Object DisplayName | ft -AutoSize

#getting all installed software, then getting only DS, then getting highest DS version
(Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | 
Where-Object {$_.DisplayName -eq 'ADC Device Server'} | 
Measure-Object -Maximum DisplayVersion).Maximum

#getting all installed software, then getting only ADC Services
Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | 
Where-Object {$_.DisplayName -eq 'ADC Services'} | Select-Object -Property DisplayName,DisplayVersion | 
Format-Table -HideTableHeaders

#just show me all DS installed
Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -eq 'ADC Device Server'} | Select-Object -Property DisplayName,DisplayVersion | Sort-Object DisplayVersion | ft -AutoSize
