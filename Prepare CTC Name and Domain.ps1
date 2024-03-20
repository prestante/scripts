$ComputerNames = @(
    [PSCustomObject]@{HostName="WTL-ADC-CTC-01"; IPaddress="10.9.80.59"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-02"; IPaddress="10.9.80.95"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-03"; IPaddress="10.9.80.96"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-04"; IPaddress="10.9.80.97"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-05"; IPaddress="10.9.80.98"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-06"; IPaddress="10.9.80.99"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-07"; IPaddress="10.9.80.100"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-08"; IPaddress="10.9.80.101"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-09"; IPaddress="10.9.80.102"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-10"; IPaddress="10.9.80.106"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-11"; IPaddress="10.9.80.107"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-12"; IPaddress="10.9.80.108"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-13"; IPaddress="10.9.80.109"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-14"; IPaddress="10.9.80.110"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-15"; IPaddress="10.9.80.112"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-16"; IPaddress="10.9.80.113"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-17"; IPaddress="10.9.80.114"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-18"; IPaddress="10.9.80.115"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-19"; IPaddress="10.9.80.116"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-20"; IPaddress="10.9.80.117"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-21"; IPaddress="10.9.80.118"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-22"; IPaddress="10.9.80.119"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-23"; IPaddress="10.9.80.120"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-24"; IPaddress="10.9.80.121"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-25"; IPaddress="10.9.80.122"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-26"; IPaddress="10.9.80.123"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-27"; IPaddress="10.9.80.124"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-28"; IPaddress="10.9.80.125"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-29"; IPaddress="10.9.80.126"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-30"; IPaddress="10.9.80.127"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-31"; IPaddress="10.9.80.128"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-32"; IPaddress="10.9.80.129"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-33"; IPaddress="10.9.80.130"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-34"; IPaddress="10.9.80.131"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-35"; IPaddress="10.9.80.133"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-36"; IPaddress="10.9.80.134"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-37"; IPaddress="10.9.80.135"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-38"; IPaddress="10.9.80.136"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-39"; IPaddress="10.9.80.137"}
    [PSCustomObject]@{HostName="WTL-ADC-CTC-40"; IPaddress="10.9.80.138"}
)
    #[PSCustomObject]@{HostName="WTL-ADC-CTC-REF"; IPaddress="10.9.80.50"}
$CredsLocal = [System.Management.Automation.PSCredential]::new('local\imagineLocal',(ConvertTo-SecureString -AsPlainText $env:imgLocPW -Force))
$CredsDomain = [System.Management.Automation.PSCredential]::new('wtldev.net\vadc',(ConvertTo-SecureString -AsPlainText $env:vPW -Force))
$DesiredDomain = 'CTC'

#$IPsToDomain = @(Invoke-Command -ComputerName $ComputerNames.IPaddress -Credential $CredsLocal -ArgumentList $ComputerNames, $DesiredDomain {
$IPsToDomain = @(Invoke-Command -ComputerName $ComputerNames.HostName -Credential $CredsLocal -ArgumentList $ComputerNames, $DesiredDomain {
    param ($ComputerNames, $DesiredDomain)
    $HostName = HOSTNAME.EXE

    $IPaddress = Get-NetIPAddress | Where-Object {$_.AddressState -eq "Preferred" -and $_.ValidLifetime -lt "24:00:00"} | Select-Object -ExpandProperty IPAddress
    $Domain = (Get-WmiObject Win32_ComputerSystem).Domain
    $PartOfDomain = (Get-WmiObject Win32_ComputerSystem).PartOfDomain
    #$DesiredName = $ComputerNames | Where-Object {$_.IPaddress -eq $IPaddress} | Select-Object -ExpandProperty HostName
    $DesiredName = $HostName
    #$DesiredName = 'WTL-ADC-CTC-REF'
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
    
    Write-Host "$report" -f (Get-Random (1,2,3,5,6,9,10,11,13,14))
    if ($NeedDomainChanges) {return $IPaddress}  # to return an IP to add this PC to the domain after restart
})

if ($IPsToDomain) {
    Write-Host '--------------------------------------------------------------'
    Write-Host "Changing the domain of the next IPs to '$DesiredDomain':"
    Write-Host $IPsToDomain
    Write-Host 'Waiting 15 seconds. You can stop the script now if you want to interrupt.' -NoNewline
    For ($i = 0; $i -lt 15; $i++) {Start-Sleep 1; Write-Host "." -NoNewline}; Write-Host '.'

    Invoke-Command -ComputerName $IPsToDomain -Credential $CredsLocal -ArgumentList $DesiredDomain, $CredsDomain {
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
}

#Remove-Variable * -ErrorAction SilentlyContinue