$HouseID='Clip17'
$IP = '192.168.13.69'
#$IP = 'adc-core-vm'
#$IP = '192.168.13.163'
$NewSOM = '00:00:00;00'
$NewDUR = '00:00:17;00'
$NewTITLE = $HouseID + ' title'
$NewTITLE = 'String with thirty four characters'

$Body = '{ 
"videoStream": {
    "start": "' + $NewSOM + '%00SD",
    "duration": "' + $NewDUR + '%00SD",
    "customStart": "' + $NewSOM + '%00SD",
    "customDuration": "' + $NewDUR + '%00SD",
    "functionalType": "program",
},
"houseId": "' + $HouseID + '",
"type": "clip",
"title": "' + $NewTITLE + '",
"description": "' + $($HouseID + ' des') + '",
}'

#"createdOn": "2020-03-15T10:48:01.45Z",

#retrieve ID by HouseID
#(Invoke-RestMethod -Method Get -Uri "http://$IP/ContentService/api/contents?houseId=$HouseID" | ConvertTo-Json -Depth 10 | ConvertFrom-Json).results.id | Tee-Object -Variable ID

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
elseif ($results.type) {
    Write-Host "--$($results.type)--" -NoNewline -fo White -ba DarkGray
    $results | select -Property houseID, title, createdOn, modifiedOn | fl
}
else {Write-Host "--Not found--" -NoNewline -fo Red -ba Black ; return}
#(Invoke-RestMethod -Method Get -Uri "http://$IP/ContentService/api/contents?houseId=$HouseID" | ConvertTo-Json -Depth 9 | ConvertFrom-Json).results | select -Property houseID, title, lastPlayDate -ExpandProperty videostream | select -Property HouseID,Title,start,duration,lastPlayDate  | fl

#delete ID
#Invoke-RestMethod -Method Delete -Uri "http://$IP/ContentService/api/contents/$((Invoke-RestMethod -Method Get -Uri "http://$IP/ContentService/api/contents?houseId=$HouseID").results.id)?deleteRedundant=true" ; Write-Host "DELETED" -fo White -ba DarkRed

return

#create every ID in range "Demo0500-Demo0699". SOM and DUR are increasing for 1 seconds starting from 5 seconds.
for ($($i=0 ; $j=500 ; $t=Get-Date(0) -Second 5) ; $i -lt 20 ; $i++) {
    $HouseID = "Demo{0:d4}" -f ($i + $j)
    $tt = $t.AddSeconds($i)
    if ( ($tt.Second -eq 0) -and ($tt.Minute -ne 10) ) { $Timecode = "{0:HH:mm:ss;28}" -f $tt.AddSeconds(-1) }
    else { $Timecode = "{0:HH:mm:ss;00}" -f $tt }
    $NewSOM = $Timecode
    $NewDUR = $Timecode
    $NewTITLE = 
        if ( $tt.Minute -eq 0 ) { "$($tt.Second)s real video" }
        elseif ( ($tt.Minute -ne 0) -and ($tt.Second -eq 0) ) { "$($tt.Minute)m real video" }
        else { "$($tt.Minute)m$($tt.Second)s real video" }
    $Body = '{ 
    "videoStream": {
        "start": "' + $NewSOM + '%00SD",
        "duration": "' + $NewDUR + '%00SD",
        "customStart": "' + $NewSOM + '%00SD",
        "customDuration": "' + $NewDUR + '%00SD",
        "frameRate": "smpte30d",
    },
    "houseId": "' + $HouseID + '",
    "type": "clip",
    "title": "' + $NewTITLE + '",
    "description": "' + $($NewTITLE -replace ' real video') + '",
    }'
    Invoke-RestMethod -Method Post -Uri "http://$IP/ContentService/api/contents" -Body $Body -ContentType 'application/json' | Out-Null
    $HouseID
}

#show/delete found IDs with some prefix (see $HouseID)
for ($i=0 ; $i -le 99 ; $i++) {
    $HouseID = "Demo06{0:d2}" -f ($i)
    $ID=(Invoke-RestMethod -Method Get -Uri "http://$IP/ContentService/api/contents?houseId=$HouseID").results.id
    #if ($ID) {Invoke-RestMethod -Method Delete -Uri "http://$IP/ContentService/api/contents/$($ID)?deleteRedundant=true" -ea SilentlyContinue | Out-Null}
    if ($ID) {"$HouseID - $ID"}
}