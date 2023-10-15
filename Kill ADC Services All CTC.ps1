﻿$CTC = @('WTL-HP3B8-VDS1.WTLDEV.NET','WTL-HP3B8-VDS2.WTLDEV.NET','WTL-HP3B8-VDS3.WTLDEV.NET','WTL-HP3B8-VDS4.WTLDEV.NET','WTL-HP3B8-VDS5.WTLDEV.NET','WTL-HP3B8-VDS6.WTLDEV.NET','WTL-HP3B8-VDS7.WTLDEV.NET','WTL-HP3B8-VDS8.WTLDEV.NET','WTL-HP3B8-VDS9.WTLDEV.NET','WTL-HP3B8-VDS10.WTLDEV.NET','WTL-HP3B9-VDS1.WTLDEV.NET','WTL-HP3B9-VDS2.WTLDEV.NET','WTL-HP3B9-VDS3.WTLDEV.NET','WTL-HP3B9-VDS4.WTLDEV.NET','WTL-HP3B9-VDS5.WTLDEV.NET','WTL-HP3B9-VDS6.WTLDEV.NET','WTL-HP3B9-VDS7.WTLDEV.NET','WTL-HP3B9-VDS8.WTLDEV.NET','WTL-HP3B9-VDS9.WTLDEV.NET','WTL-HP3B9-VDS10.WTLDEV.NET')
$CTC = @('WTL-HP3B8-VDS1.WTLDEV.NET')

$pass = ConvertTo-SecureString -String '01000000d08c9ddf0115d1118c7a00c04fc297eb010000007c87033a3f02f847a3f4d44805ffa55b0000000002000000000003660000c000000010000000aa4bb3e813a3281af0fc4c14f844adfd0000000004800000a000000010000000872646a5dfd994f49500eb831518deb820000000381f88ed6d9764b2a0a5575455b39b3d90f97981cd7338bb504279ab9bf77f87140000005782fcc9c5411d027b5b0d1ae7463094e75774f5'

Invoke-Command -ComputerName $CTC -ArgumentList $InstallAppVersion, $PrevAppVersion, $pass -ScriptBlock {
    #Stopping all ADC Services except Aggregation

    function GD {Get-Date -Format 'yyyy-MM-dd HH:mm:ss - '}

    Write-Host "$(GD)Disabling ADC Services" -b Black -f Yellow
    Get-Service -Name 'ADC*' | Set-Service -StartupType Disabled
    Start-Sleep 1

    Write-Host "$(GD)Stopping ADC Services processes" -b Black -f Yellow
    Get-Process -Name 'Harris.Automation.ADC.Services*' | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep 1
    Get-Process -Name 'Harris.Automation.ADC.Services*' | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep 1

    Write-Host "$(GD)Enabling ADC Services" -b Black -f Yellow
    Get-Service -Name 'ADC*' | Set-Service -StartupType Manual
    Start-Sleep 1

    Write-Host "Done" -b Black -f Green
    Sleep 2
}