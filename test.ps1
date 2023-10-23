#$username = 'wtldev.net\vadc'
#$password = ConvertTo-SecureString $env:vpw -AsPlainText -Force
#$credential = New-Object System.Management.Automation.PSCredential($username, $password)
#$hostname = 'wtl-adc-ctc-01.wtldev.net'

$properties = 'Name, IDProcess, Timestamp_Sys100NS, PercentProcessorTime, WorkingSet'
$all = Get-WmiObject -Query "SELECT * FROM Win32_PerfRawData_PerfProc_Process"
$all | Where-Object {$_.Name -match 'Chrome'} | Select-Object -Property $properties.Split(', ') | ft
return

do {
    $time1 = Get-Date
    $process = Get-Process explorer
    #$allRawProcesses = Get-WmiObject -Query "SELECT Name, Timestamp_Sys100NS, PercentProcessorTime FROM Win32_PerfRawData_PerfProc_Process" -ComputerName $hostname -Credential $credential
    #$allRawProcesses | Where-Object {$_.Name -match 'Idle'}
    Write-Host "$([int](((Get-Date) - $time1).TotalMilliseconds)), " -NoNewline
} while (1)


