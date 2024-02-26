$ComputerNames = @(
    [PSCustomObject]@{HostName="wtl-adc-ctc-01"; IPaddress="10.9.80.59"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-02"; IPaddress="10.9.80.95"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-03"; IPaddress="10.9.80.96"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-04"; IPaddress="10.9.80.97"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-05"; IPaddress="10.9.80.98"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-06"; IPaddress="10.9.80.99"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-07"; IPaddress="10.9.80.100"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-08"; IPaddress="10.9.80.101"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-09"; IPaddress="10.9.80.102"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-10"; IPaddress="10.9.80.106"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-11"; IPaddress="10.9.80.107"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-12"; IPaddress="10.9.80.108"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-13"; IPaddress="10.9.80.109"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-14"; IPaddress="10.9.80.110"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-15"; IPaddress="10.9.80.112"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-16"; IPaddress="10.9.80.113"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-17"; IPaddress="10.9.80.114"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-18"; IPaddress="10.9.80.115"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-19"; IPaddress="10.9.80.116"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-20"; IPaddress="10.9.80.117"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-21"; IPaddress="10.9.80.118"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-22"; IPaddress="10.9.80.119"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-23"; IPaddress="10.9.80.120"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-24"; IPaddress="10.9.80.121"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-25"; IPaddress="10.9.80.122"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-26"; IPaddress="10.9.80.123"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-27"; IPaddress="10.9.80.124"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-28"; IPaddress="10.9.80.125"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-29"; IPaddress="10.9.80.126"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-30"; IPaddress="10.9.80.127"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-31"; IPaddress="10.9.80.128"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-32"; IPaddress="10.9.80.129"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-33"; IPaddress="10.9.80.130"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-34"; IPaddress="10.9.80.131"}
)
  #[PSCustomObject]@{HostName="wtl-adc-ctc-ref"; IPaddress="10.9.80.50"}
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