$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net', 'WTL-ADC-CTC-03.wtldev.net', 'WTL-ADC-CTC-04.wtldev.net', 'WTL-ADC-CTC-05.wtldev.net', 'WTL-ADC-CTC-06.wtldev.net', 'WTL-ADC-CTC-07.wtldev.net', 'WTL-ADC-CTC-08.wtldev.net', 'WTL-ADC-CTC-09.wtldev.net', 'WTL-ADC-CTC-10.wtldev.net', 'WTL-ADC-CTC-11.wtldev.net', 'WTL-ADC-CTC-12.wtldev.net', 'WTL-ADC-CTC-13.wtldev.net', 'WTL-ADC-CTC-14.wtldev.net', 'WTL-ADC-CTC-15.wtldev.net', 'WTL-ADC-CTC-16.wtldev.net', 'WTL-ADC-CTC-17.wtldev.net', 'WTL-ADC-CTC-18.wtldev.net', 'WTL-ADC-CTC-19.wtldev.net', 'WTL-ADC-CTC-20.wtldev.net', 'WTL-ADC-CTC-21.wtldev.net', 'WTL-ADC-CTC-22.wtldev.net', 'WTL-ADC-CTC-23.wtldev.net', 'WTL-ADC-CTC-24.wtldev.net', 'WTL-ADC-CTC-25.wtldev.net', 'WTL-ADC-CTC-26.wtldev.net', 'WTL-ADC-CTC-27.wtldev.net', 'WTL-ADC-CTC-28.wtldev.net', 'WTL-ADC-CTC-29.wtldev.net', 'WTL-ADC-CTC-30.wtldev.net', 'WTL-ADC-CTC-31.wtldev.net', 'WTL-ADC-CTC-32.wtldev.net')
#$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net', 'WTL-ADC-CTC-32.wtldev.net')
# I want this variant to use one fast job for every CTC, which (job) will gather all required data from CTC and return it to the main script.
# Then when the job is done AND at is done at least 500 milliseconds ago, we remove current job and start new job with the same name.
# The memory is... The CPU is from 2 to 8 (at start). As for CTC CPU, it looks less intense than with continuous jobs.

$CredsDomain = [System.Management.Automation.PSCredential]::new('wtldev.net\vadc',(ConvertTo-SecureString -AsPlainText $env:vPW -Force))
$CommandCenterHost = HOSTNAME.EXE
$List = New-Object 'System.Collections.Generic.List[PSCustomObject]'

$ScriptBlock = {
    [CmdletBinding()]
    param ( $CommandCenterHost )
    $DSProcess = Get-Process -Name ADC1000NT -ErrorAction SilentlyContinue
    $ServicesProcesses = Get-Process -Name Harris* -ErrorAction SilentlyContinue
    [pscustomobject]@{
        DateTime = Get-Date
        ServerName = HOSTNAME.EXE
        Ping = Test-Connection $CommandCenterHost -Count 1 | Select-Object * -ExpandProperty ResponseTime
        #IPaddress = [System.Net.Dns]::GetHostAddresses($Name) | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -ExpandProperty IPAddressToString
        DSver = if (Test-Path 'C:\Users\Public\Desktop\ADC Device Server.lnk') {
            $sh = New-Object -ComObject WScript.Shell
            ((Get-ChildItem $sh.CreateShortcut('C:\Users\Public\Desktop\ADC Device Server.lnk').Targetpath).VersionInfo).ProductVersion
        } else {''}
        DSmem = if ($DSProcess) { "{0:n2}" -f [math]::round(($DSProcess.WorkingSet64 | Measure-Object -Sum).Sum/1MB,2) }
                else {''}
        SEver = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -eq 'ADC Services'} | Select-Object -Property DisplayVersion).DisplayVersion
        SEmem = if ($ServicesProcesses) {
            "{0:n2}" -f [math]::Round((($ServicesProcesses.WorkingSet64 | Measure-Object -Sum).Sum/1MB),2)
        } else {''} } }

# Prepare the List which will work as a Table
foreach ($server in $CTC) {
    $obj = [PSCustomObject]@{
        ServerName = $server -replace '\.wtldev\.net$'
        IPAddress = [System.Net.Dns]::GetHostAddresses($server) | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -ExpandProperty IPAddressToString }
    $List.Add($obj)
    Invoke-Command -ComputerName $server -Credential $CredsDomain -ArgumentList $CommandCenterHost -AsJob -JobName $server -ScriptBlock $ScriptBlock | Out-Null }

# Set and start stopwatches to show table once every second and to remove all jobs once in an hour. Also remember general start time to be able to get get Elapsed time. $Iterations is the iteration counter to calculate AVGmem
$StopwatchDraw = [System.Diagnostics.Stopwatch]::new()
$StopwatchDraw.Start()
$StopwatchReset = [System.Diagnostics.Stopwatch]::new()
$StopwatchReset.Start()
$StartTime = Get-Date
$Iterations = 0

while ( $true ) {  # Main cycle
    # Handle Jobs. Get results from all Jobs, find corresponding indexes in the List and rewrite them with the new data. Also remove and restart hanging jobs
    foreach ( $job in Get-Job ) {
        $Result = Receive-Job $job -ErrorAction SilentlyContinue
        $index = $List.FindIndex({ param($item) $item.ServerName -eq $Result.ServerName })  # Looking for an index of a row in the List corresponding to received result
        if ($index -ne -1) { $List[$index] = $Result }  # Update the List's row with the new data
        if ( ((Get-Date) - $job.PSBeginTime).TotalSeconds -ge 3) {  # if job is started earlier than X ago, starting it again with the same name
            Remove-Job -Name $job.Name -Force
            $job = Invoke-Command -ComputerName $job.Name -Credential $CredsDomain -ArgumentList $CommandCenterHost -AsJob -JobName $job.Name -ScriptBlock $ScriptBlock } }
    
    # Handle List Rows which have not been updated for a while (reset a row if not updated for more than X seconds). Create an intermediate object to avoid BadEnumeration error
    $ObjectsToReset = $List | Where-Object { $_.DateTime } | Where-Object { ((Get-Date) - $_.DateTime).TotalSeconds -ge 5 }
    $ObjectsToReset | ForEach-Object {
        $index = $List.FindIndex({ param($item) $item.ServerName -eq $_.ServerName })
        $Result = [PSCustomObject]@{
            ServerName = $_.ServerName
            IPAddress = $_.IPAddress}
        if ($index -ne -1) { $List[$index] = $Result } }

    # Redraw the table once in about 1 second
    if ( $StopwatchDraw.ElapsedMilliseconds -ge 900 ) {
        $StopwatchDraw.Restart()
        # Get info about current powershell process
        $Mem = "{0:n2}" -f [math]::round(($(Get-Process -Id $PID).WorkingSet64 | Measure-Object -Sum).Sum/1MB,2)
        $AvgMem = [math]::round((($AvgMem * $Iterations + $Mem) / ($Iterations + 1)),2)
        $Elapsed = "{0:00}:{1:mm}:{1:ss}" -f [math]::Floor(((get-date) - $StartTime).TotalHours),((get-date) - $StartTime)
        
        Clear-Host
        "PID: {0}  Mem: {1:n2}  Avg: {2:n2}  Elapsed: {4}  SEmem: {5}  GoodCTC: {6}  Jobs: {7}" -f $PID, $Mem, $AvgMem, $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss:fff'), $Elapsed, $List[0].SEmem, $List.Where({$null -ne $_.Ping}).Count, (Get-Job).Count
        $List | Select-Object *, @{Name='LastInfo'; Expression={$_.DateTime.ToString("HH:mm:ss")}} -ExcludeProperty DateTime, PSComputerName, RunspaceId | Format-Table
        $Iterations++ }
    
    # Force remove all jobs and start them again once in an hour
    if ( $StopwatchReset.Elapsed.Hours -ge 1 ) { 
        $StopwatchReset.Restart()
        foreach ($server in $CTC) { 
            Invoke-Command -ComputerName $server -Credential $CredsDomain -ArgumentList $CommandCenterHost -AsJob -JobName $server -ScriptBlock $ScriptBlock | Out-Null } }

    Start-Sleep -Milliseconds 200 }