do {

    $conns = [System.Collections.ArrayList]@()
    Get-NetTCPConnection -LocalPort 1433 | where {$_.RemoteAddress -match '192\.168\..*$'} | % {$conns.add($_)} | Out-Null
    $remoteSorted = $conns.remoteAddress -replace '^\d{1,3}\.\d{1,3}\.\d{1,3}\.' | % {[int]$_} | sort
    $connsSorted = foreach ($RS in $remoteSorted) {$conns | where {$_.remoteAddress -match "$RS$"}}
    cls
    $connsSorted | ft

    if ($host.ui.RawUi.KeyAvailable) {
        $key=$host.ui.RawUI.ReadKey("NoEcho,IncludeKeyUp")
        $Host.UI.RawUI.FlushInputBuffer()
        switch ($key.VirtualKeyCode) {
            <#Space#> 32 {}
            <#Esc#> 27 {return}
        } #end switch
    }
    Start-Sleep 1
} until ($key.VirtualKeyCode -eq 27)