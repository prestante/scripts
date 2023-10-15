#current
[int]$cores = $env:NUMBER_OF_PROCESSORS
$ms = 1000
$process = Get-Process -Name Harris.Automation.ADC.Services.AggregationServiceHost
$cpu1 = $process.TotalProcessorTime.TotalMilliseconds
Start-Sleep -Milliseconds $ms
$cpu2 = $process.TotalProcessorTime.TotalMilliseconds
"{0:n2}" -f (($cpu2 - $cpu1)/($cores*$ms)*100)

#avg
[int]$cores = $env:NUMBER_OF_PROCESSORS
$process = Get-Process -Name ChronosExe
$tm = $process.TotalProcessorTime.TotalMilliseconds
$ms = ((get-date) - ($process.StartTime)).TotalMilliseconds
"{0:n2}" -f ($tm/($cores*$ms)*100)
  
#right from performance monitor
[int]$cores = $env:NUMBER_OF_PROCESSORS
$process = Get-Process -Name Harris.Automation.ADC.Services.AggregationServiceHost
(Get-Counter "\Process($($process.ProcessName))\% Processor Time").CounterSamples | Select InstanceName, @{Name="CPU %";Expression={[Decimal]::Round(($_.CookedValue / $cores), 2)}} | sort *CPU* -Descending | select -First 10