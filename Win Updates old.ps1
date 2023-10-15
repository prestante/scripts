$OSName = (Get-WmiObject -class Win32_OperatingSystem).Caption

$Session = New-Object -ComObject "Microsoft.Update.Session"
$Searcher = $Session.CreateUpdateSearcher()
$historyCount = $Searcher.GetTotalHistoryCount()
$folder = 'C:\WinUpdates\' ; $file = $folder + "WinUpdates_$($env:COMPUTERNAME).txt"
if (!(Test-Path $file)) {New-Item -Path $file -ItemType file -Force | Out-Null}
$OSName | Out-File $file -Encoding ascii -Force -Width 300
$Searcher.QueryHistory(0, $historyCount) | sort -property Date -descending | foreach-object {if ($_.Title) {$_}} | Select-Object Title, Date, @{name='Operation'; expression={switch($_.operation){1 {'Installation'}; 2 {'Uninstallation'}; 3 {'Other'}}}} | Out-File $file -Encoding ascii -Force #-Width 300
Invoke-Item $folder
#Invoke-Item $file

