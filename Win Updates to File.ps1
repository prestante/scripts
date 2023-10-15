$Session = New-Object -ComObject "Microsoft.Update.Session"
$Searcher = $Session.CreateUpdateSearcher()

$wu = Get-Service -Name wuauserv

if ($wu.StartType -eq 'Disabled') {
    $wu | set-service -StartupType Automatic
    Write-Host "Enabling Windows Update Service..." -f Yellow -b Black
    sleep 1
    $wasDisabled = 1
}

Write-Host "Gathering Windows Updates data..." -f Yellow -b Black
$historyCount = $Searcher.GetTotalHistoryCount()
$folder = 'C:\WinUpdates\' ; $file = $folder + $env:COMPUTERNAME + '_WinUpdates.txt'
if (!(Test-Path $file)) {New-Item -Path $file -ItemType file -Force | Out-Null}
(Get-WmiObject -class Win32_OperatingSystem).Caption | Out-File $file -Encoding utf8 -Force -Width 300
$Searcher.QueryHistory(0, $historyCount) | 
    sort -property Date -descending | 
        foreach-object {if ($_.Title) {$_}} | 
            Select-Object Title, Date, @{name='Operation'; expression={switch($_.operation){1 {'Installation'}; 2 {'Uninstallation'}; 3 {'Other'}}}} | 
                Out-File $file -Encoding utf8 -Force -Width 300 -Append

if ($wasDisabled) { 
    Write-Host "Stopping Windows Update Service..." -f Yellow -b Black
    $wu | Stop-Service -Force
    sleep 1

    Write-Host "Disabling Windows Update Service..." -f Yellow -b Black
    $wu | set-service -StartupType Disabled
    sleep 1
}

Invoke-Item $folder