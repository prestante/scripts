$CTC = '192.168.13.170','192.168.13.171','192.168.13.172','192.168.13.173','192.168.13.174','192.168.13.175','192.168.13.176','192.168.13.177','192.168.13.178','192.168.13.179','192.168.13.180','192.168.13.181','192.168.13.182','192.168.13.138','192.168.13.139','192.168.13.140','192.168.13.141','192.168.13.142','192.168.13.143','192.168.13.145','192.168.13.161','192.168.13.168','192.168.13.232','192.168.13.191'

function TC { #ping PCs
    $Global:TCjob = for ($i = 0 ; $i -lt $CTC.Length ; $i++) {Test-Connection -ComputerName $CTC[$i] -Count 1 -AsJob}
}
function DS { #getting DS version through shortcut target
    $Global:DSjob = for ($i = 0 ; $i -lt $CTC.Length ; $i++) {
        Invoke-Command -ComputerName $CTC[$i] -AsJob -ScriptBlock {
            if (Test-Path 'C:\Users\Public\Desktop\ADC Device Server.lnk') {
                $sh = New-Object -ComObject WScript.Shell
                ((gci $sh.CreateShortcut('C:\Users\Public\Desktop\ADC Device Server.lnk').Targetpath).VersionInfo).ProductVersion
            } else {''}
        }
    }
}
function DSmem { #getting DS memory
    $Global:DSmemjob = for ($i = 0 ; $i -lt $CTC.Length ; $i++) {
        Invoke-Command -ComputerName $CTC[$i] -AsJob -ScriptBlock {
            if (Get-Process -Name ADC1000NT) {
                "{0:n2}" -f [math]::round(((Get-Process -Name ADC1000NT).WorkingSet64/1MB),2)
            } else {''}
        }
    }
}
function Title {"--------`nPress <Space> to start/stop all DS.`nPress <S> to start/stop single DS.`nPress <Esc> to exit.`n--------"}
function TitleInit {"--------`nPlease wait few seconds...`n--------"}
function StopDS ($DS) {
    if (($DS -ne $Null) -and ($DS -ne '')) {$Comp = $CTC[$DS-1] ; "Stopping DS on CTC{0:d2}" -f $DS}
    else {$Comp=@() ; $table.Where({$_.Ping -ne [DBNull]::Value}).foreach({$Comp+=$_.IP}) ; "Stopping DS on all CTC"}
    Invoke-Command -ComputerName $Comp {Stop-Process  -name ADC1000NT} -ea SilentlyContinue
    Start-Sleep -Milliseconds 500
}
function StartDS ($DS) {
    $PSSessionOption.IdleTimeout = New-TimeSpan -days 24 -Seconds 0
    if (($DS -ne $Null) -and ($DS -ne '')) {$Comp = $CTC[$DS-1] ; "Starting DS on CTC{0:d2}" -f $DS}
    else {$Comp=@() ; $table.Where({$_.Ping -ne [DBNull]::Value}).foreach({$Comp+=$_.IP}) ; "Starting DS on all CTC"}
    Invoke-Command -ComputerName $Comp -InDisconnectedSession {
        Start-Process 'C:\Users\Public\Desktop\ADC Device Server.lnk'
    }  | Out-Null
    Start-Sleep -Milliseconds 500
}
function Mem {
    [math]::Round((Get-Process -id $PID).WorkingSet64 / 1MB)
}
function GCmem { [math]::Round([gc]::GetTotalMemory(1)/1MB) }

$table = New-Object System.Data.DataTable
$table.Columns.Add("No","string") | Out-Null
$table.Columns.Add("Name","string") | Out-Null
$table.Columns.Add("IP","string") | Out-Null
$table.Columns.Add("Ping","string") | Out-Null
$table.Columns.Add("DS","string") | Out-Null
$table.Columns.Add("DSver","string") | Out-Null
$table.Columns.Add("DSmem","string") | Out-Null

for ($i = 1 ; $i -le $CTC.Length ; $i++) {
    $row = $table.NewRow()
    $row.No = $i
    $row.Name = "CTC{0:d2}" -f $i
    $row.IP = $CTC[$i-1]
    $table.Rows.Add($row)
}

cls
$table | ft -AutoSize
"`$PID = $PID"
#$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch
#$Lap = New-TimeSpan -Seconds 5
#$StopWatch.Start()
if ($init -eq 'completed') {Title} else {TitleInit}

do {
    if (!($TCjob)) {TC} #first time doing job
    if (!($DSjob)) {DS} #first time doing job
    if (!($DSmemjob)) {DSmem} #first time doing job

    if ($TCjob.State -eq 'Completed') {
        for ($i=0 ; $i -lt $TCjob.Length ; $i++) {
            $table.Rows[$i].Ping = (Receive-Job $TCjob[$i]).ResponseTime 
        }
        Remove-Job $TCjob -Force -ea SilentlyContinue
        TC
        $table.Where({$_.Ping -ne [DBNull]::Value}).foreach({
            if (Test-Connection -ComputerName $_.IP -Count 1 -Quiet) {
                if (Get-Process ADC1000NT -ComputerName $_.IP -ea SilentlyContinue){$_.DS = '*'} else {$_.DS = [DBNull]::Value}
            }
        })
        $table.Where({$_.Ping -eq [DBNull]::Value}).foreach({$_.DS = [DBNull]::Value})
        if ($init -ne 'completed') {$init = 'completed' ; $origMem = (Mem) ; $origGC = (GCmem)}
        $passes++
    }

    if ($DSjob.State -eq 'Completed') {
        for ($i=0 ; $i -lt $DSjob.Length ; $i++) {
            if (Receive-Job $DSjob[$i] -Keep -ea SilentlyContinue) {$table.Rows[$i].DSver=Receive-Job $DSjob[$i]}
            else {$table.Rows[$i].DSver=''}
        }
        Remove-Job $DSjob -Force -ea SilentlyContinue
        DS
    }

    if ($DSmemjob.State -eq 'Completed') {
        for ($i=0 ; $i -lt $DSmemjob.Length ; $i++) {
            if (Receive-Job $DSmemjob[$i] -Keep -ea SilentlyContinue) {$table.Rows[$i].DSmem=Receive-Job $DSmemjob[$i]}
            else {$table.Rows[$i].DSmem=''}
        }
        Remove-Job $DSmemjob -Force -ea SilentlyContinue
        DSmem
    }

    cls
    $table | ft -AutoSize
    "`$PID = $PID"
    if ($init -eq 'completed') {
        Title
        "WorkingSet64: $(Mem) (originally was $origMem)"
        "GC Memory: $(GCmem) (originally was $origGC)"
    } else {TitleInit}
    
    "Passes: $passes"    #$StopWatch.Elapsed.Seconds
    Start-Sleep -Milliseconds 1000
    
    #looking for <Esc> or <R> or <Space> press
    if ($host.ui.RawUi.KeyAvailable) {
        $key=$host.ui.RawUI.ReadKey("NoEcho,IncludeKeyUp")
        $Host.UI.RawUI.FlushInputBuffer()
        switch ($key.VirtualKeyCode) {
            <#S#> 83 {
                $Chosen = [int](Read-Host "Which DS to start/stop? Default = All")
                    if (($Chosen) -and ($table.DS[$Chosen-1] -ne [DBNull]::Value)) {StopDS -DS $Chosen}
                    elseif (($Chosen) -and ($table.DS[$Chosen-1] -eq [DBNull]::Value)) {StartDS -DS $Chosen}
                    elseif ((!$Chosen) -and ($table.DS.Contains('*'))) {StopDS}
                    elseif ((!$Chosen) -and !($table.DS.Contains('*'))) {StartDS}
            }
            <#Esc#> 27 {exit}
            <#Space#> 32 {
                if ($table.DS.Contains('*')) {StopDS}
                    else {StartDS}
            }
            <#F4#> 115 {cls ; Get-Job ; Write-Host "WTF"}
        } #end switch
    } #end if
} until ($key.VirtualKeyCode -eq 27)