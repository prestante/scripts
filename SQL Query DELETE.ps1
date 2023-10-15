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
    
$query = "DELETE [ASDB].dbo.ASDB where Identifier like 'D__'"
try {$recordSet = $connection.Execute($query)}
catch {Write-Host $Error[0].Exception.Message -f 14 -b 0}

"SQL query took {0:fff} ms" -f ((Get-Date) - $time)


$connection.Close()
