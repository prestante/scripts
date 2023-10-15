if ((Get-WinSystemLocale).DisplayName -notmatch 'english') {Write-Host 'System Locale is not English. Try another script'; Sleep 3; return}Write-Host "Reading CPU properties..." -fo Yellow -ba Black
$Processor = Get-WmiObject Win32_Processor
$Cores = $Processor | Measure -Property  NumberOfCores -Sum
$Cores = $Cores.Sum
$LogicalCPUs = $Processor | Measure -Property  NumberOfLogicalProcessors -Sum
$LogicalCPUs = $LogicalCPUs.sum
$totalMemory = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).sum /1mb
Update-TypeData -TypeName procListType -DefaultDisplayPropertySet 'Name','Id','Memory','CPU' -ea SilentlyContinue #this is to display only props needed

if ($Processor.Name -match 'E5-2637 v4') {$HT=1.2} # in 2022 I've changed it to be more precise. Checked, set to 1.2.
else {$HT=1}

$peakDateCpu = Get-Date
$peakDateMem = Get-Date
$Global:lastProcesses = @()
$Global:lastProcessesForupdProcs = @()

function newProcs {
    do {
        Write-Host "Now you have to enter a Key Word corresponding to the Name or Description or PID of a processes to watch." -f Yellow -b Black
        Write-Host "Be careful with the Key Word. If some new process suitable for your Key Word would appear in the system later, it will be added to the list of the processes to watch automatically." -f Yellow -b Black
        Write-Host "Later you will be able to enter new Key Word by pressing <N>." -f Cyan -b Black
        $Global:ProcKeyWord = Read-Host "Enter a Key Word"
        #$Global:ProcKeyWord = 'adc.s'
        #$Global:Processes = @(Get-Process | where {($_.Name -match $ProcKeyWord) -or ($_.Id -match $ProcKeyWord) -or ($_.Description -match $ProcKeyWord)} | sort -Property StartTime)
        updProcs
        if ($Global:Processes) {
            $Global:Processes | select -Property Name,Description,Id -Unique | ft
            $agree = Read-Host "Are you OK with these processes? Default is 'yes' (y/n)"
        }
        else {
            Write-Host "There are no processes found with key word '$ProcKeyWord'." -f Red -b Black
            $agree = Read-Host "Are you OK with the key word '$ProcKeyWord'? Default is 'yes' (y/n)"
        }
    } while ($agree -match 'n|N')
}
Function zero {
    $Global:peakCpu = $Global:peakMem = $Global:lowCpu = $Global:lowMem = 0
    $Global:peakDateCpu = $Global:peakDateMem = $Global:lowDateCpu = $Global:lowDateMem = $null
    $Global:startTime = Get-Date
    $Global:qt = [uint64]0
}
function updProcs {
    try {
        $Global:Processes = @(Get-Process | where {($_.Name -match $Global:ProcKeyWord) -or ($_.Id -match $Global:ProcKeyWord) -or ($_.Description -match $Global:ProcKeyWord)} | sort -Property StartTime -ea Stop)
    } catch {$Global:Processes = @(Get-Process | where {($_.Name -match $Global:ProcKeyWord) -or ($_.Id -match $Global:ProcKeyWord) -or ($_.Description -match $Global:ProcKeyWord)})}
    if (Compare-Object $Global:lastProcesses $Global:Processes) {
        $Global:procList = @()
        if ($Global:Processes) {$Global:procList += $Global:Processes | %{
            $obj = [pscustomobject]@{
                Name = $_.Name  -replace '^Harris.Automation.ADC.Services.' -replace 'Host' -replace 'Service' -replace 'Validation'
                Id = $_.Id
                Memory = 0
                CPU = 0
                Start = $_.StartTime
            }
            $obj.PSTypeNames.Add("procListType")
            $obj
        }} else {$Global:procList += [pscustomobject]@{
                Name = "$procKeyWord"
                Id = "N/A"
                Memory = 0
                CPU = 0}
            }
        $Global:procList += [pscustomobject]@{
            Name = '---------------'
        }
        $Global:procList += [pscustomobject]@{
            Name = 'Sum'
            Memory = 0
            CPU = 0
        }
        $Global:procList += [pscustomobject]@{
        }
        $Global:procList += [pscustomobject]@{
            Name = "Peak"
            Memory = 0
            CPU = 0
        }
        $Global:procList += [pscustomobject]@{
            Name = 'Average'
            Memory = 0
            CPU = 0
        }
        $Global:procList += [pscustomobject]@{
            Name = 'Low'
            Memory = 0
            CPU = 0
        }
        $Global:procList += [pscustomobject]@{
        }
        $Global:procList += [pscustomobject]@{
            Name = 'TOTAL'
            Memory = 0
            CPU = 0
        }
        Get-Counter -ListSet process | Out-Null
    }
    $Global:lastProcesses = $Global:Processes
}
Function updCounters {
    $countersList = New-Object System.Collections.Generic.List[System.Object]
    $counterResults = New-Object System.Collections.Generic.List[System.Object]
    foreach ($uniq in ($Global:Processes.Name | select -Unique)) {
        0..((Get-Process -Name $uniq).Count - 1) | %{
            $countersList.Add("\Process($uniq#$_)\ID Process"); 
            $countersList.Add("\Process($uniq#$_)\Working Set")
            $countersList.Add("\Process($uniq#$_)\% processor time"); 
        }
    }
    $countersList.Add("\memory\available bytes")
    $countersList.Add("\process(idle)\% processor time")

    #try {
        (Get-Counter $countersList -ea SilentlyContinue).CounterSamples | %{$counterResults.Add([pscustomobject]@{path = $_.path; cookedvalue = [decimal]$_.cookedvalue})}
    #} catch {Write-Host "$($Error[0].Exception.Message)" -f 13 -b 0}
    $sumMem = $sumCpu = [int]0
    $counterResults | ?{$_.path -match 'id process'} | %{
        $id = [int]($_.cookedvalue)
        $mem = $counterResults[($counterResults.IndexOf($_)+1)].cookedvalue/1mb
        $cpu = $counterResults[($counterResults.IndexOf($_)+2)].cookedvalue/$LogicalCPUs/$HT
        $Global:procList.Where({$_.Id -eq $id}).foreach({$_.Memory = [math]::Round($mem); $_.CPU = [math]::Round($cpu)})
        $sumMem += $mem; $sumCpu += $cpu
    }
    $Global:procList.Where({$_.Name -eq 'Sum'}).foreach({$_.Memory = [math]::Round($sumMem); $_.CPU = [math]::Round($sumCpu)})
    $Global:procList.Where({$_.Name -eq 'TOTAL'}).foreach({$_.Memory = [math]::Round($totalMemory - $counterResults[-2].cookedvalue/1mb); $_.CPU = 100 - [math]::Round($counterResults[-1].cookedvalue/$env:NUMBER_OF_PROCESSORS)})
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

    $sumCpu = $procList.Where({$_.Name -eq 'Sum'}).CPU
    $sumMem = $procList.Where({$_.Name -eq 'Sum'}).Memory
    if ($sumCpu + $sumMem -eq 0) {$zeroFlag++} else {$zeroFlag=0}
    if (($zeroFlag -eq 5) -or (($sumCpu+$sumMem -eq 0) -and ((Get-Date)-($startTime)).TotalSeconds -le 5)) {$zeroFlag=0 ; zero}
    $peakCpu = if ($peakCpu -lt $sumCpu) {$sumCpu; $peakDateCpu = Get-Date} else {$peakCpu}
    $peakMem = if ($peakMem -lt $sumMem) {$sumMem; $peakDateMem = Get-Date} else {$peakMem}
    $lowCpu = if ($lowCpu -gt $sumCpu) {$sumCpu; $lowDateCpu = Get-Date} else {$lowCpu}
    $lowMem = if (($lowMem -gt $sumMem) -or ($lowMem -eq 0)) {$sumMem; $lowDateMem = Get-Date} else {$lowMem}
    [double]$avgCpu = ($avgCpu * $qt + $sumCpu) / ($qt + 1)
    [double]$avgMem = ($avgMem * $qt + $sumMem) / ($qt + 1)
    $procList.Where({$_.Name -eq 'Peak'}).foreach({$_.Memory = [math]::Round($peakMem); $_.CPU = [math]::Round($peakCpu)})
    $procList.Where({$_.Name -eq 'Average'}).foreach({$_.Memory = [math]::Round($avgMem); $_.CPU = [math]::Round($avgCpu)})
    $procList.Where({$_.Name -eq 'Low'}).foreach({$_.Memory = [math]::Round($lowMem); $_.CPU = [math]::Round($lowCpu)})
    $qt++
   
    cls
    $procList | ft -AutoSize

    $diff = ((get-date) - $startTime)
    Write-Host ("Elapsed {0:00}:{1:mm}:{1:ss}" -f [math]::Floor($diff.TotalHours),$diff)
    if ($infoCounter) {
        Write-Host (
            "Mem peak: {0}`t({2:MMM,dd HH:mm:ss})`nCPU peak: {1} `t({3:MMM,dd HH:mm:ss})" -f [math]::Round($peakMem),[math]::Round($peakCpu),$peakDateMem,$peakDateCpu
        ) -f 7
        Write-Host "Press <C> - clear Peak/Avg/Timer" -f 7
        Write-Host "Press <N> - enter new keyword" -f 7
        $infoCounter--
    }

    #looking for <Esc> or <R> or <Space> press
    if ($host.ui.RawUi.KeyAvailable) {
        $key=$host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown,IncludeKeyUp")
        $host.UI.RawUI.FlushInputBuffer()
        if ($key.keydown) {
            switch ($key.VirtualKeyCode) {
                <#C#> 67 {zero}
                <#N#> 78 {newProcs ; zero}
                <#Enter#> 13 {}
                <#Esc#> 27 {exit}
                <#Space#> 32 {}
                <#F1#> 112 {$infoCounter = 5}
            } #end switch
        }
    } #end if
} until ($key.VirtualKeyCode -eq 27)