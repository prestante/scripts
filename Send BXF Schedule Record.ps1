<#Send schedule to multiple Lists using xml file prepared in advance with #TEMPLATES inside to change them to tomorrow's date, unique GUID and List (channel) name.To get this working you should do few preparations:    1. Configure several Integration Services for REST: One IS can process up to 48 channels (Lists). Use port 1985 for BXF communication interface.    2. Know IP of those ISs.    3. Share folder of IS PC \\192.168.IS.IP\Imagine Communications\ to be readable by EVERYONE.    4. Try to open EACH of those folders from THIS PC. Enter credentials TECOM\adcqauser Tecom123 (or admin creds) if needed.    5. Enter IP of prepared ISs to $IP1 and $IP2 values. If you use just one IS, set $IP2 =''    6. Put .xml file containing BXF message body to disk C:\     7. BXF file should content #DATE instead of date values, #LIST instead of channel name and $TIME instead of last 12 symbols in scheduleId    8. Don't forget to set right $XmlFile path and name down below.Here we are working with two Integration Services, one at CHP-7 and another at CHP-8. We are getting their IS configs to parse them for list of ListNames which will be used for sending schedule to each of them.Algorythm will decide which IS we should send the message for each particular ListName#>$IP1 = '192.168.13.69'$IP2 = ''$XmlFile = 'C:\PS\xml\Add Record Events.xml'#$XmlFile = 'C:\PS\xml\3877.xml'#$XmlFile = 'C:\PS\xml\!!!CTC_bxf_Schedule_for_Soap_UI_3877.xml'#$XmlFile = 'C:\PS\xml\Add.Pri.and.Sec.Template.Shortest.xml'#$XmlFile = 'C:\PS\xml\Add.Pri.and.Sec.Template.One.xml'#Setting configuration and Getting list of ListNames from all Integration Services config files
$Url1 = 'http://' + $IP1 + ':1985/SendMessage?destination_name=traffic'
$ISConfFile1 = '\\' + $IP1 + '\Imagine Communications\ADC Services\config\IntegrationService.xml'
$ISConf1 = (Get-Content $ISConfFile1)
if ($IP2 -like '192.168.*') {    $Url2 = 'http://' + $IP2 + ':1985/SendMessage?destination_name=traffic'
    $ISConfFile2 = '\\' + $IP2 + '\Imagine Communications\ADC Services\config\IntegrationService.xml'
    $ISConf2 = (Get-Content $ISConfFile2)
    $ISCumul = $ISConf1 + $ISConf2}
else {$ISCumul = $ISConf1; $ISConf2 = ''}
$Lists = @($ISCumul | where {$_ -match "<ChannelName>(?<ListName>.*)</ChannelName>"} | % {$matches['ListName']})

function GD {Get-Date -Format 'yyyy-MM-dd HH:mm:ss - '}
$Date=(Get-Date).AddDays(1) | Get-Date -Format 'yyyy-MM-dd'
$Time=Get-Date -Format 'ddMMyyHHmmss'
#$Lists.Length
#$time1=Get-Date
function ReplaceGUIDs {
    "$(GD)Preparing `$XmlFile to replace GUIDs..."
    $XmlFileContent=Get-Content $XmlFile #'C:\PS\xml\!!!CTC_bxf_Schedule_for_Soap_UI_3877.xml'  
    #$XmlFileContent = $content -split "\n"
    $sw = New-Object System.IO.StreamWriter $XmlFile
    "$(GD)Replacing GUIDs..."
    $XmlFileContent | % { 
        if ($_ -match "\w{8}-\w{4}-\w{4}-\w{4}-\w{12}") {
            $a1 = $matches[0].Substring(0,8)
            $a2 = $matches[0].Substring(9,4)
            $a3 = $matches[0].Substring(14,4)
            $a4 = $matches[0].Substring(19,4)
            $a5 = $matches[0].Substring(24,12)
                $b1 = "{0:x8}" -f ([int64]"0x$a1"+1)
                $b2 = "{0:x4}" -f ([int64]"0x$a2"+1)
                $b3 = "{0:x4}" -f ([int64]"0x$a3"+1)
                $b4 = "{0:x4}" -f ([int64]"0x$a4"+1)
                $b5 = "{0:x12}" -f ([int64]"0x$a5"+1)
                    $c1 = $b1.Substring($b1.Length-8,8)
                    $c2 = $b2.Substring($b2.Length-4,4)
                    $c3 = $b3.Substring($b3.Length-4,4)
                    $c4 = $b4.Substring($b4.Length-4,4)
                    $c5 = $b5.Substring($b5.Length-12,12)
            $sw.WriteLine($_.replace($matches[0], "$c1-$c2-$c3-$c4-$c5"))
            #$_.replace($matches[0], "$c1-$c2-$c3-$c4-$c5")
            #exit
        }
        else { $sw.WriteLine($_) }
    } | Out-Null #Out-File $XmlFile -Encoding utf8
    $sw.Close()
    "$(GD)$XmlFile now contains new GUIDs."    #Read-Host "Press Enter to exit" | Out-Null}$curTime = (Get-Date)for ($i=0 ; $i -lt $Lists.Length ; $i++) {    
    #pause after certain amount of messages sent
    #if (($i -gt 0) -and ($i%5 -eq 0)) {Start-Sleep -Seconds 200}

    #what url send message to? or even break the cycle
    if (($ISConf1 -match $Lists[$i]) -and ($Lists[$i] -gt ' ')) {$Url = $Url1} elseif (($ISConf2 -match $Lists[$i]) -and ($Lists[$i] -gt ' ')) {$Url = $Url2} else {break}

    #getting content for RestMethod from XmlFile replacing Dates, Lists, Start Times etc.    $x = 0 ; $curTime = (Get-Date).AddSeconds(120+$i*5)    $Content = Get-Content $XmlFile | % {        if ($_ -match "#RECTIME") {            $_ = $_ -replace "#RECTIME",("{0:HH}:{0:mm}:{0:ss};00"  -f $curTime.AddMinutes($x*30))            $x++        }        $_ -replace '#DATE',$Date -replace '#LIST',$Lists[$i] -replace '#TIME',$Time -replace '#START',$Start -replace '#MODE',$Mode    }    #$Content | Out-File "C:\PS\Conte"    "$(GD)Sending schedule for $($Lists[$i])  ->  $($Url.Substring(7,$Url.IndexOf("/S")-7))"    #"Done in {0:mm}:{0:ss}" -f ((Get-Date) - $time1)    #sending xml message to rest adapter    Invoke-RestMethod -Method 'post' -Uri $Url -Body $Content    #Start-Sleep -Seconds 2    #$Content | Out-File 'C:\PS\Galk.xml'}#replacing guids in $XmlFileReplaceGUIDs