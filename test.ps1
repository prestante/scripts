$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net', 'WTL-ADC-CTC-03.wtldev.net', 'WTL-ADC-CTC-04.wtldev.net', 'WTL-ADC-CTC-05.wtldev.net', 'WTL-ADC-CTC-06.wtldev.net', 'WTL-ADC-CTC-07.wtldev.net', 'WTL-ADC-CTC-08.wtldev.net', 'WTL-ADC-CTC-09.wtldev.net', 'WTL-ADC-CTC-10.wtldev.net', 'WTL-ADC-CTC-11.wtldev.net', 'WTL-ADC-CTC-12.wtldev.net', 'WTL-ADC-CTC-13.wtldev.net', 'WTL-ADC-CTC-14.wtldev.net', 'WTL-ADC-CTC-15.wtldev.net', 'WTL-ADC-CTC-16.wtldev.net', 'WTL-ADC-CTC-17.wtldev.net', 'WTL-ADC-CTC-18.wtldev.net', 'WTL-ADC-CTC-19.wtldev.net', 'WTL-ADC-CTC-20.wtldev.net', 'WTL-ADC-CTC-21.wtldev.net', 'WTL-ADC-CTC-22.wtldev.net', 'WTL-ADC-CTC-23.wtldev.net', 'WTL-ADC-CTC-24.wtldev.net', 'WTL-ADC-CTC-25.wtldev.net', 'WTL-ADC-CTC-26.wtldev.net', 'WTL-ADC-CTC-27.wtldev.net', 'WTL-ADC-CTC-28.wtldev.net', 'WTL-ADC-CTC-29.wtldev.net', 'WTL-ADC-CTC-30.wtldev.net', 'WTL-ADC-CTC-31.wtldev.net', 'WTL-ADC-CTC-32.wtldev.net')
#$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net', 'WTL-ADC-CTC-03.wtldev.net', 'WTL-ADC-CTC-04.wtldev.net', 'WTL-ADC-CTC-05.wtldev.net', 'WTL-ADC-CTC-06.wtldev.net', 'WTL-ADC-CTC-07.wtldev.net', 'WTL-ADC-CTC-08.wtldev.net', 'WTL-ADC-CTC-09.wtldev.net', 'WTL-ADC-CTC-10.wtldev.net')

$table = @()
$CredsDomain = [System.Management.Automation.PSCredential]::new('wtldev.net\vadc',(ConvertTo-SecureString -AsPlainText $env:vPW -Force))

# Form a table
foreach ($server in $CTC) {
    $ipAddress = [System.Net.Dns]::GetHostAddresses($server) | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -ExpandProperty IPAddressToString
    $table += [PSCustomObject]@{
        ServerName = $server -replace '\.wtldev\.net$'
        IPAddress = $ipAddress
        DSver = ''
        DSmem = ''
        SEver = ''
        SEmem = ''
    }
}

# Continuously request data from servers in background job
$Job = Start-Job -ArgumentList $table, $CredsDomain -ScriptBlock {
    param ($table, [pscredential]$CredsDomain)
    $i = 5
    while ($i -gt 0) {
        #Measure-Command {
            Invoke-Command -ComputerName $table.ServerName -Credential $CredsDomain {
                $ServerName = HOSTNAME.EXE
                $IPaddress = [System.Net.Dns]::GetHostAddresses($Name) | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -ExpandProperty IPAddressToString
                $DSProcess = Get-Process -Name ADC1000NT -ErrorAction SilentlyContinue
                $ServicesProcesses = Get-Process -Name Harris* -ErrorAction SilentlyContinue
                return [pscustomobject]@{
                    ServerName = $ServerName
                    IPaddress = $IPaddress
                    DSver = if (Test-Path 'C:\Users\Public\Desktop\ADC Device Server.lnk') {
                        $sh = New-Object -ComObject WScript.Shell
                        ((Get-ChildItem $sh.CreateShortcut('C:\Users\Public\Desktop\ADC Device Server.lnk').Targetpath).VersionInfo).ProductVersion
                    } else {''}
                    DSmem = if ($DSProcess) { "{0:n2}" -f [math]::round(($DSProcess.WorkingSet64 | Measure-Object -Sum).Sum/1MB,2) }
                            else {''}
                    SEver = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -eq 'ADC Services'} | Select-Object -Property DisplayVersion).DisplayVersion
                    SEmem = if ($ServicesProcesses) {
                        "{0:n2}" -f [math]::Round((((Get-Process -Name Harris*).WorkingSet64 | Measure-Object -Sum).Sum/1MB),2)
                    } else {''}
                }
            }
        #} | Select-Object -ExpandProperty TotalMilliseconds
    }
}

# Set and start a stopwatch to show table once every second
$Stopwatch = [System.Diagnostics.Stopwatch]::new()
$Stopwatch.Start()

while ( $true ) {
    if ( (Get-Job $Job.Id).HasMoreData ) {
        $Results = Receive-Job $Job.Id | Select-Object * -ExcludeProperty PSComputerName, RunspaceId #| Sort-Object -Property Name | Format-Table
        foreach ($result in $Results) {
            #$table.Where({$result.ServerName -match $_.ServerName}).foreach({$_.ping=$result.Ping;$_.DSver=$result.DSver;$_.DSmem=$result.DSmem;$_.SEver=$result.SEver;$_.SEmem=$result.SEmem;$_.PLmem=$result.PLmem;$_.CTmem=$result.CTmem})
            $table.Where({$result.ServerName -match $_.ServerName}).foreach({$_.DSver=$result.DSver;$_.DSmem=$result.DSmem;$_.SEver=$result.SEver;$_.SEmem=$result.SEmem})
        }
    }
    #if ( (Get-Date | Select-Object -ExpandProperty Millisecond) -gt 950 ) { $table | Format-Table }
    if ($Stopwatch.ElapsedMilliseconds -ge 900) { Get-Date -Format 'yyyy-MM-dd HH:mm:ss:fff' ; $table | Format-Table ; $Stopwatch.Restart()}
    Start-Sleep -Milliseconds 10
}