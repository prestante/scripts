$Server = "adc-ctc14"
$BaseName = "ASDB_REP"
$BaseLogin = "sa"
$BasePassw = "Tecom1"
$ConnectionString = "Provider=SQLOLEDB.1;
                        Data Source=$Server;
                        Initial Catalog=$BaseName;
                        User ID=$BaseLogin;
                        Password=$BasePassw;"
function GD {Get-Date -Format 'yyyy-MM-dd HH:mm:ss - '}

#do {
#    Start-Sleep -Milliseconds (Get-Random 6000)
#    $n = Get-Random 9
    
    if (Test-Connection $Server -Count 1 -Quiet) {
        try {
            $connection = New-Object -com "ADODB.Connection"
            $connection.Open($ConnectionString)
            $time = Get-Date
            $recordSet = $connection.Execute("SELECT * FROM [$BaseName].[dbo].[ASDB]")

            #cls
            #"{0} - {1}" -f ($Server),([System.Net.Dns]::GetHostByAddress($Server).HostName)
            #"Server: $Server"
            [psobject[]]$all = @()
            While (-not $recordSet.EOF) {
                #Write-Host "$($recordSet.Fields.Item("Identifier").Value) | " -NoNewline
                #Write-Host "$($recordSet.Fields.Item("Title").Value)  "
                #$Identifier = try {$recordSet.Fields.Item("Identifier").Value} catch {""}
                #$Identifier

                $cur = New-Object -TypeName PSObject
                foreach ($field in $recordSet.Fields) {
                    if ([string]$field.Value) {
                        $cur | Add-Member -MemberType NoteProperty -Name $field.Name -Value $field.Value
                    }
                }
                [psobject[]]$all += $cur
                $recordSet.MoveNext()
            }
            $connection.Close()
            $all | sort -Property Identifier | ft *
            Start-Sleep -Milliseconds 500
        } catch {Write-Host $Error[0] -fo Magenta -ba Black}
    } else {Write-Host "$(GD)Host '$Server' is unreachable." -fo Red -ba Black}
#} while (1)