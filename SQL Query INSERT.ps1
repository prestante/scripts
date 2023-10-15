$Server = "wtl-hpx-325-n01.wtldev.net"
$BaseName = "ASDB"
$BaseLogin = "LouthDB"
$BasePassw = "LouthDB"
$connection = New-Object -com "ADODB.Connection"
$ConnectionString = "Provider=SQLOLEDB.1;
                        Data Source=$Server;
                        Initial Catalog=$BaseName;
                        User ID=$BaseLogin;
                        Password=$BasePassw;"

$connection.Open($ConnectionString)
$time = Get-Date

$Identifier = $ShowDescription = $AFD = $Rating = $ShowID = $Title = $Duration = $StartOfMessage = $Content = $AssegTitle1 = $AssegStartOfMessage1 = $AssegDuration1 = $AssegTitle2 = $AssegStartOfMessage2 = $AssegDuration2 = $null

$refQuerySS = "INSERT [ASDB].[dbo].[ASDB] (Identifier, Type, Operator, ShowDescription, AFD, Rating, DialNorm, ClosedCaption, ShowID, Title, Duration, StartOfMessage, Content)
    Values ('$Identifier', 's', 'aa', '$ShowDescription', $AFD, '$Rating', 4096, 1, '$ShowID', '$Title', $Duration, $StartOfMessage, '$Content')"
$refQueryMS = "INSERT [ASDB].[dbo].[ASDB] (Identifier, Type, Operator, ShowDescription, AFD, Rating, DialNorm, ClosedCaption, ShowID, Title, Duration, StartOfMessage, Content)
    Values ('$Identifier', 'm', 'aa', '$ShowDescription', $AFD, '$Rating', 4096, 1, '$ShowID', '$Title', $Duration, $StartOfMessage, '$Content')
    INSERT [ASDB].[dbo].[ASSEG] (Identifier, Type, SegNum, SegType, Title, StartOfMessage, Duration)
    Values ('$Identifier', 'm', 1, 1, '$AssegTitle1', $AssegStartOfMessage1, $AssegDuration1)
    INSERT [ASDB].[dbo].[ASSEG] (Identifier, Type, SegNum, SegType, Title, StartOfMessage, Duration)
    Values ('$Identifier', 'm', 2, 1, '$AssegTitle2', $AssegStartOfMessage2, $AssegDuration2)"

    
for ($i = 0; $i -lt 10; $i++){
    $query = "INSERT [ASDB].dbo.ASDB (Identifier, Type) Values ('!{0:d1}', 's')" -f $i
    try {$recordSet = $connection.Execute($query)}
    catch {Write-Host $Error[0].Exception.Message -f 14 -b 0}
    #$query
}

"$i SQL queries took {0:fff} ms" -f ((Get-Date) - $time)


$connection.Close()

sleep 1
