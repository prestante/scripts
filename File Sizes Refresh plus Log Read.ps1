$folder = 'C:\Program Files (x86)\Imagine Communications\ADC Services\log\'
$file = 'C:\Program Files (x86)\Imagine Communications\ADC Services\cache\IntegrationServiceDataStorage.sdf'
$log = 'C:\Program Files (x86)\Imagine Communications\ADC Services\log\IntegrationService.log'
$logfile="C:\PS\logs\Integration $(Get-Date -Format 'yyyy-MM-dd HH-mm-ss').csv"
New-Item -Path $logfile -ItemType file -Force | Out-Null
"Cache(KB),PlaylistProcessorMessage" | Out-File $logfile -Append ascii

$Matches = @()
$oldSize = $null
$oldLog = $null
$showSize = $null
$showLog = $null

do {
    $Matches = @()
    $oldSize = $showSize
    $oldLog = $showLog
    $showSize = (Get-ItemProperty $file).Length/1KB
    $showLog = (Get-Content $log -Tail 1) -match '] - (?<name>.*)' | % {$matches['name']}
    if (($showLog -eq $oldLog) -and ($showSize -eq $oldSize)) {$skip = 1}

    if ($skip -eq 0) {
        cls
        $showSize
        $showLog
    
        "$showSize,$showLog" | Out-File $logfile -Append ascii
        if ($showLog -eq '') {(Get-Content $log -Tail 1) | Out-File $logfile -Append ascii}
    }
    else {$skip = 0}

    #looking for <Esc> or <Enter> press
    if ($host.ui.RawUi.KeyAvailable) {
        $key=$host.ui.RawUI.ReadKey("NoEcho,IncludeKeyUp")
        $Host.UI.RawUI.FlushInputBuffer()
        if ($key.VirtualKeyCode -eq 13) {exit}                  #<Enter>
        if ($key.VirtualKeyCode -eq 27) {exit}                  #<Esc>
    }
    Start-Sleep -Milliseconds 100
} until ($key.VirtualKeyCode -eq 27)