#$CTC = @('WTL-HP3B8-VDS1.WTLDEV.NET','WTL-HP3B8-VDS2.WTLDEV.NET','WTL-HP3B8-VDS3.WTLDEV.NET','WTL-HP3B8-VDS4.WTLDEV.NET','WTL-HP3B8-VDS5.WTLDEV.NET','WTL-HP3B8-VDS6.WTLDEV.NET','WTL-HP3B8-VDS7.WTLDEV.NET','WTL-HP3B8-VDS8.WTLDEV.NET','WTL-HP3B8-VDS9.WTLDEV.NET','WTL-HP3B8-VDS10.WTLDEV.NET','WTL-HP3B9-VDS1.WTLDEV.NET','WTL-HP3B9-VDS2.WTLDEV.NET','WTL-HP3B9-VDS3.WTLDEV.NET','WTL-HP3B9-VDS4.WTLDEV.NET','WTL-HP3B9-VDS5.WTLDEV.NET','WTL-HP3B9-VDS6.WTLDEV.NET','WTL-HP3B9-VDS7.WTLDEV.NET','WTL-HP3B9-VDS8.WTLDEV.NET','WTL-HP3B9-VDS9.WTLDEV.NET','WTL-HP3B9-VDS10.WTLDEV.NET')
$CTC = @('adc-ctc01.tecomgroup.ru','adc-ctc02.tecomgroup.ru','adc-ctc03.tecomgroup.ru','adc-ctc04.tecomgroup.ru','adc-ctc05.tecomgroup.ru','adc-ctc06.tecomgroup.ru','adc-ctc07.tecomgroup.ru','adc-ctc08.tecomgroup.ru','adc-ctc09.tecomgroup.ru','adc-ctc10.tecomgroup.ru','adc-ctc11.tecomgroup.ru','adc-ctc12.tecomgroup.ru','adc-ctc13.tecomgroup.ru','adc-ctc14.tecomgroup.ru','adc-ctc15.tecomgroup.ru','adc-ctc16.tecomgroup.ru','adc-ctc17.tecomgroup.ru','adc-ctc18.tecomgroup.ru','adc-ctc19.tecomgroup.ru','adc-ctc20.tecomgroup.ru','adc-ctc21.tecomgroup.ru','adc-ctc22.tecomgroup.ru','adc-ctc23.tecomgroup.ru','adc-ctc24.tecomgroup.ru')
#$CTC = @('adc-ctc01.tecomgroup.ru','adc-ctc02.tecomgroup.ru')

#$adcConf = Get-Content -Path 'C:\PS\ADC1000NT-CTC-1-list.INI'
#$listConf = Get-Content -Path 'C:\PS\LISTCONF-CTC-1-list.INI'
#$adcConf = Get-Content -Path 'C:\PS\ADC1000NT-CTC-2-lists.INI'
#$listConf = Get-Content -Path 'C:\PS\LISTCONF-CTC-2-lists.INI'
#$adcConf = Get-Content -Path 'C:\PS\ADC1000NT-CTC-4-lists.INI'
#$listConf = Get-Content -Path 'C:\PS\LISTCONF-CTC-4-lists.INI'
#$adcConf = Get-Content -Path 'C:\PS\ADC1000NT-CTC-8-lists.INI'
#$listConf = Get-Content -Path 'C:\PS\LISTCONF-CTC-8-lists.INI'
$adcConf = Get-Content -Path 'C:\PS\ADC1000NT-CTC-16-lists.INI'
$listConf = Get-Content -Path 'C:\PS\LISTCONF-CTC-16-lists.INI'

$Creds = [System.Management.Automation.PSCredential]::new('local\Administrator',(ConvertTo-SecureString -AsPlainText 'Tecom_1!' -Force))

Invoke-Command -ComputerName $CTC -Credential $Creds -ArgumentList $adcConf, $listConf {
    param ( $adcConf, $listConf )

    $ctcName = $env:COMPUTERNAME -replace 'ADC-'
    $sh = New-Object -ComObject WScript.Shell
    $DSwd = $sh.CreateShortcut('C:\Users\Public\Desktop\ADC Device Server.lnk').WorkingDirectory
    $ADC1000NTINI = $DSwd + '\ADC1000NT.INI'
    $ListConfINI = $DSwd + '\LISTCONF.INI'
    
    Copy-Item $ADC1000NTINI ("$ADC1000NTINI" -replace "ADC1000NT","ADC1000NT-Backup")
    Copy-Item $ListConfINI ("$ListConfINI" -replace "LISTCONF","LISTCONF-Backup")

    $adcConf | Out-File $ADC1000NTINI -Encoding ascii
    $listConf -replace "Name=CTC01","Name=$($ctcName)" | Out-File $ListConfINI -Encoding ascii

    "$ctcName - $DSwd - Done"
}


