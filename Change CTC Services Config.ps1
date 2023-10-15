$CTC = @('adc-ctc01.tecomgroup.ru','adc-ctc02.tecomgroup.ru','adc-ctc03.tecomgroup.ru','adc-ctc04.tecomgroup.ru','adc-ctc05.tecomgroup.ru','adc-ctc06.tecomgroup.ru','adc-ctc07.tecomgroup.ru','adc-ctc08.tecomgroup.ru','adc-ctc09.tecomgroup.ru','adc-ctc10.tecomgroup.ru','adc-ctc11.tecomgroup.ru','adc-ctc12.tecomgroup.ru','adc-ctc13.tecomgroup.ru','adc-ctc14.tecomgroup.ru','adc-ctc15.tecomgroup.ru','adc-ctc16.tecomgroup.ru','adc-ctc17.tecomgroup.ru','adc-ctc18.tecomgroup.ru','adc-ctc19.tecomgroup.ru','adc-ctc20.tecomgroup.ru','adc-ctc21.tecomgroup.ru','adc-ctc22.tecomgroup.ru','adc-ctc23.tecomgroup.ru','adc-ctc24.tecomgroup.ru')
#$CTC = @('adc-ctc01.tecomgroup.ru')

$Creds = [System.Management.Automation.PSCredential]::new('local\Administrator',(ConvertTo-SecureString -AsPlainText 'Tecom_1!' -Force))

$ASR = Get-Content 'C:\PS\xml\AsRunServiceRef.xml'
$ERR = Get-Content 'C:\PS\xml\ErrorReportingServiceRef.xml'
$DEV = Get-Content 'C:\PS\xml\DeviceServiceRef.xml'
$LST = Get-Content 'C:\PS\xml\ListServiceRef.xml'
$TMC = Get-Content 'C:\PS\xml\TimecodeServiceRef.xml'
$DAT = Get-Content 'C:\PS\xml\DataServiceRef.xml'

Invoke-Command -ComputerName $CTC -ArgumentList $ASR, $ERR, $DEV, $LST, $TMC, $DAT -Credential $Creds {
    param ( $ASR, $ERR, $DEV, $LST, $TMC, $DAT )
    
    $Name = $env:COMPUTERNAME -replace 'ADC-'
    $Address = ipconfig | where {($_ -match '192.168.13.') -and ($_ -match 'IPv4')} | %{$_ -replace '^.*\.13\.'}
    
    $ASRfile = 'C:\Program Files (x86)\Imagine Communications\ADC Services\config\AsRunService.xml'
    $ERRfile = 'C:\Program Files (x86)\Imagine Communications\ADC Services\config\ErrorReportingService.xml'
    $DEVfile = 'C:\Program Files (x86)\Imagine Communications\ADC Services\config\DeviceService.xml'
    $LSTfile = 'C:\Program Files (x86)\Imagine Communications\ADC Services\config\ListService.xml'
    $TMCfile = 'C:\Program Files (x86)\Imagine Communications\ADC Services\config\TimecodeService.xml'
    $DATfile = 'C:\Program Files (x86)\Imagine Communications\ADC Services\config\DataService.xml'

    $ASR -replace '#NAME',$Name -replace '#IPEND',$Address | Out-File $ASRfile -Encoding utf8
    $ERR -replace '#NAME',$Name -replace '#IPEND',$Address | Out-File $ERRfile -Encoding utf8
    $DEV -replace '#NAME',$Name -replace '#IPEND',$Address | Out-File $DEVfile -Encoding utf8
    $LST -replace '#NAME',$Name -replace '#IPEND',$Address | Out-File $LSTfile -Encoding utf8
    $TMC -replace '#NAME',$Name -replace '#IPEND',$Address | Out-File $TMCfile -Encoding utf8
    $DAT | Out-File $DATfile -Encoding utf8

    Write-Host "$env:COMPUTERNAME - Done" -f Green
}

