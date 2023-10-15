#do {
#    $IP = Read-Host "Enter IP or address to ping"
#    if ($IP -notmatch '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}') {Write-Host "Wrong IP!" -fo Red -ba Black}
#} until ($IP -match '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}')

$IP = Read-Host "Enter IP or DNS address to ping"

$logfile = "C:\PS\logs\Ping $IP $(Get-Date -Format 'yyyy-MM-dd HH-mm-ss').csv"
New-Item -Path $logfile -ItemType file -Force | Out-Null

function TC { #ping Nexio
    $Global:TCjob = Test-Connection -ComputerName $IP -Count 1 -AsJob
}
function Title {"Current logfile is in $logfile"}
function GD {Get-Date -Format "ddd HH:mm:ss"}

Title
$ping = 999 ; $fails = 0 ; $lastFail = 'No fails yet'
do {
    if (!($TCjob)) {TC} #first time doing job

    Start-Sleep -Milliseconds 1000

    if ($TCjob.State -eq 'Completed') {
        $ping = (Receive-Job $TCjob).ResponseTime
        Remove-Job $TCjob -Force -ea SilentlyContinue
        TC
    }
    
    if ($ping -eq $null) {$ping = '...' ; $fails++ ; $lastFail = "{0:ddd HH:mm:ss}" -f (Get-Date)}
    "$(GD) - {0} | ping: {1:d3} | fails: {2} | last fail: {3}" -f $IP,$ping,$fails,$lastFail | Tee-Object -FilePath $logfile -Append

    #looking for <Esc> or <R> or <Space> press
    if ($host.ui.RawUi.KeyAvailable) {
        $key=$host.ui.RawUI.ReadKey("NoEcho,IncludeKeyUp")
        $Host.UI.RawUI.FlushInputBuffer()
        switch ($key.VirtualKeyCode) {
            <#S#> 83 {}
            <#Esc#> 27 {exit}
            <#Space#> 32 {}
            <#F1#> 112 {Title}
        } #end switch
    } #end if
} until ($key.VirtualKeyCode -eq 27)