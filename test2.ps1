$file = 'C:\Lists\List12500 PL Clear.lst'
#$file = Get-FileName('C:\Lists')
if (!$file) { exit }

#$time1 = Get-Date
#$Content = New-object -type System.Collections.ArrayList
#(Get-Content $file -ReadCount 0 -Encoding Byte) | % {$Content.Add($_)} | Out-Null # read entire list
#(Get-Content $file -TotalCount 7000 -Encoding Byte) | % {$Content.Add($_)} | Out-Null #read first 7000 bytes ~10-20 events
#(Get-Content $file -TotalCount (750*$eventsToShow) -Encoding Byte) | % {$Content.Add($_)} | Out-Null # read approximate number of bytes corresponding to $eventsToShow
#(Get-Content $file -TotalCount (750*($startEvent + $eventsToShow)) -Encoding Byte) | % {$Content.Add($_)} | Out-Null # read approximate number of bytes corresponding to $startEvent plus $eventsToShow
$Content = Get-Content $file -Raw -Encoding Byte
#"{0} seconds ({1} ms)" -f[math]::Round(((Get-Date) - $time1).TotalSeconds, 1), [int]((Get-Date) - $time1).TotalMilliseconds ; return

$table = New-Object System.Data.DataTable  # creating a table of events
$table.Columns.Add("No","int") | Out-Null
$table.Columns.Add("DateToAir","string") | Out-Null
$table.Columns.Add("OnAirTime","string") | Out-Null
$table.Columns.Add("OrigDate","string") | Out-Null
$table.Columns.Add("OrigTime","string") | Out-Null
$table.Columns.Add("Sec","string") | Out-Null
$table.Columns.Add("Type","string") | Out-Null
$table.Columns.Add("ID","string") | Out-Null
$table.Columns.Add("Seg","string") | Out-Null
$table.Columns.Add("Title","string") | Out-Null
$table.Columns.Add("DUR","string") | Out-Null
$table.Columns.Add("SOM","string") | Out-Null
$table.Columns.Add("ABOX","string") | Out-Null
$table.Columns.Add("ABOXSOM","string") | Out-Null
$table.Columns.Add("BBOX","string") | Out-Null
$table.Columns.Add("BBOXSOM","string") | Out-Null
$table.Columns.Add("Reconcile","string") | Out-Null
$table.Columns.Add("CompileID","string") | Out-Null
$table.Columns.Add("CompileSOM","string") | Out-Null
$table.Columns.Add("sSP","string") | Out-Null
$table.Columns.Add("EvtType","string") | Out-Null
$table.Columns.Add("ResBuffer","string") | Out-Null
$table.Columns.Add("Content","string") | Out-Null
$table.Columns.Add("Rating","string") | Out-Null
$table.Columns.Add("ShowID","string") | Out-Null
$table.Columns.Add("ShowDescription","string") | Out-Null

$pos = 0
$time0 = Get-Date

do {
    $pos = $pos + 1    
} while (($pos -lt $Content.Count))

"{0} seconds ({1} ms)" -f[math]::Round(((Get-Date) - $time0).TotalSeconds, 1), [int]((Get-Date) - $time0).TotalMilliseconds


