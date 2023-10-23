#Good WMIs:
# Get Logical Processors Number (CTC - 35 ms, agalkovs - 65 ms)
# (Get-WmiObject -Query "SELECT Name FROM Win32_PerfRawData_Counters_ProcessorInformation").Count - 2
# Get Formatted PercentProcessorTime (or any process formatted property)
# (Get-WmiObject -Query "SELECT * FROM Win32_PerfFormattedData_PerfProc_Process WHERE IDProcess like '1768'").PercentProcessorTime
# Get Timestamp_Sys100NS
# (Get-WmiObject -Query "SELECT Timestamp_Sys100NS FROM Win32_PerfRawData_PerfOS_System").Timestamp_Sys100NS

#$table = Get-WmiObject -List | Where-Object {$_.Name -match 'system'}
#$table | ft -AutoSize
#Get-WmiObject Win32_Process | Where-Object {$_.Name -match 'TaskMgr'} #| select -Property Name, PercentProcessorTime, ElapsedTime
#Get-WmiObject Win32_PerfRawData_PerfProc_Process | select -First 1 | select -Property  Name, Description, PercentProcessorTime, PercentProcessorUtility

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
function Get-MultiResults {
    param (
        [Parameter(Mandatory=0)][string]$procName,
        [Parameter(Mandatory=0)][int]$procID
    )
    if ($procName) {return Get-WmiObject -Query "SELECT Timestamp_Sys100NS, PercentProcessorTime FROM Win32_PerfRawData_PerfProc_Process WHERE Name like '$procName'" | Select-Object -Property Timestamp_Sys100NS, PercentProcessorTime}
    elseif ($procID) {return Get-WmiObject -Query "SELECT Timestamp_Sys100NS, PercentProcessorTime FROM Win32_PerfRawData_PerfProc_Process WHERE IDProcess like '$procID'" | Select-Object -Property Timestamp_Sys100NS, PercentProcessorTime}
    else {Write-Error "You should give at least one of [string]procName or [int]procID"}
}

$procName = ''
$procID = 3804
$cores = (Get-WmiObject -Query "SELECT Name FROM Win32_PerfRawData_Counters_ProcessorInformation").Count - 2

#$timestampPrev = Get-TimeStamp
#$rawResultPrev = Get-RawResults -procName $procName -procID $procID
$rawResultsPrev = Get-MultiResults -procName $procName -procID $procID
sleep 1  # for the first results to be more precise
$formattedResult = 0
do {
    $time0 = Get-Date
    #$timestamp = Get-TimeStamp
    #$rawResult = Get-RawResults -procName $procName -procID $procID
    $rawResults = Get-MultiResults -procName $procName -procID $procID
    #$formattedResult = Get-FormattedResults -procName $procName -procID $procID
    $timeDiff = [int](((Get-Date) - $time0).TotalMilliseconds)
    #$resultRaw = [math]::Round((($rawResult - $rawResultPrev) / ($timestamp - $timestampPrev) / $cores * 100), 2)
    $resultRaw = [math]::Round((($rawResults.PercentProcessorTime - $rawResultsPrev.PercentProcessorTime) / ($rawResults.Timestamp_Sys100NS - $rawResultsPrev.Timestamp_Sys100NS) / $cores * 100), 2)
    $resultFormatted = [math]::Round(($formattedResult / $cores), 2)
    $timestampPrev = $timestamp
    $rawResultPrev = $rawResult
    [pscustomobject]@{TimeDifference=$timeDiff; ResultFormatted=$resultFormatted; ResultRaw=$resultRaw; }
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

