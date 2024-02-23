$ComputerNames = @(
    [PSCustomObject]@{HostName="wtl-adc-ctc-32"; IPaddress="10.9.80.75"}
    [PSCustomObject]@{HostName="wtl-adc-ctc-31"; IPaddress="10.9.80.76"}
    #[PSCustomObject]@{HostName="wtl-adc-ctc-30"; IPaddress="10.9.80.89"}
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
$CredsLocal = [System.Management.Automation.PSCredential]::new('local\imagineLocal',(ConvertTo-SecureString -AsPlainText '!imagineL0cal!' -Force))

$results = Invoke-Command -ComputerName $ComputerNames.IPaddress -Credential $CredsLocal -ArgumentList $ComputerNames,'' {
    param ($ComputerNames)
    $HostName = HOSTNAME.EXE
    $IPaddress = Get-NetIPAddress | Where-Object {$_.AddressState -eq "Preferred" -and $_.ValidLifetime -lt "24:00:00"} | Select-Object -ExpandProperty IPAddress
    $Domain = (Get-WmiObject Win32_ComputerSystem).Domain
    $DesiredName = $ComputerNames | Where-Object {$_.IPaddress -eq $IPaddress} | Select-Object -ExpandProperty HostName
    $report = "$DesiredName ($IPaddress)" #Domain: $Domain"

    return $IPaddress

    Write-Host "$report" -f (Get-Random (1,2,3,5,6,9,10,11,13,14))
}

$results


