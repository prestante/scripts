$CTC = '192.168.13.170','192.168.13.171','192.168.13.172','192.168.13.173','192.168.13.174','192.168.13.175','192.168.13.176','192.168.13.177','192.168.13.178','192.168.13.179','192.168.13.180','192.168.13.181','192.168.13.182','192.168.13.138','192.168.13.139','192.168.13.140','192.168.13.141','192.168.13.142','192.168.13.143','192.168.13.145','192.168.13.161','192.168.13.168','192.168.13.232','192.168.13.191'

#check if Chronos Service is running all CTC PC
#Invoke-Command -ComputerName $CTC -ScriptBlock {
#  Get-Service -Name 'Chronos*'}

#start Chronos Service all CTC PC
#Invoke-Command -ComputerName $CTC -ScriptBlock {
#  Start-Service -Name 'Chronos*'}


#check if ADC Services running at every CTC PC one by one. It also shows ADC Services version.
for ($i=0 ; $i -lt $CTC.Length ; $i++) {
    Invoke-Command -ComputerName $CTC[$i] -ScriptBlock {
        $env:COMPUTERNAME
        Get-WmiObject Win32_Product -Filter "Name like 'ADC Services'" | Select-Object -ExpandProperty Version -ErrorAction SilentlyContinue
        Get-Service -Name 'ADC*'}
        "---------------------------------------------------------------------------------"}

#fast version
#Invoke-Command -ComputerName $CTC -ScriptBlock {Get-Service -Name 'ADC*'}
