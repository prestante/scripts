Write-Host "Reading CPU properties..." -fo Yellow -ba Black
$Processor = Get-WmiObject Win32_Processor
$Cores = $Processor | Measure -Property  NumberOfCores -Sum
$Cores = $Cores.Sum
$LogicalCPUs = $Processor | Measure -Property  NumberOfLogicalProcessors -Sum
$LogicalCPUs = $LogicalCPUs.sum

if ($Processor.Caption -match 'Family 6 Model 79') {$HT=2.75}
elseif ($Cores -lt $LogicalCPUs) {$HT=0.9}
else {$HT=1}

$ms = 1000
#'ChronosExe',
$Processes = @(
'ADC1000NT'
)

Function cpu {
    $time = New-Object datetime[] $Processes.Length
    $TPT1 = New-Object decimal[] $Processes.Length
    for ($i=0 ; $i -lt $Processes.Count ; $i++) {
        try {
            $Process = Get-Process -name $Processes[$i] -ea stop
            $time[$i] = Get-Date
            $TPT1[$i] = $Process.TotalProcessorTime.TotalMilliseconds
        } catch { $time[$i] = 0 ; $TPT1[$i] = 0 }
    }
    Start-Sleep -Milliseconds $ms
    #$Global:fromCounter = (Get-Counter "\Process(powershell)\% Processor Time").CounterSamples.cookedvalue/$LogicalCPUs
    for ($i=0 ; $i -lt $Processes.Count ; $i++) {
        try {
            $Process = Get-Process -name $Processes[$i] -ea stop
            $TPT2 = [decimal]$Process.TotalProcessorTime.TotalMilliseconds
            $diff = ((Get-Date) - $time[$i]).totalmilliseconds
            [decimal](($TPT2 - $TPT1[$i])/($LogicalCPUs*$HT*$diff)*100)
        } catch { 0 }
    }
}
Function mem {
    for ($i=0 ; $i -lt $Processes.Count ; $i++) {
        try {
            $Process = Get-Process -name $Processes[$i] -ea stop
            if ($Process -eq 'Playlist') {[int][math]::Round(((get-process -name 'CefSharp.BrowserSubprocess' -ea SilentlyContinue).workingset64 | Measure-Object -Sum).Sum/1MB + ((Get-Process $Process -ea Stop).WorkingSet64)/1MB)}
            else {[int][math]::Round(($Process.WorkingSet64) / 1MB)}
        }
        catch { 0 }
    }
}

$table = New-Object System.Data.DataTable
$table.Columns.Add("Name","string") | Out-Null
$table.Columns.Add("CPU","string") | Out-Null
$table.Columns.Add("Memory","string") | Out-Null
for ($i = 0 ; $i -lt $Processes.Length ; $i++) {
    $row = $table.NewRow()
    $row.Name = "$($Processes[$i])" -replace '^Harris.Automation.ADC.Services.' -replace 'Host' -replace 'Service' -replace 'Validation'
    $row.Memory = '0'
    $row.CPU = '0'
    $table.Rows.Add($row)
}
$row = $table.NewRow()
$row.Name = '---------------'
$table.Rows.Add($row)

$row = $table.NewRow()
$row.Name = 'TOTAL'
$table.Rows.Add($row)

$row = $table.NewRow()
$row.Name = ''
$table.Rows.Add($row)

$row = $table.NewRow()
$row.Name = 'Peak'
$table.Rows.Add($row)

$row = $table.NewRow()
$row.Name = 'Average'
$table.Rows.Add($row)

[int32[]]$allCpu = @() ; [int32[]]$allMem = @()

$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch
$StopWatch.Start()

do {
    $cpu = (cpu)
    $mem = (mem) 
    $totalCpu = ($cpu | Measure-Object -Sum).Sum
    $totalMem = ($mem | Measure-Object -Sum).Sum
    
    #if $totalCpu is zero for last 5 iterations, clearing avg and peak values
    if ((($allCpu | select -Last 5 | Measure-Object -Sum).sum -eq 0) -and (($allMem | select -Last 5 | Measure-Object -Sum).sum -eq 0)) {$peakCpu=0 ; $peakMem=0 ; [int32[]]$allCpu=@() ; [int32[]]$allMem=@() ; $StopWatch.Restart()}

    $peakCpu = if ($peakCpu -lt $totalCpu) {$totalCpu} else {$peakCpu}
    $peakMem = if ($peakMem -lt $totalMem) {$totalMem} else {$peakMem}
    $allCpu += $totalCpu
    $allMem += $totalMem
    [int32]$avgCpu = ($allCpu | Measure-Object -Sum).Sum / $allCpu.Length
    [int32]$avgMem = ($allMem | Measure-Object -Sum).Sum / $allMem.Length

    for ($i = 0 ; $i -lt $Processes.Length ; $i++) {
        $table.Rows[$i].CPU = [math]::Round($cpu[$i])
        $table.Rows[$i].Memory = $mem[$i]
    }
    $table.Where({$_.Name -eq 'TOTAL'}).foreach({$_.CPU = [math]::Round($totalCpu) ; $_.Memory = $totalMem})
    $table.Where({$_.Name -eq 'Peak'}).foreach({$_.CPU = [math]::Round($peakCpu) ; $_.Memory = $peakMem})
    $table.Where({$_.Name -eq 'Average'}).foreach({$_.CPU = $avgCpu ; $_.Memory = $avgMem})

    cls
    $table | ft -AutoSize
    #$fromCounter
    "Elapsed {0:00}:{1:00}:{2:00}" -f [math]::Floor($StopWatch.Elapsed.TotalHours), $StopWatch.Elapsed.Minutes, $StopWatch.Elapsed.Seconds
    
    #looking for <Esc> or <R> or <Space> press
    if ($host.ui.RawUi.KeyAvailable) {
        $key=$host.ui.RawUI.ReadKey("NoEcho,IncludeKeyUp")
        $Host.UI.RawUI.FlushInputBuffer()
        switch ($key.VirtualKeyCode) {
            <#C#> 67 {$peakCpu=0 ; $peakMem=0 ; [int32[]]$allCpu=@() ; [int32[]]$allMem=@()}
            <#Esc#> 27 {exit}
            <#Space#> 32 {}
            <#F4#> 115 {}
        } #end switch
    } #end if
} until ($key.VirtualKeyCode -eq 27)
