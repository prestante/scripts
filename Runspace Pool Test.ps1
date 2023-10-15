$i=0
do {

$time = Get-Date

$CTC = '192.168.13.170','192.168.13.171','192.168.13.172','192.168.13.173','192.168.13.174','192.168.13.175','192.168.13.176','192.168.13.177','192.168.13.178','192.168.13.179','192.168.13.180','192.168.13.181','192.168.13.182','192.168.13.138','192.168.13.139','192.168.13.140','192.168.13.141','192.168.13.142','192.168.13.143','192.168.13.145','192.168.13.161','192.168.13.168','192.168.13.232','192.168.13.191'

# BLOCK 1: Create and open runspace pool, setup runspaces array with min and max threads
$pool = [RunspaceFactory]::CreateRunspacePool(1, [int]$env:NUMBER_OF_PROCESSORS+1)
$pool.ApartmentState = "MTA"
$pool.Open()
$runspaces = $results = @()
    
# BLOCK 2: Create reusable scriptblock. This is the workhorse of the runspace. Think of it as a function.
$scriptblock = {
    Param (
    [string]$CTCip
    )
    
    Invoke-Command -ComputerName $CTCip -ScriptBlock {
        if (Test-Path 'C:\Users\Public\Desktop\ADC Device Server.lnk') {
            $sh = New-Object -ComObject WScript.Shell
            ((gci $sh.CreateShortcut('C:\Users\Public\Desktop\ADC Device Server.lnk').Targetpath).VersionInfo).ProductVersion
        } else {''}   
    }
}
 
# BLOCK 3: Create runspace and add to runspace pool
foreach ($CTCpc in $CTC) {
 
    $runspace = [PowerShell]::Create()
    $null = $runspace.AddScript($scriptblock)
    $null = $runspace.AddArgument($CTCpc)
    $runspace.RunspacePool = $pool
 
# BLOCK 4: Add runspace to runspaces collection and "start" it
    # Asynchronously runs the commands of the PowerShell object pipeline
    $runspaces += [PSCustomObject]@{ Pipe = $runspace; Status = $runspace.BeginInvoke() }
}
 
# BLOCK 5: Wait for runspaces to finish
while ($runspaces.Status.IsCompleted -notcontains $true) {}
 
# BLOCK 6: Clean up
foreach ($runspace in $runspaces ) {
    # EndInvoke method retrieves the results of the asynchronous call
    $results += $runspace.Pipe.EndInvoke($runspace.Status)
    $runspace.Pipe.Dispose()
}
    
$pool.Close() 
$pool.Dispose()
 
# Bonus block 7
# Look at $results to see any errors or whatever was returned from the runspaces

"{0:ss}:{0:fff}" -f ((Get-Date) - $time)
cls
$results
"Pass = {2} ; PID = {0} ; Mem = {1} MB" -f $PID, [math]::Round(((Get-Process -Id $PID).WorkingSet64/1MB),0), (++$i)

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