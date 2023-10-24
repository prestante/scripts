Remove-Variable * -ea SilentlyContinue
Write-Host "Reading CPU properties..." -fo Yellow -ba Black -NoNewline
$Global:LogicalCPUs = (Get-WmiObject Win32_PerfRawData_PerfOS_Processor).Count - 1
Write-Host "Done" -fo Yellow -ba Black
Write-Host "Reading Memory properties..." -fo Yellow -ba Black -NoNewline
$Global:totalMemory = (Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).sum /1mb
Write-Host "Done" -fo Yellow -ba Black
Update-TypeData -TypeName procListType -DefaultDisplayPropertySet 'Name','Id','Memory','CPU' -ea SilentlyContinue  # this is to display by default only props needed
$peakDateCpu = $peakDateMem = Get-Date  # starting date to compare newer dates with it
$Global:lastProcesses = @{ID=4294967296}  # impossible ID for a comparison in updProcs to show difference for the keywords with no processes
function GD {Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'}
function newLog {
    $Global:logFile = "C:\PS\logs\$(Get-Date -Format 'yyyy-MM-dd HH-mm-ss').csv"
    New-Item -Path $Global:logFile -Force | Out-Null
    $string = "Time"
    foreach ($id in $Global:table) {if ($id.Id) {$string += ",$($id.Name)($($id.Id))MEM"; $string += ",$($id.Name)($($id.Id))CPU"}}
    $string | Out-File $logFile -Append ascii
}
function newLogSum {
    $Global:logFileSum = "C:\PS\logs\$(Get-Date -Format 'yyyy-MM-dd HH-mm-ss').csv"
    New-Item -Path $Global:logFileSum -Force| Out-Null
    $string = "Time,SUM($($global:Processes.Count)procs)-MEM,SUM($($global:Processes.Count)procs)-CPU"
    $string | Out-File $logFileSum -Append ascii
}
function newProcs {
    do {
        #Write-Host "Now you have to enter a Key Word corresponding to the Name or Description or PID of a processes to watch." -f Yellow -b Black
        #Write-Host "Be careful with the Key Word. If some new process suitable for your Key Word will appear in the system later, it will be added to the list automatically." -f Yellow -b Black
        #Write-Host "You can also type several keywords separated by comma. They all will be used at once to filter the processes list." -f Yellow -b Black
        #Write-Host "Later you will be able to enter new Key Word by pressing <N>." -f Cyan -b Black
        #$Global:EnteredWords = Read-Host "Enter Key Word(s)"
        #$Global:EnteredWords = 'ADC.Services'
        $Global:EnteredWords = 'chrome'
        $Global:ProcKeyWords = $Global:EnteredWords -split ','
        updProcs
        return
        if ($Global:Processes) {
            $Global:Processes | Select-Object -Property Name,IdProcess -Unique | Format-Table
            $agree = Read-Host "Are you OK with these processes? Default is 'yes' (y/n)"
        }
        else {
            Write-Host "There are no processes found with key word(s) '$EnteredWords'." -f Red -b Black
            $agree = Read-Host "Are you OK with the key word(s) '$EnteredWords'? Default is 'yes' (y/n)"
        }
    } while ($agree -match 'n|N')
}
Function zero {
    $Global:peakCpu = $Global:peakMem = $Global:lowCpu = $Global:lowMem = [decimal]0
    $Global:peakDateCpu = $Global:peakDateMem = $Global:lowDateCpu = $Global:lowDateMem = $null
    $Global:logging = $Global:loggingSum = $null
    $Global:startTime = Get-Date
    $Global:qt = [uint64]0
}
function updProcs {
    $Global:timeGetRawProcess0 = (Get-Date)
    $Global:Processes = @()
    $allRawProcesses = Get-WmiObject -Query "SELECT * FROM Win32_PerfRawData_PerfProc_Process"  # Getting all processes raw information
    foreach ($ProcKeyWord in $Global:ProcKeyWords) {$Global:Processes += @($allRawProcesses | Where-Object {$_.Name -match $ProcKeyWord -or $_.IDProcess -match $ProcKeyWord})}

        if ((($Global:Processes.IdProcess | Sort-Object) -join '') -ne (($Global:lastProcesses.IdProcess | Sort-Object) -join '')) {  #processes list has been changed
        $Global:table = @()
        if ($Global:Processes.Name) {$Global:table += $Global:Processes | ForEach-Object{
            $tempID = $_.IdProcess  # just in case to avoid double $_ $_ in one string
            $obj = [pscustomobject]@{
                Name = $_.Name  -replace '^Harris.Automation.ADC.Services.' -replace 'Host' -replace 'Service' -replace 'Validation' -replace '#\d+$'
                Id = $tempID
                Memory = 0
                CPU = 0
                Start = (Get-Process -Id $_.IDProcess).StartTime  # looks like it doesn't affect the performance
                LastRawMEM = $allRawProcesses.Where({$_.IDProcess -eq $tempID}).WorkingSet
                LastRawCPU = $allRawProcesses.Where({$_.IDProcess -eq $tempID}).PercentProcessorTime
                LastTimestamp = $allRawProcesses.Where({$_.IDProcess -eq $tempID}).Timestamp_Sys100NS
            }
            $obj.PSTypeNames.Add("procListType")
            $obj
        }} else {$Global:table += [pscustomobject]@{
                Name = "$Global:enteredWords"
                Id = "N/A"
                Memory = 0
                CPU = 0}
                $Global:logging = $Global:loggingSum = $null
            }
        $Global:table += [pscustomobject]@{
            Name = '---------------'
        }
        $Global:table += [pscustomobject]@{
            Name = 'Sum'
            Memory = 0
            CPU = 0
        }
        $Global:table += [pscustomobject]@{
        }
        $Global:table += [pscustomobject]@{
            Name = "Peak"
            Memory = 0
            CPU = 0
        }
        $Global:table += [pscustomobject]@{
            Name = 'Average'
            Memory = 0
            CPU = 0
        }
        $Global:table += [pscustomobject]@{
            Name = 'Low'
            Memory = 0
            CPU = 0
        }
        $Global:table += [pscustomobject]@{
        }
        $Global:table += [pscustomobject]@{
            Name = 'TOTAL'
            Memory = 0
            CPU = 0
            LastIdleCPU = $allRawProcesses.Where({$_.Name -eq 'Idle'}).PercentProcessorTime
            LastIdleTimestamp = $allRawProcesses.Where({$_.Name -eq 'Idle'}).Timestamp_Sys100NS
        }
        if ($Global:logging) {newLog}
        if ($Global:loggingSum) {newLogSum}
    }
    $Global:timeGetRawProcess = "$([int]((Get-Date) - $Global:timeGetRawProcess0).TotalMilliseconds) `tms to get allRawProcesses in updProcs"
    $Global:lastProcesses = $Global:Processes
}
Function updCounters {
    $Global:timeAllRawProcess0 = (Get-Date)
    $allRawProcesses = Get-WmiObject -Query "SELECT * FROM Win32_PerfRawData_PerfProc_Process"  # Getting all processes raw information
    $Global:timeAllRawProcess = "$([int]((Get-Date) - $Global:timeAllRawProcess0).TotalMilliseconds) `tms to get allRawProcesses in updCounters"
    
    $Global:timeToUpdateTable0 = (Get-Date)
    $sumMem = $sumCpu = [decimal]0
    foreach ($id in ($Global:Processes.IdProcess)) {
        $allRawProcesses | Where-Object {$_.IDProcess -eq $id} | ForEach-Object {
            $currentProc = $allRawProcesses.Where({$_.IDProcess -eq $id})  # just for shortening the cpu calculation line
            $mem = $currentProc.WorkingSet/1mb
            $cpu = [math]::Round((($currentProc.PercentProcessorTime - $Global:table.Where({$_.Id -eq $id}).LastRawCPU) / ($currentProc.Timestamp_Sys100NS - $Global:table.Where({$_.Id -eq $id}).LastTimestamp) / $Global:LogicalCPUs * 100), 2)

            $Global:table.Where({$_.Id -eq $id}).foreach({  # updating Global table with new raw and calculated results
                $_.Memory = [int][math]::Round($mem)
                $_.CPU = [int][math]::Round($cpu)
                $_.LastRawMEM = $currentProc.WorkingSet
                $_.LastRawCPU = $currentProc.PercentProcessorTime
                $_.LastTimestamp = $currentProc.Timestamp_Sys100NS
            })
            $sumMem += $mem; $sumCpu += $cpu
        } #| Select-Object -Property Name, IDProcess, Timestamp_Sys100NS, WorkingSet
    }
    $idleCPU = [math]::Round((($allRawProcesses.where({$_.Name -match 'Idle'}).PercentProcessorTime - $Global:table.Where({$_.Name -eq 'TOTAL'}).LastIdleCPU) / ($allRawProcesses.where({$_.Name -match 'Idle'}).Timestamp_Sys100NS - $Global:table.Where({$_.Name -eq 'TOTAL'}).LastIdleTimestamp) / $Global:LogicalCPUs * 100), 2)
    $Global:table.Where({$_.Name -eq 'Sum'}).foreach({$_.Memory = [int][math]::Round($sumMem); $_.CPU = [int][math]::Round($sumCpu)})
    $Global:table.Where({$_.Name -eq 'TOTAL'}).foreach({$_.Memory = [int][math]::Round($Global:totalMemory - (Get-WmiObject Win32_PerfRawData_PerfOS_Memory).AvailableBytes/1mb); $_.CPU = [int](100 - [math]::Floor($idleCPU)); $_.LastIdleCPU = $allRawProcesses.where({$_.Name -match 'Idle'}).PercentProcessorTime; $_.LastIdleTimestamp = $allRawProcesses.where({$_.Name -match 'Idle'}).Timestamp_Sys100NS})
    $Global:timeToUpdateTable = "$([int]((Get-Date) - $Global:timeToUpdateTable0).TotalMilliseconds) `tms to update Table in updCounters"
}

newProcs
zero
$debug = 1
updCounters
$Global:table | select * | ft
return

do {   
    $timeProcs0 = (Get-Date)
    updProcs
    $timeProcs = "$([int]((Get-Date) - $timeProcs0).TotalMilliseconds) ms for updProcs"
    $timeCounters0 = (Get-Date)
    updCounters
    $timeCounters = "$([int]((Get-Date) - $timeCounters0).TotalMilliseconds) ms for updCounters"

    $sumCpu = $table.Where({$_.Name -eq 'Sum'}).CPU
    $sumMem = $table.Where({$_.Name -eq 'Sum'}).Memory
    if ($sumCpu + $sumMem -eq 0) {$zeroFlag++} else {$zeroFlag=0}
    if (($zeroFlag -eq 5) -or (($sumCpu+$sumMem -eq 0) -and ((Get-Date)-($startTime)).TotalSeconds -le 5)) {$zeroFlag=0 ; zero}
    $peakCpu = if ($peakCpu -lt $sumCpu) {$sumCpu; $peakDateCpu = Get-Date} else {$peakCpu}
    $peakMem = if ($peakMem -lt $sumMem) {$sumMem; $peakDateMem = Get-Date} else {$peakMem}
    $lowCpu = if ($lowCpu -gt $sumCpu) {$sumCpu; $lowDateCpu = Get-Date} else {$lowCpu}
    $lowMem = if (($lowMem -gt $sumMem) -or ($lowMem -eq 0)) {$sumMem; $lowDateMem = Get-Date} else {$lowMem}
    [double]$avgCpu = ($avgCpu * $qt + $sumCpu) / ($qt + 1)
    [double]$avgMem = ($avgMem * $qt + $sumMem) / ($qt + 1)
    $table.Where({$_.Name -eq 'Peak'}).foreach({$_.Memory = [math]::Round($peakMem); $_.CPU = [math]::Round($peakCpu)})
    $table.Where({$_.Name -eq 'Average'}).foreach({$_.Memory = [math]::Round($avgMem); $_.CPU = [math]::Round($avgCpu)})
    $table.Where({$_.Name -eq 'Low'}).foreach({$_.Memory = [math]::Round($lowMem); $_.CPU = [math]::Round($lowCpu)})
    $qt++

    if (-not $Debug) {Clear-Host}
    $table | Format-Table -AutoSize
    
    $diff = ((get-date) - $startTime)
    Write-Host ("Elapsed {0:00}:{1:mm}:{1:ss}  (F1) - help" -f [math]::Floor($diff.TotalHours),$diff) -f Gray

    if ($logging) {
        Write-Host $logFile -f Cyan
        $string = "$(GD)"
        foreach ($id in $table) {
            if ($id.Id) {$string += ",$($id.Memory),$($id.CPU)"}
            #"$id" 
        }
        $string | Out-File $logFile -Append ascii
    }
    if ($loggingSum) {
        Write-Host $logFileSum -f Magenta
        $string = "$(GD)"
        $table | Where-Object {$_.Name -eq 'Sum'} | ForEach-Object {$string += ",$($_.Memory),$($_.CPU)"}
        $string | Out-File $logFileSum -Append ascii
    }
    if ($infoCounter) {
        Write-Host (
            "Mem peak: {0}`t({2:MMM,dd HH:mm:ss})`nCPU peak: {1} `t({3:MMM,dd HH:mm:ss})" -f [math]::Round($peakMem),[math]::Round($peakCpu),$peakDateMem,$peakDateCpu
        ) -f 7
        Write-Host "Press <C> - clear Peak/Avg/Timer" -f 7
        Write-Host "Press <N> - enter new keyword" -f 7
        Write-Host "Press <L> - CSV log (every process)" -f 7
        Write-Host "Press <M> - CSV log (sum of procs)" -f 7
        $infoCounter--
    }
    if ($remCounter) {
        Write-Host (
            "Mem peak: {0}`t({2:MMM,dd HH:mm:ss})`nCPU peak: {1} `t({3:MMM,dd HH:mm:ss})" -f [math]::Round($peakMem),[math]::Round($peakCpu),$peakDateMem,$peakDateCpu
        ) -f 7
        "CounterResults:
        $Global:remResults"
        "table:
        $Global:remTable"
        $remCounter--
    }
    if ($debug) {
        Write-Host "$Global:timeGetProcess"
        Write-Host "$Global:timeGetRawProcess"
        Write-Host "$Global:timeAllRawProcess"
        Write-Host "$Global:timeToUpdateTable"
    }
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
                <#F4#> 115 {$remCounter = 20} #to show abnormal counterResutls if any
            } #end switch
        }
    } #end if
} until ($key.VirtualKeyCode -eq 27)