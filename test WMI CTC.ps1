$username = 'wtldev.net\vadc'
$password = ConvertTo-SecureString $env:vpw -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($username, $password)
$hostname = 'wtl-adc-ctc-01.wtldev.net'

$time0 = Get-Date; $i = 0; $longs = 0; $longest = 0
do {
    $i++
    $spent = [int](Measure-Command {
        $processes = (Get-WmiObject -Query "SELECT Name,IDProcess,PercentProcessorTime,WorkingSet,Timestamp_Sys100NS FROM Win32_PerfRawData_PerfProc_Process WHERE NOT Name='_Total'" -ComputerName $hostname -Credential $credential).Count
    }).TotalMilliseconds
    $elapsed = [int]((Get-Date) - $time0).Totalseconds
    if ($spent -gt 1000) {$longs++}
    if ($longest -lt $spent) {$longest = $spent}
    "CTC-Spent:{0}ms | Elapsed:{1}s | Iterations:{2} | Longs:{3} | Longest:{4}ms" -f $spent, $elapsed, $i, $longs, $longest
} While (1) #((Read-Host) -ne 'n')