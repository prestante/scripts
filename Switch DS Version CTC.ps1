$CTC = @('adc-ctc01.tecomgroup.ru','adc-ctc02.tecomgroup.ru','adc-ctc03.tecomgroup.ru','adc-ctc04.tecomgroup.ru','adc-ctc05.tecomgroup.ru','adc-ctc06.tecomgroup.ru','adc-ctc07.tecomgroup.ru','adc-ctc08.tecomgroup.ru','adc-ctc09.tecomgroup.ru','adc-ctc10.tecomgroup.ru','adc-ctc11.tecomgroup.ru','adc-ctc12.tecomgroup.ru','adc-ctc13.tecomgroup.ru','adc-ctc14.tecomgroup.ru','adc-ctc15.tecomgroup.ru','adc-ctc16.tecomgroup.ru','adc-ctc17.tecomgroup.ru','adc-ctc18.tecomgroup.ru','adc-ctc19.tecomgroup.ru','adc-ctc20.tecomgroup.ru','adc-ctc21.tecomgroup.ru','adc-ctc22.tecomgroup.ru','adc-ctc23.tecomgroup.ru','adc-ctc24.tecomgroup.ru')
#$CTC = @('adc-ctc01.tecomgroup.ru','adc-ctc02.tecomgroup.ru')

$Creds = [System.Management.Automation.PSCredential]::new('local\Administrator',(ConvertTo-SecureString -AsPlainText 'Tecom_1!' -Force))

#$NewDSVersion = Read-Host "What DS version to switch to?"
$NewDSVersion = '12.29.2'

If ($NewDSVersion -match '^\d+\.\d+\.\d+') {
    Invoke-Command -ComputerName $CTC -Credential $Creds -ArgumentList $NewDSVersion -ScriptBlock {
        param ( $NewDSVersion )

        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut('C:\Users\Public\Desktop\ADC Device Server.lnk')
        $shortcut.Targetpath = (gci "C:\server" | where {$_.Name -match $NewDSVersion} | select -First 1 | gci | where {$_.Name -eq 'ADC1000NT.exe'}).fullname
        $shortcut.save()

        #Write-Host "$($env:COMPUTERNAME) - Done" -fo Green -ba Black  # sorting of Invoke-Command doesn't work for Write-Host
        "$($env:COMPUTERNAME) - Done"
    } | sort
}
else { Write-Host "Wrong DS Version!" -fo Red -ba Black }
