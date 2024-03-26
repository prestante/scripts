$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net')
#$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net', 'WTL-ADC-CTC-03.wtldev.net', 'WTL-ADC-CTC-04.wtldev.net', 'WTL-ADC-CTC-05.wtldev.net', 'WTL-ADC-CTC-06.wtldev.net', 'WTL-ADC-CTC-07.wtldev.net', 'WTL-ADC-CTC-08.wtldev.net', 'WTL-ADC-CTC-09.wtldev.net', 'WTL-ADC-CTC-10.wtldev.net', 'WTL-ADC-CTC-11.wtldev.net', 'WTL-ADC-CTC-12.wtldev.net', 'WTL-ADC-CTC-13.wtldev.net', 'WTL-ADC-CTC-14.wtldev.net', 'WTL-ADC-CTC-15.wtldev.net', 'WTL-ADC-CTC-16.wtldev.net', 'WTL-ADC-CTC-17.wtldev.net', 'WTL-ADC-CTC-18.wtldev.net', 'WTL-ADC-CTC-19.wtldev.net', 'WTL-ADC-CTC-20.wtldev.net', 'WTL-ADC-CTC-21.wtldev.net', 'WTL-ADC-CTC-22.wtldev.net', 'WTL-ADC-CTC-23.wtldev.net', 'WTL-ADC-CTC-24.wtldev.net')
$CredsDomain = [System.Management.Automation.PSCredential]::new('wtldev.net\vadc',(ConvertTo-SecureString -AsPlainText $env:vPW -Force))
$List = New-Object 'System.Collections.Generic.List[PSCustomObject]'
foreach ($server in $CTC) {
    $obj = [PSCustomObject]@{
        ServerName = $server -replace '\.wtldev\.net$'
        IPAddress = [System.Net.Dns]::GetHostAddresses($server) | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -ExpandProperty IPAddressToString }
    $List.Add($obj) }

$Array = @()
foreach ($server in $CTC) { 
    $Array += [PSCustomObject]@{
        ServerName = $server -replace '\.wtldev\.net$'
        IPAddress = [System.Net.Dns]::GetHostAddresses($server) | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -ExpandProperty IPAddressToString } }

#Measure-Command {
    Invoke-Command -ComputerName $CTC -Credential $CredsDomain -ArgumentList $List, $Array {
        param ( $List, $Array )
        return $List
        #return [pscustomobject]@{}
    }
#} | Select-Object -ExpandProperty TotalMilliseconds