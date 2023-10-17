#$CTC = @('WTL-ADC-CTC-01.WTLDEV.NET', 'WTL-ADC-CTC-02.WTLDEV.NET', 'WTL-ADC-CTC-03.WTLDEV.NET', 'WTL-ADC-CTC-04.WTLDEV.NET', 'WTL-ADC-CTC-05.WTLDEV.NET', 'WTL-ADC-CTC-06.WTLDEV.NET', 'WTL-ADC-CTC-07.WTLDEV.NET', 'WTL-ADC-CTC-08.WTLDEV.NET', 'WTL-ADC-CTC-09.WTLDEV.NET', 'WTL-ADC-CTC-10.WTLDEV.NET', 'WTL-ADC-CTC-11.WTLDEV.NET', 'WTL-ADC-CTC-12.WTLDEV.NET', 'WTL-ADC-CTC-13.WTLDEV.NET', 'WTL-ADC-CTC-14.WTLDEV.NET', 'WTL-ADC-CTC-15.WTLDEV.NET', 'WTL-ADC-CTC-16.WTLDEV.NET', 'WTL-ADC-CTC-17.WTLDEV.NET', 'WTL-ADC-CTC-18.WTLDEV.NET', 'WTL-ADC-CTC-19.WTLDEV.NET', 'WTL-ADC-CTC-20.WTLDEV.NET', 'WTL-ADC-CTC-21.WTLDEV.NET', 'WTL-ADC-CTC-22.WTLDEV.NET', 'WTL-ADC-CTC-23.WTLDEV.NET', 'WTL-ADC-CTC-24.WTLDEV.NET')
$CTC = @('WTL-ADC-CTC-01.WTLDEV.NET', 'WTL-ADC-CTC-02.WTLDEV.NET')

#$Creds = [System.Management.Automation.PSCredential]::new('wtldev.net\vadc',(ConvertTo-SecureString -AsPlainText '*real password*' -Force))
$Creds = [System.Management.Automation.PSCredential]::new('wtldev.net\vadc',(ConvertTo-SecureString '01000000d08c9ddf0115d1118c7a00c04fc297eb01000000be6cfee0e75a0949ba2fdb6de1be94dc0000000002000000000003660000c0000000100000006db45abcaa44ac13ffe44bf2c7d3e36d0000000004800000a000000010000000401071773556c48f0e7e41965cbf42ac18000000978e0f16f904e10e1f5ebf3f7f4a9ac9868797e2d8af87ab1400000006ee747bf93bbf0be2c227e545d619d46e04fd3b'))

Invoke-Command -ComputerName $CTC -Credential $Creds {
    $report = "$(HOSTNAME.EXE):"

    # Create \\wtlnas1 and \\wtlnas5 shortcuts on desktop
    @(
        @{path = "$env:USERPROFILE\Desktop\Releases ADC.lnk"; target = "\\wtlnas5\Public\Releases\ADC"}
        @{path = "$env:USERPROFILE\Desktop\WTLNAS1 ADC.lnk"; target = "\\wtlnas1\Public\ADC"}
    ) | ForEach-Object {
        if (!(Get-Item $_.path -ea SilentlyContinue)) {$shell = New-Object -ComObject WScript.Shell; $shortcut = $shell.CreateShortcut($_.path); $shortcut.TargetPath = $_.target; $shortcut.Save(); $report += "`n`tDesktop Shortcut '$($_.path -replace('.*\\([\w\s]+)\.lnk$','$1'))' is added leading to '$($_.target)'"}
    }

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
    Restart-Computer -Force
}

Remove-Variable * -ea SilentlyContinue
