do {
    $time1 = Get-Date
    $allRawProcesses = Get-WmiObject -Query "SELECT Name, Timestamp_Sys100NS, PercentProcessorTime FROM Win32_PerfRawData_PerfProc_Process"
    #$allRawProcesses | Where-Object {$_.Name -match 'Idle'}
    Write-Host "$([int](((Get-Date) - $time1).TotalMilliseconds)), " -NoNewline
} while (1)
return