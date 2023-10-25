# Trying to convert giant WMI array to hash table
do {
    Measure-Command {
        #$Global:ProcKeyWords = 'chrome', 'taskmgrr' -join '|'
        $allRawProcesses = [ordered]@{}
        Get-WmiObject -Query "SELECT Name,IDProcess,PercentProcessorTime,WorkingSet,Timestamp_Sys100NS FROM Win32_PerfRawData_PerfProc_Process WHERE NOT Name='_Total'" | ForEach-Object {
            $allRawProcesses.Add($_.IDProcess, [PSCustomObject]@{
                Name = $_.Name
                IDProcess = $_.IDProcess
                PercentProcessorTime = $_.PercentProcessorTime
                WorkingSet = $_.WorkingSet
                Timestamp_Sys100NS = $_.Timestamp_Sys100NS
            })
            #$allRawProcesses.Add($_.IDProcess, '')
        }
    }
} While ((Read-Host) -ne 'n')
