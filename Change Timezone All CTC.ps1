$CTC = @('wtl-hp3b8-vds1.wtldev.net','wtl-hp3b8-vds2.wtldev.net','wtl-hp3b8-vds3.wtldev.net','wtl-hp3b8-vds4.wtldev.net','wtl-hp3b8-vds5.wtldev.net','wtl-hp3b8-vds6.wtldev.net','wtl-hp3b8-vds7.wtldev.net','wtl-hp3b8-vds8.wtldev.net','wtl-hp3b8-vds9.wtldev.net','wtl-hp3b8-vds10.wtldev.net','wtl-hp3b9-vds1.wtldev.net','wtl-hp3b9-vds2.wtldev.net','wtl-hp3b9-vds3.wtldev.net','wtl-hp3b9-vds4.wtldev.net','wtl-hp3b9-vds5.wtldev.net','wtl-hp3b9-vds6.wtldev.net','wtl-hp3b9-vds7.wtldev.net','wtl-hp3b9-vds8.wtldev.net','wtl-hp3b9-vds9.wtldev.net','wtl-hp3b9-vds10.wtldev.net')
#$CTC = @('wtl-hp3b8-vds1.wtldev.net')

$pass = ConvertTo-SecureString -String '01000000d08c9ddf0115d1118c7a00c04fc297eb010000007c87033a3f02f847a3f4d44805ffa55b0000000002000000000003660000c000000010000000aa4bb3e813a3281af0fc4c14f844adfd0000000004800000a000000010000000872646a5dfd994f49500eb831518deb820000000381f88ed6d9764b2a0a5575455b39b3d90f97981cd7338bb504279ab9bf77f87140000005782fcc9c5411d027b5b0d1ae7463094e75774f5'

Invoke-Command -ComputerName $CTC -ArgumentList $InstallAppVersion, $PrevAppVersion, $pass -ScriptBlock {
    Set-TimeZone -Id 'Russian Standard Time'
    Write-Host "$($env:COMPUTERNAME) - Done" -fo Green -ba Black
}

