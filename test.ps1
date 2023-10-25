# Trying to convert giant WMI array to hash table
do {
    Measure-Command {
        #$Global:ProcKeyWords = 'chrome', 'taskmgrr' -join '|'
        $allRawProcesses = Get-WmiObject -Query "SELECT * FROM Win32_PerfRawData_PerfProc_Process WHERE NOT Name='_Total'"
        $hash = [ordered]@{}
        $allRawProcesses | % {$hash.Add($_.IDProcess, '')}
    }
} While ((Read-Host) -ne 'n')