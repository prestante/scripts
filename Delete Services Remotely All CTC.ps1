﻿$CTC = '192.168.13.170','192.168.13.171','192.168.13.172','192.168.13.173','192.168.13.174','192.168.13.175','192.168.13.176','192.168.13.177','192.168.13.178','192.168.13.179','192.168.13.180','192.168.13.181','192.168.13.182','192.168.13.138','192.168.13.139','192.168.13.140','192.168.13.141','192.168.13.142','192.168.13.143','192.168.13.145','192.168.13.161','192.168.13.168','192.168.13.232','192.168.13.191'
$CTC = @('192.168.13.180')

$Login = 'local\Administrator'
$Password = 'Tecom_1!'
$Pass = ConvertTo-SecureString -AsPlainText $Password -Force
$SecureString = $Pass
$Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Login, $SecureString

Invoke-Command -ComputerName $CTC -Credential $Creds -ScriptBlock {

    Invoke-Command -ScriptBlock {
        
        #stop all ADC Services
        Get-Service -Name 'ADC*' | Set-Service -StartupType Disabled
        Start-Sleep 1
        Get-Process -Name 'Harris.Automation.ADC.Services*' | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep 1
        Get-Service -Name 'ADC*' | Set-Service -StartupType Manual

        #backup 5 main and integration Services configs
        #."C:\PS\scripts\Copy ADC Services Configs CTC.ps1"        
        
        $rLogin = 'TECOM\adcqauser'
        $rPassword = 'Tecom_123!'
        $rPass = ConvertTo-SecureString -AsPlainText $rPassword -Force
        $rCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $rLogin, $rPass

        New-PSDrive -Name T -PSProvider FileSystem -Root \\192.168.12.3\Shares\Engineering\ADC\QA\Builds -Credential $rCreds #creating temporary network drive S: with our Builds shares

        $Version = '5.9.6.1'
        $DBName = 'ADCFS-1'
        $DBUser = 'sa'
        $DBPassword = 'Tecom1'
        $File = 'T:\ADC_Services\'+$Version+'\ADCServicesSetup_'+$Version+'.exe'

        $Parameters = '/x /s, /v"/qn" /v"DELETEDB=Yes" /v"REBOOT=ReallySuppress"'

        Start-Process $File -ArgumentList $Parameters -Wait
 
    }
}