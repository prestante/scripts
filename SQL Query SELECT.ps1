Param(
#[array]
#[Parameter(ValueFromRemainingArguments=$true)]
[string]$Server)

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

do {
    if (Test-Connection $Server -Count 1 -Quiet) {
        try {
            $connection = New-Object -com "ADODB.Connection"
            $connection.Open($ConnectionString)
            $time = Get-Date
            $recordSet = $connection.Execute("SELECT * FROM [ASDB].[dbo].[ASDB] where Identifier LIKE '!_'")
            $i=0
            [int[]]$durs = @()

            cls
            Write-Host "$($Server -replace '\.\w*?\.\w*?$')" -f Green
            While (-not $recordSet.EOF) {
                Write-Host "$($recordSet.Fields.Item("Identifier").Value)  " -NoNewline
                #Write-Host "$($recordSet.Fields.Item("Duration").Value)  " -NoNewline 
                $durs += $recordSet.Fields.Item("Duration").Value
                $a = ("{0:x}" -f $durs[$i]).PadLeft(8,'0') -split '(..)' | ? {$_}
                Write-Host ("{0}:{1}:{2};{3}" -f $a[-4], $a[-3], $a[-2], $a[-1])
                $i++
                $recordSet.MoveNext()
            }
            #Write-Host "$(GD)SQL Query from $env:COMPUTERNAME to $($Server -replace '\.\w*?\.\w*?$') returned $i results and took $([math]::Round(((get-date) -$time).TotalMilliseconds)) ms" -f Green
            $connection.Close()
            Start-Sleep -Milliseconds 500
        } catch {Write-Host "$(GD)Connection to $Server cannot be established. We'll try again in 5 seconds." -fo Red -ba Black ; Start-Sleep 5}
    } else {Write-Host "$(GD)Connection to $Server cannot be established. We'll try again in 10 seconds." -fo Red -ba Black ; Start-Sleep 10}
} while (1)