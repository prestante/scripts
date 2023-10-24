# Trying to convert giant WMI array to hash table
$time0 = (Get-Date)
$Global:ProcKeyWords = 'chrome', 'taskmgr' -join '|'
$allRawProcesses = Get-WmiObject -Query "SELECT * FROM Win32_PerfRawData_PerfProc_Process WHERE NOT Name='_Total'"
$hash = [ordered]@{}
$allRawProcesses | Where-Object {$_.Name -match $Global:ProcKeyWords} | ForEach-Object {
    $hash.Add([string]$_.IDProcess, [PSCustomObject]@{
        Name = $_.Name
        Id = $_.IDProcess
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
$hash.Add('Divider', [PSCustomObject]@{Name = '---------------'})
$hash.Add('Sum', [pscustomobject]@{Name = 'Sum'; Memory = 0; CPU = 0})
$hash.Add('Space1', [PSCustomObject]@{})
$hash.Add('Peak', [pscustomobject]@{Name = 'Peak'; Memory = 0; CPU = 0})
$hash.Add('Average', [pscustomobject]@{Name = 'Average'; Memory = 0; CPU = 0})
$hash.Add('Low', [pscustomobject]@{Name = 'Low'; Memory = 0; CPU = 0})
$hash.Add('Space2', [PSCustomObject]@{})
$allRawProcesses | Where-Object {$_.Name -eq 'Idle'} | ForEach-Object {
    $hash.Add([string]$_.IDProcess, [PSCustomObject]@{
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

$hash.Values | ft
Write-Host "$([int]((Get-Date) - $time0).TotalMilliseconds) ms"
return

