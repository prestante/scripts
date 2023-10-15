$CTC = @('wtl-hp3b8-vds1.wtldev.net','wtl-hp3b8-vds2.wtldev.net','wtl-hp3b8-vds3.wtldev.net','wtl-hp3b8-vds4.wtldev.net','wtl-hp3b8-vds5.wtldev.net','wtl-hp3b8-vds6.wtldev.net','wtl-hp3b8-vds7.wtldev.net','wtl-hp3b8-vds8.wtldev.net','wtl-hp3b8-vds9.wtldev.net','wtl-hp3b8-vds10.wtldev.net','wtl-hp3b9-vds1.wtldev.net','wtl-hp3b9-vds2.wtldev.net','wtl-hp3b9-vds3.wtldev.net','wtl-hp3b9-vds4.wtldev.net','wtl-hp3b9-vds5.wtldev.net','wtl-hp3b9-vds6.wtldev.net','wtl-hp3b9-vds7.wtldev.net','wtl-hp3b9-vds8.wtldev.net','wtl-hp3b9-vds9.wtldev.net','wtl-hp3b9-vds10.wtldev.net')
$CTC = @('wtl-hp3b9-vds6.wtldev.net')
$CTC = @('wtl-hpx-325-n01.wtldev.net','wtl-hpx-325-n02.wtldev.net','wtl-hpx-325-m01.wtldev.net','wtl-hpx-325-m02.wtldev.net')

$pass = ConvertTo-SecureString -String '01000000d08c9ddf0115d1118c7a00c04fc297eb010000007c87033a3f02f847a3f4d44805ffa55b0000000002000000000003660000c000000010000000aa4bb3e813a3281af0fc4c14f844adfd0000000004800000a000000010000000872646a5dfd994f49500eb831518deb820000000381f88ed6d9764b2a0a5575455b39b3d90f97981cd7338bb504279ab9bf77f87140000005782fcc9c5411d027b5b0d1ae7463094e75774f5'

Invoke-Command $CTC -Credential ([System.Management.Automation.PSCredential]::new('agalkovs',$pass)) -ScriptBlock {
    $address = 'wtl-hp3b7-plc1.wtldev.net'
    $domain = $address -replace '.*\.(\w+\.\w+$)','$1'
    $place = $address -replace '(.*)\.\w+\.\w+$','$1'
    $registryPaths = @()
    $registryPaths += "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\EscDomains"
    $registryPaths += "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains"

    $name2 = "file"
    $value2 = 1

    foreach ($registryPath in $registryPaths) { 
        if (!(Test-Path $registryPath)) {New-Item -Path $registryPath -Force | Out-Null}
        if (!(Test-Path "$registryPath\$domain")) {New-Item -Path "$registryPath\$domain" -Force | Out-Null}
        if (!(Test-Path "$registryPath\$domain\$place")) {New-Item -Path "$registryPath\$domain\$place" -Force | Out-Null}
        if ((gi "$registryPath\$domain\$place").property -notcontains $name2) {New-ItemProperty -Path "$registryPath\$domain\$place" -Name $name2 -Value $value2 -PropertyType DWORD -Force | Out-Null}
    }

    #Restart-Computer -Force #it doesn't help by itself: need at least one manual login into the PC.
}