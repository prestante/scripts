Measure-Command { $lines = 0 ; Get-Content $logfile -ReadCount 1000 | % { $lines += $_.count } ; $lines}
#Measure-Command { $lines = 0 ; (Get-Content $logfile).Length }
#Measure-Command { (Get-Content $logfile -ReadCount 1000 | Measure-Object -Line).Lines }
#Measure-Command { [System.IO.File]::ReadLines($logfile) | Measure-Object -Line | Select-Object -ExpandProperty Lines }
