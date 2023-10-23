#$username = 'wtldev.net\vadc'
#$password = ConvertTo-SecureString $env:vpw -AsPlainText -Force
#$credential = New-Object System.Management.Automation.PSCredential($username, $password)
#$hostname = 'wtl-adc-ctc-01.wtldev.net'

#Good WMIs:
# Get Logical Processors Number (CTC - 35 ms, agalkovs - 65 ms)
# (Get-WmiObject -Query "SELECT Name FROM Win32_PerfRawData_Counters_ProcessorInformation").Count - 2
# Get Formatted PercentProcessorTime (or any process formatted property)
# (Get-WmiObject -Query "SELECT * FROM Win32_PerfFormattedData_PerfProc_Process WHERE IDProcess like '1768'").PercentProcessorTime
# Get Timestamp_Sys100NS
# (Get-WmiObject -Query "SELECT Timestamp_Sys100NS FROM Win32_PerfRawData_PerfOS_System").Timestamp_Sys100NS

#$table = Get-WmiObject -List | Where-Object {$_.Name -match 'processor'}
#$table | ft -AutoSize
#Get-WmiObject Win32_Process | Where-Object {$_.Name -match 'TaskMgr'} #| select -Property Name, PercentProcessorTime, ElapsedTime
#Get-WmiObject Win32_PerfFormattedData_Counters_ProcessorInformation | select -First 100 | select -Property  Name, Description, PercentProcessorTime, PercentProcessorUtility

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
}


$procName = 'Idle'
$procID = 0
$cores = (Get-WmiObject -Query "SELECT Name FROM Win32_PerfRawData_Counters_ProcessorInformation").Count - 2

$timestampPrev = Get-TimeStamp
$rawResultPrev = Get-RawResults -procName $procName -procID $procID
sleep 1  # for the first results to be more precise
$formattedResult = 0
$steps = 30
for ($i = 0; $i -lt $steps; $i++) {
    $time0 = Get-Date
    $timestamp = (Get-WmiObject -Query "SELECT Timestamp_Sys100NS FROM Win32_PerfRawData_PerfOS_System").Timestamp_Sys100NS
    $rawResult = Get-RawResults -procName $procName -procID $procID
    #$formattedResult = Get-FormattedResults -procName $procName -procID $procID
    $timeDiff = [int](((Get-Date) - $time0).TotalMilliseconds)
    $resultRaw = [math]::Round((($rawResult - $rawResultPrev) / ($timestamp - $timestampPrev) / $cores * 100), 2)
    $resultFormatted = [math]::Round(($formattedResult / $cores), 2)
    $timestampPrev = $timestamp
    $rawResultPrev = $rawResult
    [pscustomobject]@{TimeDifference=$timeDiff; ResultFormatted=$resultFormatted; ResultRaw=$resultRaw; }
    if ($timeDiff -lt 1000) {Start-Sleep -Milliseconds (1000 - $timeDiff)}
}
Write-Host ("Avg time diff: {0:n0} ms" -f ($avgTimeDiff/$steps))

