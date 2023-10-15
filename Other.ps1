$CTC = '192.168.13.170','192.168.13.171','192.168.13.172','192.168.13.173','192.168.13.174','192.168.13.175','192.168.13.176','192.168.13.177','192.168.13.178','192.168.13.179','192.168.13.180','192.168.13.181','192.168.13.182','192.168.13.138','192.168.13.139','192.168.13.140','192.168.13.141','192.168.13.142','192.168.13.143','192.168.13.145'

#restart all CTC PCs
Invoke-Command -ComputerName $CTC -ScriptBlock {
  shutdown -r -t 3 -f}

#launch DS installer
Start-Process '\\192.168.12.3\Shares\Engineering\ADC\QA\Builds\ADC_v12\12.27\12.27.31.0M\Standard\SERVER_QATEST_12.27.31.1M.exe'

#copy old INIs to new DS folder (run this locally)
Copy-Item "C:\server\12.27.21.1M\ADC1000NT.INI" -Destination "C:\server\12.27.31.1M"
Copy-Item "C:\server\12.27.21.1M\LISTCONF.INI" -Destination "C:\server\12.27.31.1M"
Copy-Item "C:\server\12.27.21.1M\NETWORK.INI" -Destination "C:\server\12.27.31.1M"
Start-Process "C:\Users\Public\Desktop\DS 12.27.31.1M.lnk"

#launch DS remotely at all CTC (DS will start silently without interface). Script will be active until you stop it. Once you do that, all DS will be closed.
Invoke-Command -ComputerName $CTC {
 Start-Process 'C:\Users\Public\Desktop\DS 12.27.31.1M.lnk' -Wait
}

#stop DS remotely at all CTC
Invoke-Command -ComputerName $CTC {
 Stop-Process  -name ADC1000NT
}

#check if ADC Services running at every CTC PC
Invoke-Command -ComputerName $CTC -ScriptBlock {
  Get-Service -Name 'ADC*'}
