# Trying to convert giant WMI array to hash table
$time0 = (Get-Date)
#$Global:ProcKeyWords = 'chrome', 'taskmgrr' -join '|'
$allRawProcesses = Get-WmiObject -Query "SELECT * FROM Win32_PerfRawData_PerfProc_Process WHERE NOT Name='_Total'"
$Global:Table = [ordered]@{}
$allRawProcesses | Where-Object {$_.Name -match $Global:ProcKeyWords} | ForEach-Object {
    $Global:Table.Add([string]$_.IDProcess, [PSCustomObject]@{
        Name = $_.Name  -replace '^Harris.Automation.ADC.Services.' -replace 'Host' -replace 'Service' -replace 'Validation' -replace '#\d+$'
        Id = $_.IDProcess
        LastMemory = 0
        Memory = 0
        LastCPU = 0
        CPU = 0
        Start = (Get-Process -Id $_.IDProcess).StartTime  # looks like it doesn't affect the performance
        LastPercentProcessorTime = $_.PercentProcessorTime
        PercentProcessorTime = $_.PercentProcessorTime
        LastWorkingSet = $_.WorkingSet
        WorkingSet = $_.WorkingSet
        LastTimestamp_Sys100NS = $_.Timestamp_Sys100NS
        Timestamp_Sys100NS = $_.Timestamp_Sys100NS
    })
}
if (-not $Global:Table.Values.Id) {$Global:Table.Add($Global:ProcKeyWords, [PSCustomObject]@{
    Name = "$Global:ProcKeyWords"
    Id = "N/A"
    Memory = 0
    CPU = 0})
    $Global:logging = $Global:loggingSum = $null}
$Global:Table.Add('Divider', [PSCustomObject]@{Name = '---------------'})
$Global:Table.Add('Sum', [pscustomobject]@{Name = 'Sum'; Memory = 0; CPU = 0})
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
        PercentProcessorTime = $_.PercentProcessorTime
        LastWorkingSet = $_.WorkingSet
        WorkingSet = $_.WorkingSet
        LastTimestamp_Sys100NS = $_.Timestamp_Sys100NS
        Timestamp_Sys100NS = $_.Timestamp_Sys100NS
    })
}

$Global:Table.Values | ft
Write-Host "$([int]((Get-Date) - $time0).TotalMilliseconds) ms"
return

