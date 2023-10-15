do {
    #Get-NetTCPConnection -OwningProcess (Get-Process -Name ADC1000NT).Id | where {$_.LocalAddress -match '^fe80'} | sort -Property LocalPort
    
    cls

    Get-NetTCPConnection -OwningProcess (Get-Process -Name ADC1000NTCFG).Id | where {$_.LocalPort -notmatch '^65\d\d\d'} | sort -Property State, LocalPort | ft #, LocalPort

    sleep 1

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