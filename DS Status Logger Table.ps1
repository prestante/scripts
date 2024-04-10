Remove-Variable * -Force -ErrorAction SilentlyContinue
Remove-Job * -Force -ErrorAction SilentlyContinue
#$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net', 'WTL-ADC-CTC-03.wtldev.net', 'WTL-ADC-CTC-04.wtldev.net', 'WTL-ADC-CTC-05.wtldev.net', 'WTL-ADC-CTC-06.wtldev.net', 'WTL-ADC-CTC-07.wtldev.net', 'WTL-ADC-CTC-08.wtldev.net', 'WTL-ADC-CTC-09.wtldev.net', 'WTL-ADC-CTC-10.wtldev.net', 'WTL-ADC-CTC-11.wtldev.net', 'WTL-ADC-CTC-12.wtldev.net', 'WTL-ADC-CTC-13.wtldev.net', 'WTL-ADC-CTC-14.wtldev.net', 'WTL-ADC-CTC-15.wtldev.net', 'WTL-ADC-CTC-16.wtldev.net', 'WTL-ADC-CTC-17.wtldev.net', 'WTL-ADC-CTC-18.wtldev.net', 'WTL-ADC-CTC-19.wtldev.net', 'WTL-ADC-CTC-20.wtldev.net', 'WTL-ADC-CTC-21.wtldev.net', 'WTL-ADC-CTC-22.wtldev.net', 'WTL-ADC-CTC-23.wtldev.net', 'WTL-ADC-CTC-24.wtldev.net', 'WTL-ADC-CTC-25.wtldev.net', 'WTL-ADC-CTC-26.wtldev.net', 'WTL-ADC-CTC-27.wtldev.net', 'WTL-ADC-CTC-28.wtldev.net', 'WTL-ADC-CTC-29.wtldev.net', 'WTL-ADC-CTC-30.wtldev.net', 'WTL-ADC-CTC-31.wtldev.net', 'WTL-ADC-CTC-32.wtldev.net')
$CTC = @('WTL-ADC-CTC-30.wtldev.net', 'WTL-ADC-CTC-31.wtldev.net', 'WTL-ADC-CTC-32.wtldev.net')
#$CTC = @('WTL-ADC-CTC-32.wtldev.net')
# The idea is to gather DS/SE versions by the job once in like a minute. And to receive CPU and MEM by fast WMI provider directly.

$CredsDomain = [System.Management.Automation.PSCredential]::new('wtldev.net\vadc',(ConvertTo-SecureString -AsPlainText $env:vPW -Force))
$CommandCenterHost = $env:COMPUTERNAME
$List = New-Object 'System.Collections.Generic.List[PSCustomObject]'
$Query = "SELECT * FROM Win32_PerfRawData_PerfProc_Process WHERE ((Name = 'Idle') OR (Name like '%ADC1000NT%') OR (Name like '%ADC.Services%')) AND (NOT Name like '_Total')"
#$Query = "SELECT * FROM Win32_PerfRawData_PerfProc_Process WHERE Name = 'Idle'"
    
# Prepare the List which will work as a Table
foreach ($server in $CTC) {
    $obj = [PSCustomObject]@{
        ServerName = $server -replace '\.wtldev\.net$'
        IPAddress = [System.Net.Dns]::GetHostAddresses($server) | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -ExpandProperty IPAddressToString
        Ping = $null
        DSver = $null
        DSmem = $null
        SEver = $null
        SEmem = $null
        DateTime = $null }
    $List.Add($obj) }

# Prepare the Script for the JobVer
$JobVerScript = {
    Invoke-Command -ComputerName $List.Where({$null -ne $_.Ping}).ServerName -Credential $CredsDomain -AsJob {
        return [pscustomobject]@{
            DSver = if (Test-Path 'C:\Users\Public\Desktop\ADC Device Server.lnk') {
                $sh = New-Object -ComObject WScript.Shell
                ((Get-ChildItem $sh.CreateShortcut('C:\Users\Public\Desktop\ADC Device Server.lnk').Targetpath).VersionInfo).ProductVersion
            } else {$null}
            SEver = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -eq 'ADC Services'} | Select-Object -Property DisplayVersion).DisplayVersion } } }

# Set and start stopwatches to show table once every second and to remove all jobs once in an hour. Also remember general start time to be able to get get Elapsed time. $Iterations is the iteration counter to calculate AVGmem
$StopwatchDraw = [System.Diagnostics.Stopwatch]::new()
$StopwatchDraw.Start()
$StopwatchReset = [System.Diagnostics.Stopwatch]::new()
$StopwatchReset.Start()
$StartTime = Get-Date
$Iterations = 0

do {  # Main cycle
    # Clear DSmem and SEmem for List Rows which have not been updated for a while
    if ( $List | Where-Object { $_.DateTime } | Where-Object { $_.DateTime -lt (Get-Date).AddSeconds(-3) } ) {
        $List | Where-Object { $_.DateTime } | Where-Object { $_.DateTime -lt (Get-Date).AddSeconds(-3) } | ForEach-Object {
            $_.DSmem = $_.SEmem = $_.DSver = $_.SEver = $null } }

    # Receive Ping data from JobPing
    if ( $JobPing.HasMoreData ) {
        $Results = Receive-Job $JobPing
        foreach ($result in $Results) { $List.Where({ $result.Address -match $_.ServerName }).foreach({ $_.Ping=$result.ResponseTime }) } }

    # Receive version data from JobVer
    if ( $JobVer.HasMoreData ) {
        $Results = Receive-Job $JobVer -ErrorAction SilentlyContinue
        foreach ($result in $Results) { 
            $List.Where({ $result.PSComputerName -match $_.ServerName }).foreach({ $_.DSver=$result.DSver;$_.SEver=$result.SEver }) } }
    
    # Receive mem from JobWMI
    if ( $JobWMI.HasMoreData ) {
        $Results = @( Receive-Job $JobWMI -ErrorAction SilentlyContinue )
        $ServerNames = $Results.PSComputerName | Select-Object -Unique
        foreach ( $ServerName in $ServerNames ) {
            $LocalResults = $Results.Where({ $_.PSComputerName -eq $ServerName })
            $List.Where({ $ServerName -match $_.ServerName }).foreach({ $_.DSmem = $_.SEmem = $null ; $_.DateTime = (Get-Date) })  # clear mem values for current ServerName and update DateTime
            foreach ($result in $LocalResults) { 
                if ( $result.Name -eq 'ADC1000NT' ) { $List.Where({ $ServerName -match $_.ServerName }).foreach({ [int]$_.DSmem = $result.WorkingSet / 1MB }) }
                if ( $result.Name -match 'ADC.Services' ) { $List.Where({ $ServerName -match $_.ServerName }).foreach({ [int]$_.SEmem = $_.SEmem + $result.WorkingSet / 1MB }) }
                } } }
    
    # restart JobPing on complete
    if ( $JobPing.State -ne 'Running' -or -not $JobPing ) {
        $JobPing = Test-Connection $List.ServerName -Count 1 -AsJob }

    # start new JobVer every X seconds
    if ( $JobVer.PSBeginTime -lt (Get-Date).AddSeconds(-60) -or -not $JobVer ) {
        if ( $List.Where({$null -ne $_.Ping}) ) { $JobVer = .$JobVerScript -ArgumentList $List, $CredsDomain, $CommandCenterHost } }

    # start new JobWMI every X seconds
    if ( $JobWMI.PSBeginTime -lt (Get-Date).AddSeconds(-1) -or -not $JobWMI ) {
        if ( $List.Where({$null -ne $_.Ping}) ) { $JobWMI = Get-WmiObject -ComputerName $List.Where({$null -ne $_.Ping}).ServerName -Credential $CredsDomain -Query $Query -AsJob } }

    # Redraw the table once in about 1 second
    if ( $StopwatchDraw.ElapsedMilliseconds -ge 1000 ) {
        $StopwatchDraw.Restart()
        # Get info about current powershell process
        $Mem = "{0:n2}" -f [math]::round(($(Get-Process -Id $PID).WorkingSet64 | Measure-Object -Sum).Sum/1MB,2)
        $AvgMem = [math]::round((($AvgMem * $Iterations + $Mem) / ($Iterations + 1)),2)
        $Elapsed = "{0:00}:{1:mm}:{1:ss}" -f [math]::Floor(((get-date) - $StartTime).TotalHours),((get-date) - $StartTime)
        
        Clear-Host
        #Get-Job | Select-Object Id, Name, State, HasMoreData, PSBeginTime, PSEndTime, Command | Format-Table
        "PID: {0}  Mem: {1:n2}  Avg: {2:n2}  Elapsed: {4}  SEmem: {5}  GoodCTC: {6}  Jobs: {7}" -f $PID, $Mem, $AvgMem, $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss:fff'), $Elapsed, $List[0].SEmem, $List.Where({$null -ne $_.Ping}).Count, (Get-Job).Count
        $List | Select-Object @{Name='ServerName'; Expression={$_.ServerName -replace "^WTL-ADC-"}}, IPAddress, Ping, DSmem, SEmem, @{Name='LastInfo'; Expression={$_.DateTime.ToString("HH:mm:ss")}} -ExcludeProperty DateTime, PSComputerName, RunspaceId | Format-Table
        #$List | Select-Object @{Name='ServerName'; Expression={$_.ServerName -replace "^WTL-ADC-"}}, IPAddress, Ping, DSver, DSmem, SEver, SEmem, @{Name='LastInfo'; Expression={$_.DateTime.ToString("HH:mm:ss")}} -ExcludeProperty DateTime, PSComputerName, RunspaceId | Format-Table
        $Iterations++ }
    
    # Remove all jobs with old PSBeginTime
    $JobsToRemove = Get-Job | Where-Object { ( $_.PSBeginTime -lt (Get-Date).AddSeconds(-30) -and $_.State -ne 'Running' ) -or ( $_.State -ne 'Running' -and ( -not $_.HasMoreData ) ) }  # old and finished or finished and empty
    #$JobsToRemove | Select-Object Id, Name, State, HasMoreData, PSBeginTime, PSEndTime, Command | Format-Table
    $JobsToRemove | Remove-Job -Force

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