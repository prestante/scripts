#$CTC = @('WTL-ADC-CTC-01.WTLDEV.NET', 'WTL-ADC-CTC-02.WTLDEV.NET', 'WTL-ADC-CTC-03.WTLDEV.NET', 'WTL-ADC-CTC-04.WTLDEV.NET', 'WTL-ADC-CTC-05.WTLDEV.NET', 'WTL-ADC-CTC-06.WTLDEV.NET', 'WTL-ADC-CTC-07.WTLDEV.NET', 'WTL-ADC-CTC-08.WTLDEV.NET', 'WTL-ADC-CTC-09.WTLDEV.NET', 'WTL-ADC-CTC-10.WTLDEV.NET', 'WTL-ADC-CTC-11.WTLDEV.NET', 'WTL-ADC-CTC-12.WTLDEV.NET', 'WTL-ADC-CTC-13.WTLDEV.NET', 'WTL-ADC-CTC-14.WTLDEV.NET', 'WTL-ADC-CTC-15.WTLDEV.NET', 'WTL-ADC-CTC-16.WTLDEV.NET', 'WTL-ADC-CTC-17.WTLDEV.NET', 'WTL-ADC-CTC-18.WTLDEV.NET', 'WTL-ADC-CTC-19.WTLDEV.NET', 'WTL-ADC-CTC-20.WTLDEV.NET', 'WTL-ADC-CTC-21.WTLDEV.NET', 'WTL-ADC-CTC-22.WTLDEV.NET', 'WTL-ADC-CTC-23.WTLDEV.NET', 'WTL-ADC-CTC-24.WTLDEV.NET')
$CTC = @('WTL-ADC-CTC-01.WTLDEV.NET', 'WTL-ADC-CTC-02.WTLDEV.NET')

#$Creds = [System.Management.Automation.PSCredential]::new('wtldev.net\vadc',(ConvertTo-SecureString -AsPlainText '**********' -Force))
#$Key = ConvertFrom-SecureString $Creds.Password
$Creds = [System.Management.Automation.PSCredential]::new('wtldev.net\vadc',(ConvertTo-SecureString '01000000d08c9ddf0115d1118c7a00c04fc297eb01000000be6cfee0e75a0949ba2fdb6de1be94dc0000000002000000000003660000c0000000100000006db45abcaa44ac13ffe44bf2c7d3e36d0000000004800000a000000010000000401071773556c48f0e7e41965cbf42ac18000000978e0f16f904e10e1f5ebf3f7f4a9ac9868797e2d8af87ab1400000006ee747bf93bbf0be2c227e545d619d46e04fd3b'))

Invoke-Command -ComputerName $CTC -Credential $Creds {
    $report = "$(HOSTNAME.EXE):"

    # Copy \\wtlnas1 and \\wtlnas5 shortcuts to desktop
    $Creds = [System.Management.Automation.PSCredential]::new('wtldev.net\vadc',(ConvertTo-SecureString '01000000d08c9ddf0115d1118c7a00c04fc297eb010000009f66db1c1d1e7848b88b5f8ae4ba6c490000000002000000000003660000c000000010000000d6e57e6a4848208a6200222e5998baea0000000004800000a00000001000000077f50fb87b47fb35f49a831af787650e1800000083d2be68850f21b9607ac78a51c6b12bf6e4a6826bf8592e14000000800c89a6890c68b73e146b022522ffe2f6068c72'))
    New-PSDrive -Name "Z" -PSProvider FileSystem -Root "\\wtlnas1\Public\ADC\PS\resources" -Credential $Creds
    @(
        [PSCustomObject]@{name = "Releases ADC.lnk"; target = "$env:USERPROFILE\Desktop\"}
        [PSCustomObject]@{name = "WTLNAS1 ADC.lnk"; target = "$env:USERPROFILE\Desktop\"}
    ) | ForEach-Object {
        Copy-Item "Z:\$($_.name)" -Destination $_.target
        $report += "`n`tItem '$($_.name)' has been copied to '$($_.target)'"
    }
    Remove-PSDrive "Z"

    # Remove Run Warnings for \\wtlnas1 and \\wtlnas5
    @('wtlnas1.wtldev.net','wtlnas5.wtldev.net') | ForEach-Object {
        $domain = $_ -replace '.*\.(\w+\.\w+$)','$1'
        $place = $_ -replace '(.*)\.\w+\.\w+$','$1'
        $registryPaths = @(
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\EscDomains"
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains"
        )
        $name = "file"
        $value = 1
        foreach ($registryPath in $registryPaths) {
            if (!(Test-Path $registryPath)) {$item = $registryPath; New-Item -Path $item -Force | Out-Null; $report += "`n`tNew Registry Item:`t$item"}
            if (!(Test-Path "$registryPath\$domain")) {$item = "$registryPath\$domain"; New-Item -Path $item -Force | Out-Null; $report += "`n`tNew Registry Item:`t$item"}
            if (!(Test-Path "$registryPath\$domain\$place")) {$item = "$registryPath\$domain\$place"; New-Item -Path $item -Force | Out-Null; $report += "`n`tNew Registry Item:`t$item"}
            if ((Get-Item "$registryPath\$domain\$place").property -notcontains $name) {$item = "$registryPath\$domain\$place"; New-ItemProperty -Path $item -Name $name -Value $value -PropertyType DWORD -Force | Out-Null; $report += "`n`tNew Registry Property:`t$item\$name=$value"}
        }
    }
    Write-Host "$report" -f (Get-Random (9..15))
    #Restart-Computer -Force
}

Remove-Variable * -ea SilentlyContinue
