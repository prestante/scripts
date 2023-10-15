# This script sends bxf message to Integration Service REST adapter to add/remove or update ss or ms.
# Enter IP of Integration Service. 
# Enter Action ('add' or 'remove' or 'update')
# Enter HouseIDmask which will be used as prefix of Multi Segment head ID
# Enter FirstSuffix and LastSuffix
# Bunch of Multi Segments with IDs constucted by adding suffix to prefix will be added/removed
# I.E. prefix is 'bxf', suffixes are 0 to 99 will result in such IDs: bxf00,bxf01,...,bxf98,bxf99
# Enter XmlFile which is a path to xml document with right structure

$IP = '192.168.13.169'
$Action = 'add'
$HouseIDmask = 'BXF-SS'
$FirstSuffix = 1
$LastSuffix = 1
$XmlFile = 'C:\PS\xml\Dub List.xml'
#$XmlFile = 'C:\PS\xml\Add or Remove DB single spot.xml'
#$XmlFile = 'C:\PS\xml\BxfQuery.xml'
#$XmlFile = '\\fs\Shares\Engineering\ADC\QA\ResourcesForTesting\Integration - REST\Content Processor\SS Add DB.xml'

if ($LastSuffix -lt $FirstSuffix) {break}
$ScriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$Url = 'http://' + $IP + ':1985/SendMessage'
$n = switch ($LastSuffix) {
    {$_ -eq 0} { 0 }
    {$_ -in 1..9} { 1 }
    {$_ -in 10..99} { 2 }
    {$_ -in 100..999} { 3 }
}

function GD {Get-Date -Format 'yyyy-MM-dd HH:mm:ss - '}
$Time=Get-Date -Format 'ddMMyyHHmmss'

for ($i=$FirstSuffix ; $i -le $LastSuffix ; $i++) {    
    if ($n) { $HouseID = $HouseIDmask + "{0:d$n}" -f $i }    else { $HouseID = $HouseIDmask }    $Content = Get-Content $XmlFile -Raw | % {$_ -replace '#ACTION',$Action -replace '#HOUSEID',$HouseID -replace '#TIME',$Time}        "$(GD)Sending bxf to $Action $HouseID"            #sending xml message to rest adapter    Invoke-RestMethod -Method 'post' -Uri $Url -Body $Content}
