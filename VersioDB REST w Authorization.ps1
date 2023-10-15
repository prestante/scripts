$HouseID='clip23'
$IP = '192.168.13.69'
#$IP = '192.168.19.68'
#$IP = 'adc-core-vm'
$NewSOM = '00:00:00;00'
$NewDUR = '00:00:17;00'
$NewTITLE = $HouseID + ' title'

$Body = '{
"houseId": "' + $HouseID + '",
"type": "clip",
"title": "' + $NewTITLE + 'program",
"functionalType": "program",
}'

<#
"videoStream": {
    "start": "' + $NewSOM + '%00SD",
    "duration": "' + $NewDUR + '%00SD",
    "customStart": "' + $NewSOM + '%00SD",
    "customDuration": "' + $NewDUR + '%00SD",
},
"createdOn": "2020-03-15T10:48:01.45Z",
"description": "' + $($HouseID + ' des') + '",
"functionalType": "GraphicElement",
#>

#We probably have to also request client_secret (Content-portal's secret) somehow because it changes sometimes as I understand.
$tokenRequestBody = @{ grant_type = 'password'
                client_id = 'content-portal'
                client_secret = 'daa3dc33-9f7c-4160-9e1f-5c23085bc6be'
                username = 'administrator'
                password = 'Pass123$'
                scope = 'openid role content-service.configuration.write content-service.configuration.read content-service.content.read content-service.content.write'}
$token = (Invoke-RestMethod -Method post -Uri "http://it-docker02.tecomgroup.ru:8180/auth/realms/Versio/protocol/openid-connect/token" -Body $tokenRequestBody -ContentType "application/x-www-form-urlencoded").access_token
$headers = @{Authorization="Bearer $token"}

##########################################################################################################################################################################################################

#retrieve ID by HouseID
#(Invoke-RestMethod -Method Get -Uri "http://$IP/ContentService/api/contents?houseId=$HouseID" -Headers $headers | ConvertTo-Json -Depth 10 | ConvertFrom-Json).results.id | Tee-Object -Variable ID

#update ID by HouseID
#Invoke-RestMethod -Method Patch -Uri "http://$IP/ContentService/api/contents?houseId=$HouseID" -Body $Body -ContentType 'application/json' -Headers $headers

#create new ID
Invoke-RestMethod -Method Post -Uri "http://$IP/ContentService/api/contents" -Body $Body -ContentType 'application/json' -Headers $headers | Out-Null

#retrieve HouseID,Title,Start,Duration by HouseID
$results = (Invoke-RestMethod -Method Get -Uri "http://$IP/ContentService/api/contents?houseId=$HouseID" -Headers $headers | ConvertTo-Json -Depth 9 | ConvertFrom-Json).results

#retrieve HouseID,Title,Start,Duration by ID
#$ID = 'ffaffc306ee14051b2a10d7f330b14f5'
#$results = (Invoke-RestMethod -Method Get -Uri "http://$IP/ContentService/api/contents?Id=$ID" -Headers $headers | ConvertTo-Json -Depth 9 | ConvertFrom-Json).results

if ($results.videostream.segments) {
    Write-Host "--Multi Segment--" -NoNewline -fo White -ba DarkGreen
    $results | select -Property houseID, title, lastPlayDate, Type, FunctionalType -ExpandProperty videostream | select -Property HouseID,Title,start,duration,lastPlayDate, Type, FunctionalType
    $results.videostream.segments | select -Property number, description, start, duration
}
elseif ($results.videostream) {
    Write-Host "--Single Spot--" -NoNewline -fo White -ba Blue
    $results | select -Property houseID, title, lastPlayDate, Type, FunctionalType -ExpandProperty videostream | select -Property HouseID,Title,start,duration,lastPlayDate, Type, FunctionalType
}
elseif ($results.type) {
    Write-Host "--$($results.type)--" -NoNewline -fo White -ba DarkGray
    $results | select -Property houseID, title, createdOn, modifiedOn, Type, FunctionalType | fl
}
else {Write-Host "--Not found--" -NoNewline -fo Red -ba Black ; return}
#(Invoke-RestMethod -Method Get -Uri "http://$IP/ContentService/api/contents?houseId=$HouseID" | ConvertTo-Json -Depth 9 | ConvertFrom-Json).results | select -Property houseID, title, lastPlayDate -ExpandProperty videostream | select -Property HouseID,Title,start,duration,lastPlayDate  | fl

#delete ID
#Invoke-RestMethod -Method Delete -Uri "http://$IP/ContentService/api/contents/$((Invoke-RestMethod -Method Get -Uri "http://$IP/ContentService/api/contents?houseId=$HouseID" -Headers $headers).results.id)?deleteRedundant=true" -Headers $headers ; Write-Host "DELETED" -fo White -ba DarkRed

return

#create every ID in range "Demo0500-Demo0699". SOM and DUR are increasing for 1 seconds starting from 5 seconds.
for ($($i=0 ; $j=500 ; $t=Get-Date(0) -Second 5) ; $i -lt 200 ; $i++) {
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
    Invoke-RestMethod -Method Post -Uri "http://$IP/ContentService/api/contents" -Body $Body -ContentType 'application/json' -Headers $headers | Out-Null
    $HouseID
}

#show/delete found IDs with some prefix (see $HouseID)
for ($i=500 ; $i -lt 700 ; $i++) {
    $HouseID = "Demo0{0:d3}" -f ($i)
    $ID=(Invoke-RestMethod -Method Get -Uri "http://$IP/ContentService/api/contents?houseId=$HouseID" -Headers $headers).results.id
    #if ($ID) {Invoke-RestMethod -Method Delete -Uri "http://$IP/ContentService/api/contents/$($ID)?deleteRedundant=true" -Headers $headers -ea SilentlyContinue | Out-Null}
    if ($ID) {"$HouseID - $ID"}
}