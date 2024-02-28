#$CTC = @('WTL-HP3B8-VDS1.WTLDEV.NET','WTL-HP3B8-VDS2.WTLDEV.NET','WTL-HP3B8-VDS3.WTLDEV.NET','WTL-HP3B8-VDS4.WTLDEV.NET','WTL-HP3B8-VDS5.WTLDEV.NET','WTL-HP3B8-VDS6.WTLDEV.NET','WTL-HP3B8-VDS7.WTLDEV.NET','WTL-HP3B8-VDS8.WTLDEV.NET','WTL-HP3B8-VDS9.WTLDEV.NET','WTL-HP3B8-VDS10.WTLDEV.NET','WTL-HP3B9-VDS1.WTLDEV.NET','WTL-HP3B9-VDS2.WTLDEV.NET','WTL-HP3B9-VDS3.WTLDEV.NET','WTL-HP3B9-VDS4.WTLDEV.NET','WTL-HP3B9-VDS5.WTLDEV.NET','WTL-HP3B9-VDS6.WTLDEV.NET','WTL-HP3B9-VDS7.WTLDEV.NET','WTL-HP3B9-VDS8.WTLDEV.NET','WTL-HP3B9-VDS9.WTLDEV.NET','WTL-HP3B9-VDS10.WTLDEV.NET')
#$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net', 'WTL-ADC-CTC-03.wtldev.net', 'WTL-ADC-CTC-04.wtldev.net', 'WTL-ADC-CTC-05.wtldev.net', 'WTL-ADC-CTC-06.wtldev.net', 'WTL-ADC-CTC-07.wtldev.net', 'WTL-ADC-CTC-08.wtldev.net', 'WTL-ADC-CTC-09.wtldev.net', 'WTL-ADC-CTC-10.wtldev.net', 'WTL-ADC-CTC-11.wtldev.net', 'WTL-ADC-CTC-12.wtldev.net', 'WTL-ADC-CTC-13.wtldev.net', 'WTL-ADC-CTC-14.wtldev.net', 'WTL-ADC-CTC-15.wtldev.net', 'WTL-ADC-CTC-16.wtldev.net', 'WTL-ADC-CTC-17.wtldev.net', 'WTL-ADC-CTC-18.wtldev.net', 'WTL-ADC-CTC-19.wtldev.net', 'WTL-ADC-CTC-20.wtldev.net', 'WTL-ADC-CTC-21.wtldev.net', 'WTL-ADC-CTC-22.wtldev.net', 'WTL-ADC-CTC-23.wtldev.net', 'WTL-ADC-CTC-24.wtldev.net', 'WTL-ADC-CTC-25.wtldev.net', 'WTL-ADC-CTC-26.wtldev.net', 'WTL-ADC-CTC-27.wtldev.net', 'WTL-ADC-CTC-28.wtldev.net', 'WTL-ADC-CTC-29.wtldev.net', 'WTL-ADC-CTC-30.wtldev.net', 'WTL-ADC-CTC-31.wtldev.net', 'WTL-ADC-CTC-32.wtldev.net', 'WTL-ADC-CTC-33.wtldev.net', 'WTL-ADC-CTC-34.wtldev.net', 'WTL-ADC-CTC-35.wtldev.net', 'WTL-ADC-CTC-36.wtldev.net', 'WTL-ADC-CTC-37.wtldev.net', 'WTL-ADC-CTC-38.wtldev.net', 'WTL-ADC-CTC-39.wtldev.net', 'WTL-ADC-CTC-40.wtldev.net')
$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net', 'WTL-ADC-CTC-03.wtldev.net', 'WTL-ADC-CTC-04.wtldev.net', 'WTL-ADC-CTC-05.wtldev.net', 'WTL-ADC-CTC-06.wtldev.net', 'WTL-ADC-CTC-07.wtldev.net', 'WTL-ADC-CTC-08.wtldev.net', 'WTL-ADC-CTC-09.wtldev.net')
$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net')

$CredsDomain = [System.Management.Automation.PSCredential]::new('wtldev.net\vadc',(ConvertTo-SecureString -AsPlainText $env:vPW -Force))
$BuildsFolder = '\\wtlnas5.wtldev.net\Public\Releases\ADC\ADC1000\QATEST'
    
#prompts for DS versions and copying INIs
$InstallAppVersion = '12.29.19'
#$InstallAppVersion = Read-Host "Install what DS version?"

If ($InstallAppVersion -notmatch '^\d+\.\d+\.\d+') {
    echo 'Wrong DS Version'
    return
}

<#If ((Read-Host "Copy INIs from previous DS version?(y/n)") -match '[yY]') {
    $PrevAppVersion = Read-Host "Previous installed DS version?"
    If ($PrevAppVersion -notmatch '^\d+\.\d+\.\d+') {
        echo 'Wrong DS Version'
        return
    }

} else {$PrevAppVersion = ''}#>

write-host "Please wait.."

Invoke-Command -ComputerName $CTC -ArgumentList $InstallAppVersion, $PrevAppVersion, $CredsDomain, $BuildsFolder -Credential $CredsDomain {
    param ( $InstallAppVersion, $PrevAppVersion, $CredsDomain, $BuildsFolder )
    
    $HostName = HOSTNAME.EXE
    $IPaddress = Get-NetIPAddress | Where-Object {$_.AddressState -eq "Preferred" -and $_.ValidLifetime -lt "24:00:00"} | Select-Object -ExpandProperty IPAddress
    $Domain = (Get-WmiObject Win32_ComputerSystem).Domain
    $PartOfDomain = (Get-WmiObject Win32_ComputerSystem).PartOfDomain
    $report = "$HostName ($IPaddress)"
    
    # attaching network drive with builds from \\wtlnas5
    New-PSDrive -Name S -PSProvider FileSystem -Root $BuildsFolder -Credential $CredsDomain | Out-Null
    
    return

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

    Remove-PSDrive -Name S
    $report += "`n`t Done"
    Write-Host "$report" -f (Get-Random (1,2,3,5,6,9,10,11,13,14))
}


<#
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut('C:\Users\Public\Desktop\ADC Device Server.lnk')
$shortcut.Arguments = 'PLC1'
$shortcut.save()
#>
