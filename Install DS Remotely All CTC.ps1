#$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net', 'WTL-ADC-CTC-03.wtldev.net', 'WTL-ADC-CTC-04.wtldev.net', 'WTL-ADC-CTC-05.wtldev.net', 'WTL-ADC-CTC-06.wtldev.net', 'WTL-ADC-CTC-07.wtldev.net', 'WTL-ADC-CTC-08.wtldev.net', 'WTL-ADC-CTC-09.wtldev.net', 'WTL-ADC-CTC-10.wtldev.net', 'WTL-ADC-CTC-11.wtldev.net', 'WTL-ADC-CTC-12.wtldev.net', 'WTL-ADC-CTC-13.wtldev.net', 'WTL-ADC-CTC-14.wtldev.net', 'WTL-ADC-CTC-15.wtldev.net', 'WTL-ADC-CTC-16.wtldev.net', 'WTL-ADC-CTC-17.wtldev.net', 'WTL-ADC-CTC-18.wtldev.net', 'WTL-ADC-CTC-19.wtldev.net', 'WTL-ADC-CTC-20.wtldev.net', 'WTL-ADC-CTC-21.wtldev.net', 'WTL-ADC-CTC-22.wtldev.net', 'WTL-ADC-CTC-23.wtldev.net', 'WTL-ADC-CTC-24.wtldev.net', 'WTL-ADC-CTC-25.wtldev.net', 'WTL-ADC-CTC-26.wtldev.net', 'WTL-ADC-CTC-27.wtldev.net', 'WTL-ADC-CTC-28.wtldev.net', 'WTL-ADC-CTC-29.wtldev.net', 'WTL-ADC-CTC-30.wtldev.net', 'WTL-ADC-CTC-31.wtldev.net', 'WTL-ADC-CTC-32.wtldev.net')
$CTC = @('WTL-ADC-CTC-01.wtldev.net')
$InstallAppVersion = '12.29.19'
#$InstallAppVersion = Read-Host "Install what DS version?"
#If ( $InstallAppVersion -notmatch '^\d{1,2}\.\d{1,2}\.\d{1,2}$' ) { Write-Host "Wrong DS Version: $InstallAppVersion`nIt should be like 12.29.19" -f Red ; return }

$CredsLocal = [System.Management.Automation.PSCredential]::new('local\imagineLocal',(ConvertTo-SecureString -AsPlainText $env:imgLocPW -Force))
$CredsDomain = [System.Management.Automation.PSCredential]::new('wtldev.net\vadc',(ConvertTo-SecureString -AsPlainText $env:vPW -Force))
$BuildsFolder = '\\wtlnas5.wtldev.net\Public\Releases\ADC\ADC1000\QATEST'
$wtlnas1PSFolder = '\\wtlnas1\public\ADC\PS'
Write-Host "Please wait.."

Invoke-Command -ComputerName $CTC -ArgumentList $InstallAppVersion, $CredsLocal, $CredsDomain, $BuildsFolder, $wtlnas1PSFolder -Credential $CredsDomain {
    param ( $InstallAppVersion, [PSCredential] $CredsLocal, [PSCredential] $CredsDomain, $BuildsFolder, $wtlnas1PSFolder )
    $HostName = "$(HOSTNAME.EXE)"
    $IPaddress = Get-NetIPAddress | Where-Object {$_.AddressState -eq "Preferred" -and $_.ValidLifetime -lt "24:00:00"} | Select-Object -ExpandProperty IPAddress
    $Report = "$HostName ($IPaddress)"

    $Report += "`n`t Creating PSDrives:"
    try {
        $Report += "`n`t`t '$BuildsFolder'"
        New-PSDrive -Name B -PSProvider FileSystem -Root $BuildsFolder -Credential $CredsDomain -ErrorAction Stop | Out-Null
        $Report += " - Done"
    }
    catch { $Report += "`n`t`t Error: $_" }
    try {
        $Report += "`n`t`t '$wtlnas1PSFolder'"
        New-PSDrive -Name P -PSProvider FileSystem -Root $wtlnas1PSFolder -Credential $CredsDomain -ErrorAction Stop | Out-Null
        $Report += " - Done"
    }
    catch { $Report += "`n`t`t Error: $_" }

    # prepare device server installator with parameters
    try { if (-not (Get-ChildItem B: -ErrorAction Stop | Where-Object { $_.Name -match $InstallAppVersion }).Count) { Throw }
        $DistantFolderPath = ( Get-ChildItem B: -ErrorAction Stop | Where-Object { $_.Name -match $InstallAppVersion } | Select-Object -First 1 ).FullName + "\Standard"
        try { $DistantFilePath = (Get-ChildItem $DistantFolderPath -ErrorAction Stop | Where-Object { $_.Name -match '^SERVER_QATEST' } | Select-Object -First 1).FullName
            try { Test-Path $DistantFilePath -ErrorAction Stop | Out-Null
                try { $File = Copy-Item $DistantFilePath "C:\temp\" -PassThru -ErrorAction Stop }
                catch { $Report += "`n`t Error while copying the installer to 'C:\temp': $_" }
            } catch { $Report += "`n`t Error while looking for the desired installer in '$DistantFolderPath': $_" }
        } catch { $Report += "`n`t Error while getting files from '$DistantFolderPath': $_" }
    } catch { $Report += "`n`t Error while searching for the appropriate folder for version $InstallAppVersion" }
    $InstallPath = 'C:\server\'
    $DSName = $HostName -replace 'WTL-ADC-'
    $DSNum = $HostName -replace 'WTL-ADC-CTC-'
    $Parameters = "\s \server`"$DSName`""  # \s means silent install
    #if ( Get-Process ADC1000NT -ErrorAction SilentlyContinue | Stop-Process -Force -PassThru ) { $Report += "`n`t Stopping ADC1000NT process" }

    # stop running DS and delete all installed DS
    Import-Module "P:\scripts\Get-ADC.psm1", "P:\scripts\Remove-ADC.psm1"
    $AllDS = (Get-ADC).AllDS
    if ( $AllDS ) { $Report += "`n`t $(Remove-ADC -toDelete $AllDS)" }

    # run installation
    $Report += "`n`t Installing $($File.VersionInfo.ProductName) $($File.VersionInfo.ProductVersion)"
    Start-Process $File.FullName -ArgumentList $Parameters -Wait
    ( Get-Content 'P:\resources\ADC1000NT-CTC-1-list.INI' ) -replace 'DDsk\d+', "Dsk$DSNum" | Out-File "$InstallPath\ADC1000NT.INI" -Encoding ascii -Force  # Change Name and IDMatchName DDsk00 to Dsk01 for CTC-01, Dsk02 for CTC-02 and so on
    ( Get-Content 'P:\resources\LISTCONF-CTC-1-list.INI' ) -replace 'CTC-00', $DSName | Out-File "$InstallPath\LISTCONF.INI" -Encoding ascii -Force
    $Report += " - Done"

    $Report += "`n`t Removing PSDrives" ; Remove-PSDrive -Name B ; Remove-PSDrive -Name P ; $Report += " - Done"
    Write-Host "$Report" -f ( 1, 2, 3, 5, 6, 9, 10, 11, 13, 14 )[ ( $HostName.Split('-')[-1] ) % 10 ]  # Choose the color as a remainder of dividing the name number part by 10 (number of color variants)
}
