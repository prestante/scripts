$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net', 'WTL-ADC-CTC-03.wtldev.net', 'WTL-ADC-CTC-04.wtldev.net', 'WTL-ADC-CTC-05.wtldev.net', 'WTL-ADC-CTC-06.wtldev.net', 'WTL-ADC-CTC-07.wtldev.net', 'WTL-ADC-CTC-08.wtldev.net', 'WTL-ADC-CTC-09.wtldev.net', 'WTL-ADC-CTC-10.wtldev.net', 'WTL-ADC-CTC-11.wtldev.net', 'WTL-ADC-CTC-12.wtldev.net', 'WTL-ADC-CTC-13.wtldev.net', 'WTL-ADC-CTC-14.wtldev.net', 'WTL-ADC-CTC-15.wtldev.net', 'WTL-ADC-CTC-16.wtldev.net', 'WTL-ADC-CTC-17.wtldev.net', 'WTL-ADC-CTC-18.wtldev.net', 'WTL-ADC-CTC-19.wtldev.net', 'WTL-ADC-CTC-20.wtldev.net', 'WTL-ADC-CTC-21.wtldev.net', 'WTL-ADC-CTC-22.wtldev.net', 'WTL-ADC-CTC-23.wtldev.net', 'WTL-ADC-CTC-24.wtldev.net', 'WTL-ADC-CTC-25.wtldev.net', 'WTL-ADC-CTC-26.wtldev.net', 'WTL-ADC-CTC-27.wtldev.net', 'WTL-ADC-CTC-28.wtldev.net', 'WTL-ADC-CTC-29.wtldev.net', 'WTL-ADC-CTC-30.wtldev.net', 'WTL-ADC-CTC-31.wtldev.net', 'WTL-ADC-CTC-32.wtldev.net')
$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net', 'WTL-ADC-CTC-03.wtldev.net', 'WTL-ADC-CTC-04.wtldev.net', 'WTL-ADC-CTC-05.wtldev.net', 'WTL-ADC-CTC-06.wtldev.net', 'WTL-ADC-CTC-07.wtldev.net', 'WTL-ADC-CTC-08.wtldev.net', 'WTL-ADC-CTC-09.wtldev.net')

$CredsLocal = [System.Management.Automation.PSCredential]::new('local\imagineLocal',(ConvertTo-SecureString -AsPlainText $env:imgLocPW -Force))
$CredsDomain = [System.Management.Automation.PSCredential]::new('wtldev.net\vadc',(ConvertTo-SecureString -AsPlainText $env:vPW -Force))
$PSSessionOption.IdleTimeout = New-TimeSpan -days 24 -Seconds 0

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
                    DSver = if (Test-Path 'C:\Users\Public\Desktop\ADC Device Server.lnk') {
                        $sh = New-Object -ComObject WScript.Shell
                        ((gci $sh.CreateShortcut('C:\Users\Public\Desktop\ADC Device Server.lnk').Targetpath).VersionInfo).ProductVersion
                    } else {''}
                    DSmem = if ((Get-Process -Name ADC1000NT -ea SilentlyContinue).Count) {
                        "{0:n2}" -f [math]::round(((Get-Process -Name ADC1000NT -ea SilentlyContinue).WorkingSet64 | Measure-Object -Sum).Sum/1MB,2)
                    } else {''}         
                    SEver = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -eq 'ADC Services'} | Select-Object -Property DisplayVersion).DisplayVersion
                    SEmem = if ((Get-Process -Name Harris* -ea SilentlyContinue).Count) {
                        "{0:n2}" -f [math]::Round((((Get-Process -Name Harris*).WorkingSet64 | Measure-Object -Sum).Sum/1MB),2)
                    } else {''}
                    PLmem = if ((Get-Process -Name Playlist -ea SilentlyContinue).Count) {
                        "{0:n2}" -f [math]::Round((((Get-Process -Name Playlist).WorkingSet64 | Measure-Object -Sum).Sum/1MB),2)
                    } else {''}
                    CTmem = if ((Get-Process -Name ADC1000NTCFG -ea SilentlyContinue).Count) {
                        "{0:n2}" -f [math]::Round((((Get-Process -Name ADC1000NTCFG -ea SilentlyContinue).WorkingSet64 | Measure-Object -Sum).Sum/1MB),2)
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
        #Start-Process 'C:\Users\Public\Desktop\ADC Device Server2.lnk'
    }  | Out-Null
    Start-Sleep -Seconds 1
}
function StopCT ($CT) {
    $Creds = [System.Management.Automation.PSCredential]::new('local\Administrator',(ConvertTo-SecureString -AsPlainText 'Tecom_1!' -Force))
    if (($CT -ne $Null) -and ($CT -ne '')) {
        if (!(Test-Connection -ComputerName $CTC[$CT-1] -Count 1 -Quiet)) {return}
        $Comp = $CTC[$CT-1] ; "Stopping CT on CTC{0:d2}" -f $CT
    }
    else {$Comp=@() ; $table.Where({$_.Ping -ne [DBNull]::Value}).foreach({$Comp+=$_.Name}) ; "Stopping CT on all CTC"}
    Invoke-Command -ComputerName $Comp -Credential $Creds {Stop-Process  -name ADC1000NTCFG} -ea SilentlyContinue
    Start-Sleep -Seconds 1
}
function StartCT ($CT) {
    $Creds = [System.Management.Automation.PSCredential]::new('local\Administrator',(ConvertTo-SecureString -AsPlainText 'Tecom_1!' -Force))
    $PSSessionOption.IdleTimeout = New-TimeSpan -days 24 -Seconds 0
    if (($CT -ne $Null) -and ($CT -ne '')) {
        if (!(Test-Connection -ComputerName $CTC[$CT-1] -Count 1 -Quiet)) {return}
        $Comp = $CTC[$CT-1] ; "Starting CT on CTC{0:d2}" -f $CT
    }
    #else {$Comp=@() ; $table.Where({($_.Ping -ne [DBNull]::Value) -and ([int]$_.No -le 14)}).foreach({$Comp+=$_.Name}) ; "Starting CT on all (14) CTC"}
    else {$Comp=@() ; $table.Where({($_.Ping -ne [DBNull]::Value)}).foreach({$Comp+=$_.Name}) ; "Starting CT on all CTC"}
    Invoke-Command -ComputerName $Comp -InDisconnectedSession -Credential $Creds {
        Start-Process 'C:\Users\Public\Desktop\ADC Config Tool.lnk'
    }  | Out-Null
    Start-Sleep -Seconds 1
}
function StopPL {
    $Creds = [System.Management.Automation.PSCredential]::new('local\Administrator',(ConvertTo-SecureString -AsPlainText 'Tecom_1!' -Force))
    $Comp=@() ; $table.Where({$_.Ping -ne [DBNull]::Value}).foreach({$Comp+=$_.Name}) ; "Stopping PL on all CTC"
    Invoke-Command -ComputerName $Comp -Credential $Creds {Stop-Process -name Playlist -Force} -ea SilentlyContinue
    Start-Sleep -Seconds 1
}
function StartPL {
    $Creds = [System.Management.Automation.PSCredential]::new('local\Administrator',(ConvertTo-SecureString -AsPlainText 'Tecom_1!' -Force))
    $PSSessionOption.IdleTimeout = New-TimeSpan -days 24 -Seconds 0
    $Comp=@() ; $table.Where({$_.Ping -ne [DBNull]::Value}).foreach({$Comp+=$_.Name}) ; "Starting PL on all CTC"
    Invoke-Command -ComputerName $Comp -InDisconnectedSession -Credential $Creds {
        if (Test-Path 'C:\Users\Public\Desktop\Playlist.lnk') {Start-Process 'C:\Users\Public\Desktop\Playlist.lnk'}
    }  | Out-Null
    Start-Sleep -Seconds 1
}
function StopSE {
    $Creds = [System.Management.Automation.PSCredential]::new('local\Administrator',(ConvertTo-SecureString -AsPlainText 'Tecom_1!' -Force))
    $Comp=@() ; $table.Where({$_.Ping -ne [DBNull]::Value}).foreach({$Comp+=$_.Name}) ; "Stopping SE on all CTC"
    Invoke-Command -ComputerName $Comp -Credential $Creds {
        Get-Service -Name 'ADC*' | Set-Service -StartupType Disabled
        Start-Sleep 1
        Get-Process -Name 'Harris.Automation.ADC.Services*' | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep 1
        Get-Service -Name 'ADC*' | Set-Service -StartupType Manual
    } -ea SilentlyContinue
    Start-Sleep -Seconds 1
}
function StartSE {
    $Creds = [System.Management.Automation.PSCredential]::new('local\Administrator',(ConvertTo-SecureString -AsPlainText 'Tecom_1!' -Force))
    $PSSessionOption.IdleTimeout = New-TimeSpan -days 24 -Seconds 0
    $NumberOfPL = 8
    $Comp=@() ; $table.Where({$_.Ping -ne [DBNull]::Value}).foreach({$Comp+=$_.Name}) ; "Starting SE on all CTC"
    Invoke-Command -ComputerName $Comp -Credential $Creds {
        #Get-Service -Name 'ADCSecurityService', 'ADCDataService', 'ADCMaterialService', 'ADCAggregationService' | Start-Service
        [System.Collections.Generic.List[PSObject]]$services = Get-Service -Name 'ADC*' | where {$_.DisplayName -notmatch 'Aggregation'}
        [System.Collections.Generic.List[PSObject]]$servicesInOrder = @()
        $services | where {$_.DisplayName -match 'Data'} | % {$servicesInOrder.Add($_)}
        $services | where {$_.DisplayName -match 'Timecode'} | % {$servicesInOrder.Add($_)}
        $services | where {$_.DisplayName -match 'AsRun'} | % {$servicesInOrder.Add($_)}
        $services | where {$_.DisplayName -match 'Device'} | % {$servicesInOrder.Add($_)}
        $services | where {$_.DisplayName -match 'List'} | % {$servicesInOrder.Add($_)}
        $services | where {$_.DisplayName -match 'Error'} | % {$servicesInOrder.Add($_)}
        $services | 
         where {$_.DisplayName -notmatch 'Data'} |
         where {$_.DisplayName -notmatch 'Timecode'} |
         where {$_.DisplayName -notmatch 'AsRun'} | 
         where {$_.DisplayName -notmatch 'Device'} | 
         where {$_.DisplayName -notmatch 'List'} | 
         where {$_.DisplayName -notmatch 'Error'} | 
         where {$_.DisplayName -notmatch 'Synchro'} | 
         where {$_.DisplayName -notmatch 'Integra'} | 
         where {$_.DisplayName -notmatch 'Manager'} | 
        % {$servicesInOrder.Add($_)}
        $services | where {$_.DisplayName -match 'Integra'} | % {$servicesInOrder.Add($_)}
        $services | where {$_.DisplayName -match 'Synchro'} | % {$servicesInOrder.Add($_)}
        $services | where {$_.DisplayName -match 'Manager'} | % {$servicesInOrder.Add($_)}

        $servicesInOrder | % {
            #Write-Host "$(GD)Starting $($_.name -replace '(ADC)(.*)(Service)','$1 $2 $3')" -b Black -f Yellow
            Start-Service $_.name -WarningAction SilentlyContinue
        }
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
    #cls
    $table | ft -AutoSize -Property ($table.Columns.ColumnName | select -SkipLast 2)

    if ($infoCounter) {
        Title
        $Global:infoCounter--
    }
}
function Title {
    Write-Host "`$PID = $PID" -f 7
    Write-Host "Passes: $passes" -f 7
    Write-Host "-----------------------------------" -f 7
    Write-Host "Press <Enter> to start/stop all PL." -f 7
    Write-Host "Press <Space> to start/stop all DS." -f 7
    Write-Host "Press <Tab> to start/stop all SE." -f 7
    Write-Host "Press <S> to start/stop single DS." -f 7
    Write-Host "Press <T> to start/stop all CT." -f 7
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
$table.Columns.Add("DSver","string") | Out-Null
$table.Columns.Add("DSmem","string") | Out-Null
$table.Columns.Add("SEver","string") | Out-Null
$table.Columns.Add("SEmem","string") | Out-Null
$table.Columns.Add("PLmem","string") | Out-Null
$table.Columns.Add("CTmem","string") | Out-Null

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
    $time1 = Get-Date
    if ($runspacesPing.Status.IsCompleted -notcontains $false) {
        #WatchRunspaces
        foreach ($runspace in $runspacesPing) {
            $runspace.Pipe.EndInvoke($runspace.Status)
            $runspace.Pipe.Dispose()
        }
        try {
            foreach ($result in $HS.results) {
                $table.Where({$result.Server -match $_.Name}).foreach({$_.ping=$result.Ping;$_.DSver=$result.DSver;$_.DSmem=$result.DSmem;$_.SEver=$result.SEver;$_.SEmem=$result.SEmem;$_.PLmem=$result.PLmem;$_.CTmem=$result.CTmem})
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
    #Write-Output $time_diff.TotalMilliseconds
    $time_diff = (Get-Date) - $time1
    #if ($time_diff.TotalMilliseconds -lt 1000) {Start-Sleep -Milliseconds (1000 - $time_diff.TotalMilliseconds)}
    Start-Sleep -Milliseconds 500
    
    #looking for <Esc> or <R> or <Space> press
    if ($host.ui.RawUi.KeyAvailable) {
        $key=$host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown,IncludeKeyUp")
        $Host.UI.RawUI.FlushInputBuffer()
        if ($key.keydown) {
            switch ($key.VirtualKeyCode) {
                <#Enter#> 13 {
                    if ($table.PLmem -gt 0) {StopPL}
                        else {StartPL}
                }
                <#S#>     83 {
                    $Chosen = [int](Read-Host "Which DS to start/stop? Default = All")
                        if (($Chosen) -and ($table.DSmem[$Chosen-1] -ne [DBNull]::Value)) {StopDS -DS $Chosen}
                        elseif (($Chosen) -and ($table.DSmem[$Chosen-1] -eq [DBNull]::Value)) {StartDS -DS $Chosen}
                        elseif ((!$Chosen) -and [bool]($table.DSmem -gt 0)) {StopDS}
                        elseif ((!$Chosen) -and ![bool]($table.DSmem -gt 0)) {StartDS}
                }
                <#T#>     84 {
                    if ($table.CTmem -gt 0) {StopCT}
                        else {StartCT}
                }
                <#Esc#>   27 {exit}
                <#Space#> 32 {
                    if ($table.DSmem -gt 0) {StopDS}
                        else {StartDS}
                }
                <#Tab#>   9 {
                    if ($table.SEmem -gt 0) {StopSE}
                        else {StartSE}
                }
                <#F1#>    112 {$infoCounter = 10}
                <#F4#>    #115 {cls ; Get-Job ; Write-Host "WTF"}
            } #end switch
        }
    } #end if
} until ($key.VirtualKeyCode -eq 27)