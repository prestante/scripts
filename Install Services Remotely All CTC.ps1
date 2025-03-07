$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net', 'WTL-ADC-CTC-03.wtldev.net', 'WTL-ADC-CTC-04.wtldev.net', 'WTL-ADC-CTC-05.wtldev.net', 'WTL-ADC-CTC-06.wtldev.net', 'WTL-ADC-CTC-07.wtldev.net', 'WTL-ADC-CTC-08.wtldev.net', 'WTL-ADC-CTC-09.wtldev.net', 'WTL-ADC-CTC-10.wtldev.net', 'WTL-ADC-CTC-11.wtldev.net', 'WTL-ADC-CTC-12.wtldev.net', 'WTL-ADC-CTC-13.wtldev.net', 'WTL-ADC-CTC-14.wtldev.net', 'WTL-ADC-CTC-15.wtldev.net', 'WTL-ADC-CTC-16.wtldev.net', 'WTL-ADC-CTC-17.wtldev.net', 'WTL-ADC-CTC-18.wtldev.net', 'WTL-ADC-CTC-19.wtldev.net', 'WTL-ADC-CTC-20.wtldev.net', 'WTL-ADC-CTC-21.wtldev.net', 'WTL-ADC-CTC-22.wtldev.net', 'WTL-ADC-CTC-23.wtldev.net', 'WTL-ADC-CTC-24.wtldev.net', 'WTL-ADC-CTC-25.wtldev.net', 'WTL-ADC-CTC-26.wtldev.net', 'WTL-ADC-CTC-27.wtldev.net', 'WTL-ADC-CTC-28.wtldev.net', 'WTL-ADC-CTC-29.wtldev.net', 'WTL-ADC-CTC-30.wtldev.net', 'WTL-ADC-CTC-31.wtldev.net', 'WTL-ADC-CTC-32.wtldev.net')
#$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net')

$DBparams = @{DBName = 'wtl-hpx-325-m01' ; DBUser = 'sa' ; DBPassword = 'ImagineDB1'}
$WannaRemove = 0  # top priority
$InstallAppVersion = '5.10.4.1'

$CredsLocal = [System.Management.Automation.PSCredential]::new('local\imagineLocal',(ConvertTo-SecureString -AsPlainText $env:imgLocPW -Force))
$CredsDomain = [System.Management.Automation.PSCredential]::new('wtldev.net\vadc',(ConvertTo-SecureString -AsPlainText $env:VADC_PASSWORD -Force))
$BuildsFolder = '\\wtlnas5\Public\Releases\ADC\ADC Services'
$wtlnas1PSFolder = '\\wtlnas1\public\ADC\PS'
Write-Host "$(if ($WannaRemove){"Removing"} else {"Installing"}) ADC Services $InstallAppVersion... Please wait..."

# main PS remote procedure
Invoke-Command -ComputerName $CTC -ArgumentList $InstallAppVersion, $CredsLocal, $CredsDomain, $BuildsFolder, $wtlnas1PSFolder, $DBparams, $WannaRemove -Credential $CredsDomain {
    param ( $InstallAppVersion, [PSCredential] $CredsLocal, [PSCredential] $CredsDomain, $BuildsFolder, $wtlnas1PSFolder, $DBparams, $WannaRemove )
    $HostName = "$(HOSTNAME.EXE)"
    $IPaddress = Get-NetIPAddress | Where-Object {$_.AddressState -eq "Preferred" -and $_.ValidLifetime -lt "24:00:00"} | Select-Object -ExpandProperty IPAddress
    $Report = "$HostName ($IPaddress)"
    function GD {Get-Date -Format 'yyyy-MM-dd HH:mm:ss -'}
    function Set-Drive {
        $Report += "`n`t $(GD) Creating PSDrives:"
        try {
            $Report += "`n`t`t '$BuildsFolder'"
            New-PSDrive -Name B -PSProvider FileSystem -Root $BuildsFolder -Credential $CredsDomain -Scope Global -ErrorAction Stop | Out-Null
            $Report += " - Done"
        }
        catch { $Report += "`n`t`t Error: $_" }
        try {
            $Report += "`n`t`t '$wtlnas1PSFolder'"
            New-PSDrive -Name P -PSProvider FileSystem -Root $wtlnas1PSFolder -Credential $CredsDomain -Scope Global -ErrorAction Stop | Out-Null
            $Report += " - Done"
        }
        catch { $Report += "`n`t`t Error: $_" }
        return $Report
    }
    function Copy-Installer {
        param ($Version = $InstallAppVersion)
        $Report = ""
        try { if (-not (Get-ChildItem B: -ErrorAction Stop | Where-Object { $_.Name -match $Version }).Count) { Throw }
            $DistantFolderPath = ( Get-ChildItem B: -ErrorAction Stop | Where-Object { $_.Name -match $Version } | Select-Object -First 1 ).FullName
            try { $DistantFilePath = (Get-ChildItem $DistantFolderPath -ErrorAction Stop | Where-Object { $_.Name -match '^ADCServicesSetup.*exe' } | Select-Object -First 1).FullName
                try { Test-Path $DistantFilePath -ErrorAction Stop | Out-Null
                    try { New-Item "C:\temp" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
                        try { $Report += "`n`t $(GD) Copying ADC Services $Version installer into C:\temp - "
                            Copy-Item $DistantFilePath "C:\temp\" -ErrorAction Stop
                            $Report += "Done"
                        } catch { $Report += "`n`t $(GD) Error while copying the installer to 'C:\temp': $_" }
                    } catch { $Report += "`n`t $(GD) Error while creating C:\temp directory: $_" }
                } catch { $Report += "`n`t $(GD) Error while looking for the desired installer in '$DistantFolderPath': $_" }
            } catch { $Report += "`n`t $(GD) Error while getting files from '$DistantFolderPath': $_" }
        } catch { $Report += "`n`t $(GD) Error while searching for the appropriate folder for version $Version" }
        return $Report
    }
    function Stop-Services {
        $Report = ""
        $Services = Get-Service -Name 'ADC*' -ErrorAction SilentlyContinue
        if ( $Services.Status -contains 'Running' ) {  # Some ADC Services are running, stopping them
            $Report += "`n`t $(GD) Stopping ADC Services - "
            $Services | Set-Service -StartupType Disabled -ErrorAction SilentlyContinue ; Start-Sleep 1
            Get-Process -Name 'Harris.Automation.ADC.Services*' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue ; Start-Sleep 1
            Get-Process -Name 'Harris.Automation.ADC.Services*' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue ; Start-Sleep 1
            $Services  | Set-Service -StartupType Manual -ErrorAction SilentlyContinue ; Start-Sleep 1
            $Report += "Done"
        }        
        return $Report
    }
    function Install-Services {
        param ($Version = $InstallAppVersion)
        $Report = ""
        $File = Get-ChildItem 'C:\temp' | Where-Object { $_.Name -match 'ADCServicesSetup' -and $_.VersionInfo.ProductVersion -match $Version} | Select-Object -Last 1
        if ( $File ) {  # If there is an installer, prepare parameters and start removal
            $DBName = $DBparams.DBName ; $DBUser = $DBparams.DBUser ; $DBPassword = $DBparams.DBPassword
            $Parameters = "/s, /v`"/qn`" /v`"IS_SQLSERVER_SERVER=$DBName`" /v`"IS_SQLSERVER_USERNAME=$DBUser`" /v`"IS_SQLSERVER_PASSWORD=$DBPassword`" /v`"INSTALLLEVEL=101`" /v`"/l*v C:\ADCServicesInstaller.log`" /v`"REBOOT=ReallySuppress`""
            $Report += "`n`t $(GD) Installing $($File.VersionInfo.ProductName) $($File.VersionInfo.ProductVersion) - "
            Start-Process $File.FullName -ArgumentList $Parameters -Wait
            $Report += "Done"
        }
        else { $Report += "`n`t $(GD) Failed to install ADC Services $($InstalledApp.DisplayVersion) because there is no appropriate installer in C:\temp"}
        return $Report
    }
    function Remove-Services {
        param ($Version = $InstallAppVersion)
        $Report = ""
        if (Get-Service -Name 'ADC*' -ErrorAction SilentlyContinue) {
            $Report += Stop-Services
            $File = Get-ChildItem 'C:\temp' | Where-Object { $_.Name -match 'ADCServicesSetup' -and $_.VersionInfo.ProductVersion -match $Version} | Select-Object -Last 1
            if ( $File ) {  # If there is an installer, prepare parameters and start removal
                $Parameters = "/x /s, /v`"/qn`" /v`"DELETEDB=No`" /v`"REBOOT=ReallySuppress`"" # parameters for removing ADC Services
                $Report += "`n`t $(GD) Removing $($File.VersionInfo.ProductName) $($File.VersionInfo.ProductVersion) - "
                Start-Process $File.FullName -ArgumentList $Parameters -Wait
                $Report += "Done"
                #Stop-Process -Name ADC1000NT -Force ; Start-Sleep 1
                #$Report += "`n`t $(GD) Restarting the computer..."
                #Restart-Computer -Force
            }
            else { $Report += "`n`t $(GD) Failed to remove ADC Services $($InstalledApp.DisplayVersion) because there is no appropriate installer in C:\temp"}
        }
        else { $Report += "`n`t $(GD) Failed to remove ADC Services $($InstalledApp.DisplayVersion) because ADC Services are not found in the system"}
        return $Report
    }
    function Set-Configs {
        $Report = ""
        $Report = "`n`t $(GD) Copying ADC Services config files, rules and license - "
        Get-ChildItem 'P:\resources\CTC Services Refs' | Where-Object {$_.Name -match '.*CTCRef.xml'} | ForEach-Object { 
            (Get-Content $_.FullName) -replace '#NUM',$HostName.Replace('WTL-ADC-CTC-','') -replace '#ADDRESS',$IPaddress -replace '#DBName',$DBparams.DBName -replace '#DBUser',$DBparams.DBUser -replace '#DBPassword',$DBparams.DBPassword |
            Out-File "C:\Program Files (x86)\Imagine Communications\ADC Services\config\$($_.Name -replace 'CTCRef')"  -Encoding utf8 -Force
        }
        New-Item -Path 'C:\Program Files (x86)\Imagine Communications\ADC Services\rules' -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
        New-Item -Path 'C:\Program Files (x86)\Imagine Communications\ADC Services\license' -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
        Copy-Item 'P:\resources\ADCLicense.lic' 'C:\Program Files (x86)\Imagine Communications\ADC Services\license' -Force
        Copy-Item 'P:\resources\PlaylistTranslator.Rule.xml' 'C:\Program Files (x86)\Imagine Communications\ADC Services\rules' -Force
        Copy-Item 'P:\resources\Harris.Automation.ADC.Services.IntegrationServiceHost.exe.config' 'C:\Program Files (x86)\Imagine Communications\ADC Services' -Force
        $Report += "Done"
        return $Report
    }

    # check which ADC Services are already installed, if any
    $InstalledApp = (Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.displayname -like "ADC Services"})
    $Report += Set-Drive
    Import-Module "\\wtlnas1\public\ADC\PS\scripts\Compare-ADCVersions.psm1"

    if ( $WannaRemove ) {
        $Report += Copy-Installer       # search for and copy the ADC Services installer
        $Report += Remove-Services      # stop and remove ADC Services
    }
    elseif ( -not $InstalledApp ) {  # there is no ADC Services installed, so install them
        $Report += Copy-Installer
        $Report += Install-Services
        $Report += Stop-Services
        $Report += Set-Configs
    }
    elseif ( $InstallAppVersion -match $InstalledApp.DisplayVersion ) {  # we already have the same version installed
        $Report += "`n`t $(GD) $($InstalledApp.DisplayName) $($InstalledApp.DisplayVersion) is already installed."
        $Report += Stop-Services
        $Report += Set-Configs
    }
    elseif ( Compare-ADCVersions -Version1 $InstallAppVersion -Version2 $InstalledApp.DisplayVersion ) {  # we have older version installed, so try to upgrade
        $Report += "`n`t $(GD) $($InstalledApp.DisplayName) $($InstalledApp.DisplayVersion) is installed, upgrading to $($InstallAppVersion)"
        $Report += Copy-Installer
        $Report += Stop-Services
        $Report += Install-Services
        $Report += Set-Configs
    } 
    else { $Report += "`n`t $(GD) Don't know what else))" }


    #$Report += "`n`t Returning so far"
    Write-Host "$Report" -f ( 1, 2, 3, 5, 6, 9, 10, 11, 13, 14 )[ ( $HostName.Split('-')[-1] ) % 10 ]  # Choose the color as a remainder of dividing the name number part by 10 (number of color variants)
}