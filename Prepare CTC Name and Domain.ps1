$ComputerNames = @(
    #[PSCustomObject]@{HostName="wtl-adc-ctc-32"; IPaddress="10.9.80.75"}
    #[PSCustomObject]@{HostName="wtl-adc-ctc-31"; IPaddress="10.9.80.76"}
    #[PSCustomObject]@{HostName="wtl-adc-ctc-30"; IPaddress="10.9.80.89"}
    #[PSCustomObject]@{HostName="wtl-adc-ctc-29"; IPaddress="10.9.80.90"}
    #[PSCustomObject]@{HostName="wtl-adc-ctc-28"; IPaddress="10.9.80.91"}
    #[PSCustomObject]@{HostName="wtl-adc-ctc-27"; IPaddress="10.9.80.92"}
    #[PSCustomObject]@{HostName="wtl-adc-ctc-26"; IPaddress="10.9.80.93"}
    #[PSCustomObject]@{HostName="wtl-adc-ctc-25"; IPaddress="10.9.80.94"}
    #[PSCustomObject]@{HostName="wtl-adc-ctc-24"; IPaddress="10.9.80."}
    #[PSCustomObject]@{HostName="wtl-adc-ctc-23"; IPaddress="10.9.80."}
    #[PSCustomObject]@{HostName="wtl-adc-ctc-22"; IPaddress="10.9.80."}
    #[PSCustomObject]@{HostName="wtl-adc-ctc-21"; IPaddress="10.9.80."}
    #[PSCustomObject]@{HostName="wtl-adc-ctc-20"; IPaddress="10.9.80."}
    #[PSCustomObject]@{HostName="wtl-adc-ctc-19"; IPaddress="10.9.80."}
    #[PSCustomObject]@{HostName="wtl-adc-ctc-18"; IPaddress="10.9.80."}
    #[PSCustomObject]@{HostName="wtl-adc-ctc-17"; IPaddress="10.9.80."}
    #[PSCustomObject]@{HostName="wtl-adc-ctc-16"; IPaddress="10.9.80."}
    #>
    [PSCustomObject]@{HostName="wtl-adc-ctc-02"; IPaddress="10.9.80.51"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-01"; IPaddress="10.9.80.52"}
    #[PSCustomObject]@{HostName="wtl-adc-ctc-ref"; IPaddress="10.9.80.50"}
)
$CredsLocal = [System.Management.Automation.PSCredential]::new('local\imagineLocal',(ConvertTo-SecureString -AsPlainText 'imagineL0cal' -Force))
$DesiredDomain = 'CTC'

$IPsToDomain = @(Invoke-Command -ComputerName $ComputerNames.HostName -Credential $CredsLocal -ArgumentList $ComputerNames,$DesiredDomain {
    param ($ComputerNames, $DesiredDomain)
    $HostName = HOSTNAME.EXE

    (Get-WmiObject Win32_ComputerSystem)
    return

    $IPaddress = Get-NetIPAddress | Where-Object {$_.AddressState -eq "Preferred" -and $_.ValidLifetime -lt "24:00:00"} | Select-Object -ExpandProperty IPAddress
    $Domain = (Get-WmiObject Win32_ComputerSystem).Domain
    $PartOfDomain = (Get-WmiObject Win32_ComputerSystem).PartOfDomain
    $DesiredName = $ComputerNames | Where-Object {$_.IPaddress -eq $IPaddress} | Select-Object -ExpandProperty HostName
    #$DesiredName = 'WTL-ADC-CTC-REF'
    $report = "$DesiredName ($IPaddress) HostName: $HostName, Domain: $Domain"

    if ($HostName -eq $DesiredName -and $Domain -match $DesiredDomain) { $report += "`n`t The computer already has a desired name '$DesiredName' and is part of the desired domain '$DesiredDomain'" }
    elseif ($Domain -notmatch $DesiredDomain) { $report += "`n`t The computer domain should be changed to '$DesiredDomain'. If you also need to change the computer name, run the script once more after the domain is changed"; $NeedDomainChanges = 1 }
    elseif ($PartOfDomain -and $HostName -ne $DesiredName) { $report += "`n`t The computer name should be changed to '$DesiredName' but first we have to exit the domain. Run the script once more after the domain is changed"; $NeedDomainChanges = 1 }
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
    
    Write-Host "$report" -f (Get-Random (1,2,3,5,6,9,10,11,13,14))
    if ($NeedDomainChanges) {return $IPaddress}  # to return an IP to add this PC to the domain after restart
})

if ($IPsToDomain) {
    Write-Host '--------------------------------------------------------------'
    Write-Host "Waiting 15 seconds before changing the domain to '$DesiredDomain'" -NoNewline
    For ($i = 0; $i -lt 15; $i++) {Start-Sleep 1; Write-Host "." -NoNewline}; Write-Host '.'

    Invoke-Command -ComputerName $IPsToDomain -Credential $CredsLocal -ArgumentList $DesiredDomain {
        param($DesiredDomain)
        $IPaddress = Get-NetIPAddress | Where-Object {$_.AddressState -eq "Preferred" -and $_.ValidLifetime -lt "24:00:00"} | Select-Object -ExpandProperty IPAddress
        $Domain = (Get-WmiObject Win32_ComputerSystem).Domain
        $report = "$(HOSTNAME.EXE) ($IPaddress)"
        $CredsDomain = [System.Management.Automation.PSCredential]::new('wtldev.net\vadc',(ConvertTo-SecureString -AsPlainText '!Trade33Wait!' -Force))
        if ($Domain -notmatch $DesiredDomain -and $DesiredDomain -match 'wtl') {  # if we are not in desired domain/group and desire to wtl, then joining it
            Add-Computer -DomainName 'wtldev.net' -Credential $CredsDomain -Force -Restart
            $report += "`n`t Joining the WTLDEV.NET domain" }
        elseif ($Domain -notmatch $DesiredDomain -and $DesiredDomain -notmatch 'wtl') {  # if we are not in desired domain/group and desire somewhere else, then joining a workgroup
            Add-Computer -WorkgroupName $DesiredDomain -Credential $CredsDomain -Force -Restart
            $report += "`n`t Joining the '$DesiredDomain' workgroup" }
        $report += "`n`t Restarting the computer"
        Write-Host "$report" -f (Get-Random (1,2,3,5,6,9,10,11,13,14))
    }
}

#Remove-Variable * -ErrorAction SilentlyContinue