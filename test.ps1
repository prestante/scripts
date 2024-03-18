#$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net', 'WTL-ADC-CTC-03.wtldev.net', 'WTL-ADC-CTC-04.wtldev.net', 'WTL-ADC-CTC-05.wtldev.net', 'WTL-ADC-CTC-06.wtldev.net', 'WTL-ADC-CTC-07.wtldev.net', 'WTL-ADC-CTC-08.wtldev.net', 'WTL-ADC-CTC-09.wtldev.net', 'WTL-ADC-CTC-10.wtldev.net', 'WTL-ADC-CTC-11.wtldev.net', 'WTL-ADC-CTC-12.wtldev.net', 'WTL-ADC-CTC-13.wtldev.net', 'WTL-ADC-CTC-14.wtldev.net', 'WTL-ADC-CTC-15.wtldev.net', 'WTL-ADC-CTC-16.wtldev.net', 'WTL-ADC-CTC-17.wtldev.net', 'WTL-ADC-CTC-18.wtldev.net', 'WTL-ADC-CTC-19.wtldev.net', 'WTL-ADC-CTC-20.wtldev.net', 'WTL-ADC-CTC-21.wtldev.net', 'WTL-ADC-CTC-22.wtldev.net', 'WTL-ADC-CTC-23.wtldev.net', 'WTL-ADC-CTC-24.wtldev.net', 'WTL-ADC-CTC-25.wtldev.net', 'WTL-ADC-CTC-26.wtldev.net', 'WTL-ADC-CTC-27.wtldev.net', 'WTL-ADC-CTC-28.wtldev.net', 'WTL-ADC-CTC-29.wtldev.net', 'WTL-ADC-CTC-30.wtldev.net', 'WTL-ADC-CTC-31.wtldev.net', 'WTL-ADC-CTC-32.wtldev.net')
$CTC = @('WTL-ADC-CTC-01.wtldev.net')
$WannaRemove = 0  # top priority
$InstallAppVersion = '5.9.10.1'
$DBparams = @{DBName = 'wtl-hpx-325-m01' ; DBUser = 'sa' ; DBPassword = 'ImagineDB1'}

$CredsLocal = [System.Management.Automation.PSCredential]::new('local\imagineLocal',(ConvertTo-SecureString -AsPlainText $env:imgLocPW -Force))
$CredsDomain = [System.Management.Automation.PSCredential]::new('wtldev.net\vadc',(ConvertTo-SecureString -AsPlainText $env:vPW -Force))
$BuildsFolder = '\\wtlnas5\Public\Releases\ADC\ADC Services'
$wtlnas1PSFolder = '\\wtlnas1\public\ADC\PS'
Write-Host "Please wait.."

# main PS remote procedure
Invoke-Command -ComputerName $CTC -ArgumentList $InstallAppVersion, $CredsLocal, $CredsDomain, $BuildsFolder, $wtlnas1PSFolder, $DBparams, $WannaRemove -Credential $CredsDomain {
    param ( $InstallAppVersion, [PSCredential] $CredsLocal, [PSCredential] $CredsDomain, $BuildsFolder, $wtlnas1PSFolder, $DBparams, $WannaRemove )
    $HostName = "$(HOSTNAME.EXE)"
    $IPaddress = Get-NetIPAddress | Where-Object {$_.AddressState -eq "Preferred" -and $_.ValidLifetime -lt "24:00:00"} | Select-Object -ExpandProperty IPAddress
    $Report = "$HostName ($IPaddress)"
    function Set-Drive {
        $Report = "`n`t Creating PSDrives:"
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
        $Report = ''
        try { if (-not (Get-ChildItem B: -ErrorAction Stop | Where-Object { $_.Name -match $InstallAppVersion }).Count) { Throw }
            $DistantFolderPath = ( Get-ChildItem B: -ErrorAction Stop | Where-Object { $_.Name -match $InstallAppVersion } | Select-Object -First 1 ).FullName
            try { $DistantFilePath = (Get-ChildItem $DistantFolderPath -ErrorAction Stop | Where-Object { $_.Name -match '^ADCServicesSetup.*exe' } | Select-Object -First 1).FullName
                try { Test-Path $DistantFilePath -ErrorAction Stop | Out-Null
                    try { New-Item "C:\temp" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
                        try { $Report += "`n`t Copy ADC Services $InstallAppVersion installer into C:\temp - "
                            Copy-Item $DistantFilePath "C:\temp\" -ErrorAction Stop
                            $Report += "Done"
                        } catch { $Report += "`n`t Error while copying the installer to 'C:\temp': $_" }
                    } catch { $Report += "`n`t Error while creating C:\temp directory: $_" }
                } catch { $Report += "`n`t Error while looking for the desired installer in '$DistantFolderPath': $_" }
            } catch { $Report += "`n`t Error while getting files from '$DistantFolderPath': $_" }
        } catch { $Report += "`n`t Error while searching for the appropriate folder for version $InstallAppVersion" }
        return $Report
    }
    function Install-Services {
        $Report = ''
        $File = Get-ChildItem 'C:\temp' | Where-Object { $_.Name -match 'ADCServicesSetup' -and $_.VersionInfo.ProductVersion -match $InstallAppVersion} | Select-Object -Last 1
        if ( $File ) {  # If there is an installer, prepare parameters and start removal
            $DBName = $DBparams.DBName ; $DBUser = $DBparams.DBUser ; $DBPassword = $DBparams.DBPassword
            $Parameters = "/s, /v`"/qn`" /v`"IS_SQLSERVER_SERVER=$DBName`" /v`"IS_SQLSERVER_USERNAME=$DBUser`" /v`"IS_SQLSERVER_PASSWORD=$DBPassword`" /v`"INSTALLLEVEL=101`" /v`"/l*v C:\ADCServicesInstaller.log`" /v`"REBOOT=ReallySuppress`""
            $Report += "`n`t Installing $($File.VersionInfo.ProductName) $($File.VersionInfo.ProductVersion) - "
            Start-Process $File.FullName -ArgumentList $Parameters -Wait
            $Report += "Done"
        }
        else { $Report += "Fail`n`t Cannot install ADC Services $($InstalledApp.DisplayVersion) because there is no appropriate installer in C:\temp"}
        return $Report
    }
    function Remove-Services {
        $Report = ''
        $Services = Get-Service -Name 'ADC*' -ErrorAction SilentlyContinue
        if ($Services) {
            if ( $Services.Status -contains 'Running' ) {  # Some ADC Services are running, stopping them
                $Report += "`n`t Stopping ADC Services - "
                $Services | Set-Service -StartupType Disabled -ErrorAction SilentlyContinue ; Start-Sleep 1
                Get-Process -Name 'Harris.Automation.ADC.Services*' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue ; Start-Sleep 1
                Get-Process -Name 'Harris.Automation.ADC.Services*' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue ; Start-Sleep 1
                $Services  | Set-Service -StartupType Manual -ErrorAction SilentlyContinue ; Start-Sleep 1
                $Report += "Done"
            }
            $File = Get-ChildItem 'C:\temp' | Where-Object { $_.Name -match 'ADCServicesSetup' -and $_.VersionInfo.ProductVersion -match $InstallAppVersion} | Select-Object -Last 1
            if ( $File ) {  # If there is an installer, prepare parameters and start removal
                $Parameters = "/x /s, /v`"/qn`" /v`"DELETEDB=No`" /v`"REBOOT=ReallySuppress`"" # parameters for removing ADC Services
                $Report += "`n`t Removing $($File.VersionInfo.ProductName) $($File.VersionInfo.ProductVersion) - "
                Start-Process $File.FullName -ArgumentList $Parameters -Wait
                $Report += "Done"
            }
            else { $Report += "`n`t Cannot remove ADC Services $($InstalledApp.DisplayVersion) because there is no appropriate installer in C:\temp"}
        }
        else { $Report += "`n`t Cannot remove ADC Services $($InstalledApp.DisplayVersion) because ADC Services are not found in a system"}
        return $Report
    }
    function Set-Configs {
        # copy ref files to C:\temp       TRY TO CREATE CONFIG FILES READING AND CHANGING THEM ON THE FLY
        Get-ChildItem 'P:\resources\CTC Services Refs' | Where-Object {$_.Name -match '.*CTCRef.xml'} | ForEach-Object { 
            (Get-Content $_.FullName) -replace '#NUM',$HostName.Replace('WTL-ADC-CTC-','') -replace '#ADDRESS',$IPaddress -replace '#DBName',$DBparams.DBName -replace '#DBUser',$DBparams.DBUser -replace '#DBPassword',$DBparams.DBPassword |
            Out-File "C:\Program Files (x86)\Imagine Communications\ADC Services\config\$($_.Name -replace 'CTCRef')"  -Encoding utf8 -Force
        }
        # create rules and license directories  TRY TO CREATE FOLDERS BY THE SAME COMMAND AS COPY FILES
        #New-Item -Path 'C:\Program Files (x86)\Imagine Communications\ADC Services\rules' -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
        #New-Item -Path 'C:\Program Files (x86)\Imagine Communications\ADC Services\license' -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
        # copy license, rule and IntegrationServiceHost.exe.config
        Copy-Item 'P:\resources\ADCLicense.lic' 'C:\Program Files (x86)\Imagine Communications\ADC Services\license' -Force
        Copy-Item 'P:\resources\PlaylistTranslator.Rule.xml' 'C:\Program Files (x86)\Imagine Communications\ADC Services\rules' -Force
        Copy-Item 'P:\resources\Harris.Automation.ADC.Services.IntegrationServiceHost.exe.config' 'C:\Program Files (x86)\Imagine Communications\ADC Services' -Force
    }

    # check which ADC Services are already installed, if any
    $InstalledApp = (Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.displayname -like "ADC Services"})

    if ( $WannaRemove ) {
        $Report += Set-Drive            # prepare PS drives for builds and PS shared folders
        $Report += Copy-Installer       # search for and copy the ADC Services installer
        $Report += Remove-Services      # stop and remove ADC Services
    }
    elseif ( -not $InstalledApp ) {  # there is no ADC Services installed, so install them
        $Report += Set-Drive
        $Report += Copy-Installer
        $Report += Install-Services
    }
    elseif ( $InstalledApp.DisplayVersion -match $InstallAppVersion ) {  # we already have the same version installed
        $Report += "`n`t $($InstalledApp.DisplayName) $($InstalledApp.DisplayVersion) is already installed."
    }
    elseif ( $InstallAppVersion -notmatch $InstallAppVersion ) {  # we have other version installed, so try to upgrade or find, copy and run a corresponding installer to delete
        $Report += "`n`t $($InstalledApp.DisplayName) $($InstalledApp.DisplayVersion) is installed, upgrading to $($InstallAppVersion) - "
    } 
    else { $Report += "`n`t Don't know what else))" }

    Set-Configs

    #$Report += "`n`t Returning so far"
    Write-Host "$Report" -f ( 1, 2, 3, 5, 6, 9, 10, 11, 13, 14 )[ ( $HostName.Split('-')[-1] ) % 10 ]  # Choose the color as a remainder of dividing the name number part by 10 (number of color variants)
}