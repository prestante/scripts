$CTC = @('WTL-HP3B8-VDS1.WTLDEV.NET','WTL-HP3B8-VDS2.WTLDEV.NET','WTL-HP3B8-VDS3.WTLDEV.NET','WTL-HP3B8-VDS4.WTLDEV.NET','WTL-HP3B8-VDS5.WTLDEV.NET','WTL-HP3B8-VDS6.WTLDEV.NET','WTL-HP3B8-VDS7.WTLDEV.NET','WTL-HP3B8-VDS8.WTLDEV.NET','WTL-HP3B8-VDS9.WTLDEV.NET','WTL-HP3B8-VDS10.WTLDEV.NET','WTL-HP3B9-VDS1.WTLDEV.NET','WTL-HP3B9-VDS2.WTLDEV.NET','WTL-HP3B9-VDS3.WTLDEV.NET','WTL-HP3B9-VDS4.WTLDEV.NET','WTL-HP3B9-VDS5.WTLDEV.NET','WTL-HP3B9-VDS6.WTLDEV.NET','WTL-HP3B9-VDS7.WTLDEV.NET','WTL-HP3B9-VDS8.WTLDEV.NET','WTL-HP3B9-VDS9.WTLDEV.NET','WTL-HP3B9-VDS10.WTLDEV.NET')
#$CTC = @('WTL-HP3B8-VDS1.WTLDEV.NET')

$pass = ConvertTo-SecureString -String '01000000d08c9ddf0115d1118c7a00c04fc297eb010000007c87033a3f02f847a3f4d44805ffa55b0000000002000000000003660000c000000010000000aa4bb3e813a3281af0fc4c14f844adfd0000000004800000a000000010000000872646a5dfd994f49500eb831518deb820000000381f88ed6d9764b2a0a5575455b39b3d90f97981cd7338bb504279ab9bf77f87140000005782fcc9c5411d027b5b0d1ae7463094e75774f5'

Invoke-Command -ComputerName $CTC -ArgumentList $InstallAppVersion, $PrevAppVersion, $pass -ScriptBlock {
    param ( $InstallAppVersion, $PrevAppVersion, $pass )
    $creds = [System.Management.Automation.PSCredential]::new('agalkovs',$pass)
    
    # Attach network drive with builds from shared network drive
    New-PSDrive -Name S -PSProvider FileSystem -Root \\wtl-hp3b7-plc1.wtldev.net\Shared -Credential $creds | out-null

    # check and install vc_redist.x64.exe
    if (!(Get-ItemProperty HKLM:Software\Microsoft\Windows\CurrentVersion\Uninstall\* | where {$_.displayname -like "Microsoft Visual C++ 2017*"} | Select-Object DisplayName, DisplayVersion)) {
        Copy-Item 'S:\vc_redist.x64.exe' 'C:\temp'
        Write-Host "$($env:COMPUTERNAME): Installing Microsoft Visual C++ Redistributable x64..."
        Start-Process -FilePath 'C:\temp\vc_redist.x64.exe' -ArgumentList "/Q" -Wait #-Credential $creds
    }
    # check and install vc_redist.x86.exe
    if (!(Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | where {$_.displayname -like "Microsoft Visual C++ * Redistributable*"} | Select-Object DisplayName, DisplayVersion)) {
        Copy-Item 'S:\vc_redist.x86.exe' 'C:\temp'
        Write-Host "$($env:COMPUTERNAME): Installing Microsoft Visual C++ Redistributable x86..."
        Start-Process -FilePath 'C:\temp\vc_redist.x86.exe' -ArgumentList "/Q" -Wait #-Credential $creds
    }

    # Check and prepare Chronos installator and params
    if (!(Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | where {$_.displayname -like "*Chronos*"} | Select-Object DisplayName, DisplayVersion)) {
        Copy-Item (gci 'S:' | where { $_.Name -match 'Chronos.exe'} | sort VersionInfo | select -Last 1).FullName 'C:\temp'
        $file = gci 'C:\temp' | where { $_.Name -match 'Chronos.exe'} | sort VersionInfo | select -Last 1
        $arguments = '-nogui'

        # Install Chronos
        $p = Start-Process -FilePath $file.FullName -ArgumentList $arguments -NoNewWindow -Wait -PassThru
        # allow "ok" or "reboot required" codes
        if (($p.ExitCode -ne 0) -and ($p.ExitCode -ne 3010)) {
            $exitcode = $p.ExitCode
            throw  $MyInvocation.MyCommand.Name + " ERROR: Chronos install failed with exit code $exitcode"
        }
        Write-Host "$($env:COMPUTERNAME) - $($File.VersionInfo.ProductName) $($File.VersionInfo.ProductVersion) has been successfully installed." -fo Green -ba Black
    } else {
        Write-Host "$($env:COMPUTERNAME) - Chronos already exists in system." -fo Yellow -ba Black
    }

    # Update config
    Copy-Item (gci 'S:' | where { $_.Name -match 'chronossettings.json'} | sort VersionInfo | select -Last 1).FullName 'C:\temp'
    $ChronosSettingsFileFull = 'C:\ProgramData\Imagine Communications\Chronos\chronossettings.json'
    $chronossettings = (Get-Content (gci 'C:\temp' | where { $_.Name -match 'chronossettings.json'} | sort VersionInfo | select -Last 1).FullName) | ConvertFrom-Json
    $chronossettings.ptpSettings.adaptername = (Get-NetAdapter).InterfaceDescription
    # Set Priority1 to the last number of IPv4Address
    $chronossettings.ptpSettings.priority1 = [int]((Get-NetIPAddress | where {$_.IPv4Address -match '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' -and $_.IPv4Address -notmatch '127.0.0.1' -and $_.IPv4Address -notmatch '169.254.\d{1,3}.\d{1,3}'} | select -First 1).IPv4Address -replace '\d{1,3}\.\d{1,3}\.\d{1,3}\.')
    # Set depth in case any levels get added to the json file
    ConvertTo-Json $chronossettings -Depth 4 | Set-Content $ChronosSettingsFileFull -Encoding Ascii


    # Ensure chronos service and process are running
    if ((Get-Service ChronosServer).Status -eq 'Stopped') {Start-Service ChronosServer; Sleep 2}
    $process = Get-Process ChronosExe -ea SilentlyContinue
    if (((Get-Service ChronosServer).Status -ne 'Running') -or !($process)) {Write-Host "$($env:COMPUTERNAME) - Chronos isn't running" -fo Red -ba Black}
}



