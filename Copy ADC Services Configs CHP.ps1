$CTC = '192.168.13.7','192.168.13.8','192.168.13.146','192.168.13.147'

Write-Host "Back up ADC Services configs to C:\PS\xml" -fo Yellow -ba Black

$Login = 'local\Administrator'
$Password = 'ADC1000hrs'
$Pass = ConvertTo-SecureString -AsPlainText $Password -Force
$Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Login, $Pass

Invoke-Command -ComputerName $CTC -Authentication Credssp -Credential $Creds -ScriptBlock {

    Invoke-Command -ScriptBlock {
        
        if (!(Test-Path C:\PS\xml)) {New-Item -Path 'C:\PS\xml' -ItemType Directory -force -ea SilentlyContinue | Out-Null}
        #Copy-Item 'C:\Program Files (x86)\Imagine Communications\ADC Services\config\IntegrationService.xml' -Destination 'C:\PS\xml' -Force
        #Copy-Item 'C:\Program Files (x86)\Imagine Communications\ADC Services\Harris.Automation.ADC.Services.IntegrationServiceHost.exe.config' -Destination 'C:\PS\xml' -Force
        #Copy-Item 'C:\Program Files (x86)\Imagine Communications\ADC Services\rules\PlaylistTranslator.Rule.xml' -Destination 'C:\PS\xml' -Force
        #Copy-Item 'C:\Program Files (x86)\Imagine Communications\ADC Services\license\ADCLicense.lic' -Destination 'C:\PS\xml' -Force

        Copy-Item 'C:\Program Files (x86)\Imagine Communications\ADC Services\config\AsRunService.xml' -Destination 'C:\PS\xml' -Force
        Copy-Item 'C:\Program Files (x86)\Imagine Communications\ADC Services\config\DeviceService.xml' -Destination 'C:\PS\xml' -Force
        Copy-Item 'C:\Program Files (x86)\Imagine Communications\ADC Services\config\ErrorReportingService.xml' -Destination 'C:\PS\xml' -Force
        Copy-Item 'C:\Program Files (x86)\Imagine Communications\ADC Services\config\ListService.xml' -Destination 'C:\PS\xml' -Force
        Copy-Item 'C:\Program Files (x86)\Imagine Communications\ADC Services\config\TimecodeService.xml' -Destination 'C:\PS\xml' -Force

        Write-Host "$($env:COMPUTERNAME) - Done." -fo Green -ba Black
    }
}