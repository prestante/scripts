Param(
    [string]$Server="WTL-HPY-345-6",
    [decimal]$Probability = 0.1,  # Probability is the chance (in percents) of the cycle to execute the query. Normally there are about 10 cycles per second per CTC. So if we set it to 10, each CTC will query in average opce a second
    [int]$Duration = 3600)    # Set the number of seconds to continue querying. For some reason we are able to interrupt it by stopping the script...

$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net', 'WTL-ADC-CTC-03.wtldev.net', 'WTL-ADC-CTC-04.wtldev.net', 'WTL-ADC-CTC-05.wtldev.net', 'WTL-ADC-CTC-06.wtldev.net', 'WTL-ADC-CTC-07.wtldev.net', 'WTL-ADC-CTC-08.wtldev.net', 'WTL-ADC-CTC-09.wtldev.net', 'WTL-ADC-CTC-10.wtldev.net', 'WTL-ADC-CTC-11.wtldev.net', 'WTL-ADC-CTC-12.wtldev.net', 'WTL-ADC-CTC-13.wtldev.net', 'WTL-ADC-CTC-14.wtldev.net', 'WTL-ADC-CTC-15.wtldev.net', 'WTL-ADC-CTC-16.wtldev.net', 'WTL-ADC-CTC-17.wtldev.net', 'WTL-ADC-CTC-18.wtldev.net', 'WTL-ADC-CTC-19.wtldev.net', 'WTL-ADC-CTC-20.wtldev.net', 'WTL-ADC-CTC-21.wtldev.net', 'WTL-ADC-CTC-22.wtldev.net', 'WTL-ADC-CTC-23.wtldev.net', 'WTL-ADC-CTC-24.wtldev.net', 'WTL-ADC-CTC-25.wtldev.net', 'WTL-ADC-CTC-26.wtldev.net', 'WTL-ADC-CTC-27.wtldev.net', 'WTL-ADC-CTC-28.wtldev.net', 'WTL-ADC-CTC-29.wtldev.net', 'WTL-ADC-CTC-30.wtldev.net', 'WTL-ADC-CTC-31.wtldev.net', 'WTL-ADC-CTC-32.wtldev.net')
#$CTC = @('WTL-ADC-CTC-30.wtldev.net', 'WTL-ADC-CTC-31.wtldev.net', 'WTL-ADC-CTC-32.wtldev.net')
#$CTC = @('WTL-ADC-CTC-01.wtldev.net')

$EndTime = (Get-Date).AddSeconds($Duration)

$CredsDomain = [System.Management.Automation.PSCredential]::new('wtldev.net\vadc',(ConvertTo-SecureString -AsPlainText $env:vPW -Force))

Write-Host "Updating SQL records on $Server until $EndTime" -f Yellow

Invoke-Command -ComputerName $CTC -Credential $CredsDomain -ArgumentList $Server, $EndTime, $Probability {
    param ( $Server, $EndTime, $Probability )

    $HostName = $env:COMPUTERNAME

    $BaseName = "ASDB"
    $BaseLogin = "LouthDB"
    $BasePassw = "LouthDB"
    $connection = New-Object -com "ADODB.Connection"
    $ConnectionString = "Provider=SQLOLEDB.1;
                            Data Source=$Server;
                            Initial Catalog=$BaseName;
                            User ID=$BaseLogin;
                            Password=$BasePassw;"

    function GD {Get-Date -Format 'yyyy-MM-dd HH:mm:ss:fff - '}
    function get-decT {
        $tt = Get-Date -Hour (Get-Random(24)) -Minute (Get-Random(60)) -Second (Get-Random(60))
        if (($tt.Second -eq 0) -and ($tt.Minute -ne 10)) { $decT = [int]("0x{0:HHmmss28}" -f ($tt.AddSeconds(-1))) }
        else { $decT = [int]("0x{0:HHmmss00}" -f ($tt)) }
        return $decT
    }
    function upd-query {
        $Global:n = 1 + (Get-Random 999)
        $Global:id = "Demo0{0:d3}" -f $n
        $dateTime = "{0:HH}:{0:mm}:{0:ss}" -f (Get-Date)
        $rndTC1 = (get-decT) ; $rndTC2 = (get-decT)
        $Global:query = "UPDATE [ASDB].[dbo].[ASDB] SET Title = '$dateTime', StartOfMessage = 0, Duration = 4096 WHERE Identifier = '$id'"
    }
    <#function upd-query {
        $Global:n = 1 + (Get-Random 4)
        $Global:id = "SWTCH7"
        $dateTime = "{0:HH}:{0:mm}:{0:ss}" -f (Get-Date)
        $rndTC1 = (get-decT) ; $rndTC2 = (get-decT)
        $Global:query = "UPDATE [ASDB].[dbo].[ASSEG] SET Title = '$dateTime' WHERE Identifier = '$id' and SegNum = $n"
    }#>

    do {
        if ( ( Get-Random 100000 ) -lt ( $Probability * 1000 ) ) {  # using thousands to be more precise on low percent values
            upd-query

            $connection.Open($ConnectionString)
            $time = Get-Date
            $connection.Execute($query) | Out-Null
            $log_string = "$HostName`: $(GD)UPDATE '$id' on $($Server -replace '\.\w*?\.\w*?$') from $env:COMPUTERNAME took $([math]::Round(((get-date) -$time).TotalMilliseconds)) ms"
            #$log_string = "$HostName`: $(GD)UPDATE '$id' Seg $n on $($Server -replace '\.\w*?\.\w*?$') from $env:COMPUTERNAME took $([math]::Round(((get-date) -$time).TotalMilliseconds)) ms"
            Write-Host "$log_string" -f ( 1, 2, 3, 5, 6, 9, 10, 11, 13, 14 )[ ( $HostName.Split('-')[-1] ) % 10 ]  # Choose the color as a remainder of dividing the name number part by 10 (number of color variants)
            $connection.Close()
        }
        Start-Sleep -Milliseconds 100
    } until ( (Get-Date) -ge $EndTime )
}
Write-Host "Done"
if ( $Host.Name -notmatch 'Visual Studio') { Read-Host }