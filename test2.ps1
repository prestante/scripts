$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net', 'WTL-ADC-CTC-03.wtldev.net', 'WTL-ADC-CTC-04.wtldev.net', 'WTL-ADC-CTC-05.wtldev.net', 'WTL-ADC-CTC-06.wtldev.net', 'WTL-ADC-CTC-07.wtldev.net', 'WTL-ADC-CTC-08.wtldev.net', 'WTL-ADC-CTC-09.wtldev.net', 'WTL-ADC-CTC-10.wtldev.net', 'WTL-ADC-CTC-11.wtldev.net', 'WTL-ADC-CTC-12.wtldev.net', 'WTL-ADC-CTC-13.wtldev.net', 'WTL-ADC-CTC-14.wtldev.net', 'WTL-ADC-CTC-15.wtldev.net', 'WTL-ADC-CTC-16.wtldev.net', 'WTL-ADC-CTC-17.wtldev.net', 'WTL-ADC-CTC-18.wtldev.net', 'WTL-ADC-CTC-19.wtldev.net', 'WTL-ADC-CTC-20.wtldev.net', 'WTL-ADC-CTC-21.wtldev.net', 'WTL-ADC-CTC-22.wtldev.net', 'WTL-ADC-CTC-23.wtldev.net', 'WTL-ADC-CTC-24.wtldev.net', 'WTL-ADC-CTC-25.wtldev.net', 'WTL-ADC-CTC-26.wtldev.net', 'WTL-ADC-CTC-27.wtldev.net', 'WTL-ADC-CTC-28.wtldev.net', 'WTL-ADC-CTC-29.wtldev.net', 'WTL-ADC-CTC-30.wtldev.net', 'WTL-ADC-CTC-31.wtldev.net', 'WTL-ADC-CTC-32.wtldev.net')
#$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net', 'WTL-ADC-CTC-32.wtldev.net')
# This variant uses one jobPing as a "ping all CTC" in background and another jobData as "get all data from all pingable CTC".
# Second Job uses prepared ScriptBlock with one Invoke-Command for all CTC inside and constantly restarts when previous cycle is completed. 
# The memory stays at about 150 MB per day. CPU is 2-3%.

$CredsDomain = [System.Management.Automation.PSCredential]::new('wtldev.net\vadc',(ConvertTo-SecureString -AsPlainText $env:vPW -Force))
$CommandCenterHost = $env:COMPUTERNAME
$List = New-Object 'System.Collections.Generic.List[PSCustomObject]'

$JobDataScript = {
    param ( $List, [pscredential]$CredsDomain, $CommandCenterHost )
    Invoke-Command -ComputerName $List.Where({$null -ne $_.Ping}).ServerName -Credential $CredsDomain -ArgumentList $List, $plug {
        param ( $List, $plug )
        $ServerName = $env:COMPUTERNAME
        $DSProcess = Get-Process -Name ADC1000NT -ErrorAction SilentlyContinue
        $ServicesProcesses = Get-Process -Name Harris* -ErrorAction SilentlyContinue
        return [pscustomobject]@{
            DateTime = Get-Date
            ServerName = $ServerName
            IPaddress = [System.Net.Dns]::GetHostAddresses($Name) | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -ExpandProperty IPAddressToString
            Ping = ( $List | Where-Object { $_.ServerName -eq $ServerName } ).Ping
            DSver = if (Test-Path 'C:\Users\Public\Desktop\ADC Device Server.lnk') {
                $sh = New-Object -ComObject WScript.Shell
                ((Get-ChildItem $sh.CreateShortcut('C:\Users\Public\Desktop\ADC Device Server.lnk').Targetpath).VersionInfo).ProductVersion
            } else {''}
            DSmem = if ($DSProcess) { "{0:n2}" -f [math]::round(($DSProcess.WorkingSet64 | Measure-Object -Sum).Sum/1MB,2) }
                    else {''}
            SEver = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -eq 'ADC Services'} | Select-Object -Property DisplayVersion).DisplayVersion
            SEmem = if ($ServicesProcesses) {
                "{0:n2}" -f [math]::Round((($ServicesProcesses.WorkingSet64 | Measure-Object -Sum).Sum/1MB),2)
            } else {''}
        }#>
    }
}

# Prepare the List which will work as a Table
foreach ($server in $CTC) {
    $obj = [PSCustomObject]@{
        ServerName = $server -replace '\.wtldev\.net$'
        IPAddress = [System.Net.Dns]::GetHostAddresses($server) | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -ExpandProperty IPAddressToString
        Ping = $null }
    $List.Add($obj) }

# Set and start stopwatches to show table once every second and to remove all jobs once in an hour. Also remember general start time to be able to get get Elapsed time. $Iterations is the iteration counter to calculate AVGmem
$StopwatchDraw = [System.Diagnostics.Stopwatch]::new()
$StopwatchDraw.Start()
$StopwatchReset = [System.Diagnostics.Stopwatch]::new()
$StopwatchReset.Start()
$StartTime = Get-Date
$Iterations = 0

do {  # Main cycle
    if ( $JobPing.HasMoreData ) {
        $Results = Receive-Job $JobPing
        foreach ($result in $Results) { $List.Where({ $result.Address -match $_.ServerName }).foreach({ $_.Ping=$result.ResponseTime }) } }

    if ( $JobData.HasMoreData ) {  # Extract data from the Job
        $Results = Receive-Job $JobData -ErrorAction SilentlyContinue | Select-Object * -ExcludeProperty PSComputerName, RunspaceId #| Sort-Object -Property Name | Format-Table
        foreach ($result in $Results) { #$List.Where({ $result.ServerName -match $_.ServerName }).foreach({ $_.DSver=$result.DSver;$_.DSmem=$result.DSmem;$_.SEver=$result.SEver;$_.SEmem=$result.SEmem }) }
            $index = $List.FindIndex({ param($item) $item.ServerName -eq $Result.ServerName })  # Looking for an index of a row in the List corresponding to received result
            if ($index -ne -1) { $List[$index] = $Result } } } # Update the List's row with the new data

    if ( $JobPing.State -eq 'Completed' -or $JobPing.State -eq 'Failed' -or -not $JobPing ) {
        if ( $JobPing ) { Remove-Job $JobPing -Force -ErrorAction SilentlyContinue }
        $JobPing = Test-Connection $List.ServerName -Count 1 -AsJob }

    if ( $JobData.State -eq 'Completed' -or $JobData.State -eq 'Failed' -or -not $JobData -or $JobData.PSBeginTime -lt (Get-Date).AddSeconds(-2) ) {
        if ( $JobData ) { Remove-Job -Job $JobData -Force -ErrorAction SilentlyContinue }
        if ( $List.Where({$null -ne $_.Ping}) ) { $JobData = Start-Job -ScriptBlock $JobDataScript -ArgumentList $List, $CredsDomain, $CommandCenterHost } }

<#    # Handle List Rows which have not been updated for a while (reset a row if not updated for more than X seconds). Create an intermediate object to avoid BadEnumeration error
    $ObjectsToReset = $List | Where-Object { $_.DateTime } | Where-Object { $_.DateTime -lt (Get-Date).AddSeconds(-3) }
    $ObjectsToReset | ForEach-Object {
        $index = $List.FindIndex({ param($item) $item.ServerName -eq $_.ServerName })
        $Result = [PSCustomObject]@{
            ServerName = $_.ServerName
            IPAddress = $_.IPAddress
            Ping = $null
            DateTime = $_.DateTime }
        if ($index -ne -1) { $List[$index] = $Result } } #>

    # Redraw the table once in about 1 second
    if ( $StopwatchDraw.ElapsedMilliseconds -ge 1000 ) {
        $StopwatchDraw.Restart()
        # Get info about current powershell process
        $Mem = "{0:n2}" -f [math]::round(($(Get-Process -Id $PID).WorkingSet64 | Measure-Object -Sum).Sum/1MB,2)
        $AvgMem = [math]::round((($AvgMem * $Iterations + $Mem) / ($Iterations + 1)),2)
        $Elapsed = "{0:00}:{1:mm}:{1:ss}" -f [math]::Floor(((get-date) - $StartTime).TotalHours),((get-date) - $StartTime)
        
        #Clear-Host
        "PID: {0}  Mem: {1:n2}  Avg: {2:n2}  Elapsed: {4}  SEmem: {5}  GoodCTC: {6}  Jobs: {7}" -f $PID, $Mem, $AvgMem, $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss:fff'), $Elapsed, $List[0].SEmem, $List.Where({$null -ne $_.Ping}).Count, (Get-Job).Count
        $List | Select-Object ServerName, IPAddress, Ping, DSver, DSmem, SEver, SEmem, @{Name='LastInfo'; Expression={$_.DateTime.ToString("HH:mm:ss")}} -ExcludeProperty DateTime, PSComputerName, RunspaceId | Format-Table
        $Iterations++ }
    
    # Force remove all jobs and start them again once in X time
<#    if ( $StopwatchReset.Elapsed.Minutes -ge 5 ) {
        $StopwatchReset.Restart()
        Remove-Job * -Force -ErrorAction SilentlyContinue
        Remove-Variable JobPing, JobData } #>

    # Look for a key press
    if ($host.ui.RawUi.KeyAvailable) {
        $key=$host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown,IncludeKeyUp")
        $Host.UI.RawUI.FlushInputBuffer()
        if ($key.keydown) {
            switch ($key.VirtualKeyCode) {
                <#Enter#> 13 {
                }
                <#P#> 80 {
                    if ($table.PLmem -gt 0) {StopPL}
                        else {StartPL}
                }
                <#S#>     83 {
                    $Chosen = [int](Read-Host "Which DS to start/stop? Default = All")
                        if (($Chosen) -and ($table.DSmem[$Chosen-1] -ne [DBNull]::Value)) {StopDS -DS $Chosen}
                        elseif (($Chosen) -and ($table.DSmem[$Chosen-1] -eq [DBNull]::Value)) {StartDS -DS $Chosen}
                        elseif ((!$Chosen) -and [bool]($table.DSmem -gt 0)) {StopDS}
                        elseif ((!$Chosen) -and ![bool]($table.DSmem -gt 0)) {StartDS}
                }
                <#T#>     84 {
                    if ($table.CTmem -gt 0) {StopCT}
                        else {StartCT}
                }
                <#Esc#>   27 { Remove-Job * -Force -ErrorAction SilentlyContinue ; exit }
                <#Space#> 32 {
                    if ($table.DSmem -gt 0) {StopDS}
                        else {StartDS}
                }
                <#Tab#>   9 {
                    if ($table.SEmem -gt 0) {StopSE}
                        else {StartSE}
                }
                <#F1#>    112 {$infoCounter = 10}
                <#F4#>    115 { } } } }

    Start-Sleep -Milliseconds 333 } until ( $key.VirtualKeyCode -eq 27 )