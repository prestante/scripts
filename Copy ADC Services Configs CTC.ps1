$CTC = '192.168.13.170','192.168.13.171','192.168.13.172','192.168.13.173','192.168.13.174','192.168.13.175','192.168.13.176','192.168.13.177','192.168.13.178','192.168.13.179','192.168.13.180','192.168.13.181','192.168.13.182','192.168.13.138','192.168.13.139','192.168.13.140','192.168.13.141','192.168.13.142','192.168.13.143','192.168.13.145','192.168.13.161','192.168.13.168','192.168.13.232','192.168.13.191'

Write-Host "Back up ADC Services configs to C:\PS\xml" -fo Yellow -ba Black

Invoke-Command -ComputerName $CTC -ScriptBlock {

    Invoke-Command -ScriptBlock {
        
        if (!(Test-Path C:\PS\xml)) {New-Item -Path 'C:\PS\xml' -ItemType Directory -force -ea SilentlyContinue | Out-Null}
        Copy-Item 'C:\Program Files (x86)\Imagine Communications\ADC Services\config\IntegrationService.xml' -Destination 'C:\PS\xml' -Force
        Copy-Item 'C:\Program Files (x86)\Imagine Communications\ADC Services\Harris.Automation.ADC.Services.IntegrationServiceHost.exe.config' -Destination 'C:\PS\xml' -Force
        Copy-Item 'C:\Program Files (x86)\Imagine Communications\ADC Services\rules\PlaylistTranslator.Rule.xml' -Destination 'C:\PS\xml' -Force
        Copy-Item 'C:\Program Files (x86)\Imagine Communications\ADC Services\license\ADCLicense.lic' -Destination 'C:\PS\xml' -Force

        Copy-Item 'C:\Program Files (x86)\Imagine Communications\ADC Services\config\AsRunService.xml' -Destination 'C:\PS\xml' -Force
        Copy-Item 'C:\Program Files (x86)\Imagine Communications\ADC Services\config\DeviceService.xml' -Destination 'C:\PS\xml' -Force
        Copy-Item 'C:\Program Files (x86)\Imagine Communications\ADC Services\config\ErrorReportingService.xml' -Destination 'C:\PS\xml' -Force
        Copy-Item 'C:\Program Files (x86)\Imagine Communications\ADC Services\config\ListService.xml' -Destination 'C:\PS\xml' -Force
        Copy-Item 'C:\Program Files (x86)\Imagine Communications\ADC Services\config\TimecodeService.xml' -Destination 'C:\PS\xml' -Force

    }
}