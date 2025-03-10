$ComputerNames = @(
    [PSCustomObject]@{ HostName = "WTL-ADC-CTC-01"; IPaddress = "10.9.80.144" }
    [PSCustomObject]@{ HostName = "WTL-ADC-CTC-02"; IPaddress = "10.9.80.145" }
    [PSCustomObject]@{ HostName = "WTL-ADC-CTC-03"; IPaddress = "10.9.80.146" }
    [PSCustomObject]@{ HostName = "WTL-ADC-CTC-04"; IPaddress = "10.9.80.147" }
    [PSCustomObject]@{ HostName = "WTL-ADC-CTC-05"; IPaddress = "10.9.80.148" }
    [PSCustomObject]@{ HostName = "WTL-ADC-CTC-06"; IPaddress = "10.9.80.149" }
    [PSCustomObject]@{ HostName = "WTL-ADC-CTC-07"; IPaddress = "10.9.80.150" }
    [PSCustomObject]@{ HostName = "WTL-ADC-CTC-08"; IPaddress = "10.9.80.151" }
    [PSCustomObject]@{ HostName = "WTL-ADC-CTC-09"; IPaddress = "10.9.80.152" }
    [PSCustomObject]@{ HostName = "WTL-ADC-CTC-10"; IPaddress = "10.9.80.153" }
    [PSCustomObject]@{ HostName = "WTL-ADC-CTC-11"; IPaddress = "10.9.80.154" }
    [PSCustomObject]@{ HostName = "WTL-ADC-CTC-12"; IPaddress = "10.9.80.155" }
    [PSCustomObject]@{ HostName = "WTL-ADC-CTC-13"; IPaddress = "10.9.80.156" }
    [PSCustomObject]@{ HostName = "WTL-ADC-CTC-14"; IPaddress = "10.9.80.157" }
    [PSCustomObject]@{ HostName = "WTL-ADC-CTC-15"; IPaddress = "10.9.80.158" }
    [PSCustomObject]@{ HostName = "WTL-ADC-CTC-16"; IPaddress = "10.9.80.159" }
    [PSCustomObject]@{ HostName = "WTL-ADC-CTC-17"; IPaddress = "10.9.80.160" }
    [PSCustomObject]@{ HostName = "WTL-ADC-CTC-18"; IPaddress = "10.9.80.161" }
    [PSCustomObject]@{ HostName = "WTL-ADC-CTC-19"; IPaddress = "10.9.80.162" }
    [PSCustomObject]@{ HostName = "WTL-ADC-CTC-20"; IPaddress = "10.9.80.163" }
    [PSCustomObject]@{ HostName = "WTL-ADC-CTC-21"; IPaddress = "10.9.80.164" }
    [PSCustomObject]@{ HostName = "WTL-ADC-CTC-22"; IPaddress = "10.9.80.165" }
    [PSCustomObject]@{ HostName = "WTL-ADC-CTC-23"; IPaddress = "10.9.80.166" }
    [PSCustomObject]@{ HostName = "WTL-ADC-CTC-24"; IPaddress = "10.9.80.167" }
    [PSCustomObject]@{ HostName = "WTL-ADC-CTC-25"; IPaddress = "10.9.80.168" }
    [PSCustomObject]@{ HostName = "WTL-ADC-CTC-26"; IPaddress = "10.9.80.169" }
    [PSCustomObject]@{ HostName = "WTL-ADC-CTC-27"; IPaddress = "10.9.80.170" }
    [PSCustomObject]@{ HostName = "WTL-ADC-CTC-28"; IPaddress = "10.9.80.171" }
    [PSCustomObject]@{ HostName = "WTL-ADC-CTC-29"; IPaddress = "10.9.80.172" }
    [PSCustomObject]@{ HostName = "WTL-ADC-CTC-30"; IPaddress = "10.9.80.173" }
    [PSCustomObject]@{ HostName = "WTL-ADC-CTC-31"; IPaddress = "10.9.80.174" }
    [PSCustomObject]@{ HostName = "WTL-ADC-CTC-32"; IPaddress = "10.9.80.175" })
    #[PSCustomObject]@{ HostName = "WTL-ADC-CTC-REF"; IPaddress = "10.9.80.50" }
$CredsLocal = [System.Management.Automation.PSCredential]::new('local\imagineLocal',(ConvertTo-SecureString -AsPlainText $env:imgLocPW -Force))
$CredsDomain = [System.Management.Automation.PSCredential]::new('wtldev.net\vadc',(ConvertTo-SecureString -AsPlainText $env:VADC_PASSWORD -Force))
$DesiredDomain = 'WTL'  # set CTC if you want VMs in a workgroup or WTL if you want them to join WTLDEV.NET domain
$FreshCTC = 0  # set this flag if you have just created VMs and wrote their IPs into the table. So we are sure IPs correspond to CTC VMs.

if ( $FreshCTC ) { $ComputersList = $ComputerNames.IPAddress }
else { $ComputersList = $ComputerNames.HostName }

$IPsToDomain = @(Invoke-Command -ComputerName $ComputersList -Credential $CredsLocal -ArgumentList $ComputerNames, $DesiredDomain {
    param ($ComputerNames, $DesiredDomain)
    $HostName = HOSTNAME.EXE

    $IPaddress = Get-NetIPAddress | Where-Object {$_.AddressState -eq "Preferred" -and $_.ValidLifetime -lt "24:00:00"} | Select-Object -ExpandProperty IPAddress
    $Domain = (Get-WmiObject Win32_ComputerSystem).Domain
    $PartOfDomain = (Get-WmiObject Win32_ComputerSystem).PartOfDomain
    if ($HostName -eq 'WTL-ADC-CTC-REF') {$DesiredName = $ComputerNames | Where-Object {$_.IPaddress -eq $IPaddress} | Select-Object -ExpandProperty HostName}  # this means we have just created these VMs and they should be renamed in accordance with manual IP/name table
    else {$DesiredName = $HostName}  # this means VMs are already have correct names but IPs may differ from manual IP/name table made on VM create
    $report = "$DesiredName ($IPaddress) HostName: $HostName, Domain: $Domain"

    if ($HostName -ceq $DesiredName -and $Domain -match $DesiredDomain) { $report += "`t The computer already has a desired name '$DesiredName' and is part of the desired domain '$DesiredDomain'" }
    elseif ($HostName -ceq $DesiredName -and $Domain -notmatch $DesiredDomain) { $report += "`n`t The computer already has a desired name, but domain should be changed to '$DesiredDomain'"; $NeedDomainChanges = 1 }
    elseif ($PartOfDomain -and $HostName -cne $DesiredName) { $report += "`n`t The computer name should be changed to '$DesiredName' but first we have to exit the domain. Run the script once more after the domain is changed"; $NeedDomainChanges = 1 }
    else {  # not in the domain and want to change name
        try {
            Rename-Computer -NewName $DesiredName -Force -Restart -ErrorAction Stop
            $report += "`n`t Renaming the computer from '$HostName' to '$DesiredName'"
            $report += "`n`t Restarting the computer"
            $NeedDomainChanges = 1
        }
        catch {
            $report += "`n`t Failed to rename the computer from '$HostName' to '$DesiredName'"  # the fail is probably related to being in the domain
            $NeedDomainChanges = 1  # so we probably want to exit the domain in the next Invoke-Command
        }
    }
    
    Write-Host "$Report" -f ( 1, 2, 3, 5, 6, 9, 10, 11, 13, 14 )[ ( $HostName.Split('-')[-1] ) % 10 ]  # Choose the color as a remainder of dividing the name number part by 10 (number of color variants)
    if ($NeedDomainChanges) {return $IPaddress}  # to return an IP to add this PC to the domain after restart
})

$IPsToDomainSorted = $IPsToDomain | Sort-Object
if ($IPsToDomain) {
    Write-Host '--------------------------------------------------------------'
    Write-Host "Changing the domain of the next IPs to '$DesiredDomain':"
    Write-Host $IPsToDomainSorted
    Write-Host 'Waiting 15 seconds. You can stop the script now if you want to interrupt.' -NoNewline
    For ($i = 0; $i -lt 15; $i++) {Start-Sleep 1; Write-Host "." -NoNewline}; Write-Host '.'

    foreach ($Computer in $IPsToDomainSorted) {
        Invoke-Command -ComputerName $Computer -Credential $CredsLocal -ArgumentList $DesiredDomain, $CredsDomain {
            param($DesiredDomain, [PSCredential] $CredsDomain)
            $HostName = HOSTNAME.EXE
            $IPaddress = Get-NetIPAddress | Where-Object {$_.AddressState -eq "Preferred" -and $_.ValidLifetime -lt "24:00:00"} | Select-Object -ExpandProperty IPAddress
            $Domain = (Get-WmiObject Win32_ComputerSystem).Domain
            $report = "$(HOSTNAME.EXE) ($IPaddress)"
            if ($Domain -notmatch $DesiredDomain -and $DesiredDomain -match 'wtl') {  # if we are not in desired domain/group and desire to wtl, then joining it
                Add-Computer -DomainName 'wtldev.net' -Credential $CredsDomain -Force -Restart
                $report += "`n`t Joining the WTLDEV.NET domain" }
            elseif ($Domain -notmatch $DesiredDomain -and $DesiredDomain -notmatch 'wtl') {  # if we are not in desired domain/group and desire somewhere else, then joining a workgroup
                Add-Computer -WorkgroupName $DesiredDomain -Credential $CredsDomain -Force -Restart
                $report += "`n`t Joining the '$DesiredDomain' workgroup" }
            $report += "`n`t Restarting the computer"
            Write-Host "$report" -f ( 1, 2, 3, 5, 6, 9, 10, 11, 13, 14 )[ ( $HostName.Split('-')[-1] ) % 10 ]  # Choosing the color as a remainder of dividing the name number part by 10 (number of color variants)
        }
        Start-Sleep -Seconds 10
    }
}

#Remove-Variable * -ErrorAction SilentlyContinue