$time0 = Get-Date; $i = 0; $longs = 0; $longest = 0
do {
    $i++
    $spent = [int](Measure-Command {
        #NOT Name='_Total'
        #$processes = (Get-WmiObject -Query "SELECT Name,IDProcess,PercentProcessorTime,WorkingSet,Timestamp_Sys100NS FROM Win32_PerfRawData_PerfProc_Process WHERE Name like '%edge%'").Count
        #$processes = (Get-WmiObject -Query "SELECT Name,ProcessID,PercentProcessorTime,WorkingSet,Timestamp_Sys100NS FROM Win32_PerfRawData_Counters_ProcessV2 WHERE Name like '%edge%'").Count
        $counterList = '\Process(msedge)\% Processor Time,        \Process(msedge)\% User Time,        \Process(msedge)\% Privileged Time,        \Process(msedge)\Virtual Bytes Peak,        \Process(msedge)\Virtual Bytes,        \Process(msedge)\Page Faults/sec,        \Process(msedge)\Working Set Peak,        \Process(msedge)\Working Set,        \Process(msedge)\Page File Bytes Peak,        \Process(msedge)\Page File Bytes,        \Process(msedge)\Private Bytes,        \Process(msedge)\Thread Count,        \Process(msedge)\Priority Base,        \Process(msedge)\Elapsed Time,        \Process(msedge)\ID Process,        \Process(msedge)\Creating Process ID,        \Process(msedge)\Pool Paged Bytes,        \Process(msedge)\Pool Nonpaged Bytes,        \Process(msedge)\Handle Count'.Split(',').Trim()
        (Get-Counter $counterList).CounterSamples.Count
    }).TotalMilliseconds
    $elapsed = [int]((Get-Date) - $time0).Totalseconds
    if ($spent -gt 2000) {$longs++; $last = "{0:HH}:{0:mm}:{0:ss}" -f (Get-Date)}
    if ($longest -lt $spent) {$longest = $spent}
    "Spent:{0}ms | Elapsed:{1}s | Iterations:{2} | Longs:{3} | Longest:{4} | Last:{5}" -f $spent, $elapsed, $i, $longs, $longest, $last
    #return
} While (1) #((Read-Host) -ne 'n')