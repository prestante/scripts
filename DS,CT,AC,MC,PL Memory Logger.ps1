Clear-Host
$dateTime = Get-Date -Format 'yyyy-MM-dd HH-mm-ss'
$logfile='C:\PS\logs\DS.Memory.' + $dateTime + '.csv'
New-Item -Path $logfile -ItemType file -Force | Out-Null
$DS = 'ADC1000NT'
$CT = 'ADC1000NTCFG'
$AC = 'ACLNT32'
$MC = 'MCLIENT'
$PL = 'Playlist'
function DSmem {
    $DSProcess = Get-Process $DS -ea SilentlyContinue
    [math]::Round(($DSProcess.WorkingSet64) / 1MB)}
function CTmem {
    $CTProcess = Get-Process $CT -ea SilentlyContinue
    [math]::Round(($CTProcess.WorkingSet64) / 1MB)}
function ACmem {
    $ACProcess = Get-Process $AC -ea SilentlyContinue
    [math]::Round(($ACProcess.WorkingSet64) / 1MB)}
function MCmem {
    $MCProcess = Get-Process $MC -ea SilentlyContinue
    [math]::Round(($MCProcess.WorkingSet64) / 1MB)}
function PLmem {
    $PLProcess = Get-Process $PL -ea SilentlyContinue
    [math]::Round(($PLProcess.WorkingSet64) / 1MB)}
function GD {Get-Date -Format "ddd HH:mm:ss"}
function Title {"------------------------"
"Logfile is in $logfile"
"Press <Esc> to exit."
"------------------------"
}
Title
"Time,DS,CT,AC,MC,PL" | Out-File $logfile -Append ascii
do {
    #logging DS memory consumption values to logfile
    "$(GD),$(DSmem),$(CTmem),$(ACmem),$(MCmem),$(PLmem)" | Out-File $logfile -Append ascii
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