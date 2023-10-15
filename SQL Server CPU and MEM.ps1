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
$Processes = @(
'sqlservr'
)
$ProcessIDs = @(0)

Function cpu {
    $time = New-Object datetime[] $ProcessIDs.Length
    $TPT1 = New-Object decimal[] $ProcessIDs.Length
    for ($i=0 ; $i -lt $ProcessIDs.Count ; $i++) {
        try {
            $Process = Get-Process -id $ProcessIDs[$i] -ea stop
            $time[$i] = Get-Date
            $TPT1[$i] = $Process.TotalProcessorTime.TotalMilliseconds
        } catch { $time[$i] = 0 ; $TPT1[$i] = 0 }
    }
    Start-Sleep -Milliseconds $ms
    #$Global:fromCounter = (Get-Counter "\Process(powershell)\% Processor Time").CounterSamples.cookedvalue/$LogicalCPUs
    for ($i=0 ; $i -lt $ProcessIDs.Count ; $i++) {
        try {
            $Process = Get-Process -id $ProcessIDs[$i] -ea stop
            $TPT2 = [decimal]$Process.TotalProcessorTime.TotalMilliseconds
            $diff = ((Get-Date) - $time[$i]).totalmilliseconds
            [decimal](($TPT2 - $TPT1[$i])/($LogicalCPUs*$HT*$diff)*100)
        } catch { 0 }
    }
}
Function mem {
    for ($i=0 ; $i -lt $ProcessIDs.Count ; $i++) {
        try {
            $Process = Get-Process -id $ProcessIDs[$i] -ea stop
            if ($Process -eq 'Playlist') {[int][math]::Round(((get-process -name 'CefSharp.BrowserSubprocess' -ea SilentlyContinue).workingset64 | Measure-Object -Sum).Sum/1MB + ((Get-Process $Process -ea Stop).WorkingSet64)/1MB)}
            else {[int][math]::Round(($Process.WorkingSet64) / 1MB)}
        }
        catch { 0 }
    }
}
Function makeTable {
    $NewProcessIDs = @()
    foreach ($process in $Processes) {
        Get-Process -Name $process -ea SilentlyContinue | % {$NewProcessIDs += $_.Id}
    }
    if (Compare-Object $ProcessIDs $newprocessIDs) {
        $Global:ProcessIDs = $NewProcessIDs
        $Global:table = @()
        for ($i = 0 ; $i -lt $ProcessIDs.Length ; $i++) {
            try {
                $proc = get-process -id $ProcessIDs[$i] -ea Stop
                $Global:table += [pscustomobject]@{
                Name = "$($proc.name)($($proc.id))" -replace '^Harris.Automation.ADC.Services.' -replace 'Host' -replace 'Service' -replace 'Validation'
                Memory = 0
                CPU = 0
                }
            } catch {}
        }
        $Global:table += [pscustomobject]@{
            Name = '---------------'
        }
        $Global:table += [pscustomobject]@{
            Name = 'TOTAL'
            Memory = 0
            CPU = 0
        }
        $Global:table += [pscustomobject]@{
        }
        $Global:table += [pscustomobject]@{
            Name = 'Peak'
            Memory = 0
            CPU = 0
        }
        $Global:table += [pscustomobject]@{
            Name = 'Average'
            Memory = 0
            CPU = 0
        }
    }
} #end of Function makeTable
Function zero {
    #$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch
    #$StopWatch.Start()
    $Global:allCpu = [System.Collections.ArrayList]@() ; $Global:allMem = [System.Collections.ArrayList]@()
    $Global:startTime = Get-Date
}
zero

do {
    makeTable
    $cpu = (cpu)
    $mem = (mem)
    $totalCpu = ($cpu | Measure-Object -Sum).Sum
    $totalMem = ($mem | Measure-Object -Sum).Sum
    
    #if $totalCpu is zero for last 5 iterations, clearing avg and peak values
    #if ((($allCpu | select -Last 5 | Measure-Object -Sum).sum -eq 0) -and (($allMem | select -Last 5 | Measure-Object -Sum).sum -eq 0)) {$peakCpu=0 ; $peakMem=0 ; [int32[]]$allCpu=@() ; [int32[]]$allMem=@() ; $StopWatch.Restart()}
    if (($totalCpu -eq 0) -and ($totalMem -eq 0)) {$zeroFlag++}
    if ($zeroFlag -eq 5) {$peakCpu=0 ; $peakMem=0 ; $zeroFlag=0 ; zero}

    $peakCpu = if ($peakCpu -lt $totalCpu) {$totalCpu} else {$peakCpu}
    $peakMem = if ($peakMem -lt $totalMem) {$totalMem} else {$peakMem}
    $allCpu.add($totalCpu) | Out-Null
    $allMem.add($totalMem) | Out-Null
    [int32]$avgCpu = ($allCpu | Measure-Object -Sum).Sum / $allCpu.Count
    [int32]$avgMem = ($allMem | Measure-Object -Sum).Sum / $allMem.Count

    for ($i = 0 ; $i -lt $ProcessIDs.Length ; $i++) {
        $table[$i].CPU = [math]::Round($cpu[$i])
        $table[$i].Memory = $mem[$i]
    }
    $table.Where({$_.Name -eq 'TOTAL'}).foreach({$_.CPU = [math]::Round($totalCpu) ; $_.Memory = $totalMem})
    $table.Where({$_.Name -eq 'Peak'}).foreach({$_.CPU = [math]::Round($peakCpu) ; $_.Memory = $peakMem})
    $table.Where({$_.Name -eq 'Average'}).foreach({$_.CPU = $avgCpu ; $_.Memory = $avgMem})

    cls
    $table | ft -AutoSize
    #$fromCounter
    #"Elapsed {0:00}:{1:00}:{2:00}" -f [math]::Floor($StopWatch.Elapsed.TotalHours), $StopWatch.Elapsed.Minutes, $StopWatch.Elapsed.Seconds
    $diff = ((get-date) - $startTime)
    "Elapsed {0:00}:{1:mm}:{1:ss}" -f [math]::Floor($diff.TotalHours),$diff
    
    #looking for <Esc> or <R> or <Space> press
    if ($host.ui.RawUi.KeyAvailable) {
        $key=$host.ui.RawUI.ReadKey("NoEcho,IncludeKeyUp")
        $host.UI.RawUI.FlushInputBuffer()
        switch ($key.VirtualKeyCode) {
            <#C#> 67 {$peakCpu=0 ; $peakMem=0 ; [int32[]]$allCpu=@() ; [int32[]]$allMem=@()}
            <#Esc#> 27 {exit}
            <#Space#> 32 {}
            <#F4#> 115 {}
        } #end switch
    } #end if
} until ($key.VirtualKeyCode -eq 27)
