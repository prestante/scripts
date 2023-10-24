# Trying to convert giant WMI array to hash table
$allRawProcesses = Get-WmiObject -Query "SELECT * FROM Win32_PerfRawData_PerfProc_Process"
$time0 = (Get-Date)
$hash = @{}
$allRawProcesses | ForEach-Object {
    $hash.Add($_.IDProcess, [PSCustomObject]@{
        Name = $_.Name
        PercentProcessorTime = $_.PercentProcessorTime
        WorkingSet = $_.WorkingSet
        Timestamp_Sys100NS = $_.Timestamp_Sys100NS
    })
}





Write-Host "$([int]((Get-Date) - $time0).TotalMilliseconds) ms"
return



$time0 = (Get-Date)
$Global:Processes = @()
$allRawProcesses = Get-WmiObject -Query "SELECT * FROM Win32_PerfRawData_PerfProc_Process"  # Getting all processes raw information
foreach ($ProcKeyWord in $Global:ProcKeyWords) {$Global:Processes += @($allRawProcesses | Where-Object {$_.Name -match $ProcKeyWord -or $_.IDProcess -match $ProcKeyWord})}

$Global:table = New-Object System.Collections.Generic.List[System.Object]
#$Global:table = @()
    if ($Global:Processes.Name) {
        $Global:Processes | ForEach-Object{
            $tempID = $_.IdProcess  # just in case to avoid double $_ $_ in one string
            $Global:table.Add($_.Name, [pscustomobject]@{
                Name = $_.Name  -replace '^Harris.Automation.ADC.Services.' -replace 'Host' -replace 'Service' -replace 'Validation' -replace '#\d+$'
                Id = $tempID
                Memory = 0
                CPU = 0
                Start = (Get-Process -Id $_.IDProcess).StartTime  # looks like it doesn't affect the performance
                LastRawMEM = $allRawProcesses.Where({$_.IDProcess -eq $tempID}).WorkingSet
                LastRawCPU = $allRawProcesses.Where({$_.IDProcess -eq $tempID}).PercentProcessorTime
                LastTimestamp = $allRawProcesses.Where({$_.IDProcess -eq $tempID}).Timestamp_Sys100NS
            })
        }
    }

    $tableHeaders=@('Name','Id','Memory','CPU')

    $Global:table.Values | Format-Table -Property $tableHeaders

    $tableFormat=@(
            @{Label='Name';Expression={$_.Name}}
            @{Label='Id';Expression={$_.Id}}
            @{Label='Memory';Expression={$_.Memory}}
            @{Label='CPU';Expression={$_.CPU}}
    )
    
    Write-Host ""
    Write-Host "Here's your beautiful table:"
    Write-Host ""
    $Global:table.Values | Format-Table $tableFormat
    Write-Host ""
    
    Write-Host "$([int]((Get-Date) - $time0).TotalMilliseconds) ms"
    
return

$tablePeakMemoryObj = $Global:table.Values | Sort-Object -Property Memory -Descending | Select-Object -First 1
$tablePeakCPUObj = $Global:table.Values | Sort-Object -Property CPU -Descending | Select-Object -First 1
$tableAverageMemoryObj = [pscustomobject]@{
    Name = "Average"
    Memory = ($Global:table.Values | Measure-Object -Property Memory -Average).Average
}
$tableAverageCPUObj = [pscustomobject]@{
    Name = "Average"
    CPU = ($Global:table.Values | Measure-Object -Property CPU -Average).Average
}
$tableLowMemoryObj = $Global:table.Values | Sort-Object -Property Memory | Select-Object -First 1
$tableLowCPUObj = $Global:table.Values | Sort-Object -Property CPU | Select-Object -First 1

$Global:table.Add("SumMemory", [pscustomobject]@{
    Name = "Sum"
    Memory = $tableSumMemory
})
$Global:table.Add("SumCPU", [pscustomobject]@{
    Name = ""
    Id=""
    Memory=""
    CPU=$tableSumCPU
})
$Global:table.Add("PeakMemory", [pscustomobject]@{
    Name="Peak"
    Id=$tablePeakMemoryObj.Id
    Memory=$tablePeakMemoryObj.Memory
})
$Global:table.Add("PeakCPU", [pscustomobject]@{
    Name=""
    Id=$tablePeakCPUObj.Id
    Memory=""
    CPU=$tablePeakCPUObj.CPU
})
$Global:table.Add("Total", [pscustomobject]@{
   Name="TOTAL"
   Id=""
   Memory=($Global:table.Values | Measure-Object -Property Memory -Sum).Sum 
   CPU=($Global:table.Values | Measure-Object -Property CPU -Sum).Sum 
})

