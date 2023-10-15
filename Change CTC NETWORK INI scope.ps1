$CTC = @('adc-ctc01.tecomgroup.ru','adc-ctc02.tecomgroup.ru','adc-ctc03.tecomgroup.ru','adc-ctc04.tecomgroup.ru','adc-ctc05.tecomgroup.ru','adc-ctc06.tecomgroup.ru','adc-ctc07.tecomgroup.ru','adc-ctc08.tecomgroup.ru','adc-ctc09.tecomgroup.ru','adc-ctc10.tecomgroup.ru','adc-ctc11.tecomgroup.ru','adc-ctc12.tecomgroup.ru','adc-ctc13.tecomgroup.ru','adc-ctc14.tecomgroup.ru','adc-ctc15.tecomgroup.ru','adc-ctc16.tecomgroup.ru','adc-ctc17.tecomgroup.ru','adc-ctc18.tecomgroup.ru','adc-ctc19.tecomgroup.ru','adc-ctc20.tecomgroup.ru','adc-ctc21.tecomgroup.ru','adc-ctc22.tecomgroup.ru','adc-ctc23.tecomgroup.ru','adc-ctc24.tecomgroup.ru')

$Creds = [System.Management.Automation.PSCredential]::new('local\Administrator',(ConvertTo-SecureString -AsPlainText 'Tecom_1!' -Force))

#get Multicast Address Scope value
Invoke-Command $CTC -Credential $Creds {
    $DSpath = (New-Object -ComObject WScript.Shell).CreateShortcut('C:\Users\Public\Desktop\ADC Device Server.lnk').WorkingDirectory
    $file = "$DSpath\NETWORK.INI"
    "$env:computername`: $($DSpath -replace 'C:\\server\\') : $(Get-Content $file | where {$_ -like 'Multicast*'} | % {$_})"
} | sort

$newValue = Read-Host "Set to which value (0 - default, 1 - local)"

Invoke-Command $CTC -Credential $Creds -ArgumentList ($newValue) {
    param ($newValue)
    $DSpath = (New-Object -ComObject WScript.Shell).CreateShortcut('C:\Users\Public\Desktop\ADC Device Server.lnk').WorkingDirectory
    $file = "$DSpath\NETWORK.INI"
    (Get-Content $file) -replace '(Multicast Address Scope)=\d',"`$1=$newValue" | Out-File $file -Encoding ascii
}