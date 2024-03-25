$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net', 'WTL-ADC-CTC-03.wtldev.net', 'WTL-ADC-CTC-04.wtldev.net', 'WTL-ADC-CTC-05.wtldev.net', 'WTL-ADC-CTC-06.wtldev.net', 'WTL-ADC-CTC-07.wtldev.net', 'WTL-ADC-CTC-08.wtldev.net', 'WTL-ADC-CTC-09.wtldev.net', 'WTL-ADC-CTC-10.wtldev.net', 'WTL-ADC-CTC-11.wtldev.net', 'WTL-ADC-CTC-12.wtldev.net', 'WTL-ADC-CTC-13.wtldev.net', 'WTL-ADC-CTC-14.wtldev.net', 'WTL-ADC-CTC-15.wtldev.net', 'WTL-ADC-CTC-16.wtldev.net', 'WTL-ADC-CTC-17.wtldev.net', 'WTL-ADC-CTC-18.wtldev.net', 'WTL-ADC-CTC-19.wtldev.net', 'WTL-ADC-CTC-20.wtldev.net', 'WTL-ADC-CTC-21.wtldev.net', 'WTL-ADC-CTC-22.wtldev.net', 'WTL-ADC-CTC-23.wtldev.net', 'WTL-ADC-CTC-24.wtldev.net', 'WTL-ADC-CTC-25.wtldev.net', 'WTL-ADC-CTC-26.wtldev.net', 'WTL-ADC-CTC-27.wtldev.net', 'WTL-ADC-CTC-28.wtldev.net', 'WTL-ADC-CTC-29.wtldev.net', 'WTL-ADC-CTC-30.wtldev.net', 'WTL-ADC-CTC-31.wtldev.net', 'WTL-ADC-CTC-32.wtldev.net')
#$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net', 'WTL-ADC-CTC-32.wtldev.net')
# I want this variant to use one continuous job for every CTC, which (job) will last several seconds on CTC gathering all required data and return it part by part to the main script. 
# The memory is about 220 MB. Looks stable. But the script loads CPU by about 7%. And loads 

$CredsDomain = [System.Management.Automation.PSCredential]::new('wtldev.net\vadc',(ConvertTo-SecureString -AsPlainText $env:vPW -Force))
$CommandCenterHost = HOSTNAME.EXE
$List = New-Object 'System.Collections.Generic.List[PSCustomObject]'

$ScriptBlock = {
    [CmdletBinding()]
    param ( $CommandCenterHost )
    while ( $true ) {  # infinitely send any data back to main script by the jobs
        $DSProcess = Get-Process -Name ADC1000NT -ErrorAction SilentlyContinue
        $ServicesProcesses = Get-Process -Name Harris* -ErrorAction SilentlyContinue
        $Result = [pscustomobject]@{
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
                "{0:n2}" -f [math]::Round((((Get-Process -Name Harris*).WorkingSet64 | Measure-Object -Sum).Sum/1MB),2)
            } else {''}
        }
        Write-Output $Result
        Start-Sleep -Milliseconds 900
    }
}

foreach ($server in $CTC) {
    $obj = [PSCustomObject]@{
        ServerName = $server -replace '\.wtldev\.net$'
        IPAddress = [System.Net.Dns]::GetHostAddresses($server) | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -ExpandProperty IPAddressToString
    }
    $List.Add($obj)
    Invoke-Command -ComputerName $server -Credential $CredsDomain -ArgumentList $CommandCenterHost -AsJob -JobName $server -ScriptBlock $ScriptBlock | Out-Null
}

# Set and start a stopwatch to show table once every second
$StopwatchDraw = [System.Diagnostics.Stopwatch]::new()
$StopwatchDraw.Start()

$StartTime = Get-Date
$qt = 0

while ( $true ) {  # Main cycle
    # Get results from all Jobs, find corresponding indexes in the List and rewrite them with the new data
    foreach ( $job in Get-Job) {  # assuming we only have the number of jobs equal to the number of CTC
        $Result = Receive-Job $job -ErrorAction SilentlyContinue 
        $index = $List.FindIndex({ param($item) $item.ServerName -eq $Result.ServerName })
        if ($index -ne -1) { $List[$index] = $Result }  # Update the List

        if ( $job.State -ne "Running" ) {  # if job is finished, starting it again with the same name
            Remove-Job -Name $job.Name -Force
            $job = Invoke-Command -ComputerName $job.Name -Credential $CredsDomain -ArgumentList $CommandCenterHost -AsJob -JobName $job.Name -ScriptBlock $ScriptBlock  # Assign new job to $job to be able to smth with it down the script block
        }

        if ( ((Get-Date) - $job.PSBeginTime).TotalSeconds -ge 5 ) {
            Remove-Job -Name $job.Name -Force
            $job = Invoke-Command -ComputerName $job.Name -Credential $CredsDomain -ArgumentList $CommandCenterHost -AsJob -JobName $job.Name -ScriptBlock $ScriptBlock
        }
    }
    
    # Handle List Rows which have not been updated for a while (reset a row if not updated for more than 5 seconds). Create interobject to avoid BadEnumeration error
    $ObjectsToReset = $List | Where-Object { $_.DateTime } | Where-Object { ((Get-Date) - $_.DateTime).TotalSeconds -ge 5 }
    $ObjectsToReset | ForEach-Object {
        $index = $List.FindIndex({ param($item) $item.ServerName -eq $_.ServerName })
        $Result = [PSCustomObject]@{
            ServerName = $_.ServerName
            IPAddress = $_.IPAddress
        }
        if ($index -ne -1) { $List[$index] = $Result }
    }

    # Redraw the table once in about 1 second
    if ( $StopwatchDraw.ElapsedMilliseconds -ge 900 ) {
        # Get info about current powershell process
        $Mem = "{0:n2}" -f [math]::round(($(Get-Process -Id $PID).WorkingSet64 | Measure-Object -Sum).Sum/1MB,2)
        $AvgMem = [math]::round((($AvgMem * $qt + $Mem) / ($qt + 1)),2)
        $Elapsed = "{0:00}:{1:mm}:{1:ss}" -f [math]::Floor(((get-date) - $StartTime).TotalHours),((get-date) - $StartTime)
        
        Clear-Host
        "PID: {0}  Mem: {1:n2}  Avg: {2:n2}  Elapsed: {4}  SEmem: {5}  GoodCTC: {6}  Jobs: {7}" -f $PID, $Mem, $AvgMem, $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss:fff'), $Elapsed, $List[0].SEmem, $List.Where({$null -ne $_.Ping}).Count, (Get-Job).Count
        $List | Select-Object *, @{Name='LastInfo'; Expression={$_.DateTime.ToString("HH:mm:ss")}} -ExcludeProperty DateTime, PSComputerName, RunspaceId | Format-Table
        $StopwatchDraw.Restart()
        $qt++
    }
    #Start-Sleep -Milliseconds 10
}