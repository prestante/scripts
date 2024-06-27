$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net', 'WTL-ADC-CTC-03.wtldev.net', 'WTL-ADC-CTC-04.wtldev.net', 'WTL-ADC-CTC-05.wtldev.net', 'WTL-ADC-CTC-06.wtldev.net', 'WTL-ADC-CTC-07.wtldev.net', 'WTL-ADC-CTC-08.wtldev.net', 'WTL-ADC-CTC-09.wtldev.net', 'WTL-ADC-CTC-10.wtldev.net', 'WTL-ADC-CTC-11.wtldev.net', 'WTL-ADC-CTC-12.wtldev.net', 'WTL-ADC-CTC-13.wtldev.net', 'WTL-ADC-CTC-14.wtldev.net', 'WTL-ADC-CTC-15.wtldev.net', 'WTL-ADC-CTC-16.wtldev.net', 'WTL-ADC-CTC-17.wtldev.net', 'WTL-ADC-CTC-18.wtldev.net', 'WTL-ADC-CTC-19.wtldev.net', 'WTL-ADC-CTC-20.wtldev.net', 'WTL-ADC-CTC-21.wtldev.net', 'WTL-ADC-CTC-22.wtldev.net', 'WTL-ADC-CTC-23.wtldev.net', 'WTL-ADC-CTC-24.wtldev.net', 'WTL-ADC-CTC-25.wtldev.net', 'WTL-ADC-CTC-26.wtldev.net', 'WTL-ADC-CTC-27.wtldev.net', 'WTL-ADC-CTC-28.wtldev.net', 'WTL-ADC-CTC-29.wtldev.net', 'WTL-ADC-CTC-30.wtldev.net', 'WTL-ADC-CTC-31.wtldev.net', 'WTL-ADC-CTC-32.wtldev.net')
#$CTC = @('WTL-ADC-CTC-01.wtldev.net')

$CredsLocal = [System.Management.Automation.PSCredential]::new('local\imagineLocal',(ConvertTo-SecureString -AsPlainText $env:imgLocPW -Force))
$CredsDomain = [System.Management.Automation.PSCredential]::new('wtldev.net\vadc',(ConvertTo-SecureString -AsPlainText $env:vPW -Force))
$BuildsFolder = '\\wtlnas5.wtldev.net\Public\Releases\ADC\ADC1000\QATEST'
$wtlnas1PSFolder = '\\wtlnas1\public\ADC\PS'

# main PS remote procedure
Invoke-Command -ComputerName $CTC -ArgumentList $InstallAppVersion, $CredsLocal, $CredsDomain, $BuildsFolder, $wtlnas1PSFolder -Credential $CredsDomain {
    param ( $InstallAppVersion, [PSCredential] $CredsLocal, [PSCredential] $CredsDomain, $BuildsFolder, $wtlnas1PSFolder )
    $HostName = "$(HOSTNAME.EXE)"
    $IPaddress = Get-NetIPAddress | Where-Object {$_.AddressState -eq "Preferred" -and $_.ValidLifetime -lt "24:00:00"} | Select-Object -ExpandProperty IPAddress
    $Report = "$HostName ($IPaddress)"
    $DSNum = [int]($HostName -replace 'WTL-ADC-CTC-')

    # prepare PS drives for builds and PS shared folders
    try {
        $Report += "`n`t`t '$wtlnas1PSFolder'"
        New-PSDrive -Name P -PSProvider FileSystem -Root $wtlnas1PSFolder -Credential $CredsDomain -ErrorAction Stop | Out-Null
        $Report += " - Done"
    }
    catch { $Report += "`n`t`t Error: $_" }
    
    # stop running DS
    if ( Get-Process ADC1000NT -ErrorAction SilentlyContinue | Stop-Process -Force -PassThru ) { $Report += "`n`t Stopping ADC1000NT process" }

    # change original .exe to multi server .exe if not yet done
    if ( -not ( Get-Item "C:\server\ADC1000NT.exe.orig" -ErrorAction SilentlyContinue ) ) {
        $Report += "`n`t Backing up the original server to ADC1000NT.exe.orig"
        Move-Item "C:\server\ADC1000NT.exe" "C:\server\ADC1000NT.exe.orig"
    }

    # copy multi server ADC1000NT.exe to C:\server
    $Report += "`n`t Copying multi server ADC1000NT.exe to C:\server"
    Copy-Item "P:\resources\ADC 12.29.21 Multi DS and AC\ADC1000NT.exe" "C:\server" -Force

    # copy default NETWORK.INI from network resources to C:\server
    $Report += "`n`t Copying NETWORK.INI to C:\server"
    Copy-Item "P:\resources\NETWORK.INI" "C:\server" -Force

    # remove HANDLES.INI from C:\server
    $Report += "Removing HANDLES.INI from C:\server"
    Remove-Item "C:\server\HANDLES.INI" -Force -ErrorAction SilentlyContinue

    # remove server2 and server3 folders if any
    $Report += "`n`t Removing server2 and server3 folders forcefully"
    Remove-Item "C:\server2" -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item "C:\server3" -Force -Recurse -ErrorAction SilentlyContinue
    
    # create server2 and server3 by copying it from C:\server
    $Report += "`n`t Copying server to server2 and server3"
    Copy-Item "C:\server" "C:\server2" -Recurse -Force
    Copy-Item "C:\server" "C:\server3" -Recurse -Force
    ( Get-Content 'C:\server2\NETWORK.INI' ) -replace '47125', "47126" | Out-File "C:\server2\NETWORK.INI" -Encoding ascii -Force  # Change port to escape port conflict
    ( Get-Content 'C:\server3\NETWORK.INI' ) -replace '47125', "47127" | Out-File "C:\server3\NETWORK.INI" -Encoding ascii -Force  # Change port to escape port conflict
    $shortcut2 = (New-Object -ComObject WScript.Shell).CreateShortcut("C:\Users\Public\Desktop\server2.lnk")
    $shortcut3 = (New-Object -ComObject WScript.Shell).CreateShortcut("C:\Users\Public\Desktop\server3.lnk")
    $shortcut2.TargetPath = "C:\server2\ADC1000NT.exe"
    $shortcut3.TargetPath = "C:\server3\ADC1000NT.exe"
    $shortcut2.Arguments = "CTC-$($DSNum+32)"
    $shortcut3.Arguments = "CTC-$($DSNum+64)"
    $shortcut2.Save()
    $shortcut3.Save()
    $Report += " - Done"

    $Report += "`n`t Removing PSDrives" ; Remove-PSDrive -Name P ; $Report += " - Done"
    Write-Host "$Report" -f ( 1, 2, 3, 5, 6, 9, 10, 11, 13, 14 )[ ( $HostName.Split('-')[-1] ) % 10 ]  # Choose the color as a remainder of dividing the name number part by 10 (number of color variants)
}
