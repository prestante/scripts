Remove-Variable * -ea SilentlyContinue
Write-Host "Reading CPU properties..." -fo Yellow -ba Black -NoNewline
$Global:LogicalCPUs = (Get-WmiObject Win32_PerfRawData_PerfOS_Processor).Count - 1
Write-Host "Done" -fo Yellow -ba Black
Write-Host "Reading Memory properties..." -fo Yellow -ba Black -NoNewline
$Global:totalMemory = (Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).sum /1mb
Write-Host "Done" -fo Yellow -ba Black
Update-TypeData -TypeName procListType -DefaultDisplayPropertySet 'Name','Id','Memory','CPU' -ea SilentlyContinue  # this is to display by default only props needed
$peakDateCpu = $peakDateMem = Get-Date  # starting date to compare newer dates with it
$Global:lastTable = @{'Key'=[PSCustomObject]@{ID=4294967296}}  # impossible ID for a comparison in updProcs to show difference for the keywords with no processes
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
        $Global:EnteredWords = 'edge'
        $Global:ProcKeyWords = $Global:EnteredWords -join '|'
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
    if ((($Global:Table.Values.Id | Sort-Object) -join '') -ne (($Global:lastTable.Values.Id | Sort-Object) -join '')) {  # old and new Table are different list has been changed
        $allRawProcesses = Get-WmiObject -Query "SELECT * FROM Win32_PerfRawData_PerfProc_Process WHERE NOT Name='_Total'"
        $Global:Table = [ordered]@{}
        $allRawProcesses | Where-Object {$_.Name -match $Global:ProcKeyWords} | ForEach-Object {
            $Global:Table.Add([string]$_.IDProcess, [PSCustomObject]@{
                Name = $_.Name  -replace '^Harris.Automation.ADC.Services.' -replace 'Host' -replace 'Service' -replace 'Validation' -replace '#\d+$'
                Id = $_.IDProcess
                Memory = 0
                CPU = 0
                DecimalCPU = 0
                Start = (Get-Process -Id $_.IDProcess).StartTime  # looks like it doesn't affect the performance
                LastPercentProcessorTime = $_.PercentProcessorTime
                LastWorkingSet = $_.WorkingSet
                LastTimestamp_Sys100NS = $_.Timestamp_Sys100NS
            })
        }
        if (-not $Global:Table.Values.Id) {$Global:Table.Add($Global:ProcKeyWords, [PSCustomObject]@{
            Name = "$Global:ProcKeyWords"
            Id = "N/A"
            Memory = 0
            CPU = 0})
            $Global:logging = $Global:loggingSum = $null}
        $Global:Table.Add('Divider', [PSCustomObject]@{Name = '---------------'})
        $Global:Table.Add('Sum', [pscustomobject]@{Name = 'Sum'; Memory = 0; CPU = 0; DecimalCPU = 0})
        $Global:Table.Add('Space1', [PSCustomObject]@{})
        $Global:Table.Add('Peak', [pscustomobject]@{Name = 'Peak'; Memory = 0; CPU = 0})
        $Global:Table.Add('Average', [pscustomobject]@{Name = 'Average'; Memory = 0; CPU = 0})
        $Global:Table.Add('Low', [pscustomobject]@{Name = 'Low'; Memory = 0; CPU = 0})
        $Global:Table.Add('Space2', [PSCustomObject]@{})
        $allRawProcesses | Where-Object {$_.Name -eq 'Idle'} | ForEach-Object {
            $Global:Table.Add('TOTAL', [PSCustomObject]@{
                Name = 'TOTAL'
                LastMemory = 0
                Memory = 0
                LastCPU = 0
                CPU = 0
                LastPercentProcessorTime = $_.PercentProcessorTime
                LastTimestamp_Sys100NS = $_.Timestamp_Sys100NS
            })
        }        
        if ($Global:logging) {newLog}
        if ($Global:loggingSum) {newLogSum}
    }
    $Global:timeGetRawProcess = "$([int]((Get-Date) - $Global:timeGetRawProcess0).TotalMilliseconds) `tms to get allRawProcesses in updProcs"
    $Global:lastProcesses = $Global:Processes
}
Function updCounters {
    $Global:timeAllRawProcess0 = (Get-Date)
    $allRawProcesses = Get-WmiObject -Query "SELECT * FROM Win32_PerfRawData_PerfProc_Process WHERE NOT Name='_Total'"  # Getting all processes raw information (except _Total because its Id equals 0 and equals Idle which is also 0)
    $Global:timeAllRawProcess = "$([int]((Get-Date) - $Global:timeAllRawProcess0).TotalMilliseconds) `tms to get allRawProcesses in updCounters"
    
    # There is still a way to speed up the process by converting entire $allRawProcesses to the hash table like it is done in updProcs and then get its value very fast
    #$RawProcesses = @()  # I think we don't need this
    #foreach ($id in ($Global:Processes.IdProcess)) {$allRawProcesses | Where-Object {$_.IDProcess -eq $id} | ForEach-Object {$RawProcesses += $_}}  # the longest part
    $Global:Table."Sum".Memory = $Global:Table."Sum".CPU = [decimal]0
    $Global:timeToUpdateTable0 = (Get-Date)
    foreach ($id in $Global:Table.Values.Id) {
        if ($id) {
            $currentRawProc = $allRawProcesses.where({$_.IDProcess -eq $id})
            $currentTableProc = $Global:Table."$id"  # for avoiding double $_ $_ in one line
            $currentTableProc.Memory = [int]($currentRawProc.WorkingSet/1mb)
            $currentTableProc.DecimalCPU = ($currentRawProc.PercentProcessorTime - $currentTableProc.LastPercentProcessorTime) / ($currentRawProc.Timestamp_Sys100NS - $currentTableProc.LastTimestamp_Sys100NS) / $Global:LogicalCPUs * 100
            $currentTableProc.CPU = [int]$currentTableProc.DecimalCPU
            $currentTableProc.LastWorkingSet = $currentRawProc.WorkingSet
            $currentTableProc.LastPercentProcessorTime = $currentRawProc.PercentProcessorTime
            $currentTableProc.LastTimestamp_Sys100NS = $currentRawProc.Timestamp_Sys100NS
            $Global:Table.'Sum'.Memory += $currentTableProc.Memory
            $Global:Table.'Sum'.DecimalCPU += $currentTableProc.DecimalCPU
        }
    }
    $Global:Table."Sum".CPU = [int]$Global:Table.'Sum'.DecimalCPU
    $Global:Table.'TOTAL'.CPU = [int](100-[math]::Floor(($allRawProcesses.where({$_.Name -match 'Idle'}).PercentProcessorTime - $Global:Table.'TOTAL'.LastPercentProcessorTime) / ($allRawProcesses.where({$_.Name -match 'Idle'}).Timestamp_Sys100NS - $Global:Table.'TOTAL'.LastTimestamp_Sys100NS) / $Global:LogicalCPUs * 100))
    $Global:Table.'TOTAL'.Memory = [int]($Global:totalMemory - (Get-WmiObject Win32_PerfRawData_PerfOS_Memory).AvailableBytes/1mb)
    $Global:Table.'TOTAL'.LastPercentProcessorTime = $allRawProcesses.where({$_.Name -match 'Idle'}).PercentProcessorTime
    $Global:Table.'TOTAL'.LastTimestamp_Sys100NS = $allRawProcesses.where({$_.Name -match 'Idle'}).Timestamp_Sys100NS
    $Global:timeToUpdateTable = "$([int]((Get-Date) - $Global:timeToUpdateTable0).TotalMilliseconds) `tms to update Table in updCounters"
}

newProcs
zero
$debug = 1
updCounters
#$Global:Table.Values | select * | ft

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
    $Global:Table.Values | Select-Object -Property Name, Id, Memory, CPU | Format-Table -AutoSize
    
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