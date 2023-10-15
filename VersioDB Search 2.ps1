$IP = '192.168.13.62'

$field = 'HouseID' # HouseID Title Description createdOn lastPlayDate expiredOn
$type1 = 'greaterEqual' # equals contains doesntcontain lessEqual greaterEqual 
$value1 = '!0' # 2020-03-15
$compose = 'and' # and or
$type2 = 'lessEqual' # contains doesntcontain lessEqual greaterEqual 
$value2 = '!9' # 2020-03-17

Write-Host "$field $type1 $value1 $compose $type2 $value2" -f Yellow -b Black

if (($type1 -ne 'greaterEqual') -and ($type1 -ne 'lessEqual')) {$value1 = '*'+$value1+'*'}
if (($type2 -ne 'greaterEqual') -and ($type2 -ne 'lessEqual')) {$value2 = '*'+$value2+'*'}

$body = '{
    "type": "'+$compose+'",
    "filters":
    [
        {
        "type": "'+$type1+'",
        "value": "'+$value1+'",
        "fieldName": "'+$field+'"
        },
        {
        "type": "'+$type2+'",
        "value": "'+$value2+'",
        "fieldName": "'+$field+'"
        },
    ]
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