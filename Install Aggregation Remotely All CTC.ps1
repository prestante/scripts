$CTC = '192.168.13.170','192.168.13.171','192.168.13.172','192.168.13.173','192.168.13.174','192.168.13.175','192.168.13.176','192.168.13.177','192.168.13.178','192.168.13.179','192.168.13.180','192.168.13.181','192.168.13.182','192.168.13.138','192.168.13.139','192.168.13.140','192.168.13.141','192.168.13.142','192.168.13.143','192.168.13.145','192.168.13.161','192.168.13.168','192.168.13.232','192.168.13.191'
#$CTC = '192.168.13.182','192.168.13.138','192.168.13.139','192.168.13.140','192.168.13.141','192.168.13.142','192.168.13.143','192.168.13.145','192.168.13.161','192.168.13.168','192.168.13.232','192.168.13.191'
#$CTC = '192.168.13.181'
#$CTC = @('192.168.13.170','192.168.13.191')

$Login = 'local\Administrator'
$Password = 'Tecom_1!'
$Pass = ConvertTo-SecureString -AsPlainText $Password -Force
$Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Login, $Pass

$aggConfContent = Get-Content 'C:\PS\xml\AggregationService.xml'

Invoke-Command -ComputerName $CTC -Credential $Creds -ArgumentList $aggConfContent, -ScriptBlock {
    param ( $aggConfContent )

    $rLogin = 'TECOM\adcqauser'
    $rPassword = 'Tecom_123!'
    $rPass = ConvertTo-SecureString -AsPlainText $rPassword -Force
    $rCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $rLogin, $rPass

    #New-PSDrive -Name S -PSProvider FileSystem -Root \\192.168.12.3\Shares\Engineering\ADC\QA\Builds -Credential $rCreds #creating temporary network drive S: with our Builds shares

    $Version = '5.8.39.1M'
    $File = 'S:\ADC_Services\'+$Version+'\ADCAggregationSetup_'+$Version+'.exe'

    $Parameters = '/s /v/qn' #inst
    #$Parameters = '/x /v/qb' #uninst

    #Start-Process $File -ArgumentList $Parameters -Wait
        
    $aggConfigFile = 'C:\Program Files (x86)\Imagine Communications\ADC Aggregation Service\config\AggregationService.xml'
    $aggConfContent | Out-File $aggConfigFile -Encoding utf8 -Force
        
    Set-Service -Name ADCAggregationService -StartupType Manual

<#        Copy-Item 'C:\PS\xml\IntegrationService.xml' -Destination 'C:\Program Files (x86)\Imagine Communications\ADC Services\config' -Force
    Copy-Item 'C:\PS\xml\Harris.Automation.ADC.Services.IntegrationServiceHost.exe.config' -Destination 'C:\Program Files (x86)\Imagine Communications\ADC Services' -Force
    Copy-Item 'C:\PS\xml\AsRunService.xml' -Destination 'C:\Program Files (x86)\Imagine Communications\ADC Services\config' -Force
    Copy-Item 'C:\PS\xml\DeviceService.xml' -Destination 'C:\Program Files (x86)\Imagine Communications\ADC Services\config' -Force
    Copy-Item 'C:\PS\xml\ErrorReportingService.xml' -Destination 'C:\Program Files (x86)\Imagine Communications\ADC Services\config' -Force
    Copy-Item 'C:\PS\xml\ListService.xml' -Destination 'C:\Program Files (x86)\Imagine Communications\ADC Services\config' -Force
    Copy-Item 'C:\PS\xml\TimecodeService.xml' -Destination 'C:\Program Files (x86)\Imagine Communications\ADC Services\config' -Force
 
    New-Item -Path 'C:\Program Files (x86)\Imagine Communications\ADC Services\rules' -ItemType Directory -force -ea SilentlyContinue | out-null
    New-Item -Path 'C:\Program Files (x86)\Imagine Communications\ADC Services\license' -ItemType Directory -force -ea SilentlyContinue | out-null

    Copy-Item 'C:\PS\xml\PlaylistTranslator.Rule.xml' -Destination 'C:\Program Files (x86)\Imagine Communications\ADC Services\rules' -Force
    Copy-Item 'C:\PS\xml\ADCLicense.lic' -Destination 'C:\Program Files (x86)\Imagine Communications\ADC Services\license' -Force
    Copy-Item 'C:\PS\xml\Harris.Automation.ADC.Services.IntegrationService.PlaylistProcessor.dll' -Destination 'C:\Program Files (x86)\Imagine Communications\ADC Services' -Force
#>
}