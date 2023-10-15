#Get-Service -Name ADCSynchroService | Set-Service -StartupType Disabled
#Get-Process -Name Harris.Automation.ADC.Services.SynchroServiceHost | Stop-Process -Force
#Get-Service -Name ADCSynchroService | Set-Service -StartupType Automatic
function GD {Get-Date -Format 'yyyy-MM-dd HH:mm:ss - '}

do {
    $SS = Get-Service -Name ADCSynchroService -ea SilentlyContinue
    if ($SS.Status -ne 'Running') {Write-Host "$(GD)SS is $($SS.Status)" -fo Red -ba Black}
    else {Write-Host "$(GD)SS is $($SS.Status)"}
    Start-Sleep 1

    #looking for <Esc> or <R> or <Space> press
    if ($host.ui.RawUi.KeyAvailable) {
        $key=$host.ui.RawUI.ReadKey("NoEcho,IncludeKeyUp")
        $Host.UI.RawUI.FlushInputBuffer()
        switch ($key.VirtualKeyCode) {
            <#Esc#> 27 {exit}
        } #end switch
    } #end if
} until ($key.VirtualKeyCode -eq 27)