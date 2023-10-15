$IP = '192.168.13.62'

$field = 'HouseID' # HouseID Title Description createdOn lastPlayDate expiredOn
$type1 = 'equals' # equals contains doesntcontain lessEqual greaterEqual 
$value1 = '!4' # 2020-03-15

Write-Host "$field $type1 $value1" -f Yellow -b Black

if (($type1 -ne 'greaterEqual') -and ($type1 -ne 'lessEqual') -and ($type1 -ne 'equals')) {$value1 = '*'+$value1+'*'}

$body = '{
  "type": "'+$type1+'",
  "value": "'+$value1+'",
  "fieldName": "'+$field+'"
}'
$results = Invoke-RestMethod -Method Post -body $body -Uri "http://$IP/ContentService/api/contents/search" -ContentType 'application/json'
if ($results.results) {
    #creating a table
    $table = New-Object System.Data.DataTable
    $table.Columns.Add("Type","string") | Out-Null
    $table.Columns.Add("HouseID","string") | Out-Null
    if ($field -ne 'HouseID') {$table.Columns.Add("$field","string") | Out-Null}

    $results.results | sort -Property $field | % {
        if ($_.videostream.segments) {
            $row = $table.NewRow()
            $row.HouseID = $_.HouseID
            if ($field -ne 'HouseID') {$row.$field = $_.$field}
            $row.type = 'm'
            $table.Rows.Add($row)
            #Write-Host "$($_.HouseID)" -fo White -ba DarkGreen
        }
        elseif ($_.videostream) {
            $row = $table.NewRow()
            $row.HouseID = $_.HouseID
            if ($field -ne 'HouseID') {$row.$field = $_.$field}
            $row.type = 's'
            $table.Rows.Add($row)
            #Write-Host "$($_.HouseID)" -fo White -ba Blue
        }
    }
} else {Write-Host "--Not found--" -fo Red -ba Black ; $table = New-Object System.Data.DataTable}
$table