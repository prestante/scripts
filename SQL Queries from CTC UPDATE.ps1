Param(
#[array]
#[Parameter(ValueFromRemainingArguments=$true)]
[string]$Server)
if (!$Server) {$Server = "ADCSERVICES-3"}

#$CTC = @('WTL-HP3B8-VDS1.WTLDEV.NET','WTL-HP3B8-VDS2.WTLDEV.NET','WTL-HP3B8-VDS3.WTLDEV.NET','WTL-HP3B8-VDS4.WTLDEV.NET','WTL-HP3B8-VDS5.WTLDEV.NET','WTL-HP3B8-VDS6.WTLDEV.NET','WTL-HP3B8-VDS7.WTLDEV.NET','WTL-HP3B8-VDS8.WTLDEV.NET','WTL-HP3B8-VDS9.WTLDEV.NET','WTL-HP3B8-VDS10.WTLDEV.NET','WTL-HP3B9-VDS1.WTLDEV.NET','WTL-HP3B9-VDS2.WTLDEV.NET','WTL-HP3B9-VDS3.WTLDEV.NET','WTL-HP3B9-VDS4.WTLDEV.NET','WTL-HP3B9-VDS5.WTLDEV.NET','WTL-HP3B9-VDS6.WTLDEV.NET','WTL-HP3B9-VDS7.WTLDEV.NET','WTL-HP3B9-VDS8.WTLDEV.NET','WTL-HP3B9-VDS9.WTLDEV.NET','WTL-HP3B9-VDS10.WTLDEV.NET')
#$CTC = @('adc-ctc01.tecomgroup.ru','adc-ctc02.tecomgroup.ru','adc-ctc03.tecomgroup.ru','adc-ctc04.tecomgroup.ru','adc-ctc05.tecomgroup.ru','adc-ctc06.tecomgroup.ru','adc-ctc07.tecomgroup.ru','adc-ctc08.tecomgroup.ru','adc-ctc09.tecomgroup.ru','adc-ctc10.tecomgroup.ru','adc-ctc11.tecomgroup.ru','adc-ctc12.tecomgroup.ru','adc-ctc13.tecomgroup.ru','adc-ctc14.tecomgroup.ru','adc-ctc15.tecomgroup.ru','adc-ctc16.tecomgroup.ru','adc-ctc17.tecomgroup.ru','adc-ctc18.tecomgroup.ru','adc-ctc19.tecomgroup.ru','adc-ctc20.tecomgroup.ru','adc-ctc21.tecomgroup.ru','adc-ctc22.tecomgroup.ru','adc-ctc23.tecomgroup.ru','adc-ctc24.tecomgroup.ru')
$CTC = @('adc-ctc24.tecomgroup.ru')

$Creds = [System.Management.Automation.PSCredential]::new('local\Administrator',(ConvertTo-SecureString -AsPlainText 'Tecom_1!' -Force))

function GD {Get-Date -Format 'yyyy-MM-dd HH:mm:ss - '}
Write-Host "$(GD)Updating SQL records on $Server" -f Yellow

#### CAREFUL! Do-cycle inside Invoke-Command is endless whatever you do!!! Only PC restart can help #####################
sleep 1
do {
    Invoke-Command $CTC -Credential $Creds -ArgumentList $Server {
        param ($Server)

        #$Server = "wtl-hpx-325-n01.wtldev.net"
        $BaseName = "ASDB"
        $BaseLogin = "LouthDB"
        $BasePassw = "LouthDB"
        $connection = New-Object -com "ADODB.Connection"
        $ConnectionString = "Provider=SQLOLEDB.1;
                                Data Source=$Server;
                                Initial Catalog=$BaseName;
                                User ID=$BaseLogin;
                                Password=$BasePassw;"

        function GD {Get-Date -Format 'yyyy-MM-dd HH:mm:ss - '}
        function get-decT {
            $tt = Get-Date -Hour (Get-Random(24)) -Minute (Get-Random(60)) -Second (Get-Random(60))
            if (($tt.Second -eq 0) -and ($tt.Minute -ne 10)) { $decT = [int]("0x{0:HHmmss28}" -f ($tt.AddSeconds(-1))) }
            else { $decT = [int]("0x{0:HHmmss00}" -f ($tt)) }
            return $decT
        }
        <#function upd-query {
            $Global:n = 1 + (Get-Random 999)
            $Global:id = "Demo0{0:d3}" -f $n
            $dateTime = "{0:HH}:{0:mm}:{0:ss}" -f (Get-Date)
            $rndTC1 = (get-decT) ; $rndTC2 = (get-decT)
            $Global:query = "UPDATE [ASDB].[dbo].[ASDB] SET Title = '$dateTime', StartOfMessage = 0, Duration = 4096 WHERE Identifier = '$id'"
        }#>
        function upd-query {
            $Global:n = 1 + (Get-Random 4)
            $Global:id = "SWTCH7"
            $dateTime = "{0:HH}:{0:mm}:{0:ss}" -f (Get-Date)
            $rndTC1 = (get-decT) ; $rndTC2 = (get-decT)
            $Global:query = "UPDATE [ASDB].[dbo].[ASSEG] SET Title = '$dateTime' WHERE Identifier = '$id' and SegNum = $n"
        }

        #if (Get-Random 2) { #query will be sent with probability of n-1/n)
            $interval = 200000 #ms
            Start-Sleep -Milliseconds (Get-Random $interval)
            upd-query

            $connection.Open($ConnectionString)
            Start-Sleep -Milliseconds (Get-Random 200)
            $time = Get-Date
            $connection.Execute($query) | Out-Null
            $spent = $time - (Get-Date)
            #$log_string = "$(GD)UPDATE '$id' on $($Server -replace '\.\w*?\.\w*?$') from $env:COMPUTERNAME took $([math]::Round(((get-date) -$time).TotalMilliseconds)) ms"
            $log_string = "$(GD)UPDATE '$id' Seg $n on $($Server -replace '\.\w*?\.\w*?$') from $env:COMPUTERNAME took $([math]::Round(((get-date) -$time).TotalMilliseconds)) ms"
            Write-Host $log_string -f Green
            $connection.Close()
            Start-Sleep -Milliseconds (Get-Random $interval)
        #}
    }


    if ($host.ui.RawUi.KeyAvailable) {
        $key=$host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown,IncludeKeyUp")
        $Host.UI.RawUI.FlushInputBuffer()
            switch ($key.VirtualKeyCode) {
                <#Space#> 32 {}
                <#Esc#> 27 {return}
            } #end switch
    }

} until ($key.VirtualKeyCode -eq 27)
