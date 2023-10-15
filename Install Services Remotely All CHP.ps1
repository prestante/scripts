$CTC = '192.168.13.7','192.168.13.8','192.168.13.146','192.168.13.147'
$CTC = '192.168.13.7','192.168.13.8'

$Login = 'local\Administrator'
$Password = 'ADC1000hrs'
$Pass = ConvertTo-SecureString -AsPlainText $Password -Force
$Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Login, $Pass

Invoke-Command -ComputerName $CTC -Authentication Credssp -Credential $Creds -ScriptBlock {

    Invoke-Command -ScriptBlock {
        $rLogin = 'TECOM\adcqauser'
        $rPassword = 'Tecom123'
        $rPass = ConvertTo-SecureString -AsPlainText $rPassword -Force
        $rCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $rLogin, $rPass

        New-PSDrive -Name S -PSProvider FileSystem -Root \\192.168.12.3\Shares\Engineering\ADC\QA\Builds -Credential $rCreds #creating temporary network drive S: with our Builds shares

        $Version = '5.8.33.7M'
        $DBName = 'ADCFS-1'
        $DBUser = 'sa'
        $DBPassword = 'Tecom1'
        $File = 'S:\ADC_Services\'+$Version+'\ADCServicesSetup_'+$Version+'.exe'

        $Parameters = '/s, /v"/qn" /v"IS_SQLSERVER_SERVER=' + $DBName + '" /v"IS_SQLSERVER_AUTHENTICATION=2" /v"IS_SQLSERVER_USERNAME=' + $DBUser + '" /v"IS_SQLSERVER_PASSWORD=' + $DBPassword + '" /v"INSTALLLEVEL=101" /v"/l*v C:\ADCServicesInstaller.log" /v"REBOOT=ReallySuppress"'
 
        Start-Process $File -ArgumentList $Parameters -Wait
        
        Get-Service -Name 'ADC*' | Set-Service -StartupType Disabled
        Start-Sleep 1
        Get-Process -Name 'Harris.Automation.ADC.Services*' | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep 1
        Get-Service -Name 'ADC*' | Set-Service -StartupType Manual


#        Copy-Item 'C:\PS\xml\IntegrationService.xml' -Destination 'C:\Program Files (x86)\Imagine Communications\ADC Services\config' -Force
#        Copy-Item 'C:\PS\xml\Harris.Automation.ADC.Services.IntegrationServiceHost.exe.config' -Destination 'C:\Program Files (x86)\Imagine Communications\ADC Services' -Force
        Copy-Item 'C:\PS\xml\AsRunService.xml' -Destination 'C:\Program Files (x86)\Imagine Communications\ADC Services\config' -Force
        Copy-Item 'C:\PS\xml\DeviceService.xml' -Destination 'C:\Program Files (x86)\Imagine Communications\ADC Services\config' -Force
        Copy-Item 'C:\PS\xml\ErrorReportingService.xml' -Destination 'C:\Program Files (x86)\Imagine Communications\ADC Services\config' -Force
        Copy-Item 'C:\PS\xml\ListService.xml' -Destination 'C:\Program Files (x86)\Imagine Communications\ADC Services\config' -Force
        Copy-Item 'C:\PS\xml\TimecodeService.xml' -Destination 'C:\Program Files (x86)\Imagine Communications\ADC Services\config' -Force

#        New-Item -Path 'C:\Program Files (x86)\Imagine Communications\ADC Services\rules' -ItemType Directory -force -ea SilentlyContinue
#        New-Item -Path 'C:\Program Files (x86)\Imagine Communications\ADC Services\license' -ItemType Directory -force -ea SilentlyContinue

#        Copy-Item 'C:\PS\xml\PlaylistTranslator.Rule.xml' -Destination 'C:\Program Files (x86)\Imagine Communications\ADC Services\rules' -Force
#        Copy-Item 'C:\PS\xml\ADCLicense.lic' -Destination 'C:\Program Files (x86)\Imagine Communications\ADC Services\license' -Force
#        Copy-Item 'C:\PS\xml\Harris.Automation.ADC.Services.IntegrationService.PlaylistProcessor.dll' -Destination 'C:\Program Files (x86)\Imagine Communications\ADC Services' -Force

#        Get-Service -Name 'ADCSecurityService', 'ADCManagerService' | Start-Service
        
        Write-Host "$($env:COMPUTERNAME) - Done." -fo Green -ba Black
    }
}