$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net')

$CredsDomain = [System.Management.Automation.PSCredential]::new('wtldev.net\vadc',(ConvertTo-SecureString -AsPlainText $env:VADC_PASSWORD -Force))

$add = 0

Invoke-Command -ComputerName ($CTC) -InDisconnectedSession -ArgumentList $add -Credential $CredsDomain {
    param ($add)
    if ($add -eq 0) {
        Stop-Process  -name ADC1000NT -Force ; Start-Sleep 1
        Start-Process 'C:\Users\Public\Desktop\ADC Device Server.lnk' ; Start-Sleep 1
    }
}

Invoke-Command -ComputerName ($CTC) -Credential $CredsDomain {
    Get-Process -Name 'ADC1000NT'
}