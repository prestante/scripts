$Server = "adcservices-3"
$BaseName = "ASDB"
$BaseLogin = "sa"
$BasePassw = "Tecom1"
$ConnectionString = "Provider=SQLOLEDB.1;
                        Data Source=$Server;
                        Initial Catalog=$BaseName;
                        User ID=$BaseLogin;
                        Password=$BasePassw;"
$content = @('Commercial','Political','Sports','Paid Programming')
$ic = 0
$cc = 0
function GD {Get-Date -Format 'yyyy-MM-dd HH:mm:ss - '}
function get-decT {
    $tt = Get-Date -Hour (Get-Random(24)) -Minute (Get-Random(60)) -Second (Get-Random(60))
    if (($tt.Second -eq 0) -and ($tt.Minute -ne 10)) { $decT = [int]("0x{0:HHmmss28}" -f ($tt.AddSeconds(-1))) }
    else { $decT = [int]("0x{0:HHmmss00}" -f ($tt)) }
    return $decT
}
function update-query {
    $rndTC1 = (get-decT) ; $rndTC2 = (get-decT) ; $n = Get-Random 10000
    $a = ("{0:x}" -f $rndTC2).PadLeft(8,'0') -split '(..)' | ? {$_}
    $durSTR = "{0}:{1}:{2};{3}" -f $a[-4], $a[-3], $a[-2], $a[-1]
    $Global:query = "UPDATE [ASDB].[dbo].[ASDB] SET "

    if (($CON) -or ($ALL)) {$Global:query += "Content = '$($content[$ic])', " ; $Global:ic++ ; if ($ic -ge $content.Count){$Global:ic = 0}}
    if (($TIT) -or ($ALL)) {$Global:query += "Title = '$durSTR', "}
    if (($SOM) -or ($ALL)) {$Global:query += "StartOfMessage = $rndTC1, "}
    if (($DUR) -or ($ALL)) {$Global:query += "Duration = $rndTC2, "}

    if (($RAT) -or ($ALL)) {$Global:query += "Rating = '$durSTR', "}
    if (($AFD) -or ($ALL)) {$Global:query += "AFD = $([int]($n/100)), "}
    if (($DIA) -or ($ALL)) {$Global:query += "DialNorm = $([int]($n/10)), "}
    if (($CLC) -or ($ALL)) {$Global:query += "ClosedCaption = $cc, " ; $Global:cc++ ; if ($cc -gt 1){$Global:cc = 0}}
    if (($SHI) -or ($ALL)) {$Global:query += "ShowID = '$durSTR', "}
    if (($SHD) -or ($ALL)) {$Global:query += "ShowDescription = '$durSTR', "}

    $Global:query += "PlayNumber = $n WHERE Identifier = '!0'"
}
function send-query {
    if (Test-Connection $Server -Count 1 -Quiet) {
        update-query
        Write-Host "$(GD)$($Global:query)" -f 11
        try {
            $connection = New-Object -com "ADODB.Connection"
            $connection.Open($ConnectionString)
            #$Global:recordSet = $connection.Execute($Global:query)
            $connection.Execute($Global:query) | Out-Null
            $connection.Close()
            Write-Host "$(GD)Success" -f 10
        } catch {Write-Host "$(GD)$($Error[0])" -f Magenta -b Black}
    } else {Write-Host "$(GD)Host '$Server' is unreachable." -fo Red -ba Black}
}


#do {

#send-query

    if ($host.ui.RawUi.KeyAvailable) {
        $key=$host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        $Host.UI.RawUI.FlushInputBuffer()
            switch ($key.VirtualKeyCode) {
                <#T#> 84 {Write-Host "$(GD)Updating Title" -f 14 -b 08  ; $TIT = 1 ; send-query ; $TIT = $null}
                <#N#> 78 {Write-Host "$(GD)Updating DUR and SOM" -f 14 -b 08  ; $DUR = 1; $SOM = 1; send-query; $DUR = $SOM = $null}
                <#A#> 65 {Write-Host "$(GD)Updating All" -f 14 -b 08  ; $ALL = 1; send-query; $ALL = $null}
                <#Space#> 32 {send-query}
                <#Esc#> 27 {return}
            } #end switch
    }
    sleep -Milliseconds 1000

#} until ($key.VirtualKeyCode -eq 27)

Write-Host "$(GD)Updating All" -f 14 -b 08  ; $ALL = 1; send-query; $ALL = $null
