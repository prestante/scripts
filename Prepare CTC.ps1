#$CTC = @('WTL-ADC-CTC-01.WTLDEV.NET', 'WTL-ADC-CTC-02.WTLDEV.NET', 'WTL-ADC-CTC-03.WTLDEV.NET', 'WTL-ADC-CTC-04.WTLDEV.NET', 'WTL-ADC-CTC-05.WTLDEV.NET', 'WTL-ADC-CTC-06.WTLDEV.NET', 'WTL-ADC-CTC-07.WTLDEV.NET', 'WTL-ADC-CTC-08.WTLDEV.NET', 'WTL-ADC-CTC-09.WTLDEV.NET', 'WTL-ADC-CTC-10.WTLDEV.NET', 'WTL-ADC-CTC-11.WTLDEV.NET', 'WTL-ADC-CTC-12.WTLDEV.NET', 'WTL-ADC-CTC-13.WTLDEV.NET', 'WTL-ADC-CTC-14.WTLDEV.NET', 'WTL-ADC-CTC-15.WTLDEV.NET', 'WTL-ADC-CTC-16.WTLDEV.NET', 'WTL-ADC-CTC-17.WTLDEV.NET', 'WTL-ADC-CTC-18.WTLDEV.NET', 'WTL-ADC-CTC-19.WTLDEV.NET', 'WTL-ADC-CTC-20.WTLDEV.NET', 'WTL-ADC-CTC-21.WTLDEV.NET', 'WTL-ADC-CTC-22.WTLDEV.NET', 'WTL-ADC-CTC-23.WTLDEV.NET', 'WTL-ADC-CTC-24.WTLDEV.NET')
$CTC = @('WTL-ADC-CTC-01.WTLDEV.NET')

$Password = Read-Host "Enter password for vadc"
$Creds = [System.Management.Automation.PSCredential]::new('wtldev.net\vadc',(ConvertTo-SecureString -AsPlainText $Password -Force))
$Key = ConvertFrom-SecureString $Creds.Password
$Creds = [System.Management.Automation.PSCredential]::new('wtldev.net\vadc',(ConvertTo-SecureString $Key))

Invoke-Command -ComputerName $CTC -Credential $Creds -ArgumentList $Password {
    param ($Password)
    $report = "$(HOSTNAME.EXE):"

    $report
    return

    # Copy \\wtlnas1 and \\wtlnas5 shortcuts to desktop
    $Creds = [System.Management.Automation.PSCredential]::new('wtldev.net\vadc',(ConvertTo-SecureString -AsPlainText $Password -Force))
    $Key = ConvertFrom-SecureString $Creds.Password
    $Creds = [System.Management.Automation.PSCredential]::new('wtldev.net\vadc',(ConvertTo-SecureString $Key))
    New-PSDrive -Name "Z" -PSProvider FileSystem -Root "\\wtlnas1\Public\ADC\PS\resources" -Credential $Creds | Out-Null
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
