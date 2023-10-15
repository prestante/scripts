if ((Get-WinSystemLocale).DisplayName -match 'english') {
    $locProcName = 'Process'
    $locIdProcName = 'ID Process'
    $locWrkSetName = 'Working Set'
    $locProcTimeName = '% processor time'
    $locMemAvlName = '\memory\available bytes'
    $locProcIdlName = '\process(idle)\% processor time'}
elseif ((Get-WinSystemLocale).DisplayName -match 'русск') {
    $locProcName = 'Процесс'
    $locIdProcName = 'Идентификатор процесса'
    $locWrkSetName = 'Рабочий набор'
    $locProcTimeName = '% загруженности процессора'
    $locMemAvlName = '\Память\Доступно байт'
    $locProcIdlName = '\Процесс(idle)\% загруженности процессора'}
else {Write-Host "System Locale is not English nor Russian. Script won't work"; Sleep 3; return}


Write-Host "Reading CPU properties..." -fo Yellow -ba Black
$Processor = Get-WmiObject Win32_Processor
$LogicalCPUs = ($Processor | Measure -Property  NumberOfLogicalProcessors -Sum).Sum
$totalMemory = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).sum /1mb
Update-TypeData -TypeName procListType -DefaultDisplayPropertySet 'Name','Id','Memory','CPU' -ea SilentlyContinue #this is to display only props needed

if ($Processor.Name -match 'E5-2637 v4') {$HT=1.2} # in 2022 I've changed it to be more precise. Checked, set to 1.2.
else {$HT=1}

$peakDateCpu = $peakDateMem = Get-Date
#$lastProcesses = 1 #for the first compare-object in updProcs to show difference
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
        Write-Host "Now you have to enter a Key Word corresponding to the Name or Description or PID of a processes to watch." -f Yellow -b Black
        Write-Host "Be careful with the Key Word. If some new process suitable for your Key Word will appear in the system later, it will be added to the list automatically." -f Yellow -b Black
        Write-Host "You can also type several keywords separated by comma. They all will be used at once to filter the processes list." -f Yellow -b Black
        Write-Host "Later you will be able to enter new Key Word by pressing <N>." -f Cyan -b Black
        $Global:EnteredWords = Read-Host "Enter Key Word(s)"
        #$Global:EnteredWords = 'ADC.Services'
        $Global:ProcKeyWords = $Global:EnteredWords -split ','
        updProcs
        if ($Global:Processes) {
            $Global:Processes | select -Property Name,Description,Id -Unique | ft
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
    try {
        $Global:Processes = @()
        foreach ($ProcKeyWord in $Global:ProcKeyWords) {$Global:Processes += @(Get-Process | where {($_.Name -match $ProcKeyWord) -or ($_.Id -eq $ProcKeyWord) -or ($_.Description -match $ProcKeyWord)} | sort -Property StartTime -ea Stop)}
    } catch {
        $Global:Processes = @()
        foreach ($ProcKeyWord in $Global:ProcKeyWords) {$Global:Processes += @(Get-Process | where {($_.Name -match $ProcKeyWord) -or ($_.Id -eq $ProcKeyWord) -or ($_.Description -match $ProcKeyWord)})}
    }
    #if (Compare-Object $Global:lastProcesses $Global:Processes) { #processes list has been changed  # maybe just check equality of two sorted Id lists????
    if ((($Global:Processes.Id | Sort) -join '') -ne (($Global:lastProcesses.Id | Sort) -join '')) {  #processes list has been changed
        $Global:table = @()
        if ($Global:Processes.Name) {$Global:table += $Global:Processes | %{
            $obj = [pscustomobject]@{
                Name = $_.Name  -replace '^Harris.Automation.ADC.Services.' -replace 'Host' -replace 'Service' -replace 'Validation'
                Id = $_.Id
                Memory = 0
                CPU = 0
                Start = $_.StartTime
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
        }
        Get-Counter -ListSet $locProcName | Out-Null #just to refresh system counters data
        if ($Global:logging) {newLog}
        if ($Global:loggingSum) {newLogSum}
    }
    $Global:lastProcesses = $Global:Processes
}
Function updCounters {
    $countersList = New-Object System.Collections.Generic.List[System.Object]
    $counterResults = New-Object System.Collections.Generic.List[System.Object]
    foreach ($uniq in ($Global:Processes.Name | select -Unique)) {
        0..((Get-Process -Name $uniq).Count - 1) | %{
            $countersList.Add("\$locProcName($uniq#$_)\$locIdProcName"); 
            $countersList.Add("\$locProcName($uniq#$_)\$locWrkSetName")
            $countersList.Add("\$locProcName($uniq#$_)\$locProcTimeName"); 
        }
    }
    $countersList.Add($locMemAvlName)
    $countersList.Add($locProcIdlName)

    #try {
        (Get-Counter $countersList -ea SilentlyContinue).CounterSamples | %{$counterResults.Add([pscustomobject]@{path = $_.path; cookedvalue = [decimal]$_.cookedvalue})}
    #} catch {Write-Host "$($Error[0].Exception.Message)" -f 13 -b 0}
    $sumMem = $sumCpu = [decimal]0
    $counterResults | ?{$_.path -match "$locIdProcName"} | %{
        $id = [int]($_.cookedvalue)
        $mem = $counterResults[($counterResults.IndexOf($_)+1)].cookedvalue/1mb
        $cpu = $counterResults[($counterResults.IndexOf($_)+2)].cookedvalue/$LogicalCPUs/$HT
        $Global:table.Where({$_.Id -eq $id}).foreach({$_.Memory = [math]::Round($mem); $_.CPU = [math]::Round($cpu)})
        if ($Global:table.id -contains $id) {$sumMem += $mem; $sumCpu += $cpu}
    }
    $Global:table.Where({$_.Name -eq 'Sum'}).foreach({$_.Memory = [math]::Round($sumMem); $_.CPU = [math]::Round($sumCpu)})
    $Global:table.Where({$_.Name -eq 'TOTAL'}).foreach({$_.Memory = [math]::Round($totalMemory - $counterResults[-2].cookedvalue/1mb); $_.CPU = 100 - [math]::Floor($counterResults[-1].cookedvalue/$LogicalCPUs)})
    if ($sumCpu -gt 100) {$Global:remResults = $counterResults; $Global:remTable = $Global:table} #debug
}

newProcs
zero

do {   
    $timeProcs = (Get-Date)
    updProcs
    $msgProcs = "$(((Get-Date) - $timeProcs).TotalMilliseconds) ms for updProcs"
    $time1 = (Get-Date)
    updCounters
    #$msgProcs
    #"$(((Get-Date) - $time1).TotalMilliseconds) ms for updCounters"

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

    cls
    $table | ft -AutoSize
    
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
        $table | ?{$_.Name -eq 'Sum'} | %{$string += ",$($_.Memory),$($_.CPU)"}
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