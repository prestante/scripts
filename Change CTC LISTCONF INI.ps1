#This script replaces all specific values in the LISTCONF.INI on each CTC PC. 
#Chosen DS version is based on ADC Device Server.lnk laying on the Public Desktop of each particular CTC PC.
$CTC = '192.168.13.170','192.168.13.171','192.168.13.172','192.168.13.173','192.168.13.174','192.168.13.175','192.168.13.176','192.168.13.177','192.168.13.178','192.168.13.179','192.168.13.180','192.168.13.181','192.168.13.182','192.168.13.138','192.168.13.139','192.168.13.140','192.168.13.141','192.168.13.142','192.168.13.143','192.168.13.145','192.168.13.161','192.168.13.168','192.168.13.232','192.168.13.191'
#$CTC = @('192.168.13.175')

$Login = 'local\Administrator'
$Password = 'Tecom_1!'
$Pass = ConvertTo-SecureString -AsPlainText $Password -Force
$Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Login, $Pass


$newValues = @{ListControlNotifyFrames=0 ; AnyProperty=0}

Invoke-Command $CTC -Credential $Creds -ArgumentList ($newValues) {
    param ($newValues)
    
    $DSpath = (New-Object -ComObject WScript.Shell).CreateShortcut('C:\Users\Public\Desktop\ADC Device Server.lnk').WorkingDirectory
    $ListConfINI = $DSpath + '\LISTCONF.INI'
    $Content = get-content $ListConfINI
    foreach ($key in $newValues.Keys) {
        $Content = $Content -replace "($key)=.*$","`$1=$($newValues.$key)"
    }
    $Content | Out-File $ListConfINI -Encoding ascii

    "$env:COMPUTERNAME - Done"
}