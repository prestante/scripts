function GD {Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'}
function NewLog {
    $Global:logFile = "C:\PS\logs\$(Get-Date -Format 'yyyy-MM-dd HH-mm-ss').csv"
    New-Item -Path $logFile -Force | Out-Null
    $string = "Time"
    $Global:table.Values | Where-Object {$_.Id -gt 0} | ForEach-Object {$string += ",$($_.Name)($($_.Id))MEM"; $string += ",$($_.Name)($($_.Id))CPU"}
    $string | Out-File $logFile -Append ascii
}
function NewLogSum {
    $Global:logFileSum = "C:\PS\logs\$(Get-Date -Format 'yyyy-MM-dd HH-mm-ss').csv"
    New-Item -Path $logFileSum -Force | Out-Null
    $procs = ($Global:ProcKeyWords).Split(',') -join ' | '
    $string = "Time,MEM($procs),CPU($procs),NumOfProcs"
    $string | Out-File $logFileSum -Append ascii
}
function NewProcs {
    do {
        Write-Host "Now you have to enter a Key Word corresponding to the Name or PID of processes to watch." -f Yellow -b Black
        Write-Host "Be careful with the Key Word. If some new process suitable for your Key Word will appear in the system later, it will be added to the list automatically." -f Yellow -b Black
        Write-Host "You can also type several Key Words separated by comma. They all will be used at once to filter the processes list." -f Yellow -b Black
        Write-Host "Later you will be able to enter a new Key Word after pressing <N>." -f Cyan -b Black
        $Global:ProcKeyWords = Read-Host "Enter Key Word(s)"
        #$Global:ProcKeyWords = 'pwsh'
        UpdProcs
        
        if ($Global:table.Values | Where-Object {$_.Id -gt 0}) {
            Get-Process -Id ($Global:table.Values.Id | Where-Object {$_ -gt 0}) -ea SilentlyContinue | Select-Object -Property Name,Id -Unique | Format-Table
            $agree = Read-Host "Are you OK with these processes? Default is 'yes' (y/n)"
        }
        else {
            Write-Host "There are no processes found with key word(s) '$ProcKeyWords'." -f Red -b Black
            $agree = Read-Host "Are you OK with the Key Word(s) '$ProcKeyWords'? Default is 'yes' (y/n)"
        }
    } while ($agree -match 'n|N')
}
function Zero {
    $Global:peakCpu = $Global:peakMem = $Global:lowCpu = $Global:lowMem = [decimal]0
    $Global:peakDateCpu = $Global:peakDateMem = $Global:lowDateCpu = $Global:lowDateMem = $null
    $Global:logging = $Global:loggingSum = $null
    $Global:startTime = Get-Date
    $Global:qt = [uint64]0
}
function ComposeQuery {
    $query = "SELECT Name,IDProcess,PercentProcessorTime,WorkingSet,Timestamp_Sys100NS FROM Win32_PerfRawData_PerfProc_Process WHERE ((Name = 'Idle')"
    $Global:ProcKeyWords.Split(',') | ForEach-Object {
        if ($_ -match '^[\d]*$') {$query +=  " OR (IDProcess = $_)"}  # if the word consists of only digits, then we consider it as an IDProcess
        else {$query += " OR (Name like '%$_%')"}  # else we consider it as a Name
    }
    $query += ") AND (NOT Name like '_Total')"
    return $query
}
function UpdProcs {
    # My idea is to only get wmi objects for processes found by get-process plus Idle for calculating TOTAL. It should be really fast. 
    # Or to get wmi objects using a query with keywords divided by OR operator "WHERE Name like '%Key1%' OR Name like '%Key2%'"            <-- For now this option is chosen
    $getProcExpression = "`$Global:procs = Get-Process | Where-Object {`$_.Id -in `$Global:ProcKeyWords.split(',')"  # forming an expression to find all procs by Get-Process
    $Global:ProcKeyWords.split(',') | ForEach-Object {if ($_ -notmatch '^[\d]*$') {$getProcExpression += " -or `$_.ProcessName -match '$_'"}}  # if this is not a string consisting of only digits, the we consider it as an ProcessName
    $getProcExpression += '} | Where-Object {$_.ProcessName -ne "Idle"}'
    $Global:timeGetProcs = Measure-Command {Invoke-Expression $getProcExpression}  # getting processes by the key words

    if ((($Global:table.Values.Id | Sort-Object) -join '') -ne (($Global:procs.Id | Sort-Object) -join '')) {  # old Table process IDs are not equal to newly found process IDs
        $Global:timeGetRawProcess = Measure-Command {
            $Global:table = [ordered]@{}
            Get-WmiObject -Query (ComposeQuery) | ForEach-Object {
                if ($_.Name -ne 'Idle') {  # for all non-Idle objects, aka main table processes
                    $Global:table.Add([string]$_.IDProcess, [PSCustomObject]@{
                        Name = [string]$_.Name  -replace '^Harris.Automation.ADC.Services.' -replace 'Host' -replace 'Service' -replace 'Validation' -replace '#\d+$'
                        Id = [int]$_.IDProcess
                        Memory = [int]0
                        CPU = [int]0
                        DecimalCPU = [decimal]0
                        Start = (Get-Process -Id $_.IDProcess -ea SilentlyContinue).StartTime  # looks like it doesn't affect the performance, however it sometimes leads to errors
                        LastPercentProcessorTime = [UInt64]$_.PercentProcessorTime
                        LastWorkingSet = [UInt64]$_.WorkingSet
                        LastTimestamp_Sys100NS = [UInt64]$_.Timestamp_Sys100NS
                    })
                } else {$idleLastPercentProcessorTime = [UInt64]$_.PercentProcessorTime; $idleLastTimestamp_Sys100NS = [UInt64]$_.Timestamp_Sys100NS}  # saving Idle process CPU for later using in TOTAL
            }
            if (-not ($Global:table.Values | Where-Object {$_.Id -gt 0})) {$Global:table.Add($Global:ProcKeyWords, [PSCustomObject]@{  # when no processes found by key words. Idle has Id 0, so it won't interfere here
                Name = "$Global:ProcKeyWords"
                Id = [string]''
                Memory = [int]0
                CPU = [int]0})
                $Global:logging = $Global:loggingSum = $null
            } elseif ($Global:logging) {$Global:logging = $null}  # if some processes found by the key words and the list of ID has changed, we should disable individual proc logging

            $Global:table.Add('Divider', [PSCustomObject]@{Name = '---------------'})
            $Global:table.Add('Sum', [pscustomobject]@{Name = 'Sum'; Memory = [int]0; CPU = [int]0; DecimalCPU = [decimal]0})
            $Global:table.Add('Space1', [PSCustomObject]@{})
            $Global:table.Add('Peak', [pscustomobject]@{Name = 'Peak'; Memory = [int]0; CPU = [int]0})
            $Global:table.Add('Average', [pscustomobject]@{Name = 'Average'; Memory = [int]0; CPU = [int]0; DecimalCPU = [decimal]0})
            $Global:table.Add('Low', [pscustomobject]@{Name = 'Low'; Memory = [int]0; CPU = [int]0})
            $Global:table.Add('Space2', [PSCustomObject]@{})
            $Global:table.Add('TOTAL', [PSCustomObject]@{
                Name = 'TOTAL'
                LastMemory = [int]0
                Memory = [int]0
                LastCPU = [int]0
                CPU = [int]0
                LastPercentProcessorTime = $idleLastPercentProcessorTime
                LastTimestamp_Sys100NS = $idleLastTimestamp_Sys100NS
            })
        }
    }
}
function UpdCounters {
    # My idea is to only get wmi objects for processes found by get-process plus Idle for calculating TOTAL. It should be really fast.
    $Global:timeAllRawProcess = Measure-Command {
        $allRawProcesses = [ordered]@{}
        Get-WmiObject -Query (ComposeQuery) | ForEach-Object {
            $allRawProcesses.Add([string]$_.IDProcess, [PSCustomObject]@{
                Name = [string]$_.Name
                IDProcess = [int]$_.IDProcess
                PercentProcessorTime = [uint64]$_.PercentProcessorTime
                WorkingSet = [uint64]$_.WorkingSet
                Timestamp_Sys100NS = [uint64]$_.Timestamp_Sys100NS
            })
        }
    }
    
    $Global:table."Sum".Memory = $Global:table."Sum".CPU = $Global:table."Sum".DecimalCPU = [decimal]0
    $Global:timeToUpdateTable = Measure-Command {
        foreach ($id in $Global:table.Values.Id) {
            if ($id) {  # there are fields without Id like Sum/Low/Avg/Peak/Total and '---------' dividers
                $Global:table."$id".Memory = [int]($allRawProcesses."$id".WorkingSet/1mb)
                $Global:table."$id".DecimalCPU = ($allRawProcesses."$id".PercentProcessorTime - $Global:table."$id".LastPercentProcessorTime) / ($allRawProcesses."$id".Timestamp_Sys100NS - $Global:table."$id".LastTimestamp_Sys100NS) / $Global:LogicalCPUs * 100
                $Global:table."$id".CPU = [int]$Global:table."$id".DecimalCPU
                $Global:table."$id".LastWorkingSet = $allRawProcesses."$id".WorkingSet
                $Global:table."$id".LastPercentProcessorTime = $allRawProcesses."$id".PercentProcessorTime
                $Global:table."$id".LastTimestamp_Sys100NS = $allRawProcesses."$id".Timestamp_Sys100NS
                $Global:table.'Sum'.Memory += $Global:table."$id".Memory
                $Global:table.'Sum'.DecimalCPU += $Global:table."$id".DecimalCPU
            }
        }
        $Global:table."Sum".CPU = [int]$Global:table.'Sum'.DecimalCPU
        $Global:table.'TOTAL'.CPU = [int](100-[math]::Floor(($allRawProcesses.'0'.PercentProcessorTime - $Global:table.'TOTAL'.LastPercentProcessorTime) / ($allRawProcesses.'0'.Timestamp_Sys100NS - $Global:table.'TOTAL'.LastTimestamp_Sys100NS) / $Global:LogicalCPUs * 100))
        $Global:table.'TOTAL'.Memory = [int]($Global:totalMemory - (Get-WmiObject Win32_PerfRawData_PerfOS_Memory).AvailableBytes/1mb)
        $Global:table.'TOTAL'.LastPercentProcessorTime = $allRawProcesses.'0'.PercentProcessorTime
        $Global:table.'TOTAL'.LastTimestamp_Sys100NS = $allRawProcesses.'0'.Timestamp_Sys100NS
    }
}


Write-Host "Gathering system information..." -fo Yellow -ba Black
Remove-Variable * -ea SilentlyContinue
$Global:LogicalCPUs = (Get-WmiObject Win32_PerfRawData_PerfOS_Processor).Count - 1
$Global:totalMemory = (Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).sum /1mb
$Global:table = [ordered]@{'initKey' = [PSCustomObject]@{Id = 0}}  # for the initial compare with Get-Process results in UpdProcs in case of no-result keyword
Clear-Host
NewProcs
Zero
#return

do {
    $timeMain0 = (Get-Date)
    $Global:timeProcs = Measure-Command {UpdProcs}
    $Global:timeCounters = Measure-Command {UpdCounters}

    if ($Global:table.'Sum'.CPU + $Global:table.'Sum'.Memory -eq 0) {$zeroFlag++} else {$zeroFlag=0}
    if (($ZeroFlag -eq 5) -or (($Global:table.'Sum'.CPU+$Global:table.'Sum'.Memory -eq 0) -and ((Get-Date)-($startTime)).TotalSeconds -le 5)) {$zeroFlag=0 ; Zero}
    $Global:peakCpu = if ($Global:peakCpu -lt $Global:table.'Sum'.CPU) {$Global:table.'Sum'.CPU; $Global:peakDateCpu = Get-Date} else {$Global:peakCpu}
    [int]$Global:table.'Peak'.CPU = $Global:peakCpu
    $Global:peakMem = if ($Global:peakMem -lt $Global:table.'Sum'.Memory) {$Global:table.'Sum'.Memory; $peakDateMem = Get-Date} else {$Global:peakMem}
    [int]$Global:table.'Peak'.Memory = $Global:peakMem
    $Global:lowCpu = if ($Global:lowCpu -gt $Global:table.'Sum'.CPU) {$Global:table.'Sum'.CPU; $lowDateCpu = Get-Date} else {$Global:lowCpu}
    [int]$Global:table.'Low'.CPU = $Global:lowCpu
    $Global:lowMem = if (($Global:lowMem -gt $Global:table.'Sum'.Memory) -or ($Global:lowMem -eq 0)) {$Global:table.'Sum'.Memory; $lowDateMem = Get-Date} else {$Global:lowMem}
    [int]$Global:table.'Low'.Memory = $Global:lowMem
    [double]$Global:avgCpu = ($Global:avgCpu * $Global:qt + $Global:table.'Sum'.DecimalCPU) / ($Global:qt + 1)
    [int]$Global:table.'Average'.CPU = $Global:avgCpu
    $Global:avgMem = ($Global:avgMem * $Global:qt + $Global:table.'Sum'.Memory) / ($Global:qt + 1)
    [int]$Global:table.'Average'.Memory = $Global:avgMem

    #if (-not $Debug) {Clear-Host}
    Clear-Host
    $Global:table.Values | Select-Object -Property Name, Id, Memory, CPU | Format-Table -AutoSize
    $diff = ((get-date) - $startTime)
    Write-Host ("Elapsed {0:00}:{1:mm}:{1:ss}  (F1) - help" -f [math]::Floor($diff.TotalHours),$diff) -f Gray

    if ($Global:logging) {
        Write-Host $logFile -f Cyan
        $string = "$(GD)"
        $Global:table.Values | Where-Object {$_.Id -gt 0} | ForEach-Object {
            $string += ",$($_.Memory),$($_.CPU)"
        }
        $string | Out-File $logFile -Append ascii
    }
    if ($Global:loggingSum) {  # Time,SUM-MEM,SUM-CPU,NumOfProcs
        Write-Host $logFileSum -f Magenta
        $string = "$(GD)"
        $Global:table.'Sum' | ForEach-Object {$string += ",$($_.Memory),$($_.CPU),"}
        $string += ($Global:table.Values | Where-Object {$_.Id -gt 0}).Count
        $string | Out-File $logFileSum -Append ascii
    }
    if ($infoCounter) {
        Write-Host "Press <C> - clear Peak/Avg/Timer" -f 7
        Write-Host "Press <N> - enter new keyword" -f 7
        Write-Host "Press <L> - CSV log (every process)" -f 7
        Write-Host "Press <M> - CSV log (sum of procs)" -f 7
        Write-Host "Press <F4> - Enable/Disable debug" -f 7
        $infoCounter--
    }
    if ($debug) {
        Write-Host ("Mem peak: {0}`t({2:MMM,dd HH:mm:ss})`nCPU peak: {1} `t({3:MMM,dd HH:mm:ss})" -f [math]::Round($Global:table.'Peak'.Memory),[math]::Round($Global:table.'Peak'.CPU),$peakDateMem,$Global:peakDateCpu) -f 7
        #Write-Host "$([int]$Global:timeProcs.TotalMilliseconds) `tms for UpdProcs"
            Write-Host "$([int]$Global:timeGetProcs.TotalMilliseconds) `tms to Get-Process in UpdProcs"
            Write-Host "$([int]$Global:timeGetRawProcess.TotalMilliseconds) `tms to Get-WmiObject in UpdProcs"
        #Write-Host "$([int]$Global:timeCounters.TotalMilliseconds) `tms for UpdCounters"
            Write-Host "$([int]$Global:timeAllRawProcess.TotalMilliseconds) `tms to Get-WmiObject in UpdCounters"
            Write-Host "$([int]$Global:timeToUpdateTable.TotalMilliseconds) `tms to update table in UpdCounters"
        Write-Host "Spent:$timeMain, AvgSpent:$timeAvgMain, MaxSpent:$maxSpent at $maxSpentTime, Longs:$longs"
        $Global:timeGetRawProcess = $Global:timeAllRawProcess = $Global:timeToUpdateTable = 0
    }
    
    $timeMain = [int]((Get-Date) - $timeMain0).TotalMilliseconds
    if ($timeMain -lt 999) {Start-Sleep -Milliseconds (999 - $timeMain)} elseif ($timeMain -gt 2000) {$longs++}  # if cycle takes less than a second, waiting up to second. If more than 2 - increasing $longs
    $maxSpent = if ($maxSpent -lt $timeMain) {$maxSpentTime = "{0:HH}:{0:mm}:{0:ss}" -f (Get-Date); [int]$timeMain} else {[int]$maxSpent}
    $timeAvgMain = [int](($timeAvgMain * $Global:qt + $timeMain) / ($Global:qt + 1))
    $Global:qt++

    #looking for <Esc> or <R> or <Space> press
    if ($host.ui.RawUi.KeyAvailable) {
        $key=$host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown,IncludeKeyUp")
        $host.UI.RawUI.FlushInputBuffer()
        if ($key.keydown) {
            switch ($key.VirtualKeyCode) {
                <#C#> 67 {Zero}
                <#L#> 76 {if ($Global:logging) {$Global:logging = 0} elseif ($Global:table.Values | Where-Object {$_.Id -gt 0}) {$Global:logging = 1; NewLog}}
                <#M#> 77 {if ($Global:loggingSum) {$Global:loggingSum = 0} elseif ($Global:table.Values | Where-Object {$_.Id -gt 0}) {$Global:loggingSum = 1; NewLogSum}}
                <#N#> 78 {Zero; NewProcs}
                <#Enter#> 13 {}
                <#Esc#> 27 {exit}
                <#Space#> 32 {}
                <#F1#> 112 {$infoCounter = 5} #to show help
                <#F4#> 115 {if ($Debug) {$Debug = 0} else {$Debug = 1}}  # to show debug info
            } #end switch
        }
    } #end if
} until ($key.VirtualKeyCode -eq 27)