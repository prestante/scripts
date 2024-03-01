#$CTC = @('WTL-HP3B8-VDS1.WTLDEV.NET','WTL-HP3B8-VDS2.WTLDEV.NET','WTL-HP3B8-VDS3.WTLDEV.NET','WTL-HP3B8-VDS4.WTLDEV.NET','WTL-HP3B8-VDS5.WTLDEV.NET','WTL-HP3B8-VDS6.WTLDEV.NET','WTL-HP3B8-VDS7.WTLDEV.NET','WTL-HP3B8-VDS8.WTLDEV.NET','WTL-HP3B8-VDS9.WTLDEV.NET','WTL-HP3B8-VDS10.WTLDEV.NET','WTL-HP3B9-VDS1.WTLDEV.NET','WTL-HP3B9-VDS2.WTLDEV.NET','WTL-HP3B9-VDS3.WTLDEV.NET','WTL-HP3B9-VDS4.WTLDEV.NET','WTL-HP3B9-VDS5.WTLDEV.NET','WTL-HP3B9-VDS6.WTLDEV.NET','WTL-HP3B9-VDS7.WTLDEV.NET','WTL-HP3B9-VDS8.WTLDEV.NET','WTL-HP3B9-VDS9.WTLDEV.NET','WTL-HP3B9-VDS10.WTLDEV.NET')
$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net', 'WTL-ADC-CTC-03.wtldev.net', 'WTL-ADC-CTC-04.wtldev.net', 'WTL-ADC-CTC-05.wtldev.net', 'WTL-ADC-CTC-06.wtldev.net', 'WTL-ADC-CTC-07.wtldev.net', 'WTL-ADC-CTC-08.wtldev.net', 'WTL-ADC-CTC-09.wtldev.net', 'WTL-ADC-CTC-10.wtldev.net', 'WTL-ADC-CTC-11.wtldev.net', 'WTL-ADC-CTC-12.wtldev.net', 'WTL-ADC-CTC-13.wtldev.net', 'WTL-ADC-CTC-14.wtldev.net', 'WTL-ADC-CTC-15.wtldev.net', 'WTL-ADC-CTC-16.wtldev.net', 'WTL-ADC-CTC-17.wtldev.net', 'WTL-ADC-CTC-18.wtldev.net', 'WTL-ADC-CTC-19.wtldev.net', 'WTL-ADC-CTC-20.wtldev.net', 'WTL-ADC-CTC-21.wtldev.net', 'WTL-ADC-CTC-22.wtldev.net', 'WTL-ADC-CTC-23.wtldev.net', 'WTL-ADC-CTC-24.wtldev.net', 'WTL-ADC-CTC-25.wtldev.net', 'WTL-ADC-CTC-26.wtldev.net', 'WTL-ADC-CTC-27.wtldev.net', 'WTL-ADC-CTC-28.wtldev.net', 'WTL-ADC-CTC-29.wtldev.net', 'WTL-ADC-CTC-30.wtldev.net', 'WTL-ADC-CTC-31.wtldev.net', 'WTL-ADC-CTC-32.wtldev.net', 'WTL-ADC-CTC-33.wtldev.net', 'WTL-ADC-CTC-34.wtldev.net', 'WTL-ADC-CTC-35.wtldev.net', 'WTL-ADC-CTC-36.wtldev.net', 'WTL-ADC-CTC-37.wtldev.net', 'WTL-ADC-CTC-38.wtldev.net', 'WTL-ADC-CTC-39.wtldev.net', 'WTL-ADC-CTC-40.wtldev.net')
#$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net', 'WTL-ADC-CTC-03.wtldev.net', 'WTL-ADC-CTC-04.wtldev.net', 'WTL-ADC-CTC-05.wtldev.net', 'WTL-ADC-CTC-06.wtldev.net', 'WTL-ADC-CTC-07.wtldev.net', 'WTL-ADC-CTC-08.wtldev.net', 'WTL-ADC-CTC-09.wtldev.net')
#$CTC = @('WTL-ADC-CTC-02.wtldev.net')

$CredsLocal = [System.Management.Automation.PSCredential]::new('local\imagineLocal',(ConvertTo-SecureString -AsPlainText $env:imgLocPW -Force))
$CredsDomain = [System.Management.Automation.PSCredential]::new('wtldev.net\vadc',(ConvertTo-SecureString -AsPlainText $env:vPW -Force))
$PSSessionOption.IdleTimeout = New-TimeSpan -days 24 -Seconds 0

Invoke-Command -ComputerName $CTC -ArgumentList $CredsDomain, $CredsLocal -Credential $CredsLocal -InDisconnectedSession {
    param ( $CredsDomain, $CredsLocal )
    #$Report = "$(HOSTNAME.EXE):"
    if ( -not ( Get-Process ADC1000NT -ErrorAction SilentlyContinue ) ) {
        #$Report += " Starting DS"
        Write-Host "$(HOSTNAME.EXE): Starting DS" -f ( 1, 2, 3, 5, 6, 9, 10, 11, 13, 14 )[ ( $HostName.Split('-')[-1] ) % 10 ]
        Start-Process 'C:\Users\Public\Desktop\ADC Device Server.lnk' -Credential $CredsLocal
    } else {
        #$Report += " $(( Get-Process ADC1000NT -ErrorAction SilentlyContinue ).Id)"
        Write-Host "$(HOSTNAME.EXE): $(( Get-Process ADC1000NT -ErrorAction SilentlyContinue ).Id)" -f ( 1, 2, 3, 5, 6, 9, 10, 11, 13, 14 )[ ( $HostName.Split('-')[-1] ) % 10 ]
    }
    #Write-Host $Report
}  | Out-Null

if ( $Host.Name -notmatch 'Visual Studio') { Read-Host }
################################################DS did not started on all CTC


