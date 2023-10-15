#$CTC = '192.168.13.170','192.168.13.171','192.168.13.172','192.168.13.173','192.168.13.174','192.168.13.175','192.168.13.176','192.168.13.177','192.168.13.178','192.168.13.179','192.168.13.180','192.168.13.181','192.168.13.182','192.168.13.138','192.168.13.139','192.168.13.140','192.168.13.141','192.168.13.142','192.168.13.143','192.168.13.145','192.168.13.161','192.168.13.168','192.168.13.232','192.168.13.191'
#$CTC = @('adc-ctc01.tecomgroup.ru','adc-ctc02.tecomgroup.ru','adc-ctc03.tecomgroup.ru','adc-ctc04.tecomgroup.ru','adc-ctc05.tecomgroup.ru','adc-ctc06.tecomgroup.ru','adc-ctc07.tecomgroup.ru','adc-ctc08.tecomgroup.ru','adc-ctc09.tecomgroup.ru','adc-ctc10.tecomgroup.ru','adc-ctc11.tecomgroup.ru','adc-ctc12.tecomgroup.ru','adc-ctc13.tecomgroup.ru','adc-ctc14.tecomgroup.ru','adc-ctc15.tecomgroup.ru','adc-ctc16.tecomgroup.ru','adc-ctc17.tecomgroup.ru','adc-ctc18.tecomgroup.ru','adc-ctc19.tecomgroup.ru','adc-ctc20.tecomgroup.ru','adc-ctc21.tecomgroup.ru','adc-ctc22.tecomgroup.ru','adc-ctc23.tecomgroup.ru','adc-ctc24.tecomgroup.ru')
$CTC = @('adc-ctc01.tecomgroup.ru','adc-ctc02.tecomgroup.ru')


#[array]$CTC = '192.168.13.170'
$Config = Get-Content 'C:\PS\xml\IntegrationServiceReference.xml'
$ConfigHost = Get-Content 'C:\PS\xml\Harris.Automation.ADC.Services.IntegrationServiceHost.exe.config'
$rule = Get-Content 'C:\PS\xml\PlaylistTranslator.Rule.xml'
$license = Get-Content 'C:\PS\ADCLicense.lic'

$Creds = [System.Management.Automation.PSCredential]::new('local\Administrator',(ConvertTo-SecureString -AsPlainText 'Tecom_1!' -Force))

Invoke-Command -ComputerName $CTC -ArgumentList $Config, $ConfigHost, $rule, $license -Credential $Creds {
    param ( $Config, $ConfigHost, $rule, $license )
    
    $Name = $env:COMPUTERNAME -replace 'ADC-'
    $Address = ipconfig | where {($_ -match '192.168.13.') -and ($_ -match 'IPv4')} | %{$_ -replace '^.*: '}
    $configFile = 'C:\Program Files (x86)\Imagine Communications\ADC Services\config\IntegrationService.xml'
    $configHostFile = 'C:\Program Files (x86)\Imagine Communications\ADC Services\Harris.Automation.ADC.Services.IntegrationServiceHost.exe.config'
    $ruleFile = 'C:\Program Files (x86)\Imagine Communications\ADC Services\rules\PlaylistTranslator.Rule.xml'
    $licenseFile = 'C:\Program Files (x86)\Imagine Communications\ADC Services\license\ADCLicense.lic'

    $Config -replace '#NAME',$Name -replace '#ADDRESS',$Address | Out-File $configFile -Encoding utf8
    <#
    $ConfigHost | Out-File $configHostFile -Encoding utf8
    
    New-Item -Path 'C:\Program Files (x86)\Imagine Communications\ADC Services\rules' -ItemType Directory -force -ea SilentlyContinue
    New-Item -Path 'C:\Program Files (x86)\Imagine Communications\ADC Services\license' -ItemType Directory -force -ea SilentlyContinue
    $rule | Out-File $ruleFile -Encoding utf8
    $license | Out-File $licenseFile -Encoding utf8

    Get-Service -Name 'ADC*' | Set-Service -StartupType Disabled
    Start-Sleep 1
    Get-Process -Name 'Harris.Automation.ADC.Services*' | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep 1
    Get-Service -Name 'ADC*' | Set-Service -StartupType Manual
    #>
    #Get-Service -Name 'ADCSecurityService', 'ADCManagerService' | Start-Service


#    $Name = $env:COMPUTERNAME -replace 'ADC-'
#    $Address = ipconfig | where {($_ -match '192.168.13.') -and ($_ -match 'IPv4')} | %{$_ -replace '^.*: '}
#    $configFile = 'C:\Program Files (x86)\Imagine Communications\ADC Services\config\IntegrationService.xml'
#    $Config -replace '192.168.13.97','192.168.13.96' -replace '#NAME',$Name -replace '#ADDRESS',$Address | Out-File $configFile -Encoding utf8

    Get-Service -Name 'ADC*' | Set-Service -StartupType Disabled
    Start-Sleep 1
    Get-Process -Name 'Harris.Automation.ADC.Services*' | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep 1
    Get-Service -Name 'ADC*' | Set-Service -StartupType Manual
    
}

