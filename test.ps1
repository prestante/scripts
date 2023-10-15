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
else {Write-Host "System Locale is not English nor Russian. Script won't work"; Start-Sleep 3; return}

Write-Host "Reading CPU properties..." -fo Yellow -ba Black
$Processor = Get-WmiObject Win32_Processor
$LogicalCPUs = ($Processor | Measure-Object -Property  NumberOfLogicalProcessors -Sum).Sum
$totalMemory = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).sum /1mb
Update-TypeData -TypeName procListType -DefaultDisplayPropertySet 'Name','Id','Memory','CPU' -ea SilentlyContinue #this is to display only props needed

if ($Processor.Name -match 'E5-2637 v4') {$HT=1.2} # in 2022 I've changed it to be more precise. Checked, set to 1.2.
else {$HT=1}

$peakDateCpu = $peakDateMem = Get-Date
$lastProcesses = @{ID=4294967296} #for the first compare-object in updProcs to show difference
function GD {Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'}

function newProcs {
    do {
        $Global:EnteredWords = 'AChrome'
        $Global:ProcKeyWords = $Global:EnteredWords -split ','
        updProcs
        if ($Global:Processes) {
            $Global:Processes | select -Property Name,Description,Id -Unique | ft
            Write-Host "Are you OK with these processes? Default is 'yes' (y/n)"
            $agree = "y"
        }
        else {
            Write-Host "There are no processes found with key word(s) '$EnteredWords'." -f Red -b Black
            $agree = "y"
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



$timeProcs = (Get-Date)
updProcs
$msgProcs = "$(((Get-Date) - $timeProcs).TotalMilliseconds) ms for updProcs"
$time1 = (Get-Date)
updCounters
#$msgProcs
#"$(((Get-Date) - $time1).TotalMilliseconds) ms for updCounters"

$sumCpu = 123
$sumMem = 234

$table | ft -AutoSize

$diff = ((get-date) - $startTime)
Write-Host ("Elapsed {0:00}:{1:mm}:{1:ss}  (F1) - help" -f [math]::Floor($diff.TotalHours),$diff) -f Gray

Remove-Variable * -ea SilentlyContinue
if ($host.Name -ne 'Visual Studio Code Host') {Read-Host}  # Checking if the code is running from Visual Studio Code
