$CTC = '192.168.13.170','192.168.13.171','192.168.13.172','192.168.13.173','192.168.13.174','192.168.13.175','192.168.13.176','192.168.13.177','192.168.13.178','192.168.13.179','192.168.13.180','192.168.13.181','192.168.13.182','192.168.13.138','192.168.13.139','192.168.13.140','192.168.13.141','192.168.13.142','192.168.13.143','192.168.13.145','192.168.13.161','192.168.13.168','192.168.13.232','192.168.13.191'
#$CTC = '192.168.13.181'
#$CTC = '192.168.13.172'
#$CTC = '192.168.13.171','192.168.13.172','192.168.13.173','192.168.13.174','192.168.13.175','192.168.13.176','192.168.13.177','192.168.13.178','192.168.13.179','192.168.13.180','192.168.13.181'

$Login = 'local\Administrator'
$Password = 'Tecom_1!'
$Pass = ConvertTo-SecureString -AsPlainText $Password -Force
$Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Login, $Pass

Invoke-Command -ComputerName $CTC -Credential $Creds -ScriptBlock {

        $rLogin = 'TECOM\adcqauser'
        $rPassword = 'Tecom_123!'
        $rPass = ConvertTo-SecureString -AsPlainText $rPassword -Force
        $rCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $rLogin, $rPass

        #New-PSDrive -Name S -PSProvider FileSystem -Root \\fs\Change\panteleev.k -Credential $rCreds | Out-Null #creating temporary network drive S:

        $ItemPath = 'S:\PlayList_UI_autologin_Admin'
        $ItemName = $ItemPath -replace '^.*\\'
        $DestPath = 'C:\Program Files\Imagine Communications'
        $DestItem = $DestPath + '\Playlist'
        #Remove-Item $DestItem -Recurse -Force -ea SilentlyContinue
        #Copy-Item $ItemPath -Destination $DestPath -Recurse -Force
        Rename-Item ($DestPath + '\' + $ItemName) -NewName 'Playlist'
        
        $ConfFile = 'S:\Playlist.configuration'
        #New-Item -Path 'C:\Users\Administrator\AppData\Local\Imagine Communications\Playlist' -ItemType Directory -force -ea SilentlyContinue | out-null
        #Copy-Item $ConfFile -Destination 'C:\Users\Administrator\AppData\Local\Imagine Communications\Playlist' -Force

        #"$env:computername - Done"
        #Get-ChildItem $DestPath
}



