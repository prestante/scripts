function newProcs {
    do {
        $Global:EnteredWords = 'ADC.Services'
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