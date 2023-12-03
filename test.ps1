$logfile = "C:\PS\logs\18MB 2023-11-23 10-16-38.csv"
$mode = 'last'
#Get-Location
#return
& ".\Chart Builder.ps1" -logfile $logfile -mode $mode
Read-Host