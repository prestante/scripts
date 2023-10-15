$CTC = @('WTL-HP3B8-VDS1.WTLDEV.NET','WTL-HP3B8-VDS2.WTLDEV.NET','WTL-HP3B8-VDS3.WTLDEV.NET','WTL-HP3B8-VDS4.WTLDEV.NET','WTL-HP3B8-VDS5.WTLDEV.NET','WTL-HP3B8-VDS6.WTLDEV.NET','WTL-HP3B8-VDS7.WTLDEV.NET','WTL-HP3B8-VDS8.WTLDEV.NET','WTL-HP3B8-VDS9.WTLDEV.NET','WTL-HP3B8-VDS10.WTLDEV.NET','WTL-HP3B9-VDS1.WTLDEV.NET','WTL-HP3B9-VDS2.WTLDEV.NET','WTL-HP3B9-VDS3.WTLDEV.NET','WTL-HP3B9-VDS4.WTLDEV.NET','WTL-HP3B9-VDS5.WTLDEV.NET','WTL-HP3B9-VDS6.WTLDEV.NET','WTL-HP3B9-VDS7.WTLDEV.NET','WTL-HP3B9-VDS8.WTLDEV.NET','WTL-HP3B9-VDS9.WTLDEV.NET','WTL-HP3B9-VDS10.WTLDEV.NET')
$CTC = @('WTL-HP3B8-VDS1.WTLDEV.NET')

$pass = ConvertTo-SecureString -String '01000000d08c9ddf0115d1118c7a00c04fc297eb010000007c87033a3f02f847a3f4d44805ffa55b0000000002000000000003660000c000000010000000aa4bb3e813a3281af0fc4c14f844adfd0000000004800000a000000010000000872646a5dfd994f49500eb831518deb820000000381f88ed6d9764b2a0a5575455b39b3d90f97981cd7338bb504279ab9bf77f87140000005782fcc9c5411d027b5b0d1ae7463094e75774f5'

Invoke-Command -ComputerName $CTC -ArgumentList $InstallAppVersion, $PrevAppVersion, $pass -ScriptBlock {
    #Starting all ADC Services except Aggregation

    function GD {Get-Date -Format 'yyyy-MM-dd HH:mm:ss - '}

    #Start-Service -Name 'ADCSecurityService', 'ADCManagerService'

    [System.Collections.Generic.List[PSObject]]$services = Get-Service -Name 'ADC*' | where {$_.DisplayName -notmatch 'Aggregation'}
    [System.Collections.Generic.List[PSObject]]$servicesInOrder = @()

    $services | where {$_.DisplayName -match 'Security'} | % {$servicesInOrder.Add($_)}
    $services | where {$_.DisplayName -match 'Data'} | % {$servicesInOrder.Add($_)}
    $services | where {$_.DisplayName -match 'Timecode'} | % {$servicesInOrder.Add($_)}
    $services | where {$_.DisplayName -match 'AsRun'} | % {$servicesInOrder.Add($_)}
    $services | where {$_.DisplayName -match 'Device'} | % {$servicesInOrder.Add($_)}
    $services | where {$_.DisplayName -match 'List'} | % {$servicesInOrder.Add($_)}
    $services | where {$_.DisplayName -match 'Error'} | % {$servicesInOrder.Add($_)}
    $services | 
     where {$_.DisplayName -notmatch 'Data'} |
     where {$_.DisplayName -notmatch 'Timecode'} |
     where {$_.DisplayName -notmatch 'AsRun'} | 
     where {$_.DisplayName -notmatch 'Device'} | 
     where {$_.DisplayName -notmatch 'List'} | 
     where {$_.DisplayName -notmatch 'Error'} | 
     where {$_.DisplayName -notmatch 'Synchro'} | 
     where {$_.DisplayName -notmatch 'Integra'} | 
     where {$_.DisplayName -notmatch 'Manager'} | 
     where {$_.DisplayName -notmatch 'Security'} | 
    % {$servicesInOrder.Add($_)}
    $services | where {$_.DisplayName -match 'Integra'} | % {$servicesInOrder.Add($_)}
    $services | where {$_.DisplayName -match 'Synchro'} | % {$servicesInOrder.Add($_)}
    $services | where {$_.DisplayName -match 'Manager'} | % {$servicesInOrder.Add($_)}

    $servicesInOrder | % {
        Write-Host "$(GD)Starting $($_.name -replace '(ADC)(.*)(Service)','$1 $2 $3')" -b Black -f Yellow
        Start-Service $_.name -WarningAction SilentlyContinue
    }

    Write-Host "Done" -b Black -f Green
    Sleep 2

    <#Write-Host "$(GD)Disabling Integration Service" -b Black -f Yellow
    Get-Service -Name 'ADCIntegrationService' | Set-Service -StartupType Disabled
    Start-Sleep 1

    Write-Host "$(GD)Stopping Integration Service process" -b Black -f Yellow
    Get-Process -Name 'Harris.Automation.ADC.Services.IntegrationServiceHost' -ea SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep 1
    Get-Process -Name 'Harris.Automation.ADC.Services.IntegrationServiceHost' -ea SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep 1

    Write-Host "$(GD)Enabling Integration Service" -b Black -f Yellow
    Get-Service -Name 'ADCIntegrationService' | Set-Service -StartupType Manual
    Start-Sleep 1

    Write-Host "Done" -b Black -f Green
    Sleep 2
    #>
}