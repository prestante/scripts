$folder = 'C:\Program Files (x86)\Imagine Communications\ADC Services\log\'
$file = 'C:\Program Files (x86)\Imagine Communications\ADC Services\cache\IntegrationServiceDataStorage.sdf'

do {
    cls
    #gci -force $folder | % {(Get-ItemProperty ($folder + $_))} | ft Name, @{ Label = "Size"; Expression={"{0:N0} KB" -f ($_.length/1KB)} ; align='right'} -HideTableHeaders
    Get-ItemProperty ($file) | ft Name, @{ Label = "Size"; Expression={"{0:N0} KB" -f ($_.length/1KB)} ; align='right'} -HideTableHeaders
    #looking for <Esc> or <Enter> press
    if ($host.ui.RawUi.KeyAvailable) {
        $key=$host.ui.RawUI.ReadKey("NoEcho,IncludeKeyUp")
        $Host.UI.RawUI.FlushInputBuffer()
        if ($key.VirtualKeyCode -eq 13) {exit}                  #<Enter>
        if ($key.VirtualKeyCode -eq 27) {exit}                  #<Esc>
    }  
    Start-Sleep -Milliseconds 200
} until ($key.VirtualKeyCode -eq 27)