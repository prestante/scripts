#$table = Get-WmiObject -List | Where-Object {$_.Name -match 'Memory'} | ft -AutoSize
#$table | ft -AutoSize
#Get-WmiObject Win32_AssociatedProcessorMemory | Where-Object {$_.Name -match 'TaskMgr'} #| select -Property Name, PercentProcessorTime, ElapsedTime
#Get-WmiObject Win32_PerfRawData_PerfOS_Processor | select -First 1 | select -Property  Name, Description, PercentProcessorTime, PercentProcessorUtility

function Get-RawResults {
    param (
        [Parameter(Mandatory=0)][string]$procName,
        [Parameter(Mandatory=0)][int]$procID
    )
    if ($procName) {return (Get-WmiObject -Query "SELECT * FROM Win32_PerfRawData_PerfProc_Process WHERE Name like '$procName'").PercentProcessorTime}
    elseif ($procID) {return (Get-WmiObject -Query "SELECT * FROM Win32_PerfRawData_PerfProc_Process WHERE IDProcess like $procID").PercentProcessorTime}
    else {Write-Error "You should give at least one of [string]procName or [int]procID"}
}
function Get-FormattedResults {
    param (
        [Parameter(Mandatory=0)][string]$procName,
        [Parameter(Mandatory=0)][int]$procID
    )
    if ($procName) {return (Get-Counter  -Counter "\Process($procName)\% processor time").CounterSamples.CookedValue}
    elseif ($procID) {return (Get-WmiObject -Query "SELECT * FROM Win32_PerfFormattedData_PerfProc_Process WHERE IDProcess like $procID").PercentProcessorTime}
    else {Write-Error "You should give at least one of [string]procName or [int]procID"}
}
function Get-TimeStamp {
    return (Get-WmiObject -Query "SELECT Timestamp_Sys100NS FROM Win32_PerfRawData_PerfOS_System").Timestamp_Sys100NS
    #return (Get-WmiObject -Query "SELECT Timestamp_Sys100NS FROM Win32_PerfRawData_PerfProc_Process WHERE Name like 'Idle'").Timestamp_Sys100NS
}
function Get-RawWMI {
    param (
        [Parameter(Mandatory=0)][string]$procName,
        [Parameter(Mandatory=0)][int]$procID
    )
    if ($procName) {return Get-WmiObject -Query "SELECT Timestamp_Sys100NS, PercentProcessorTime FROM Win32_PerfRawData_PerfProc_Process WHERE Name like '$procName'" | Select-Object -Property Timestamp_Sys100NS, PercentProcessorTime}
    elseif ($procID) {return Get-WmiObject -Query "SELECT Timestamp_Sys100NS, PercentProcessorTime FROM Win32_PerfRawData_PerfProc_Process WHERE IDProcess like '$procID'" | Select-Object -Property Timestamp_Sys100NS, PercentProcessorTime}
    else {Write-Error "You should give at least one of [string]procName or [int]procID"}
}

$procName = 'Chrome'
$procID = 3804
$cores = (Get-WmiObject Win32_PerfRawData_PerfOS_Processor).Count - 1

$rawResultsPrev = Get-RawWMI -procName $procName -procID $procID
Start-Sleep 1  # for the first results to be more precise
$time0 = Get-Date  # for calculating the average time diff
$steps = 0  # for calculating the average time diff
do {
    $steps++
    $time1 = Get-Date
    $rawResults = Get-RawWMI -procName $procName -procID $procID
    #$formattedResult = Get-FormattedResults -procName $procName -procID $procID
    $timeDiff = [int](((Get-Date) - $time1).TotalMilliseconds)
    $avgTimeDiff = [int]((((Get-Date) - $time0).TotalMilliseconds)/$steps)
    $resultRaw = [math]::Round((($rawResults.PercentProcessorTime - $rawResultsPrev.PercentProcessorTime) / ($rawResults.Timestamp_Sys100NS - $rawResultsPrev.Timestamp_Sys100NS) / $cores * 100), 2)
    $resultFormatted = [math]::Round(($formattedResult / $cores), 2)
    $timestampPrev = $timestamp
    $rawResultPrev = $rawResult
    [pscustomobject]@{TimeDifference=$timeDiff; AvgTimeDiff=$avgTimeDiff; ResultFormatted=$resultFormatted; ResultRaw=$resultRaw; }
    if ($timeDiff -lt 999) {Start-Sleep -Milliseconds (999 - $timeDiff)}
    
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
Write-Host ("Avg time diff: {0:n0} ms" -f ($avgTimeDiff/$steps))

