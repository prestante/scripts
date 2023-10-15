Clear-Host
$AS = 'ADCAggregationService'
$IS = 'ADCIntegrationService'
$j=0
function ASmem {
    $ASProcess = Get-Process Harris.Automation.ADC.Services.AggregationServiceHost -ErrorAction SilentlyContinue
    [math]::Round(($ASProcess.WorkingSet64) / 1075738)}
function ISmem {
    $ISProcess = Get-Process Harris.Automation.ADC.Services.IntegrationServiceHost -ErrorAction SilentlyContinue
    [math]::Round(($ISProcess.WorkingSet64) / 1075738)}
function GD {Get-Date -Format 'yyyy-MM-dd HH:mm:ss - '}
function StopASIS ($Who) {
    if (($Who -eq "IS") -or ($Who -ne "AS")) {
        "$(GD)Disabling IS Service"
        Set-Service -Name $IS -StartupType Disabled
        "$(GD)Stopping IS process"
        Stop-Process -Name Harris.Automation.ADC.Services.IntegrationServiceHost -Force -ErrorAction SilentlyContinue
        Start-Sleep 1
        "$(GD)Enabling IS Service"
        Set-Service -Name $IS -StartupType Manual
    }
    if (($Who -eq "AS") -or ($Who -ne "IS")) {
        "$(GD)Disabling AS Service"
        Set-Service -Name $AS -StartupType Disabled
        "$(GD)Stopping AS process"
        Stop-Process -Name Harris.Automation.ADC.Services.AggregationServiceHost -Force -ErrorAction SilentlyContinue
        Start-Sleep 1
        "$(GD)Enabling AS Service"
        Set-Service -Name $AS -StartupType Manual
    }
}
function StartASIS ($Who){
    if (($Who -eq "AS") -or ($Who -ne "IS")) {
        "$(GD)Starting AS"
        Start-Service -Name $AS -ErrorAction SilentlyContinue
        "$(GD)$AS is $((Get-Service -Name $AS).Status)"
        Start-Sleep 3
    }
    if (($Who -eq "IS") -or ($Who -ne "AS")) {
        "$(GD)Starting IS"
        Start-Service -Name $IS -ErrorAction SilentlyContinue
        "$(GD)$IS is $((Get-Service -Name $IS).Status)"
    }
}
function Title {"------------------------"
"Press <Space> to start/stop AS and IS."
"Press <A> to start/stop AS."
"Press <I> to start/stop IS."
"Press <R> to restart AS and IS."
"Press <Esc> to exit."
"------------------------"
}

do {Title
    for ($i=1 ; (ASmem) -lt 5000 ; $i++) {
        #logging AS and IS memory consumption values to C:\PS1 logs\AS.Memory.log
        "$(GD)AS $(ASmem) MB, IS $(ISmem) MB."
        #looking for <Esc> or <r> or <Space> press
        if ($host.ui.RawUi.KeyAvailable) {
            $key=$host.ui.RawUI.ReadKey("NoEcho,IncludeKeyUp")
            $Host.UI.RawUI.FlushInputBuffer()
            switch ($key.VirtualKeyCode) {
                82 {StopASIS ; StartASIS} #<R>
                27 {exit} #<Esc>
                112 {Title} #<F1>
                73 { #<I>
                    if ((Get-Service -Name $IS).Status -eq 'Running') {StopASIS IS}
                    elseif (((Get-Service -Name $IS).Status -eq 'Stopped') -and ((Get-Service -Name $AS).Status -eq 'Running')) {StartASIS IS}
                    elseif (((Get-Service -Name $IS).Status -eq 'Stopped') -and ((Get-Service -Name $AS).Status -eq 'Stopped')) {
                        switch ($j) {
                            0 {"$(GD)It's not recommended to start IS when AS isn't running. Press <I> again if you sure." ; $j=1}
                            1 {"$(GD)If you insist..." ; StartASIS IS ; $j=0}
                        }
                    }
                }
                65 { #<A>
                    if ((Get-Service -Name $AS).Status -eq 'Running') {StopASIS AS}
                    elseif (((Get-Service -Name $AS).Status -eq 'Stopped') -and ((Get-Service -Name $IS).Status -eq 'Running')) {StopASIS ; StartASIS}
                    elseif (((Get-Service -Name $AS).Status -eq 'Stopped') -and ((Get-Service -Name $IS).Status -eq 'Stopped')) {StartASIS AS}
                }
                32 { #<Space>
                    if (((Get-Service -Name $AS).Status -eq 'Running') -or ((Get-Service -Name $IS).Status -eq 'Running')) {StopASIS}
                    elseif (((Get-Service -Name $AS).Status -eq 'Stopped') -and ((Get-Service -Name $IS).Status -eq 'Stopped')) {StartASIS}
                }
            }
        }
        if ((ASmem) -gt 3000) {"$(GD)Warning! AS memory consumption is too high!"}
        if ((ASmem) -gt 4000) {"AS consumes more than 4GB. Restarting AS and IS..." ; StopASIS ; StartASIS}
        Start-Sleep -milliseconds 1000
    }
    $Host.UI.RawUI.FlushInputBuffer()
} until ($key.VirtualKeyCode -eq 27)