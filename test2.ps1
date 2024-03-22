#Polling against single requests
#This is backup with polling variant

$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net', 'WTL-ADC-CTC-03.wtldev.net', 'WTL-ADC-CTC-04.wtldev.net', 'WTL-ADC-CTC-05.wtldev.net', 'WTL-ADC-CTC-06.wtldev.net', 'WTL-ADC-CTC-07.wtldev.net', 'WTL-ADC-CTC-08.wtldev.net', 'WTL-ADC-CTC-09.wtldev.net', 'WTL-ADC-CTC-10.wtldev.net', 'WTL-ADC-CTC-11.wtldev.net', 'WTL-ADC-CTC-12.wtldev.net', 'WTL-ADC-CTC-13.wtldev.net', 'WTL-ADC-CTC-14.wtldev.net', 'WTL-ADC-CTC-15.wtldev.net', 'WTL-ADC-CTC-16.wtldev.net', 'WTL-ADC-CTC-17.wtldev.net', 'WTL-ADC-CTC-18.wtldev.net', 'WTL-ADC-CTC-19.wtldev.net', 'WTL-ADC-CTC-20.wtldev.net', 'WTL-ADC-CTC-21.wtldev.net', 'WTL-ADC-CTC-22.wtldev.net', 'WTL-ADC-CTC-23.wtldev.net', 'WTL-ADC-CTC-24.wtldev.net', 'WTL-ADC-CTC-25.wtldev.net', 'WTL-ADC-CTC-26.wtldev.net', 'WTL-ADC-CTC-27.wtldev.net', 'WTL-ADC-CTC-28.wtldev.net', 'WTL-ADC-CTC-29.wtldev.net', 'WTL-ADC-CTC-30.wtldev.net', 'WTL-ADC-CTC-31.wtldev.net', 'WTL-ADC-CTC-32.wtldev.net')
#$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net', 'WTL-ADC-CTC-03.wtldev.net', 'WTL-ADC-CTC-04.wtldev.net', 'WTL-ADC-CTC-05.wtldev.net', 'WTL-ADC-CTC-06.wtldev.net', 'WTL-ADC-CTC-07.wtldev.net', 'WTL-ADC-CTC-08.wtldev.net', 'WTL-ADC-CTC-09.wtldev.net', 'WTL-ADC-CTC-10.wtldev.net')

$Table = @()
$CredsDomain = [System.Management.Automation.PSCredential]::new('wtldev.net\vadc',(ConvertTo-SecureString -AsPlainText $env:vPW -Force))

# Form a table
foreach ($server in $CTC) {
    $ipAddress = [System.Net.Dns]::GetHostAddresses($server) | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -ExpandProperty IPAddressToString
    $Table += [PSCustomObject]@{
        ServerName = $server -replace '\.wtldev\.net$'
        IPAddress = $ipAddress
        Ping = ''
        DSver = ''
        DSmem = ''
        SEver = ''
        SEmem = ''
    }
}

function Start-Polling {  # Continuously request data from servers in background job
    param ($Table, [pscredential]$CredsDomain)

    Start-Job -ArgumentList $Table, $CredsDomain -ScriptBlock {
        param ($Table, [pscredential]$CredsDomain)
        $i = 5
        while ($i -gt 0) {
            #Measure-Command {
                #$Table.Where({$null -ne $_.Ping})
                Invoke-Command -ComputerName $Table.ServerName -Credential $CredsDomain -ErrorAction SilentlyContinue {
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
        #$i--
        }
    }
}
# Set and start a stopwatch to show table once every second
$Stopwatch = [System.Diagnostics.Stopwatch]::new()
$Stopwatch.Start()
$StopwatchJob = [System.Diagnostics.Stopwatch]::new()
$StopwatchJob.Start()

$StartTime = Get-Date
$qt = 0

$JobPing = Test-Connection $Table.ServerName -Count 1 -AsJob
$JobData = Start-Polling -Table $Table -CredsDomain $CredsDomain

while ( $true ) {
    if ( $JobPing.State -eq 'Completed' ) {
        $Results = Receive-Job $JobPing
        foreach ($result in $Results) { $Table.Where({ $result.Address -match $_.ServerName }).foreach({ $_.Ping=$result.ResponseTime }) }
        $JobPing = Test-Connection $Table.ServerName -Count 1 -AsJob
        $Table | Format-Table
    }
    if ( $JobData.HasMoreData ) {  # Extract data from the Job
        $Results = Receive-Job $JobData.Id | Select-Object * -ExcludeProperty PSComputerName, RunspaceId #| Sort-Object -Property Name | Format-Table
        foreach ($result in $Results) {
            #$Table.Where({$result.ServerName -match $_.ServerName}).foreach({$_.ping=$result.Ping;$_.DSver=$result.DSver;$_.DSmem=$result.DSmem;$_.SEver=$result.SEver;$_.SEmem=$result.SEmem;$_.PLmem=$result.PLmem;$_.CTmem=$result.CTmem})
            $Table.Where({ $result.ServerName -match $_.ServerName }).foreach({ $_.DSver=$result.DSver;$_.DSmem=$result.DSmem;$_.SEver=$result.SEver;$_.SEmem=$result.SEmem })
        }
    }
    if ( $Stopwatch.ElapsedMilliseconds -ge 900 ) {  # Once in about 1 second draw the Table
        $Mem = "{0:n2}" -f [math]::round(($(Get-Process -Id $PID).WorkingSet64 | Measure-Object -Sum).Sum/1MB,2)
        $AvgMem = [math]::round((($AvgMem * $qt + $Mem) / ($qt + 1)),2)
        $Elapsed = "{0:00}:{1:mm}:{1:ss}" -f [math]::Floor(((get-date) - $StartTime).TotalHours),((get-date) - $StartTime)
        
        #Clear-Host
        "PID: {0}  Mem: {1:n2}  Avg: {2:n2}  Time: {3}  Elapsed: {4}  Cycles: {5}" -f $PID, $Mem, $AvgMem, $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss:fff'), $Elapsed, $qt
        $Table | Format-Table
        $Stopwatch.Restart()
        $qt++
    }
    if ( $StopwatchJob.Elapsed.TotalMinutes -ge 10 ) {  # Once in interval remove all jobs and create new one(s)
        Remove-Job * -Force
        $JobPing = Test-Connection $Table.ServerName -Count 1 -AsJob
        $JobData = Start-Polling -Table $Table -CredsDomain $CredsDomain
        $StopwatchJob.Restart()
    }
    Start-Sleep -Milliseconds 10
}