$ComputerNames = @(
    [PSCustomObject]@{HostName="wtl-adc-ctc-32"; IPaddress="10.9.80.75"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-31"; IPaddress="10.9.80.76"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-30"; IPaddress="10.9.80.89"}
    <#[PSCustomObject]@{HostName="wtl-adc-ctc-29"; IPaddress="10.9.80.90"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-28"; IPaddress="10.9.80.91"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-27"; IPaddress="10.9.80.92"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-26"; IPaddress="10.9.80.93"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-25"; IPaddress="10.9.80.94"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-24"; IPaddress="10.9.80."}
    [PSCustomObject]@{HostName="wtl-adc-ctc-23"; IPaddress="10.9.80."}
    [PSCustomObject]@{HostName="wtl-adc-ctc-22"; IPaddress="10.9.80."}
    [PSCustomObject]@{HostName="wtl-adc-ctc-21"; IPaddress="10.9.80."}
    [PSCustomObject]@{HostName="wtl-adc-ctc-20"; IPaddress="10.9.80."}
    [PSCustomObject]@{HostName="wtl-adc-ctc-19"; IPaddress="10.9.80."}
    [PSCustomObject]@{HostName="wtl-adc-ctc-18"; IPaddress="10.9.80."}
    [PSCustomObject]@{HostName="wtl-adc-ctc-17"; IPaddress="10.9.80."}
    [PSCustomObject]@{HostName="wtl-adc-ctc-16"; IPaddress="10.9.80."}
#>
)
$CredsLocal = [System.Management.Automation.PSCredential]::new('local\imagineLocal',(ConvertTo-SecureString -AsPlainText 'imagineL0cal' -Force))

$IPsToDomain = @(Invoke-Command -ComputerName $ComputerNames.IPaddress -Credential $CredsLocal -ArgumentList $ComputerNames,'' {
    param ($ComputerNames)
    $HostName = HOSTNAME.EXE
    $IPaddress = Get-NetIPAddress | Where-Object {$_.AddressState -eq "Preferred" -and $_.ValidLifetime -lt "24:00:00"} | Select-Object -ExpandProperty IPAddress
    $Domain = (Get-WmiObject Win32_ComputerSystem).Domain
    $PartOfDomain = (Get-WmiObject Win32_ComputerSystem).PartOfDomain
    $DesiredName = $ComputerNames | Where-Object {$_.IPaddress -eq $IPaddress} | Select-Object -ExpandProperty HostName
    #$DesiredName = 'ctc'
    $report = "$DesiredName ($IPaddress) HostName: $HostName, Domain: $Domain"

    if ($HostName -ne $DesiredName) { # if a computer name differs from a desired name, renaming it
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
    elseif (-not $PartOfDomain) { $report += "`n`t The computer has a desired name, but still have to be joined the domain" ; $NeedDomainChanges = 1 }
    else { $report += "`n`t The computer already has a desired name '$DesiredName' and is part of the domain"}
    Write-Host "$report" -f (Get-Random (1,2,3,5,6,9,10,11,13,14))
    if ($NeedDomainChanges) {return $IPaddress}  # to return an IP to add this PC to the domain after restart
})

if ($IPsToDomain) {
    Write-Host '--------------------------------------------------------------'
    Write-Host 'Waiting 15 seconds' -NoNewline
    For ($i = 0; $i -lt 15; $i++) {Start-Sleep 1; Write-Host "." -NoNewline}; Write-Host '.'

    Invoke-Command -ComputerName $IPsToDomain -Credential $CredsLocal {
        $IPaddress = Get-NetIPAddress | Where-Object {$_.AddressState -eq "Preferred" -and $_.ValidLifetime -lt "24:00:00"} | Select-Object -ExpandProperty IPAddress
        $PartOfDomain = (Get-WmiObject Win32_ComputerSystem).PartOfDomain
        $report = "$(HOSTNAME.EXE) ($IPaddress)"
        $CredsDomain = [System.Management.Automation.PSCredential]::new('wtldev.net\vadc',(ConvertTo-SecureString -AsPlainText '!Trade33Wait!' -Force))
        if (-not $PartOfDomain) {  # if we are not PartOfDomain yet, then joining it
            Add-Computer -DomainName 'wtldev.net' -Credential $CredsDomain -Force -Restart
            $report += "`n`t Adding the computer to the domain" }
        else {  # if we are in the domain and since we are in this Invoke-Command then we probably want to exit the domain (i.e. join a workgroup)
            Add-Computer -WorkgroupName "CTC" -Credential $CredsDomain -Force -Restart
            $report += "`n`t Exiting the domain and joining a workgroup" }
        $report += "`n`t Restarting the computer"
        Write-Host "$report" -f (Get-Random (1,2,3,5,6,9,10,11,13,14))
    }
}

#Remove-Variable * -ErrorAction SilentlyContinue