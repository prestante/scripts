# Trying to convert giant WMI array to hash table
$i = 0
do {
    $spent = [int](Measure-Command {
        $count = (Get-WmiObject -Query "SELECT Name,IDProcess,PercentProcessorTime,WorkingSet,Timestamp_Sys100NS FROM Win32_PerfRawData_PerfProc_Process WHERE NOT Name='_Total'").Count
    }).TotalMilliseconds
    Write-Host "Spent: $spent `t Count: $count `t Iterations: $i"
} While (1) #((Read-Host) -ne 'n')
