$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net', 'WTL-ADC-CTC-03.wtldev.net', 'WTL-ADC-CTC-04.wtldev.net', 'WTL-ADC-CTC-05.wtldev.net', 'WTL-ADC-CTC-06.wtldev.net', 'WTL-ADC-CTC-07.wtldev.net', 'WTL-ADC-CTC-08.wtldev.net', 'WTL-ADC-CTC-09.wtldev.net', 'WTL-ADC-CTC-10.wtldev.net', 'WTL-ADC-CTC-11.wtldev.net', 'WTL-ADC-CTC-12.wtldev.net', 'WTL-ADC-CTC-13.wtldev.net', 'WTL-ADC-CTC-14.wtldev.net', 'WTL-ADC-CTC-15.wtldev.net', 'WTL-ADC-CTC-16.wtldev.net', 'WTL-ADC-CTC-17.wtldev.net', 'WTL-ADC-CTC-18.wtldev.net', 'WTL-ADC-CTC-19.wtldev.net', 'WTL-ADC-CTC-20.wtldev.net', 'WTL-ADC-CTC-21.wtldev.net', 'WTL-ADC-CTC-22.wtldev.net', 'WTL-ADC-CTC-23.wtldev.net', 'WTL-ADC-CTC-24.wtldev.net', 'WTL-ADC-CTC-25.wtldev.net', 'WTL-ADC-CTC-26.wtldev.net', 'WTL-ADC-CTC-27.wtldev.net', 'WTL-ADC-CTC-28.wtldev.net', 'WTL-ADC-CTC-29.wtldev.net', 'WTL-ADC-CTC-30.wtldev.net', 'WTL-ADC-CTC-31.wtldev.net', 'WTL-ADC-CTC-32.wtldev.net')
#$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net', 'WTL-ADC-CTC-03.wtldev.net', 'WTL-ADC-CTC-04.wtldev.net', 'WTL-ADC-CTC-05.wtldev.net', 'WTL-ADC-CTC-06.wtldev.net', 'WTL-ADC-CTC-07.wtldev.net', 'WTL-ADC-CTC-08.wtldev.net', 'WTL-ADC-CTC-09.wtldev.net')

#$CredsLocal = [System.Management.Automation.PSCredential]::new('local\imagineLocal',(ConvertTo-SecureString -AsPlainText $env:imgLocPW -Force))
$CredsDomain = [System.Management.Automation.PSCredential]::new('wtldev.net\vadc',(ConvertTo-SecureString -AsPlainText $env:vPW -Force))
$PSSessionOption.IdleTimeout = New-TimeSpan -days 24 -Seconds 0

Invoke-Command -ComputerName $CTC -Credential $CredsDomain -InDisconnectedSession {
    $HostName = HOSTNAME.EXE
    if  ( Get-Process ADC1000NT -ErrorAction SilentlyContinue ) {
        # do nothing
    } else {
        Start-Process 'C:\server\ADC1000NT.exe' -ArgumentList ($HostName -replace 'WTL-ADC-')  # get CTC server name
    }
} | Select-Object -ExpandProperty ComputerName | ForEach-Object {
    $HostName = $_ -replace '.wtldev.net'
    Write-Host "$HostName`: Done" -f ( 1, 2, 3, 5, 6, 9, 10, 11, 13, 14 )[ ( $HostName.Split('-')[-1] ) % 10 ] }

<#foreach ( $PC in $CTC ) {  # This is a serial way to start CTC DS one by one to overcome a 32 sessions limit
    $Report = $HostName = $PC -replace '.wtldev.net$'
    $Report += ": Starting DS..."
    Invoke-Command -ComputerName $PC -Credential $CredsDomain -InDisconnectedSession {
        if  ( Get-Process ADC1000NT -ErrorAction SilentlyContinue ) {
            return "$(HOSTNAME.EXE): DS already started - $((Get-Process ADC1000NT -ErrorAction SilentlyContinue).Id)"
        } else {
            Start-Process 'C:\Users\Public\Desktop\ADC Device Server.lnk' | Out-Null
            return "$(HOSTNAME.EXE): Starting DS"
        }
    } | Out-Null
    $Report += "Done"
    Write-Host "$Report" -f ( 1, 2, 3, 5, 6, 9, 10, 11, 13, 14 )[ ( $HostName.Split('-')[-1] ) % 10 ]
}#>

if ( $Host.Name -notmatch 'Visual Studio') { Read-Host }
