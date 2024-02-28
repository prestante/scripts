#$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net', 'WTL-ADC-CTC-03.wtldev.net', 'WTL-ADC-CTC-04.wtldev.net', 'WTL-ADC-CTC-05.wtldev.net', 'WTL-ADC-CTC-06.wtldev.net', 'WTL-ADC-CTC-07.wtldev.net', 'WTL-ADC-CTC-08.wtldev.net', 'WTL-ADC-CTC-09.wtldev.net', 'WTL-ADC-CTC-10.wtldev.net', 'WTL-ADC-CTC-11.wtldev.net', 'WTL-ADC-CTC-12.wtldev.net', 'WTL-ADC-CTC-13.wtldev.net', 'WTL-ADC-CTC-14.wtldev.net', 'WTL-ADC-CTC-15.wtldev.net', 'WTL-ADC-CTC-16.wtldev.net', 'WTL-ADC-CTC-17.wtldev.net', 'WTL-ADC-CTC-18.wtldev.net', 'WTL-ADC-CTC-19.wtldev.net', 'WTL-ADC-CTC-20.wtldev.net', 'WTL-ADC-CTC-21.wtldev.net', 'WTL-ADC-CTC-22.wtldev.net', 'WTL-ADC-CTC-23.wtldev.net', 'WTL-ADC-CTC-24.wtldev.net', 'WTL-ADC-CTC-25.wtldev.net', 'WTL-ADC-CTC-26.wtldev.net', 'WTL-ADC-CTC-27.wtldev.net', 'WTL-ADC-CTC-28.wtldev.net', 'WTL-ADC-CTC-29.wtldev.net', 'WTL-ADC-CTC-30.wtldev.net', 'WTL-ADC-CTC-31.wtldev.net', 'WTL-ADC-CTC-32.wtldev.net', 'WTL-ADC-CTC-33.wtldev.net', 'WTL-ADC-CTC-34.wtldev.net', 'WTL-ADC-CTC-35.wtldev.net', 'WTL-ADC-CTC-36.wtldev.net', 'WTL-ADC-CTC-37.wtldev.net', 'WTL-ADC-CTC-38.wtldev.net', 'WTL-ADC-CTC-39.wtldev.net', 'WTL-ADC-CTC-40.wtldev.net')
$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net', 'WTL-ADC-CTC-03.wtldev.net', 'WTL-ADC-CTC-04.wtldev.net', 'WTL-ADC-CTC-05.wtldev.net', 'WTL-ADC-CTC-06.wtldev.net', 'WTL-ADC-CTC-07.wtldev.net', 'WTL-ADC-CTC-08.wtldev.net', 'WTL-ADC-CTC-09.wtldev.net')

$CredsDomain = [System.Management.Automation.PSCredential]::new('wtldev.net\vadc',(ConvertTo-SecureString -AsPlainText $env:vPW -Force))

Invoke-Command -ComputerName $CTC -Credential $CredsDomain {
    $report = "$(HOSTNAME.EXE):"

    $report
    return

    # Copy \\wtlnas1 and \\wtlnas5 shortcuts to desktop
    $CredsDomain = [System.Management.Automation.PSCredential]::new('wtldev.net\vadc',(ConvertTo-SecureString -AsPlainText $env:vPW -Force))
    New-PSDrive -Name "Z" -PSProvider FileSystem -Root "\\wtlnas1\Public\ADC\PS\resources" -Credential $CredsDomain | Out-Null
    $report += "`n`tPSDrive 'Z' has been mounted"
    @(
        [PSCustomObject]@{name = "Releases ADC.lnk"; target = "$env:USERPROFILE\Desktop\"}
        [PSCustomObject]@{name = "WTLNAS1 ADC.lnk"; target = "$env:USERPROFILE\Desktop\"}
    ) | ForEach-Object {
        if (!(Get-Item "$($_.target)$($_.name)" -ea SilentlyContinue)) {
            Copy-Item "Z:\$($_.name)" -Destination $_.target
            $report += "`n`t`tItem '$($_.name)' has been copied to '$($_.target)'"
        }
    }
    Remove-PSDrive "Z"

    # Remove Run Warnings for \\wtlnas1 and \\wtlnas5
    $domains = @('wtlnas1','wtlnas5')
    $registryPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\EscDomains"
    $name = "*"
    $value = 1
    foreach ($domain in $domains) {
        if (-not (Test-Path "$registryPath\$domain")) {$item = "$registryPath\$domain"; New-Item -Path $item -Force | Out-Null; $report += "`n`tNew Registry Item:`t$item"}
        if (-not (Get-Item "$registryPath\$domain" -ea SilentlyContinue).Property -contains $name) {$item = "$registryPath\$domain"; New-ItemProperty -Path $item -Name $name -Value $value -PropertyType DWORD -Force | Out-Null; $report += "`n`tNew Registry Property:`t$item\$name=$value"}
    }
    <#@('wtlnas1.wtldev.net','wtlnas5.wtldev.net') | ForEach-Object {
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
    }#>

    Write-Host "$report" -f (Get-Random (1,2,3,5,6,9,10,11,13,14))
    Restart-Computer -Force
}

Remove-Variable * -ea SilentlyContinue
