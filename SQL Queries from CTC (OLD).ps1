Invoke-Command $CTC {
    $Server = "192.168.13.238"
    $BaseName = "ASDB"
    $BaseLogin = "LouthDB"
    $BasePassw = "LouthDB"
    $connection = New-Object -com "ADODB.Connection"
    $ConnectionString = "Provider=SQLOLEDB.1;
                         Data Source=$Server;
                         Initial Catalog=$BaseName;
                         User ID=$BaseLogin;
                         Password=$BasePassw;"

    do {
        Start-Sleep -Milliseconds (Get-Random 6000)
        $n = Get-Random 9
        
        $connection.Open($ConnectionString)
        $time = Get-Date
        $recordSet = $connection.Execute("SELECT * FROM [ASDB].[dbo].[ASDB] where Identifier LIKE '_$n%'")
        $i=0
        While (-not $recordSet.EOF) {
        #  echo $recordSet.Fields.Item("Identifier").Value
            $i++
            $recordSet.MoveNext()
        }
        "SQL Query `"SELECT ID LIKE '_$n%'`" from $env:COMPUTERNAME returned {1:000} results and took {0:fff} ms" -f ((Get-Date) - $time), $i
        $connection.Close()
    } while (1)
}