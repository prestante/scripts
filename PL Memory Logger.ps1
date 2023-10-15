Clear-Host
$dateTime = Get-Date -Format 'yyyy-MM-dd HH-mm-ss'
$logfile='C:\PS\logs\PL.Memory.' + $dateTime + '.csv'
"ADC Playlist memory consumption log."
New-Item -Path $logfile -ItemType file -Force | Out-Null
#Set-Content -Path $logfile -Value "`"Time`",`"Memory`""
"Logfile is in $logfile"
$PL = 'Playlist'
function PLmem {
    $PLProcess = Get-Process $PL -ea SilentlyContinue
    [math]::Round(($PLProcess.WorkingSet64) / 1075738)}
function GD {Get-Date -Format "MM-dd HH:mm:ss"}
function Title {"------------------------"
"Press <Esc> to exit."
"------------------------"
}
"Time,Memory" | Tee-Object $logfile -Append
do {
    #logging PL memory consumption values to logfile
    "$(GD),$(PLmem)" | Tee-Object $logfile -Append
    #looking for <Esc> or <r> or <Space> press
    if ($host.ui.RawUi.KeyAvailable) {
        $key=$host.ui.RawUI.ReadKey("NoEcho,IncludeKeyUp")
        $Host.UI.RawUI.FlushInputBuffer()
        switch ($key.VirtualKeyCode) {
            82 {} #<R>
            27 {exit} #<Esc>
            112 {Title} #<F1>
            73 {}
            65 {} #<A>
            32 {} #<Space>
        } #end switch
    } #end if
    #$Host.UI.RawUI.FlushInputBuffer()
    Start-Sleep -milliseconds 1000
} until ($key.VirtualKeyCode -eq 27)