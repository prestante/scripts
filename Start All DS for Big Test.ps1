$CTC = '192.168.13.170','192.168.13.171','192.168.13.172','192.168.13.173','192.168.13.174','192.168.13.175','192.168.13.176','192.168.13.177','192.168.13.178','192.168.13.179','192.168.13.180','192.168.13.181','192.168.13.182','192.168.13.138','192.168.13.139','192.168.13.140','192.168.13.141','192.168.13.142','192.168.13.143','192.168.13.145','192.168.13.161','192.168.13.168','192.168.13.232','192.168.13.191'
$Comp = 'adcchp-7', 'adcchp-8', 'adcchp-9', 'adcchp-10'
$PSSessionOption.IdleTimeout = New-TimeSpan -days 24 -Seconds 0
$Login = 'local\Administrator'
$Password = 'ADC1000hrs'
$Pass = ConvertTo-SecureString -AsPlainText $Password -Force
$Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Login, $Pass

Invoke-Command -ComputerName $Comp -Credential $Creds -InDisconnectedSession {
    Start-Process 'C:\Users\Public\Desktop\ADC Device Server.lnk'
} | Out-Null

Invoke-Command -ComputerName $CTC -InDisconnectedSession {
    Start-Process 'C:\Users\Public\Desktop\ADC Device Server.lnk'
} | Out-Null