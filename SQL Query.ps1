Invoke-Command {
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

    $connection.Open($ConnectionString)
    $time = Get-Date
    
    $field = 'Identifier'
    $query = "SELECT * FROM [ASDB].[dbo].[ASDB] where Identifier LIKE '_1'"

    $recordSet = $connection.Execute($query)
    $i=0
    While (-not $recordSet.EOF) {
        $recordSet.Fields.Item("$field").Value
        $i++
        $recordSet.MoveNext()
    }
    "SQL Query '$query' returned {1:000} results and took {0:fff} ms" -f ((Get-Date) - $time), $i
    $connection.Close()
}