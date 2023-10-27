function GD {Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'}
function newLog {
    $Global:logFile = "C:\PS\logs\$(Get-Date -Format 'yyyy-MM-dd HH-mm-ss').csv"
    New-Item -Path $logFile -Force | Out-Null
    $string = "Time"
    $Global:table.Values | Where-Object {$_.Id -gt 0} | ForEach-Object {$string += ",$($_.Name)($($_.Id))MEM"; $string += ",$($_.Name)($($_.Id))CPU"}
    $string | Out-File $logFile -Append ascii
}
function newLogSum {
    $Global:logFileSum = "C:\PS\logs\$(Get-Date -Format 'yyyy-MM-dd HH-mm-ss').csv"
    New-Item -Path $logFileSum -Force | Out-Null
    $string = "Time,SUM-MEM,SUM-CPU,NumOfProcs"
    $string | Out-File $logFileSum -Append ascii
}
function newProcs {
    do {
        Write-Host "Now you have to enter a Key Word corresponding to the Name or Description or PID of a processes to watch." -f Yellow -b Black
        Write-Host "Be careful with the Key Word. If some new process suitable for your Key Word will appear in the system later, it will be added to the list automatically." -f Yellow -b Black
        Write-Host "You can also type several keywords separated by comma. They all will be used at once to filter the processes list." -f Yellow -b Black
        Write-Host "Later you will be able to enter new Key Word by pressing <N>." -f Cyan -b Black
        $Global:EnteredWords = Read-Host "Enter Key Word(s)"
        #$Global:EnteredWords = 'pwsh'
        $Global:ProcKeyWords = $Global:EnteredWords -join '|'
        updProcs
        
        if ($Global:table.Values | Where-Object {$_.Id -gt 0}) {
            Get-Process -Id ($Global:table.Values.Id | Where-Object {$_ -gt 0}) -ea SilentlyContinue | Select-Object -Property Name,Id -Unique | Format-Table
            $agree = Read-Host "Are you OK with these processes? Default is 'yes' (y/n)"
        }
        else {
            Write-Host "There are no processes found with key word(s) '$EnteredWords'." -f Red -b Black
            $agree = Read-Host "Are you OK with the key word(s) '$EnteredWords'? Default is 'yes' (y/n)"
        }
    } while ($agree -match 'n|N')
}
function zero {
    $Global:peakCpu = $Global:peakMem = $Global:lowCpu = $Global:lowMem = [decimal]0
    $Global:peakDateCpu = $Global:peakDateMem = $Global:lowDateCpu = $Global:lowDateMem = $null
    $Global:logging = $Global:loggingSum = $null
    $Global:startTime = Get-Date
    $Global:qt = [uint64]0
}
function updProcs {
    $Global:timeGetProcs = Measure-Command {$Global:procs = Get-Process | Where-Object {$_.Id -match $Global:ProcKeyWords -or $_.Name -match "$Global:ProcKeyWords|Idle"}}  # getting processes by the key words
    if ((($Global:table.Values.Id | Sort-Object) -join '') -ne (($Global:procs.Id | Sort-Object) -join '')) {  # old Table process IDs are not equal to newly found process IDs
        $Global:timeGetRawProcess = Measure-Command {
            $Global:table = [ordered]@{}
            Get-WmiObject -Query "SELECT Name,IDProcess,PercentProcessorTime,WorkingSet,Timestamp_Sys100NS FROM Win32_PerfRawData_PerfProc_Process WHERE NOT Name='_Total'" | Where-Object {$_.Name -match "$Global:ProcKeyWords|Idle"} | ForEach-Object {
                if ($_.Name -ne 'Idle') {
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
            if (-not $Global:table.Values.Id) {$Global:table.Add($Global:ProcKeyWords, [PSCustomObject]@{  # when no processes found by key words
                Name = "$Global:ProcKeyWords"
                Id = [int]0
                Memory = [int]0
                CPU = [int]0})
                $Global:logging = $Global:loggingSum = $null
            } else {if ($Global:logging) {newLog}; if ($Global:loggingSum) {newLogSum}}  # if there are some processes found by the key words, we may create new log files


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
function updCounters {
    $Global:timeAllRawProcess = Measure-Command {
        $allRawProcesses = [ordered]@{}
        Get-WmiObject -Query "SELECT Name,IDProcess,PercentProcessorTime,WorkingSet,Timestamp_Sys100NS FROM Win32_PerfRawData_PerfProc_Process WHERE NOT Name='_Total'" | ForEach-Object {
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
            if ($id) {  # there are fields without Id like Sum/Low/Avg/Peak/Total and --------- dividers
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
#Clear-Host
newProcs
zero
$debug = 1

do {
    $timeMain0 = (Get-Date)
    $Global:timeProcs = Measure-Command {
        updProcs
    }
    $Global:timeCounters = Measure-Command {
        updCounters
    }

    $Global:timePeakLowAvg = Measure-Command {
        if ($table.'Sum'.CPU + $table.'Sum'.Memory -eq 0) {$zeroFlag++} else {$zeroFlag=0}
        if (($zeroFlag -eq 5) -or (($table.'Sum'.CPU+$table.'Sum'.Memory -eq 0) -and ((Get-Date)-($startTime)).TotalSeconds -le 5)) {$zeroFlag=0 ; zero}
        $peakCpu = if ($peakCpu -lt $table.'Sum'.CPU) {$table.'Sum'.CPU; $peakDateCpu = Get-Date} else {$peakCpu}
        [int]$table.'Peak'.CPU = $peakCPU
        $peakMem = if ($peakMem -lt $table.'Sum'.Memory) {$table.'Sum'.Memory; $peakDateMem = Get-Date} else {$peakMem}
        [int]$table.'Peak'.Memory = $peakMem
        $lowCpu = if ($lowCpu -gt $table.'Sum'.CPU) {$table.'Sum'.CPU; $lowDateCpu = Get-Date} else {$lowCpu}
        [int]$table.'Low'.CPU = $lowCPU
        $lowMem = if (($lowMem -gt $table.'Sum'.Memory) -or ($lowMem -eq 0)) {$table.'Sum'.Memory; $lowDateMem = Get-Date} else {$lowMem}
        [int]$table.'Low'.Memory = $lowMem
        [double]$avgCpu = ($avgCpu * $qt + $table.'Sum'.DecimalCPU) / ($qt + 1)
        [int]$table.'Average'.CPU = $avgCpu
        $avgMem = ($avgMem * $qt + $table.'Sum'.Memory) / ($qt + 1)
        [int]$table.'Average'.Memory = $avgMem
        $qt++
    }

    if (-not $Debug) {Clear-Host}
    $Global:table.Values | Select-Object -Property Name, Id, Memory, CPU, DecimalCPU | Format-Table -AutoSize
    
    $diff = ((get-date) - $startTime)
    Write-Host ("Elapsed {0:00}:{1:mm}:{1:ss}  (F1) - help" -f [math]::Floor($diff.TotalHours),$diff) -f Gray
    
    if ($logging) {
        Write-Host $logFile -f Cyan
        $string = "$(GD)"
        $Global:table.Values | Where-Object {$_.Id -gt 0} | ForEach-Object {
            $string += ",$($_.Memory),$($_.CPU)"
        }
        $string | Out-File $logFile -Append ascii
    }
    if ($loggingSum) {  # Time,SUM-MEM,SUM-CPU,NumOfProcs
        Write-Host $logFileSum -f Magenta
        $string = "$(GD)"
        $Global:table.'Sum' | ForEach-Object {$string += ",$($_.Memory),$($_.CPU),"}
        $string += ($Global:table.Values | Where-Object {$_.Id -gt 0}).Count
        $string | Out-File $logFileSum -Append ascii
    }
    if ($infoCounter) {
        Write-Host (
            "Mem peak: {0}`t({2:MMM,dd HH:mm:ss})`nCPU peak: {1} `t({3:MMM,dd HH:mm:ss})" -f [math]::Round($table.'Peak'.Memory),[math]::Round($table.'Peak'.CPU),$peakDateMem,$peakDateCpu
        ) -f 7
        Write-Host "Press <C> - clear Peak/Avg/Timer" -f 7
        Write-Host "Press <N> - enter new keyword" -f 7
        Write-Host "Press <L> - CSV log (every process)" -f 7
        Write-Host "Press <M> - CSV log (sum of procs)" -f 7
        $infoCounter--
    }
    if ($debug) {
        #Write-Host "$([int]$Global:timeProcs.TotalMilliseconds) `tms for updProcs"
            Write-Host "$([int]$Global:timeGetProcs.TotalMilliseconds) `tms to get procs in updProcs"
            Write-Host "$([int]$Global:timeGetRawProcess.TotalMilliseconds) `tms to get allRawProcesses in updProcs"
        #Write-Host "$([int]$Global:timeCounters.TotalMilliseconds) `tms for updCounters"
            Write-Host "$([int]$Global:timeAllRawProcess.TotalMilliseconds) `tms to get allRawProcesses in updCounters"
            Write-Host "$([int]$Global:timeToUpdateTable.TotalMilliseconds) `tms to update Table in updCounters"
            Write-Host "$([int]$Global:timePeakLowAvg.TotalMilliseconds) `tms to update Table in main"
        $Global:timeMain = $Global:timeProcs = $Global:timeGetProcs = $Global:timeGetRawProcess = $Global:timeCounters = $Global:timeAllRawProcess = $Global:timeToUpdateTable = $Global:timePeakLowAvg = 0
    }
    
    $timeMain1 = [int]((Get-Date) - $timeMain0).TotalMilliseconds
    if ($debug) {Write-Host "$timeMain1 `tms TOTAL"}
    if ($timeMain1 -lt 999) {Start-Sleep -Milliseconds (999 - $timeMain1)}

    #looking for <Esc> or <R> or <Space> press
    if ($host.ui.RawUi.KeyAvailable) {
        $key=$host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown,IncludeKeyUp")
        $host.UI.RawUI.FlushInputBuffer()
        if ($key.keydown) {
            switch ($key.VirtualKeyCode) {
                <#C#> 67 {zero; if ($logging) {newLog}; if ($loggingSum) {newLogSum}}
                <#L#> 76 {if ($logging) {$logging = 0} else {$logging = 1; newLog}}
                <#M#> 77 {if ($loggingSum) {$loggingSum = 0} else {$loggingSum = 1; newLogSum}}
                <#N#> 78 {newProcs; zero}
                <#Enter#> 13 {}
                <#Esc#> 27 {exit}
                <#Space#> 32 {}
                <#F1#> 112 {$infoCounter = 5} #to show help and peak cpu/mem time
            } #end switch
        }
    } #end if
} until ($key.VirtualKeyCode -eq 27)