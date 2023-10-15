$processor = Get-WmiObject Win32_Processor -ComputerName wtl-hp3b8-vds1.wtldev.net
$totalMemory = Get-CimInstance Win32_PhysicalMemory -ComputerName wtl-hp3b8-vds1.wtldev.net
($processor | Measure -Property  NumberOfLogicalProcessors -Sum).Sum
($totalMemory | Measure-Object -Property capacity -Sum).Sum /1mb