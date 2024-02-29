#$CTC = @('WTL-HP3B8-VDS1.WTLDEV.NET','WTL-HP3B8-VDS2.WTLDEV.NET','WTL-HP3B8-VDS3.WTLDEV.NET','WTL-HP3B8-VDS4.WTLDEV.NET','WTL-HP3B8-VDS5.WTLDEV.NET','WTL-HP3B8-VDS6.WTLDEV.NET','WTL-HP3B8-VDS7.WTLDEV.NET','WTL-HP3B8-VDS8.WTLDEV.NET','WTL-HP3B8-VDS9.WTLDEV.NET','WTL-HP3B8-VDS10.WTLDEV.NET','WTL-HP3B9-VDS1.WTLDEV.NET','WTL-HP3B9-VDS2.WTLDEV.NET','WTL-HP3B9-VDS3.WTLDEV.NET','WTL-HP3B9-VDS4.WTLDEV.NET','WTL-HP3B9-VDS5.WTLDEV.NET','WTL-HP3B9-VDS6.WTLDEV.NET','WTL-HP3B9-VDS7.WTLDEV.NET','WTL-HP3B9-VDS8.WTLDEV.NET','WTL-HP3B9-VDS9.WTLDEV.NET','WTL-HP3B9-VDS10.WTLDEV.NET')
#$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net', 'WTL-ADC-CTC-03.wtldev.net', 'WTL-ADC-CTC-04.wtldev.net', 'WTL-ADC-CTC-05.wtldev.net', 'WTL-ADC-CTC-06.wtldev.net', 'WTL-ADC-CTC-07.wtldev.net', 'WTL-ADC-CTC-08.wtldev.net', 'WTL-ADC-CTC-09.wtldev.net', 'WTL-ADC-CTC-10.wtldev.net', 'WTL-ADC-CTC-11.wtldev.net', 'WTL-ADC-CTC-12.wtldev.net', 'WTL-ADC-CTC-13.wtldev.net', 'WTL-ADC-CTC-14.wtldev.net', 'WTL-ADC-CTC-15.wtldev.net', 'WTL-ADC-CTC-16.wtldev.net', 'WTL-ADC-CTC-17.wtldev.net', 'WTL-ADC-CTC-18.wtldev.net', 'WTL-ADC-CTC-19.wtldev.net', 'WTL-ADC-CTC-20.wtldev.net', 'WTL-ADC-CTC-21.wtldev.net', 'WTL-ADC-CTC-22.wtldev.net', 'WTL-ADC-CTC-23.wtldev.net', 'WTL-ADC-CTC-24.wtldev.net', 'WTL-ADC-CTC-25.wtldev.net', 'WTL-ADC-CTC-26.wtldev.net', 'WTL-ADC-CTC-27.wtldev.net', 'WTL-ADC-CTC-28.wtldev.net', 'WTL-ADC-CTC-29.wtldev.net', 'WTL-ADC-CTC-30.wtldev.net', 'WTL-ADC-CTC-31.wtldev.net', 'WTL-ADC-CTC-32.wtldev.net', 'WTL-ADC-CTC-33.wtldev.net', 'WTL-ADC-CTC-34.wtldev.net', 'WTL-ADC-CTC-35.wtldev.net', 'WTL-ADC-CTC-36.wtldev.net', 'WTL-ADC-CTC-37.wtldev.net', 'WTL-ADC-CTC-38.wtldev.net', 'WTL-ADC-CTC-39.wtldev.net', 'WTL-ADC-CTC-40.wtldev.net')
#$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net', 'WTL-ADC-CTC-03.wtldev.net', 'WTL-ADC-CTC-04.wtldev.net', 'WTL-ADC-CTC-05.wtldev.net', 'WTL-ADC-CTC-06.wtldev.net', 'WTL-ADC-CTC-07.wtldev.net', 'WTL-ADC-CTC-08.wtldev.net', 'WTL-ADC-CTC-09.wtldev.net')
$CTC = @('WTL-ADC-CTC-01.wtldev.net')

$CredsDomain = [System.Management.Automation.PSCredential]::new('wtldev.net\vadc',(ConvertTo-SecureString -AsPlainText $env:vPW -Force))
$BuildsFolder = '\\wtlnas5.wtldev.net\Public\Releases\ADC\ADC1000\QATEST'
$InstallAppVersion = '12.29.19'
#$InstallAppVersion = Read-Host "Install what DS version?"
If ( $InstallAppVersion -notmatch '^\d{1,2}\.\d{1,2}\.\d{1,2}$' ) { Write-Host "Wrong DS Version: $InstallAppVersion`nIt should be like 12.29.19" -f Red ; return }
Write-Host "Please wait.."

Invoke-Command -ComputerName $CTC -ArgumentList $InstallAppVersion, $PrevAppVersion, $CredsDomain, $BuildsFolder -Credential $CredsDomain {
    param ( $InstallAppVersion, $PrevAppVersion, $CredsDomain, $BuildsFolder )
    $HostName = HOSTNAME.EXE
    $IPaddress = Get-NetIPAddress | Where-Object {$_.AddressState -eq "Preferred" -and $_.ValidLifetime -lt "24:00:00"} | Select-Object -ExpandProperty IPAddress
    $CurrentDSVersion = Get-Item "C:\server\ADC1000NT.EXE" -ea SilentlyContinue | Select-Object -ExpandProperty VersionInfo | Select-Object -ExpandProperty ProductVersion
    $report = "$HostName ($IPaddress)"
    
    $report += "`n`t Creating PSDrive $BuildsFolder"
    New-PSDrive -Name S -PSProvider FileSystem -Root $BuildsFolder -Credential $CredsDomain | Out-Null
    
    # this block was done for wtldev VMs
    <# checking and installing vc_redist.x86.exe
    if (!(Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.displayname -like "Microsoft Visual C++ * Redistributable*"} | Select-Object DisplayName, DisplayVersion)) {
        #Copy-Item 'S:\vc_redist.x86.exe' 'C:\temp'
        #Write-Host "$($HostName): Installing Microsoft Visual C++ Redistributable x86..."
        #Start-Process -FilePath 'C:\temp\vc_redist.x86.exe' -ArgumentList "/Q" -Wait #-Credential $creds
        Write-Host "$($HostName): Microsoft Visual C++ Redistributable x86 is missing"
    }#>
    
    # preparing device server installator and params
    $Folder = ( Get-ChildItem S: | Where-Object { $_.Name -match $InstallAppVersion } | Select-Object -First 1 ).FullName + "\Standard"
    $File = Get-ChildItem $Folder | Where-Object { $_.Name -match '^SERVER_QATEST' } | Select-Object -First 1
    #$InstallPath = 'C:\server\' + $File.Name -replace 'SERVER_QATEST_(.*)\.exe','$1'
    $DSname = $HostName -replace 'WTL-ADC-'
    $Parameters = "\s \server`"$DSname`""  # \s means silent install

    if ($CurrentDSVersion -match $InstallAppVersion) { $report += "`n`t DS $InstallAppVersion already exists" }  # same version already installed
    elseif ( -not ( Test-Path $File.FullName ) ) { $report += "Installer not found: $($File.FullName)"}  # there is no installer
    else {  # NEED TO CHECK IF I CAN SILENT INSTALL ON TOP OF INSTALLED OLDER DS
        $report += "`n`t Installing $($File.VersionInfo.ProductName)..."
        Start-Process $File.FullName -ArgumentList $Parameters -Wait  # executing DS installer with parameters
        If ($PrevAppVersion) { #Copy old INIs to new DS folder??
            $OldInstallPath = ( Get-ChildItem 'C:\server\' | Where-Object { $_.Name -match $PrevAppVersion } | Select-Object -First 1 ).FullName
            Copy-Item ( $OldInstallPath | Get-ChildItem | Where-Object { $_.name -cmatch 'INI' } ).FullName -Destination $InstallPath -Force
        } else {               #or generate INIs from CTC00-1 List template?
            Copy-Item 'S:\ADC1000NT-CTC-1-list.INI' "$InstallPath\ADC1000NT.INI" -Force
            (Get-Content 'S:\LISTCONF-CTC-1-list.INI') -replace 'CTC00',$DSname | Out-File "$InstallPath\LISTCONF.INI" -Encoding ascii -Force
        }
        Write-Host "$($HostName) - $($File.VersionInfo.ProductName) $($File.VersionInfo.ProductVersion) has been successfully installed." -fo Green -ba Black
    }

    # Copy shared template INIs and add right $DSname to shortcut just in case?
    #Copy-Item 'S:\ADC1000NT-CTC-1-list.INI' "$InstallPath\ADC1000NT.INI" -Force
    #(Get-Content 'S:\LISTCONF-CTC-1-list.INI') -replace 'CTC00',$DSname | Out-File "$InstallPath\LISTCONF.INI" -Encoding ascii -Force
    
    #$shell = New-Object -ComObject WScript.Shell
    #$shortcut = $shell.CreateShortcut('C:\Users\Public\Desktop\ADC Device Server.lnk')
    #$shortcut.Arguments = $DSname
    #$shortcut.save()

    $report += "`n`t Removing PSDrive $((Get-Item S:).FullName)" ; Remove-PSDrive -Name S
    $report += "`n`t Done"
    Write-Host "$report" -f ( 1, 2, 3, 5, 6, 9, 10, 11, 13, 14 )[ ( $HostName.Split('-')[-1] ) % 10 ]  # Choosing the color as a remainder of dividing the name number part by 10 (number of color variants)
    #Write-Host "$report" -f (Get-Random (1,2,3,5,6,9,10,11,13,14))
}