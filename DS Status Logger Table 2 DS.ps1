#$CTC = @('192.168.13.170','192.168.13.171','192.168.13.172','192.168.13.173','192.168.13.174','192.168.13.175','192.168.13.176','192.168.13.177','192.168.13.178','192.168.13.179','192.168.13.180','192.168.13.181','192.168.13.182','192.168.13.138','192.168.13.139','192.168.13.140','192.168.13.141','192.168.13.142','192.168.13.143','192.168.13.145','192.168.13.161','192.168.13.168','192.168.13.232','192.168.13.191')
#$CTC = @('WTL-HP3B8-VDS1.WTLDEV.NET','WTL-HP3B8-VDS2.WTLDEV.NET','WTL-HP3B8-VDS3.WTLDEV.NET','WTL-HP3B8-VDS4.WTLDEV.NET','WTL-HP3B8-VDS5.WTLDEV.NET','WTL-HP3B8-VDS6.WTLDEV.NET','WTL-HP3B8-VDS7.WTLDEV.NET','WTL-HP3B8-VDS8.WTLDEV.NET','WTL-HP3B8-VDS9.WTLDEV.NET','WTL-HP3B8-VDS10.WTLDEV.NET','WTL-HP3B9-VDS1.WTLDEV.NET','WTL-HP3B9-VDS2.WTLDEV.NET','WTL-HP3B9-VDS3.WTLDEV.NET','WTL-HP3B9-VDS4.WTLDEV.NET','WTL-HP3B9-VDS5.WTLDEV.NET','WTL-HP3B9-VDS6.WTLDEV.NET','WTL-HP3B9-VDS7.WTLDEV.NET','WTL-HP3B9-VDS8.WTLDEV.NET','WTL-HP3B9-VDS9.WTLDEV.NET','WTL-HP3B9-VDS10.WTLDEV.NET')
$CTC = @('adc-ctc01.tecomgroup.ru','adc-ctc02.tecomgroup.ru','adc-ctc03.tecomgroup.ru','adc-ctc04.tecomgroup.ru','adc-ctc05.tecomgroup.ru','adc-ctc06.tecomgroup.ru','adc-ctc07.tecomgroup.ru','adc-ctc08.tecomgroup.ru','adc-ctc09.tecomgroup.ru','adc-ctc10.tecomgroup.ru','adc-ctc11.tecomgroup.ru','adc-ctc12.tecomgroup.ru','adc-ctc13.tecomgroup.ru','adc-ctc14.tecomgroup.ru','adc-ctc15.tecomgroup.ru','adc-ctc16.tecomgroup.ru','adc-ctc17.tecomgroup.ru','adc-ctc18.tecomgroup.ru','adc-ctc19.tecomgroup.ru','adc-ctc20.tecomgroup.ru','adc-ctc21.tecomgroup.ru','adc-ctc22.tecomgroup.ru','adc-ctc23.tecomgroup.ru','adc-ctc24.tecomgroup.ru')
#$CTC = @('galkovsky-a-02.tecom.nnov.ru')
#$CTC = @('adc-ctc01.tecomgroup.ru','adc-ctc02.tecomgroup.ru')

$Creds = [System.Management.Automation.PSCredential]::new('local\Administrator',(ConvertTo-SecureString -AsPlainText 'Tecom_1!' -Force))

$HS = [hashtable]::Synchronized(@{})
[System.Collections.Generic.List[PSObject]]$HS.results = @()

$poolPing = [RunspaceFactory]::CreateRunspacePool(1, [int]$env:NUMBER_OF_PROCESSORS+1)
$poolPing.ApartmentState = "MTA"
$poolPing.ThreadOptions = "ReuseThread"
$poolPing.Open()
$runspacesPing = @()

$scriptblockPing = {
    Param ([hashtable]$HS, [string]$server)
    $test = Test-Connection -ComputerName $server -Count 1 -ea SilentlyContinue
    $ping = $test.ResponseTime
    if ($test) {
        #$all = [pscustomobject]@{Server=$server;Ping=$ping;DSver='error'}
        try {
            $Creds = [System.Management.Automation.PSCredential]::new('local\Administrator',(ConvertTo-SecureString -AsPlainText 'Tecom_1!' -Force))
            $all = Invoke-Command -ComputerName $server -ArgumentList $server,$ping -Credential $Creds -ScriptBlock {
                param ($server,$ping)
                [pscustomobject]@{
                    Server = $server
                    Ping = $ping
                    DS1ver = if (Test-Path 'C:\Users\Public\Desktop\ADC Device Server.lnk') {
                        $sh = New-Object -ComObject WScript.Shell
                        ((gci $sh.CreateShortcut('C:\Users\Public\Desktop\ADC Device Server.lnk').Targetpath).VersionInfo).ProductVersion
                    } else {''}
                    DS2ver = if (Test-Path 'C:\Users\Public\Desktop\ADC Device Server2.lnk') {
                        $sh = New-Object -ComObject WScript.Shell
                        ((gci $sh.CreateShortcut('C:\Users\Public\Desktop\ADC Device Server2.lnk').Targetpath).VersionInfo).ProductVersion
                    } else {''}
                    DS1mem = if ((Get-Process -Name ADC1000NT -ea SilentlyContinue).Count) {
                        "{0:n2}" -f [math]::round(((Get-Process -Name ADC1000NT -ea SilentlyContinue | select -First 1).WorkingSet64 | Measure-Object -Sum).Sum/1MB,2)
                    } else {''}
                    DS2mem = if ((Get-Process -Name ADC1000NT -ea SilentlyContinue).Count -eq 2) {
                        "{0:n2}" -f [math]::round(((Get-Process -Name ADC1000NT -ea SilentlyContinue | select -Last 1).WorkingSet64 | Measure-Object -Sum).Sum/1MB,2)
                    } elseif ((Get-Process -Name ADC1000NT -ea SilentlyContinue).Count -gt 2) {
                        "{0}xDS" -f (Get-Process -Name ADC1000NT -ea SilentlyContinue).Count
                    } else {''}
                }
            } -ErrorAction Stop
        } catch {$all = [pscustomobject]@{Server=$server;Ping=$ping;DSver='error'}}
    } else {$all = [pscustomobject]@{Server=$server}}
    $HS.results.Add($all)
    #$HS.results.Add([PSObject]@{'Server'=$server;'Ping'=$ping;'DSver'=$DSver;'DSmem'=$DSmem;'SEver'=$SEver;'SEmem'=$SEmem;'PLmem'=$PLmem;'CTmem'=$CTmem})
}

function Ping {
    $i = 0
    foreach ($server in $CTC) {
        $runspace = [PowerShell]::Create()
        [void]$runspace.AddScript($scriptblockPing).AddArgument($HS).AddArgument($server)
        $runspace.RunspacePool = $poolPing
        $Global:runspacesPing += [PSCustomObject]@{Num=$i++; Pipe=$runspace; Status=$runspace.BeginInvoke()}
    }
}
function StopDS ($DS) {
    $Creds = [System.Management.Automation.PSCredential]::new('local\Administrator',(ConvertTo-SecureString -AsPlainText 'Tecom_1!' -Force))
    if (($DS -ne $Null) -and ($DS -ne '')) {
        if (!(Test-Connection -ComputerName $CTC[$DS-1] -Count 1 -Quiet)) {return}
        $Comp = $CTC[$DS-1] ; "Stopping DS on CTC{0:d2}" -f $DS
    }
    else {$Comp=@() ; $table.Where({$_.Ping -ne [DBNull]::Value}).foreach({$Comp+=$_.Name}) ; "Stopping DS on all CTC"}
    Invoke-Command -ComputerName $Comp -Credential $Creds {Stop-Process -name ADC1000NT} -ea SilentlyContinue
    Start-Sleep -Seconds 1
}
function StartDS ($DS) {
    $Creds = [System.Management.Automation.PSCredential]::new('local\Administrator',(ConvertTo-SecureString -AsPlainText 'Tecom_1!' -Force))
    $PSSessionOption.IdleTimeout = New-TimeSpan -days 24 -Seconds 0
    if (($DS -ne $Null) -and ($DS -ne '')) {
        if (!(Test-Connection -ComputerName $CTC[$DS-1] -Count 1 -Quiet)) {return}
        $Comp = $CTC[$DS-1] ; "Starting DS on CTC{0:d2}" -f $DS
    }
    #else {$Comp=@() ; $table.Where({($_.Ping -ne [DBNull]::Value) -and ([int]$_.No -le 14)}).foreach({$Comp+=$_.Name}) ; "Starting DS on all (14) CTC"}
    else {$Comp=@() ; $table.Where({($_.Ping -ne [DBNull]::Value)}).foreach({$Comp+=$_.Name}) ; "Starting DS on all CTC"}
    Invoke-Command -ComputerName $Comp -InDisconnectedSession -Credential $Creds {
        Start-Process 'C:\Users\Public\Desktop\ADC Device Server.lnk'
        Start-Process 'C:\Users\Public\Desktop\ADC Device Server2.lnk'
    }  | Out-Null
    Start-Sleep -Seconds 1
}
function WatchRunspaces {
    $hash = @{}
    for ($i = 0 ; $i -lt $runspacesPing.Count ; $i++) {
        $hash.Add($runspacesPing.Num[$i],$runspacesPing.Status.IsCompleted[$i])
    }
    $string = $hash.GetEnumerator() | Sort-Object -Property Name | Out-String
    cls
    Write-Host $string -ForegroundColor Red
}
function Mem {
    [math]::Round((Get-Process -id $PID).WorkingSet64 / 1MB)
}
function Draw {
    cls
    $table | ft -AutoSize -Property ($table.Columns.ColumnName)

    if ($infoCounter) {
        Title
        $Global:infoCounter--
    }
}
function Title {
    Write-Host "`$PID = $PID" -f 7
    Write-Host "Passes: $passes" -f 7
    Write-Host "-----------------------------------" -f 7
    Write-Host "Press <Space> to start/stop all DS." -f 7
    Write-Host "Press <S> to start/stop single DS." -f 7
    Write-Host "Press <Esc> to exit." -f 7
    Write-Host "-----------------------------------" -f 7
    #"WorkingSet64: $WSmem (originally was $origMem)"
    #"GC Memory: $GCmem (originally was $origGC)"
}
function TitleInit {"--------`nPlease wait few seconds...`n--------"}
#function GCmem { [math]::Round([gc]::GetTotalMemory(1)/1MB) }

$table = New-Object System.Data.DataTable
$table.Columns.Add("No","string") | Out-Null
$table.Columns.Add("Name","string") | Out-Null
$table.Columns.Add("Ping","string") | Out-Null
$table.Columns.Add("DS1ver","string") | Out-Null
$table.Columns.Add("DS1mem","string") | Out-Null
$table.Columns.Add("DS2ver","string") | Out-Null
$table.Columns.Add("DS2mem","string") | Out-Null

for ($i = 1 ; $i -le $CTC.Length ; $i++) {
    $row = $table.NewRow()
    $row.No = $i
    $row.Name = $CTC[$i-1] -replace '\.\w+\.\w+$'  # removing dns suffix
    $table.Rows.Add($row)
}

#cls
#$table | ft -AutoSize -Property $table.Columns.ColumnName
#"`$PID = $PID"
#$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch
#$Lap = New-TimeSpan -Seconds 5
#$StopWatch.Start()
#sleep 3
#if ($init -eq 'completed') {Title} else {TitleInit}
Ping
TitleInit

do {
    if ($runspacesPing.Status.IsCompleted -notcontains $false) {
        #WatchRunspaces
        foreach ($runspace in $runspacesPing) {
            $runspace.Pipe.EndInvoke($runspace.Status)
            $runspace.Pipe.Dispose()
        }
        try {
            foreach ($result in $HS.results) {
                $table.Where({$result.Server -match $_.Name}).foreach({$_.ping=$result.Ping;$_.DS1ver=$result.DS1ver;$_.DS1mem=$result.DS1mem;$_.DS2ver=$result.DS2ver;$_.DS2mem=$result.DS2mem})
            }
        }
        catch {
            "Something went wrong in TRY block"
            sleep 2
            #$hash = @{}
            #for ($i = 0 ; $i -lt $runspacesPing.Count ; $i++) {
            #    $hash.Add($runspacesPing.Num[$i],$runspacesPing.Status.IsCompleted[$i])
            #}
            #$string = $hash.GetEnumerator() | Sort-Object -Property Name
            #Write-Host $string -ForegroundColor Red
        }
        #[gc]::Collect()
        $runspacesPing = $null
        $runspacesPing = @()
        $HS = $null
        $HS = [hashtable]::Synchronized(@{})
        [System.Collections.Generic.List[PSObject]]$HS.results = @()
        $GCmem = [math]::Round([gc]::GetTotalMemory($true) / 1MB)
        $WSmem = (Mem)
        $passes++
        if ($init -ne 'completed') {$init = 'completed' ; $origMem = (Mem) ; $origGC = $GCmem}
        Ping
        Draw
    }

    
    #WatchRunspaces

    #$StopWatch.Elapsed.Seconds
    Start-Sleep -Milliseconds 100
    
    #looking for <Esc> or <R> or <Space> press
    if ($host.ui.RawUi.KeyAvailable) {
        $key=$host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown,IncludeKeyUp")
        $Host.UI.RawUI.FlushInputBuffer()
        if ($key.keydown) {
            switch ($key.VirtualKeyCode) {
                <#Esc#>   27 {exit}
                <#S#>     83 {
                    $Chosen = [int](Read-Host "Which DS to start/stop? Default = All")
                        if (($Chosen) -and ($table.DS1mem[$Chosen-1] -ne [DBNull]::Value)) {StopDS -DS $Chosen}
                        elseif (($Chosen) -and ($table.DS1mem[$Chosen-1] -eq [DBNull]::Value)) {StartDS -DS $Chosen}
                        elseif ((!$Chosen) -and [bool]($table.DS1mem -gt 0)) {StopDS}
                        elseif ((!$Chosen) -and ![bool]($table.DS1mem -gt 0)) {StartDS}
                }
                <#Space#> 32 {
                    if ($table.DS1mem -gt 0) {StopDS}
                        else {StartDS}
                }
                <#F1#>    112 {$infoCounter = 3}
                <#F4#>    #115 {cls ; Get-Job ; Write-Host "WTF"}
            } #end switch
        }
    } #end if
} until ($key.VirtualKeyCode -eq 27)