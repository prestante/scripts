Add-Type -assemblyName System.Windows.Forms
do {
    
"$([System.Windows.Forms.Control]::MousePosition.x),$([System.Windows.Forms.Control]::MousePosition.y)"


    #looking for <Esc> or <r> or <Space> press
    if ($host.ui.RawUi.KeyAvailable) {
        $key=$host.ui.RawUI.ReadKey("NoEcho,IncludeKeyUp")
        $Host.UI.RawUI.FlushInputBuffer()
        switch ($key.VirtualKeyCode) {
            <#R#> 82 {}
            <#S#> 83 {}
            <#Enter#> 13 {}
            <#Esc#> 27 {exit}
            <#F1#> 112 {Title}
            <#F2#> 113 {Receive-Job (Get-Job) -Keep}
            <#Space#> 32 { $j = Start-job $function:NewGraph -ArgumentList $logfile }
            <#O#> 79 { $j = Start-job $function:NewGraph -ArgumentList (Get-FileName 'C:\PS\logs') }
        } #end switch
    } #end if
    #$Host.UI.RawUI.FlushInputBuffer()
    if (($j.state -eq 'Running') -and ((Receive-Job $j.Name -keep) -ne "Done")) {
        "Please wait. Graph is under construction..." 
    }
    Start-Sleep -milliseconds 100
} until ($key.VirtualKeyCode -eq 27)