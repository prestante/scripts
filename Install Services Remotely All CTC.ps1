$CTC = @('WTL-HP3B8-VDS1.WTLDEV.NET','WTL-HP3B8-VDS2.WTLDEV.NET','WTL-HP3B8-VDS3.WTLDEV.NET','WTL-HP3B8-VDS4.WTLDEV.NET','WTL-HP3B8-VDS5.WTLDEV.NET','WTL-HP3B8-VDS6.WTLDEV.NET','WTL-HP3B8-VDS7.WTLDEV.NET','WTL-HP3B8-VDS8.WTLDEV.NET','WTL-HP3B8-VDS9.WTLDEV.NET','WTL-HP3B8-VDS10.WTLDEV.NET','WTL-HP3B9-VDS1.WTLDEV.NET','WTL-HP3B9-VDS2.WTLDEV.NET','WTL-HP3B9-VDS3.WTLDEV.NET','WTL-HP3B9-VDS4.WTLDEV.NET','WTL-HP3B9-VDS5.WTLDEV.NET','WTL-HP3B9-VDS6.WTLDEV.NET','WTL-HP3B9-VDS7.WTLDEV.NET','WTL-HP3B9-VDS8.WTLDEV.NET','WTL-HP3B9-VDS9.WTLDEV.NET','WTL-HP3B9-VDS10.WTLDEV.NET')
$CTC = @('WTL-HP3B8-VDS1.WTLDEV.NET')

$pass = ConvertTo-SecureString -String '01000000d08c9ddf0115d1118c7a00c04fc297eb010000007c87033a3f02f847a3f4d44805ffa55b0000000002000000000003660000c000000010000000aa4bb3e813a3281af0fc4c14f844adfd0000000004800000a000000010000000872646a5dfd994f49500eb831518deb820000000381f88ed6d9764b2a0a5575455b39b3d90f97981cd7338bb504279ab9bf77f87140000005782fcc9c5411d027b5b0d1ae7463094e75774f5'

Invoke-Command -ComputerName $CTC -ArgumentList $InstallAppVersion, $PrevAppVersion, $pass -ScriptBlock {
    param ( $InstallAppVersion, $PrevAppVersion, $pass )
    $creds = [System.Management.Automation.PSCredential]::new('agalkovs',$pass)
    
    # Attach network drive with builds from shared network drive
    New-PSDrive -Name S -PSProvider FileSystem -Root \\wtl-hp3b7-plc1.wtldev.net\Shared -Credential $creds | out-null

    # Shut ADC Services down
    Get-Service -Name 'ADC*' | Set-Service -StartupType Disabled
    Start-Sleep 1
    Get-Process -Name 'Harris.Automation.ADC.Services*' | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep 1
    Get-Service -Name 'ADC*' | Set-Service -StartupType Manual
    
    # Check if ADC Services are already installed
    $InstalledApp = (Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | where {$_.displayname -like "ADC Services"})
    if (-not $InstalledApp) { # Install ADC Services
        if (!(Get-ItemProperty HKLM:Software\Microsoft\Windows\CurrentVersion\Uninstall\* | where {$_.displayname -like "Microsoft SQL Server Compact*"} | Select-Object DisplayName, DisplayVersion)) {
            Copy-Item 'S:\SSCERuntime_x64-ENU.exe' 'C:\temp'
            $file = get-item "C:\temp\SSCERuntime_x64-ENU.exe"
            Write-Host "$($env:COMPUTERNAME): Installing Microsoft SQL Server Compact 4.0 SP1 x64 ENU..."
            Start-Process $file.FullName -ArgumentList "/package /quiet" -Wait
        }
        if ((Get-WindowsFeature -Name Web-Server).InstallState -eq 'Available') {
            Write-Host "$($env:COMPUTERNAME): Installing Web Server (IIS)..."
            Install-WindowsFeature -Name Web-Server -IncludeManagementTools | Out-Null
            Install-WindowsFeature -Name Web-Log-Libraries | Out-Null
            Install-WindowsFeature -Name Web-Request-Monitor | Out-Null
            Install-WindowsFeature -Name Web-Net-Ext45 | Out-Null
            Install-WindowsFeature -Name Web-Asp-Net45 | Out-Null
            Install-WindowsFeature -Name Web-ISAPI-Ext | Out-Null
            Install-WindowsFeature -Name Web-ISAPI-Filter | Out-Null
        }
        
        # Prepare ADC Services installator and params
        $Item = gci 'S:' | where { $_.Name -match 'ADCServicesSetup'} | sort VersionInfo | select -Last 1
        Copy-Item $Item.FullName 'C:\temp' -Force
        $File = gci 'C:\temp' | where { $_.Name -eq $Item.Name} | sort VersionInfo | select -Last 1
        $DBName = 'wtl-hpx-325-n01'
        $DBUser = 'sa'
        $DBPassword = 'Tecom_123!'
        #$Parameters = "/s, /v`"/qn`" /v`"IS_SQLSERVER_SERVER=$DBName`" /v`"IS_SQLSERVER_AUTHENTICATION=2`" /v`"IS_SQLSERVER_USERNAME=$DBUser`" /v`"IS_SQLSERVER_PASSWORD=$DBPassword`" /v`"INSTALLLEVEL=101`" /v`"/l*v C:\ADCServicesInstaller.log`" /v`"REBOOT=ReallySuppress`""
        $Parameters = "/s, /v`"/qn`" /v`"IS_SQLSERVER_SERVER=$DBName`" /v`"IS_SQLSERVER_USERNAME=$DBUser`" /v`"IS_SQLSERVER_PASSWORD=$DBPassword`" /v`"INSTALLLEVEL=101`" /v`"/l*v C:\ADCServicesInstaller.log`" /v`"REBOOT=ReallySuppress`""
        #$Parameters = "/x /s, /v`"/qn`" /v`"DELETEDB=No`" /v`"REBOOT=ReallySuppress`"" # Delete Services
        Write-Host "$($env:COMPUTERNAME): Installing $($File.VersionInfo.ProductName) $($File.VersionInfo.ProductVersion)..."
        Start-Process $File.FullName -ArgumentList $Parameters -Wait
        Start-Sleep 5

        # stop ADC Services
        Get-Service -Name 'ADC*' | Set-Service -StartupType Disabled
        Start-Sleep 1
        Get-Process -Name 'Harris.Automation.ADC.Services*' | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep 1
        Get-Process -Name 'Harris.Automation.ADC.Services*' | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep 1
        Get-Service -Name 'ADC*' | Set-Service -StartupType Manual

        # back up config files
        Copy-Item 'C:\Program Files (x86)\Imagine Communications\ADC Services\config\*' 'C:\temp\ADC Services Config Backup' -Force
        
        # copy ref files
        GCI 's:\xml' | where {$_.Name -match '.*ref.xml'} | %{Copy-Item $_.FullName 'C:\temp' -Force}
        # create rules and license directories
        New-Item -Path 'C:\Program Files (x86)\Imagine Communications\ADC Services\rules' -ItemType Directory -force -ea SilentlyContinue | Out-Null
        New-Item -Path 'C:\Program Files (x86)\Imagine Communications\ADC Services\license' -ItemType Directory -force -ea SilentlyContinue | Out-Null
        # copy license, rule and IntegrationServiceHost.exe.config
        Copy-Item 'S:\xml\ADCLicense.lic' 'C:\Program Files (x86)\Imagine Communications\ADC Services\license' -Force
        Copy-Item 'S:\xml\PlaylistTranslator.Rule.xml' 'C:\Program Files (x86)\Imagine Communications\ADC Services\rules' -Force
        Copy-Item 'S:\xml\Harris.Automation.ADC.Services.IntegrationServiceHost.exe.config' 'C:\Program Files (x86)\Imagine Communications\ADC Services' -Force
        
        # copy changed ref files to ADC Services config folder
        $name = $env:COMPUTERNAME -replace 'WTL-HP3'
        $address = (Get-NetIPAddress | where {$_.IPv4Address -match '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' -and $_.IPv4Address -notmatch '127.0.0.1' -and $_.IPv4Address -notmatch '169.254.\d{1,3}.\d{1,3}'} | select -First 1).IPv4Address
        $ipEnd = $address -replace '\d{1,3}\.\d{1,3}\.\d{1,3}\.'
        (Get-Content 'C:\temp\IntegrationServiceRef.xml') -replace '#NAME',$Name -replace '#ADDRESS',$Address | Out-File 'C:\Program Files (x86)\Imagine Communications\ADC Services\config\IntegrationService.xml' -Encoding utf8 -Force
        (Get-Content 'C:\temp\AsRunServiceRef.xml') -replace '#NAME',$Name -replace '#IPEND',$ipEnd | Out-File 'C:\Program Files (x86)\Imagine Communications\ADC Services\config\AsRunService.xml' -Encoding utf8 -Force
        (Get-Content 'C:\temp\DeviceServiceRef.xml') -replace '#NAME',$Name -replace '#IPEND',$ipEnd | Out-File 'C:\Program Files (x86)\Imagine Communications\ADC Services\config\DeviceService.xml' -Encoding utf8 -Force
        (Get-Content 'C:\temp\ErrorReportingServiceRef.xml') -replace '#NAME',$Name -replace '#IPEND',$ipEnd | Out-File 'C:\Program Files (x86)\Imagine Communications\ADC Services\config\ErrorReportingService.xml' -Encoding utf8 -Force
        (Get-Content 'C:\temp\ListServiceRef.xml') -replace '#NAME',$Name -replace '#IPEND',$ipEnd | Out-File 'C:\Program Files (x86)\Imagine Communications\ADC Services\config\ListService.xml' -Encoding utf8 -Force
        (Get-Content 'C:\temp\TimecodeServiceRef.xml') -replace '#NAME',$Name -replace '#IPEND',$ipEnd | Out-File 'C:\Program Files (x86)\Imagine Communications\ADC Services\config\TimecodeService.xml' -Encoding utf8 -Force
    
        #Get-Service -Name 'ADCSecurityService', 'ADCManagerService' | Start-Service

        Write-Host "$($env:COMPUTERNAME) - $($File.VersionInfo.ProductName) $($File.VersionInfo.ProductVersion) has been successfully installed." -fo Green -ba Black
    } 
    else { # Do not install ADC Services
        
        <# change ref files and copy them to ADC Services config folder
        $name = $env:COMPUTERNAME -replace 'WTL-HP3'
        $address = (Get-NetIPAddress | where {$_.IPv4Address -match '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' -and $_.IPv4Address -notmatch '127.0.0.1' -and $_.IPv4Address -notmatch '169.254.\d{1,3}.\d{1,3}'} | select -First 1).IPv4Address
        $ipEnd = $address -replace '\d{1,3}\.\d{1,3}\.\d{1,3}\.'
        (Get-Content 'C:\temp\IntegrationServiceRef.xml') -replace '#NAME',$Name -replace '#ADDRESS',$Address | Out-File 'C:\Program Files (x86)\Imagine Communications\ADC Services\config\IntegrationService.xml' -Encoding utf8 -Force
        (Get-Content 'C:\temp\AsRunServiceRef.xml') -replace '#NAME',$Name -replace '#IPEND',$ipEnd | Out-File 'C:\Program Files (x86)\Imagine Communications\ADC Services\config\AsRunService.xml' -Encoding utf8 -Force
        (Get-Content 'C:\temp\DeviceServiceRef.xml') -replace '#NAME',$Name -replace '#IPEND',$ipEnd | Out-File 'C:\Program Files (x86)\Imagine Communications\ADC Services\config\DeviceService.xml' -Encoding utf8 -Force
        (Get-Content 'C:\temp\ErrorReportingServiceRef.xml') -replace '#NAME',$Name -replace '#IPEND',$ipEnd | Out-File 'C:\Program Files (x86)\Imagine Communications\ADC Services\config\ErrorReportingService.xml' -Encoding utf8 -Force
        (Get-Content 'C:\temp\ListServiceRef.xml') -replace '#NAME',$Name -replace '#IPEND',$ipEnd | Out-File 'C:\Program Files (x86)\Imagine Communications\ADC Services\config\ListServiceRef.xml' -Encoding utf8 -Force
        (Get-Content 'C:\temp\TimecodeServiceRef.xml') -replace '#NAME',$Name -replace '#IPEND',$ipEnd | Out-File 'C:\Program Files (x86)\Imagine Communications\ADC Services\config\TimecodeService.xml' -Encoding utf8 -Force
        #>

        # delete services
        Get-Service -Name 'ADC*' | Set-Service -StartupType Disabled
        Start-Sleep 1
        Get-Process -Name 'Harris.Automation.ADC.Services*' | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep 1
        Get-Process -Name 'Harris.Automation.ADC.Services*' | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep 1
        Get-Service -Name 'ADC*' | Set-Service -StartupType Manual
        $File = gci 'C:\temp' | where { $_.Name -match 'ADCServicesSetup'} | sort VersionInfo | select -Last 1
        $Parameters = "/x /s, /v`"/qn`" /v`"DELETEDB=No`" /v`"REBOOT=ReallySuppress`"" # Delete Services
        Write-Host "$($env:COMPUTERNAME): Deleting $($File.VersionInfo.ProductName) $($File.VersionInfo.ProductVersion)..."
        Start-Process $File.FullName -ArgumentList $Parameters -Wait
        Write-Host "$($env:COMPUTERNAME): ADC Services were successfully deleted" -f Yellow -b Black
        return
        #>

        Write-Host "$($env:COMPUTERNAME): ADC Services already installed (v.$($InstalledApp.DisplayVersion))" -f Yellow -b Black
        return
    }

    

}




