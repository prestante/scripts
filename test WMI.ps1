$time0 = Get-Date; $i = 0; $longs = 0; $longest = 0
do {
    $i++
    $spent = [int](Measure-Command {
        #NOT Name='_Total'
        $processes = (Get-WmiObject -Query "SELECT Name,IDProcess,PercentProcessorTime,WorkingSet,Timestamp_Sys100NS FROM Win32_PerfRawData_PerfProc_Process WHERE Name like '%edge%'").Count
    }).TotalMilliseconds
    $elapsed = [int]((Get-Date) - $time0).Totalseconds
    if ($spent -gt 1000) {$longs++; $last = "{0:HH}:{0:mm}:{0:ss}" -f (Get-Date)}
    if ($longest -lt $spent) {$longest = $spent}
    "Spent:{0}ms | Elapsed:{1}s | Iterations:{2} | Longs:{3} | Longest:{4} | Last:{5}" -f $spent, $elapsed, $i, $longs, $longest, $last
} While (1) #((Read-Host) -ne 'n')