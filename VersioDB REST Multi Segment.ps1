$HouseID='@1'
$IP = '192.168.13.69'
$NewSOM = '00:00:00;00'
$NewDUR = '00:00:41;00'
$NewTITLE = $HouseID + ' title'
#$NewTITLE = 'String with thirty four characters'

$Body = '{
    "videoStream": {
        "start": "' + $NewSOM + '%00SD",
        "duration": "' + $NewDUR + '%00SD",
        "customStart": "' + $NewSOM + '%00SD",
        "customDuration": "' + $NewDUR + '%00SD",
        "segments": [
            {
                "number": "1",
                "description": "String with thirty four characters",
                "start": "00:00:00;00%00SD",
                "duration": "00:00:17;00%00SD",
            },
            {
                "number": "2",
                "description": "String with thirty four characters",
                "start": "00:00:17;00%00SD",
                "duration": "00:00:13;00%00SD",
            },
            {
                "number": "3",
                "description": "String with thirty four characters",
                "start": "00:00:30;00%00SD",
                "duration": "00:00:11;00%00SD",
            },
        ],
    },
"houseId": "' + $HouseID + '",
"type": "clip",
"title": "' + $NewTITLE + '",
"description": "' + $($HouseID + ' des') + '",
}'


#update ID by HouseID
#Invoke-RestMethod -Method Patch -Uri "http://$IP/ContentService/api/contents?houseId=$HouseID" -Body $Body -ContentType 'application/json'

#create new ID
Invoke-RestMethod -Method Post -Uri "http://$IP/ContentService/api/contents" -Body $Body -ContentType 'application/json' | Out-Null

#retrieve HouseID,Title,Start,Duration by HouseID
$results = (Invoke-RestMethod -Method Get -Uri "http://$IP/ContentService/api/contents?houseId=$HouseID" | ConvertTo-Json -Depth 9 | ConvertFrom-Json).results
if ($results.videostream.segments) {
    Write-Host "--Multi Segment--" -NoNewline -fo White -ba DarkGreen
    $results | select -Property houseID, title, lastPlayDate -ExpandProperty videostream | select -Property HouseID,Title,start,duration,lastPlayDate
    $results.videostream.segments | select -Property number, description, start, duration
}
elseif ($results.videostream) {
    Write-Host "--Single Spot--" -NoNewline -fo White -ba Blue
    $results | select -Property houseID, title, lastPlayDate -ExpandProperty videostream | select -Property HouseID,Title,start,duration,lastPlayDate
}
else {Write-Host "--Not found--" -NoNewline -fo Red -ba Black ; return}

#retrieve ID by HouseID
#(Invoke-RestMethod -Method Get -Uri "http://$IP/ContentService/api/contents?houseId=$HouseID" | ConvertTo-Json -Depth 10 | ConvertFrom-Json).results.id | Tee-Object -Variable ID

#delete ID
#Invoke-RestMethod -Method Delete -Uri "http://$IP/ContentService/api/contents/$($ID)?deleteRedundant=true"
