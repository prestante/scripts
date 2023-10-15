$CTC = '192.168.13.170','192.168.13.171','192.168.13.172','192.168.13.173','192.168.13.174','192.168.13.175','192.168.13.176','192.168.13.177','192.168.13.178','192.168.13.179','192.168.13.180','192.168.13.181','192.168.13.182','192.168.13.138','192.168.13.139','192.168.13.140','192.168.13.141','192.168.13.142','192.168.13.143','192.168.13.145','192.168.13.161','192.168.13.168','192.168.13.232','192.168.13.191'
$CTC = @('192.168.13.170')
$CTC = '192.168.13.171','192.168.13.172','192.168.13.173','192.168.13.174','192.168.13.175','192.168.13.176','192.168.13.177','192.168.13.178','192.168.13.179','192.168.13.180','192.168.13.181','192.168.13.182','192.168.13.138','192.168.13.139','192.168.13.140','192.168.13.141','192.168.13.142','192.168.13.143','192.168.13.145','192.168.13.161','192.168.13.168','192.168.13.232','192.168.13.191'

#credentials for operating CTC PCs
$Login = 'local\Administrator'
$Password = 'Tecom_1!'
$Pass = ConvertTo-SecureString -AsPlainText $Password -Force
$Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Login, $Pass

#prompts for DS versions and copying INIs
$InstallAppVersion = Read-Host "Install what CT version?"

If ($InstallAppVersion -notmatch '^\d+\.\d+\.\d+') {
    echo 'Wrong CT Version'
    return
    }

$PrevAppVersion = ''

write-host "Please wait.."

Invoke-Command -ComputerName $CTC -Credential $Creds -ArgumentList $InstallAppVersion, $PrevAppVersion -ScriptBlock {
    param ( $InstallAppVersion, $PrevAppVersion )

    #credentials for \\fs access
    $rLogin = 'TECOM\adcqauser'
    $rPassword = 'Tecom_123!'
    $rPass = ConvertTo-SecureString -AsPlainText $rPassword -Force
    $rCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $rLogin, $rPass

    #attaching network drive with builds from \\fs
    New-PSDrive -Name S -PSProvider FileSystem -Root \\192.168.12.3\Shares\Engineering\ADC\QA\Builds -Credential $rCreds | out-null

    #setting parameters
    $Folder = ((gci ('S:\ADC_v12\' + $InstallAppVersion.Substring(0,5)) | where {$_.Name -match $InstallAppVersion} | select -First 1).FullName) + '\Standard'
    $File = gci $Folder | where { $_.Name -match '^CONFIG' } | select -First 1
    $InstallPath = 'C:\config\' + $File.Name -replace 'CONFIG_(.*)\.exe','$1'
    
    #making CT name in shortcut like CTC02 or CTC12
    $name = $env:COMPUTERNAME -replace 'ADC-'
        
    $Parameters = '\s \target"' + $InstallPath + '" \client"CT_' + $name + '"'    #silent install
        
    #check if resulting file path is correct
    If (test-path $File.FullName) {
            
        #executing DS installer with parameters
        #Start-Process $File.FullName -ArgumentList $Parameters -Wait
        
        #Copy old INIs to new DS folder
        If ($PrevAppVersion) {
            $OldInstallPath = (gci 'C:\server\' | where {$_.Name -match $PrevAppVersion} | select -First 1).FullName
            Copy-Item ($OldInstallPath | gci | where {$_.name -cmatch 'INI'}).FullName -Destination $InstallPath -Force
        }
    }
    else {Write-Host "$($env:COMPUTERNAME) - File not found." -fo Red -ba Black ; return}
    
    $alias13 = (Get-NetIPAddress | where {$_.IPv4Address -match '192\.168\.13\.'}).InterfaceAlias
    $ip13 = (Get-NetIPAddress | where {$_.IPv4Address -match '192\.168\.13\.'}).IPv4Address
    $mac13 = (Get-NetAdapter | where {$_.InterfaceAlias -eq $alias13}).MacAddress
    $sh = New-Object -ComObject WScript.Shell
    $dir = (gci $sh.CreateShortcut('C:\Users\Public\Desktop\ADC Config Tool.lnk').Targetpath).Directory
    New-Item -ItemType File -Path $dir -Name 'NETWORK.INI' -Value "[Network Interface]`nMAC=$mac13" -Force

    Write-Host "$($env:COMPUTERNAME) - Done." -fo Green -ba Black

}
