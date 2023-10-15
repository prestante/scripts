$IP1 = '192.168.13.69'$IP2 = ''$XmlFile = 'C:\PS\!!!CTC_bxf_Schedule_for_Soap_UI_3877.xml'#$XmlFile = 'C:\PS\Add.Pri.and.Sec.Template.xml'#Setting configuration and Getting list of ListNames from all Integration Services config files
$Url1 = 'http://' + $IP1 + ':1985/SendMessage?destination_name=traffic'
$ISConfFile1 = '\\' + $IP1 + '\Imagine Communications\ADC Services\config\IntegrationService.xml'
$ISConf1 = (Get-Content $ISConfFile1)
if ($IP2 -like '192.168.*') {    $Url2 = 'http://' + $IP2 + ':1985/SendMessage?destination_name=traffic'
    $ISConfFile2 = '\\' + $IP2 + '\Imagine Communications\ADC Services\config\IntegrationService.xml'
    $ISConf2 = (Get-Content $ISConfFile2)
    $ISCumul = $ISConf1 + $ISConf2}
else {$ISCumul = $ISConf1; $ISConf2 = ''}
$Lists = @($ISCumul | where {$_ -match "<ChannelName>(?<ListName>.*)</ChannelName>"} | % {$matches['ListName']})

$Date=(Get-Date).AddDays(1) | Get-Date -Format 'yyyy-MM-dd'
$Time=Get-Date -Format 'ddMMyyHHmmss'
function GD {get-date -Format 'ddHHmmssffff'}
#$Lists.Length
<##for ($i=0 ; $i -lt $Lists.Length-39 ; $i++) {    
    #what url send message to? or even break the cycle
    if (($ISConf1 -match $Lists[$i]) -and ($Lists[$i] -gt ' ')) {$Url = $Url1} elseif (($ISConf2 -match $Lists[$i]) -and ($Lists[$i] -gt ' ')) {$Url = $Url2} else {break}
    
    #replacing #-templates with tomorrow's date, ListName and unique GUID based on current date/time       
    $time1=Get-Date
    
    $rawguids = Get-Content $XmlFile -raw | Select-String "\w{8}-\w{4}-\w{4}-\w{4}-\w{12}" -AllMatches
    $guids = $rawguids.Matches | Sort-Object value | Get-Unique
    Remove-Variable rawguids
    $content = Get-Content $XmlFile -raw
    $guids.Count
    for ($i=0 ; $i -lt $guids.Count ; $i++) {            $guid = '00000000-0000-0000-0000-'+(GD)            $content = $content -replace $guids.value[$i],$guid            #$old = $fresh; $fresh = $guid            #'guid: ' ; $guid            #'old: ' ; $old            #$i            #$guids.value[$i]            #'b';$content = $content -replace $guids.Matches.value[$i],$old            #            #$i            #$guids.Matches.value[$i]        }        $time2=Get-Date    "{0:mm}:{0:ss}" -f ($time2 - $time1)

    $content | Out-File 'C:\PS\Conte'

#}
#>

<#
    
    
    
    $time1=Get-Date
    $Content = (Get-Content $XmlFile | % {
        $line = $_
        if ($line -like '*<EventId>urn*') {
            $guid = '00000000-0000-0000-0000-'+(GD)
            $line = $line -replace ':.{36}<',(':' + $guid + '<')
            $old = $fresh; $fresh = $guid
        }
        if ($line -like '*<InsertAfterEventId>*') {
            $line = $line -replace ':.{36}<',(':' + $old + '<')
        }
        #if ($line -like '*#DATE*') {$line = $line -replace '#DATE',$Date}
        #if ($line -like '*#LIST*') {$line = $line -replace '#LIST',$Lists[$i]}
        #if ($line -like '*#TIME*') {$line = $line -replace '#TIME',$Time}
        $line
    })        #$Content = [string]$Content | % {$_ -replace '#DATE',$Date -replace '#LIST',$Lists[$i] -replace '#TIME',$Time}    Write-Host 'Sending schedule for ' -NoNewLine    Write-Host $Lists[$i] -NoNewline    Write-Host '  ->  ' -NoNewline    Write-Host $Url        $time2=Get-Date    "{0:mm}:{0:ss}" -f ($time2 - $time1)    #sending xml message to rest adapter    #Invoke-RestMethod -Method 'post' -Uri $Url -Body $Content    #Start-Sleep -Seconds 20}#>#testing performance difference$i=0$time1=Get-Date
    
$content = Get-Content $XmlFile | % {$_ -replace '#LIST', '#BEAST'; $i++} | Out-Null



<#
$rawguids = Get-Content $XmlFile -raw | Select-String "\w{8}-\w{4}-\w{4}-\w{4}-\w{12}" -AllMatches
$guids = $rawguids.Matches | Sort-Object value | Get-Unique
Remove-Variable rawguids
$content = Get-Content $XmlFile -raw
$guids.Count
for ($i=0 ; $i -lt $guids.Count ; $i++) {    $guid = '00000000-0000-0000-0000-'+(GD)    $content = $content -replace $guids.value[$i],$guid    #$old = $fresh; $fresh = $guid    #'guid: ' ; $guid    #'old: ' ; $old    #$i    #$guids.value[$i]    #'b';$content = $content -replace $guids.Matches.value[$i],$old    #    #$i    #$guids.Matches.value[$i]    }#>    $time2=Get-Date    "{0:mm}:{0:ss}" -f ($time2 - $time1)
    $i

    #$content | Out-File 'C:\PS\Conte'