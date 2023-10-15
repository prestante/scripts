#$CTC = @('WTL-HP3B8-VDS1.WTLDEV.NET','WTL-HP3B8-VDS2.WTLDEV.NET','WTL-HP3B8-VDS3.WTLDEV.NET','WTL-HP3B8-VDS4.WTLDEV.NET','WTL-HP3B8-VDS5.WTLDEV.NET','WTL-HP3B8-VDS6.WTLDEV.NET','WTL-HP3B8-VDS7.WTLDEV.NET','WTL-HP3B8-VDS8.WTLDEV.NET','WTL-HP3B8-VDS9.WTLDEV.NET','WTL-HP3B8-VDS10.WTLDEV.NET','WTL-HP3B9-VDS1.WTLDEV.NET','WTL-HP3B9-VDS2.WTLDEV.NET','WTL-HP3B9-VDS3.WTLDEV.NET','WTL-HP3B9-VDS4.WTLDEV.NET','WTL-HP3B9-VDS5.WTLDEV.NET','WTL-HP3B9-VDS6.WTLDEV.NET','WTL-HP3B9-VDS7.WTLDEV.NET','WTL-HP3B9-VDS8.WTLDEV.NET','WTL-HP3B9-VDS9.WTLDEV.NET','WTL-HP3B9-VDS10.WTLDEV.NET')
#$CTC = @('adc-ctc01.tecomgroup.ru','adc-ctc02.tecomgroup.ru','adc-ctc03.tecomgroup.ru','adc-ctc04.tecomgroup.ru','adc-ctc05.tecomgroup.ru','adc-ctc06.tecomgroup.ru','adc-ctc07.tecomgroup.ru','adc-ctc08.tecomgroup.ru','adc-ctc09.tecomgroup.ru','adc-ctc10.tecomgroup.ru','adc-ctc11.tecomgroup.ru','adc-ctc12.tecomgroup.ru','adc-ctc13.tecomgroup.ru','adc-ctc14.tecomgroup.ru','adc-ctc15.tecomgroup.ru','adc-ctc16.tecomgroup.ru','adc-ctc17.tecomgroup.ru','adc-ctc18.tecomgroup.ru','adc-ctc19.tecomgroup.ru','adc-ctc20.tecomgroup.ru','adc-ctc21.tecomgroup.ru','adc-ctc22.tecomgroup.ru','adc-ctc23.tecomgroup.ru','adc-ctc24.tecomgroup.ru')
$CTC = @('adc-ctc01.tecomgroup.ru','adc-ctc02.tecomgroup.ru')

#prompts for DS versions and copying INIs
$InstallAppVersion = '12.29.12'
#$InstallAppVersion = Read-Host "Install what DS version?"

If ($InstallAppVersion -notmatch '^\d+\.\d+\.\d+') {
    echo 'Wrong DS Version'
    return
}

If ((Read-Host "Copy INIs from previous DS version?(y/n)") -match '[yY]') {
    $PrevAppVersion = Read-Host "Previous installed DS version?"
    If ($PrevAppVersion -notmatch '^\d+\.\d+\.\d+') {
        echo 'Wrong DS Version'
        return
    }

} else {$PrevAppVersion = ''}

#this was done to pass the password for agalkovs username into Invoke-Command
#$pass = ConvertTo-SecureString -String '01000000d08c9ddf0115d1118c7a00c04fc297eb010000007c87033a3f02f847a3f4d44805ffa55b0000000002000000000003660000c000000010000000aa4bb3e813a3281af0fc4c14f844adfd0000000004800000a000000010000000872646a5dfd994f49500eb831518deb820000000381f88ed6d9764b2a0a5575455b39b3d90f97981cd7338bb504279ab9bf77f87140000005782fcc9c5411d027b5b0d1ae7463094e75774f5'

#credentials for operating CTC PCs
$Creds = [System.Management.Automation.PSCredential]::new('local\Administrator',(ConvertTo-SecureString -AsPlainText 'Tecom_1!' -Force))
write-host "Please wait.."

Invoke-Command -ComputerName $CTC -ArgumentList $InstallAppVersion, $PrevAppVersion, $pass -Credential $Creds -ScriptBlock {
    param ( $InstallAppVersion, $PrevAppVersion, $pass )
    #$creds = [System.Management.Automation.PSCredential]::new('agalkovs',$pass)
    $fsCreds = [System.Management.Automation.PSCredential]::new('TECOM\adcqauser',(ConvertTo-SecureString -AsPlainText 'Tecom_123!' -Force))

    # attaching network drive with builds from \\fs
    #New-PSDrive -Name S -PSProvider FileSystem -Root \\wtl-hp3b7-plc1.wtldev.net\Shared -Credential $creds | out-null
    New-PSDrive -Name S -PSProvider FileSystem -Root \\192.168.12.3\Shares\Engineering\ADC\QA\Builds -Credential $fsCreds | out-null
    
    # this block was done for wtldev VMs
    <# checking and installing vc_redist.x86.exe
    if (!(Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | where {$_.displayname -like "Microsoft Visual C++ * Redistributable*"} | Select-Object DisplayName, DisplayVersion)) {
        #Copy-Item 'S:\vc_redist.x86.exe' 'C:\temp'
        #Write-Host "$($env:COMPUTERNAME): Installing Microsoft Visual C++ Redistributable x86..."
        #Start-Process -FilePath 'C:\temp\vc_redist.x86.exe' -ArgumentList "/Q" -Wait #-Credential $creds
        Write-Host "$($env:COMPUTERNAME): Microsoft Visual C++ Redistributable x86 is missing"
    }
    
    # preparing device server installator and params
    Copy-Item (gci 'S:\' | where { $_.Name -match '^SERVER_QATEST' -and $_.Name -match $InstallAppVersion} | select -First 1).FullName 'C:\temp'
    $File = gci 'C:\temp' | where { $_.Name -match '^SERVER_QATEST' -and $_.Name -match $InstallAppVersion} | select -First 1
    $InstallPath = 'C:\server\' + $File.Name -replace 'SERVER_QATEST_(.*)\.exe','$1'
    #$DSname = $env:COMPUTERNAME -match 'WTL-HP3B8-(\D*)(\d*)' | %{"{0}{1:d2}" -f $Matches.1,[int]$Matches.2}
    $DSname = $env:COMPUTERNAME -replace 'WTL-HP3'
    $Parameters = "\s \target`"$InstallPath`" \server`"$DSname`""    #silent install    

    if (!(Test-Path $file.FullName)) {Write-Host "$($env:COMPUTERNAME) - File not found: $($File.FullName)" -fo Red -ba Black ; return}

    # checking and installing DS
    if (!(Get-ItemProperty HKLM:SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | where {$_.displayname -match 'ADC.*Server' -and $_.displayversion -match $InstallAppVersion})) {
        Write-Host "$($env:COMPUTERNAME): Installing $($File.VersionInfo.ProductName)..."
        Start-Process $File.FullName -ArgumentList $Parameters -Wait          #executing DS installer with parameters
            
        If ($PrevAppVersion) { #Copy old INIs to new DS folder??
            $OldInstallPath = (gci 'C:\server\' | where {$_.Name -match $PrevAppVersion} | select -First 1).FullName
            Copy-Item ($OldInstallPath | gci | where {$_.name -cmatch 'INI'}).FullName -Destination $InstallPath -Force
        } else {               #or generate INIs from CTC00-1 List template?
            Copy-Item 'S:\ADC1000NT-CTC-1-list.INI' "$InstallPath\ADC1000NT.INI" -Force
            (Get-Content 'S:\LISTCONF-CTC-1-list.INI') -replace 'CTC00',$DSname | Out-File "$InstallPath\LISTCONF.INI" -Encoding ascii -Force
        }
        Write-Host "$($env:COMPUTERNAME) - $($File.VersionInfo.ProductName) $($File.VersionInfo.ProductVersion) has been successfully installed." -fo Green -ba Black
    }
    else { #DS of such version is already installed in OS
        Copy-Item 'S:\ADC1000NT-CTC-1-list.INI' "$InstallPath\ADC1000NT.INI" -Force
        (Get-Content 'S:\LISTCONF-CTC-1-list.INI') -replace 'CTC00',$DSname | Out-File "$InstallPath\LISTCONF.INI" -Encoding ascii -Force
        
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut('C:\Users\Public\Desktop\ADC Device Server.lnk')
        $shortcut.Arguments = $DSname
        $shortcut.save()

        Write-Host "$($env:COMPUTERNAME) - DS $InstallAppVersion already exists." -fo Yellow -ba Black
    }#>

    # -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

    #setting parameters
    $Folder = ((gci ('S:\ADC_v12\' + $InstallAppVersion.Substring(0,5)) | where {$_.Name -match $InstallAppVersion} | select -First 1).FullName) + '\Standard'
    $File = gci $Folder | where { $_.Name -match '^SERVER_QATEST' } | select -First 1
    $InstallPath = 'C:\server\' + $File.Name -replace 'SERVER_QATEST_(.*)\.exe','$1'

    #making DS name in shortcut like CTC02 or CTC12
    $DSname = $env:COMPUTERNAME -replace 'ADC-'
        
    #$Parameters = '\s \target"' + $InstallPath + '" \server"' + $DSname + '"'    #silent install
    $Parameters = "\s \target`"$InstallPath`" \server`"$DSname`""
        
    if (!(Test-Path $file.FullName)) {Write-Host "$($env:COMPUTERNAME) - File not found: $($File.FullName)" -fo Red -ba Black ; return}

    # checking and installing DS
    if (!(Get-ItemProperty HKLM:SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | where {$_.displayname -match 'ADC.*Server' -and $_.displayversion -match $InstallAppVersion})) {
        Write-Host "$($env:COMPUTERNAME): Installing $($File.VersionInfo.ProductName)..." -NoNewline

        #executing DS installer with parameters
        Start-Process $File.FullName -ArgumentList $Parameters -Wait
        
        #Copy old INIs to new DS folder
        If ($PrevAppVersion) {
            $OldInstallPath = (gci 'C:\server\' | where {$_.Name -match $PrevAppVersion} | select -First 1).FullName
            Copy-Item ($OldInstallPath | gci | where {$_.name -cmatch 'INI'}).FullName -Destination $InstallPath -Force
        }
    }
    else {Write-Host "$($env:COMPUTERNAME) - DS $InstallAppVersion already exists." -fo Yellow -ba Black ; return}
    Write-Host "Done" -fo Green -ba Black
}


<#
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut('C:\Users\Public\Desktop\ADC Device Server.lnk')
$shortcut.Arguments = 'PLC1'
$shortcut.save()
#>
