$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net', 'WTL-ADC-CTC-03.wtldev.net', 'WTL-ADC-CTC-04.wtldev.net', 'WTL-ADC-CTC-05.wtldev.net', 'WTL-ADC-CTC-06.wtldev.net', 'WTL-ADC-CTC-07.wtldev.net', 'WTL-ADC-CTC-08.wtldev.net', 'WTL-ADC-CTC-09.wtldev.net', 'WTL-ADC-CTC-10.wtldev.net', 'WTL-ADC-CTC-11.wtldev.net', 'WTL-ADC-CTC-12.wtldev.net', 'WTL-ADC-CTC-13.wtldev.net', 'WTL-ADC-CTC-14.wtldev.net', 'WTL-ADC-CTC-15.wtldev.net', 'WTL-ADC-CTC-16.wtldev.net', 'WTL-ADC-CTC-17.wtldev.net', 'WTL-ADC-CTC-18.wtldev.net', 'WTL-ADC-CTC-19.wtldev.net', 'WTL-ADC-CTC-20.wtldev.net', 'WTL-ADC-CTC-21.wtldev.net', 'WTL-ADC-CTC-22.wtldev.net', 'WTL-ADC-CTC-23.wtldev.net', 'WTL-ADC-CTC-24.wtldev.net', 'WTL-ADC-CTC-25.wtldev.net', 'WTL-ADC-CTC-26.wtldev.net', 'WTL-ADC-CTC-27.wtldev.net', 'WTL-ADC-CTC-28.wtldev.net', 'WTL-ADC-CTC-29.wtldev.net', 'WTL-ADC-CTC-30.wtldev.net', 'WTL-ADC-CTC-31.wtldev.net', 'WTL-ADC-CTC-32.wtldev.net')
#$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net', 'WTL-ADC-CTC-03.wtldev.net', 'WTL-ADC-CTC-04.wtldev.net', 'WTL-ADC-CTC-05.wtldev.net', 'WTL-ADC-CTC-06.wtldev.net', 'WTL-ADC-CTC-07.wtldev.net', 'WTL-ADC-CTC-08.wtldev.net', 'WTL-ADC-CTC-09.wtldev.net', 'WTL-ADC-CTC-10.wtldev.net')
# This variant uses one job as a "ping all CTC" in background and another job as "get all data from all pingable CTC".
# Second Job uses prepared ScriptBlock with one Invoke-Command for all CTC inside and constantly restarts when previous cycle is completed. The memory stays at about 150 MB per day. CPU is 2-3%.
$Table = @()
$CredsDomain = [System.Management.Automation.PSCredential]::new('wtldev.net\vadc',(ConvertTo-SecureString -AsPlainText $env:vPW -Force))

# Form a table
foreach ($server in $CTC) {
    $ipAddress = [System.Net.Dns]::GetHostAddresses($server) | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -ExpandProperty IPAddressToString
    $Table += [PSCustomObject]@{
        ServerName = $server -replace '\.wtldev\.net$'
        IPAddress = $ipAddress
        Ping = $null
        DSver = ''
        DSmem = ''
        SEver = ''
        SEmem = ''
    }
}

$JobDataScript = {
    param ( $Table, [pscredential]$CredsDomain )
    Invoke-Command -ComputerName $Table.Where({$null -ne $_.Ping}).ServerName -Credential $CredsDomain {
        $ServerName = HOSTNAME.EXE
        #return $ServerName

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
}

# Set and start a stopwatch to show table once every second
$StopwatchDraw = [System.Diagnostics.Stopwatch]::new()
$StopwatchDraw.Start()
$StopwatchJob = [System.Diagnostics.Stopwatch]::new()
$StopwatchJob.Start()

$StartTime = Get-Date
$qt = 0

while ( $true ) {  # Main cycle
    if ( $JobPing.HasMoreData ) {
        $Results = Receive-Job $JobPing
        foreach ($result in $Results) { $Table.Where({ $result.Address -match $_.ServerName }).foreach({ $_.Ping=$result.ResponseTime }) }
    }
    if ( $JobData.HasMoreData ) {  # Extract data from the Job
        $Results = Receive-Job $JobData -ErrorAction SilentlyContinue | Select-Object * -ExcludeProperty PSComputerName, RunspaceId #| Sort-Object -Property Name | Format-Table
        foreach ($result in $Results) { $Table.Where({ $result.ServerName -match $_.ServerName }).foreach({ $_.DSver=$result.DSver;$_.DSmem=$result.DSmem;$_.SEver=$result.SEver;$_.SEmem=$result.SEmem }) }
    }
    if ( $JobPing.State -eq 'Completed' -or $JobPing.State -eq 'Failed' -or -not $JobPing ) {
        $JobPing = Test-Connection $Table.ServerName -Count 1 -AsJob
    }
    if ( $JobData.State -eq 'Completed' -or $JobData.State -eq 'Failed' -or -not $JobData ) {
        if ( $Table.Where({$null -ne $_.Ping}) ) { $JobData = Start-Job -ScriptBlock $JobDataScript -ArgumentList $Table, $CredsDomain }
    }

    if ( $StopwatchDraw.ElapsedMilliseconds -ge 900 ) {  # Once in about 1 second draw the Table
        $Mem = "{0:n2}" -f [math]::round(($(Get-Process -Id $PID).WorkingSet64 | Measure-Object -Sum).Sum/1MB,2)
        $AvgMem = [math]::round((($AvgMem * $qt + $Mem) / ($qt + 1)),2)
        $Elapsed = "{0:00}:{1:mm}:{1:ss}" -f [math]::Floor(((get-date) - $StartTime).TotalHours),((get-date) - $StartTime)
        
        #Clear-Host
        "PID: {0}  Mem: {1:n2}  Avg: {2:n2}  Elapsed: {4}  SEmem: {5}  JobPing: {6}  JobData: {7}  GoodCTC: {8}" -f $PID, $Mem, $AvgMem, $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss:fff'), $Elapsed, $Table[0].SEmem, "$($JobPing.Id) $($JobPing.State)", "$($JobData.Id) $($JobData.State)", $Table.Where({$null -ne $_.Ping}).Count
        $Table | Format-Table
        $StopwatchDraw.Restart()
        $qt++
    }
    if ( $StopwatchJob.Elapsed.TotalMinutes -ge 1 ) {  # Once in interval remove all jobs to free memory
        Remove-Job * -Force
        Remove-Variable JobPing, JobData
        $StopwatchJob.Restart()
    }
    Start-Sleep -Milliseconds 10
}