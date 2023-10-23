$username = 'wtldev.net\vadc'
$password = ConvertTo-SecureString $env:vpw -AsPlainText
$credential = New-Object System.Management.Automation.PSCredential($username, $password)
$hostname = 'wtl-adc-ctc-01.wtldev.net'

#local agalkovs Powershell PID = 1768
#$queryFormatted = "SELECT PercentProcessorTime FROM Win32_PerfFormattedData_PerfProc_Process WHERE Name='ChronosExe'"
#$queryRaw = "SELECT PercentProcessorTime FROM Win32_PerfRawData_PerfProc_Process WHERE Name='ChronosExe'"
#$queryFormatted = "SELECT PercentProcessorTime FROM Win32_PerfFormattedData_PerfProc_Process WHERE IDProcess='1768'"
#$queryRaw = "SELECT PercentProcessorTime FROM Win32_PerfRawData_PerfProc_Process WHERE IDProcess='1768'"
$queryFormatted = "SELECT PercentProcessorTime FROM Win32_PerfFormattedData_Counters_ProcessV2 WHERE Name='ChronosExe'"
$queryRaw = "SELECT PercentProcessorTime FROM Win32_PerfRawData_Counters_ProcessV2 WHERE Name='ChronosExe'"

for ($i = 0; $i -lt 20; $i++) {
    $time0 = Get-Date
    $resultFormatted = "{0:n3}" -f (Get-WmiObject -Query $queryFormatted -ComputerName $hostname -Credential $credential).PercentProcessorTime
    $resultRaw = "{0:n3}" -f (Get-WmiObject -Query $queryRaw -ComputerName $hostname -Credential $credential).PercentProcessorTime
    #$resultFormatted = "{0:n3}" -f (Get-WmiObject -Query $queryFormatted).PercentProcessorTime
    #$resultRaw = "{0:n3}" -f (Get-WmiObject -Query $queryRaw).PercentProcessorTime
    #$result = "{0:n3}" -f (Get-Counter "\Process(ChronosExe)\% processor time").CounterSamples.CookedValue
    $timeDiff = "{0:ss}.{0:fff}" -f ((Get-Date) - $time0)
    Write-Host "TimeDiff: $timeDiff     Formatted: $resultFormatted     Raw: $resultRaw"
}

#$table = Get-WmiObject -List | Where-Object {$_.Name -match 'Process'}
#$table | Format-Table -AutoSize

#Get-WmiObject 'Win32_PerfRawData_PerfProc_Process' | Select-Object -First 5



