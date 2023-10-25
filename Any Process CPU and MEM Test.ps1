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
    if ((($Global:table.Values.Id | Sort-Object) -join '') -ne (($Global:lastTable.Values.Id | Sort-Object) -join '')) {  # old and new Table are different list has been changed
        $Global:timeGetRawProcess = Measure-Command {
            $allRawProcesses = Get-WmiObject -Query "SELECT * FROM Win32_PerfRawData_PerfProc_Process WHERE NOT Name='_Total'"
        }
        $Global:table = [ordered]@{}
        $allRawProcesses | Where-Object {$_.Name -match $Global:ProcKeyWords} | ForEach-Object {
            $Global:table.Add([string]$_.IDProcess, [PSCustomObject]@{
                Name = $_.Name  -replace '^Harris.Automation.ADC.Services.' -replace 'Host' -replace 'Service' -replace 'Validation' -replace '#\d+$'
                Id = $_.IDProcess
                Memory = 0
                CPU = 0
                DecimalCPU = 0
                Start = (Get-Process -Id $_.IDProcess -ea SilentlyContinue).StartTime  # looks like it doesn't affect the performance, however it sometimes leads to errors
                LastPercentProcessorTime = $_.PercentProcessorTime
                LastWorkingSet = $_.WorkingSet
                LastTimestamp_Sys100NS = $_.Timestamp_Sys100NS
            })
        }
        if (-not $Global:table.Values.Id) {$Global:table.Add($Global:ProcKeyWords, [PSCustomObject]@{
            Name = "$Global:ProcKeyWords"
            Id = "N/A"
            Memory = 0
            CPU = 0})
            $Global:logging = $Global:loggingSum = $null}
        $Global:table.Add('Divider', [PSCustomObject]@{Name = '---------------'})
        $Global:table.Add('Sum', [pscustomobject]@{Name = 'Sum'; Memory = 0; CPU = 0; DecimalCPU = 0})
        $Global:table.Add('Space1', [PSCustomObject]@{})
        $Global:table.Add('Peak', [pscustomobject]@{Name = 'Peak'; Memory = 0; CPU = 0})
        $Global:table.Add('Average', [pscustomobject]@{Name = 'Average'; Memory = 0; CPU = 0; DecimalCPU = 0})
        $Global:table.Add('Low', [pscustomobject]@{Name = 'Low'; Memory = 0; CPU = 0})
        $Global:table.Add('Space2', [PSCustomObject]@{})
        $allRawProcesses | Where-Object {$_.Name -eq 'Idle'} | ForEach-Object {
            $Global:table.Add('TOTAL', [PSCustomObject]@{
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
    $Global:lastTable = $Global:table
}
Function updCounters {
    $Global:timeAllRawProcess = Measure-Command {
        $allRawProcesses = Get-WmiObject -Query "SELECT * FROM Win32_PerfRawData_PerfProc_Process WHERE NOT Name='_Total'"  # Getting all processes raw information (except _Total because its Id equals 0 and equals Idle which is also 0)
    }
    
    # There is still a way to speed up the process by converting entire $allRawProcesses to the hash table like it is done in updProcs and then get its value very fast
    #$RawProcesses = @()  # I think we don't need this
    #foreach ($id in ($Global:Processes.IdProcess)) {$allRawProcesses | Where-Object {$_.IDProcess -eq $id} | ForEach-Object {$RawProcesses += $_}}  # the longest part
    $Global:table."Sum".Memory = $Global:table."Sum".CPU = $Global:table."Sum".DecimalCPU = [decimal]0
    $Global:timeToUpdateTable0 = (Get-Date)
    foreach ($id in $Global:table.Values.Id) {
        if ($id) {
            $currentRawProc = $allRawProcesses.where({$_.IDProcess -eq $id})
            $currentTableProc = $Global:table."$id"  # for avoiding double $_ $_ in one line
            $currentTableProc.Memory = [int]($currentRawProc.WorkingSet/1mb)
            $currentTableProc.DecimalCPU = ($currentRawProc.PercentProcessorTime - $currentTableProc.LastPercentProcessorTime) / ($currentRawProc.Timestamp_Sys100NS - $currentTableProc.LastTimestamp_Sys100NS) / $Global:LogicalCPUs * 100
            $currentTableProc.CPU = [int]$currentTableProc.DecimalCPU
            $currentTableProc.LastWorkingSet = $currentRawProc.WorkingSet
            $currentTableProc.LastPercentProcessorTime = $currentRawProc.PercentProcessorTime
            $currentTableProc.LastTimestamp_Sys100NS = $currentRawProc.Timestamp_Sys100NS
            $Global:table.'Sum'.Memory += $currentTableProc.Memory
            $Global:table.'Sum'.DecimalCPU += $currentTableProc.DecimalCPU
        }
    }
    $Global:table."Sum".CPU = [int]$Global:table.'Sum'.DecimalCPU
    $Global:table.'TOTAL'.CPU = [int](100-[math]::Floor(($allRawProcesses.where({$_.Name -match 'Idle'}).PercentProcessorTime - $Global:table.'TOTAL'.LastPercentProcessorTime) / ($allRawProcesses.where({$_.Name -match 'Idle'}).Timestamp_Sys100NS - $Global:table.'TOTAL'.LastTimestamp_Sys100NS) / $Global:LogicalCPUs * 100))
    $Global:table.'TOTAL'.Memory = [int]($Global:totalMemory - (Get-WmiObject Win32_PerfRawData_PerfOS_Memory).AvailableBytes/1mb)
    $Global:table.'TOTAL'.LastPercentProcessorTime = $allRawProcesses.where({$_.Name -match 'Idle'}).PercentProcessorTime
    $Global:table.'TOTAL'.LastTimestamp_Sys100NS = $allRawProcesses.where({$_.Name -match 'Idle'}).Timestamp_Sys100NS
    $Global:timeToUpdateTable = "$([int]((Get-Date) - $Global:timeToUpdateTable0).TotalMilliseconds) `tms to update Table in updCounters"
}

newProcs
zero
$debug = 1
updCounters
#$Global:table.Values | select * | ft

do {
    $timeMain0 = (Get-Date)
    $timeProcs = Measure-Command {
        updProcs
    }
    $timeCounters = Measure-Command {
        updCounters
    }

    if ($table.'Sum'.CPU + $table.'Sum'.Memory -eq 0) {$zeroFlag++} else {$zeroFlag=0}
    if (($zeroFlag -eq 5) -or (($table.'Sum'.CPU+$table.'Sum'.Memory -eq 0) -and ((Get-Date)-($startTime)).TotalSeconds -le 5)) {$zeroFlag=0 ; zero}
    [int]$table.'Peak'.CPU = if ($table.'Peak'.CPU -lt $table.'Sum'.CPU) {$table.'Sum'.CPU; $peakDateCpu = Get-Date} else {$table.'Peak'.CPU}
    [int]$table.'Peak'.Memory = if ($table.'Peak'.Memory -lt $table.'Sum'.Memory) {$table.'Sum'.Memory; $peakDateMem = Get-Date} else {$table.'Peak'.Memory}
    [int]$table.'Low'.CPU = if ($table.'Low'.CPU -gt $table.'Sum'.CPU) {$table.'Sum'.CPU; $lowDateCpu = Get-Date} else {$table.'Low'.CPU}
    [int]$table.'Low'.Memory = if (($table.'Low'.Memory -gt $table.'Sum'.Memory) -or ($table.'Low'.Memory -eq 0)) {$table.'Sum'.Memory; $lowDateMem = Get-Date} else {$table.'Low'.Memory}
    [double]$table.'Average'.DecimalCPU = ($table.'Average'.DecimalCPU * $qt + $table.'Sum'.DecimalCPU) / ($qt + 1)
    [int]$table.'Average'.CPU = $table.'Average'.DecimalCPU
    $temp = $table.'Average'.Memory
    [int]$table.'Average'.Memory = ($temp * $qt + $table.'Sum'.Memory) / ($qt + 1)
    #[int]$table.'Average'.Memory = ($table.'Average'.Memory * $qt + $table.'Sum'.Memory) / ($qt + 1)
    $qt++

    if (-not $Debug) {Clear-Host}
    $Global:table.Values | Select-Object -Property Name, Id, Memory, CPU, DecimalCPU | Format-Table -AutoSize
    
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
            "Mem peak: {0}`t({2:MMM,dd HH:mm:ss})`nCPU peak: {1} `t({3:MMM,dd HH:mm:ss})" -f [math]::Round($table.'Peak'.Memory),[math]::Round($table.'Peak'.CPU),$peakDateMem,$peakDateCpu
        ) -f 7
        Write-Host "Press <C> - clear Peak/Avg/Timer" -f 7
        Write-Host "Press <N> - enter new keyword" -f 7
        Write-Host "Press <L> - CSV log (every process)" -f 7
        Write-Host "Press <M> - CSV log (sum of procs)" -f 7
        $infoCounter--
    }
    if ($debug) {
        
        # WHY DO WE updProcs EVERY TIME???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????

        #Write-Host "$timeMain"
        #Write-Host "$([int]$timeProcs.TotalMilliseconds) `tms for updProcs"
            Write-Host "$([int]$Global:timeGetRawProcess.TotalMilliseconds) `tms to get allRawProcesses in updProcs"
        #Write-Host "$([int]$timeCounters.TotalMilliseconds) `tms for updCounters"
            Write-Host "$([int]$Global:timeAllRawProcess.TotalMilliseconds) `tms to get allRawProcesses in updCounters"
        #Write-Host "$Global:timeToUpdateTable"
        Write-Host "$qt `t steps"
    }
    
    $timeMain1 = [int]((Get-Date) - $timeMain0).TotalMilliseconds
    if ($debug) {Write-Host "$timeMain1 `tms for main cycle"}
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