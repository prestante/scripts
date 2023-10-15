$servers = @("87.250.250.242","108.177.14.102","192.168.13.172");
#$input   = New-Object 'System.Management.Automation.PSDataCollection[psobject]'
#$output  = New-Object 'System.Management.Automation.PSDataCollection[psobject]'

$GH = [hashtable]::Synchronized(@{})

[System.Collections.Generic.List[PSObject]]$GH.results = @()
[System.Collections.Generic.List[PSObject]]$jobs = @()

$initialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()

$runspacePool = [RunspaceFactory]::CreateRunspacePool(1, ([int]$env:NUMBER_OF_PROCESSORS + 1), $initialSessionState, $host )
$runspacePool.ApartmentState = 'MTA'
$runspacePool.ThreadOptions  = "ReuseThread"
[void]$runspacePool.Open()

$jobCounter = 1

foreach ($server in $servers)
{
    Write-Host $server;

    $job = [System.Management.Automation.PowerShell]::Create($initialSessionState)
    $job.RunspacePool = $runspacePool

    $scriptBlock = { param ( [hashtable]$GH, [string]$server ); $result = (Test-Connection $server -Count 1).responseTime ; $GH.results.Add([PSObject]@{'Server' = $server; 'Result' = $result})}

    [void]$job.AddScript( $scriptBlock ).AddArgument( $GH ).AddArgument( $server )
    $jobs += New-Object PSObject -Property @{
                                    RunNum = $jobCounter++
                                    JobObj = $job
                                    Result = $job.BeginInvoke() }

    do {
        Sleep -Seconds 1 
    } while( $runspacePool.GetAvailableRunspaces() -lt 1 )

}

Do {
    Sleep -Seconds 1
} While( $jobs.Result.IsCompleted -contains $false)


$GH.results;


$runspaces = Get-Runspace | Where { $_.Id -gt 1 }

foreach( $runspace in $runspaces ) {
    try{
        [void]$runspace.Close()
        [void]$runspace.Dispose()
    }
    catch {
    }
}

[void]$runspacePool.Close()
[void]$runspacePool.Dispose()