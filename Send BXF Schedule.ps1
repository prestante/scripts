<#Send schedule to multiple Lists using xml file prepared in advance with #TEMPLATES inside to change them to tomorrow's date, unique GUID and List (channel) name.To get this working you should do few preparations:    1. Configure several Integration Services for REST: One IS can process up to 48 channels (Lists). Use port 1985 for BXF communication interface.    2. Know IP of those ISs.    3. Share folder of IS PC \\192.168.IS.IP\Imagine Communications\ to be readable by EVERYONE.    4. Try to open EACH of those folders from THIS PC. Enter credentials TECOM\adcqauser Tecom_123! (or admin creds) if needed.    5. Enter IP of prepared ISs to $IP1 and $IP2 values. If you use just one IS, set $IP2 =''    6. Put .xml file containing BXF message body to C:\PS\xml\    7. BXF file should content #DATE instead of date values, #LIST instead of channel name and $TIME instead of last 12 symbols in scheduleId    8. Don't forget to set right $XmlFile path and name down below.Here we are working with two Integration Services, one at IP1 and another at IP2. We are getting their IS configs to parse them for list of ListNames which will be used for sending the schedule to each one of them.Algorythm will decide which IS we should send the message for each particular ListName#>$IP1 = '192.168.13.69'$IP2 = ''$XmlFile = 'C:\PS\xml\3877.xml'$XmlFile = 'C:\PS\xml\25 Segments Orig.xml'#$XmlFile = 'C:\PS\xml\Add.Pri.and.Sec.Template.Customer.xml'#$XmlFile = 'C:\PS\xml\Add.Pri.and.Sec.Template.One.xml'#$XmlFile = 'C:\PS\xml\Add Record Event.xml'#$XmlFile = 'C:\PS\xml\!!!CTC_bxf_Schedule_for_Soap_UI_3877.xml'#$XmlFile = 'C:\PS\xml\Add.Pri.and.Sec.Template.Shortest.xml'$interval = 5 #OAT interval in seconds between Lists
$pause = 20 #pause in seconds between sending bxf messages
$add = 0 #set add to 1 if you want just to add schedule to already running lists. set to 0 if you want to restart DS and add new schedule starting with AO event
#Setting configuration and Getting list of ListNames from all Integration Services config files
$Url1 = 'http://' + $IP1 + ':1985/SendMessage?destination_name=traffic'
$ISConfFile1 = '\\' + $IP1 + '\Imagine Communications\ADC Services\config\IntegrationService.xml'
$ISConf1 = (Get-Content $ISConfFile1)
if ($IP2 -like '192.168.*') {    $Url2 = 'http://' + $IP2 + ':1985/SendMessage?destination_name=traffic'
    $ISConfFile2 = '\\' + $IP2 + '\Imagine Communications\ADC Services\config\IntegrationService.xml'
    $ISConf2 = (Get-Content $ISConfFile2)
    $ISCumul = $ISConf1 + $ISConf2}
else {$ISCumul = $ISConf1; $ISConf2 = ''}
$lists = @($ISCumul | where {$_ -match "<ChannelName>(?<ListName>.*)</ChannelName>"} | % {$matches['ListName']} | select -First 1)

$addTime = (Get-Date).AddSeconds(1) #at which time to send schedule
#$addTime = (Get-Date 04:00) #at which time to send schedule
if ($addTime -lt (Get-Date)) {$addTime = $addTime.AddDays(1)}

$Date=(Get-Date).AddDays(0) | Get-Date -Format 'yyyy-MM-dd'
$Time=Get-Date -Format 'ddMMyyHHmmss'
function GD {Get-Date -Format 'yyyy-MM-dd HH:mm:ss - '}
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
    "$(GD)$XmlFile now contains new GUIDs."    #Read-Host "Press Enter to exit" | Out-Null}function Send {
    if ($add -eq 0) {$Mode = 'Fixed'} else {$Mode = 'Follow'} #Should be Fixed (AO) or Follow (A)    $begin = (Get-Date).AddSeconds(60+($lists.count*($pause+1-$interval)))
        for ($i=0 ; $i -lt $lists.count ; $i++) {            #getting content for RestMethod from XmlFile replacing Dates, Lists, Start Times etc.            $Start = "{0:HH}:{0:mm}:{0:ss};00"  -f $begin.AddSeconds($i*$interval)            $List = $lists[$i]            $Content = Get-Content $XmlFile -Raw | % {$_ -replace '#DATE',$Date -replace '#LIST',$List -replace '#TIME',$Time -replace '#START',$Start -replace '#MODE',$Mode}
            if (($ISConf1 -match $List) -and ($List -gt ' ')) {$Url = $Url1} elseif (($ISConf2 -match $List) -and ($List -gt ' ')) {$Url = $Url2} else {break}
            if ($add) {Write-Host ("$(GD)Adding schedule for $List -> {0} - " -f ($Url -replace '^.*\/(\d+\.\d+\.\d+\.\d+\:\d+).*$','$1')) -NoNewline}            else {Write-Host ("$(GD)Loading schedule for $List with OAT {1} -> {0} - " -f ($Url -replace '^.*\/(\d+\.\d+\.\d+\.\d+\:\d+).*$','$1'),$Start) -NoNewline}                    #sending xml message to rest adapter            try {Write-Host (Invoke-RestMethod -Method 'post' -Uri $Url -Body $Content) -NoNewline; Write-Host "Success" -b Black -f Green}            catch {                Write-Host "Fail" -b Black -f Red                Write-Host "$(GD)Failed to send bxf for $List. Retry in 20 seconds - " -b Black -f Yellow -NoNewline                sleep 20                try {Write-Host (Invoke-RestMethod -Method 'post' -Uri $Url -Body $Content) -NoNewline ; Write-Host "Success" -b Black -f Green}                catch {Write-Host "Fail`n$(GD)Failed to send schedule for $List" -b Black -f Red}            }                        Start-Sleep -Seconds $pause            #$Content | Out-File 'C:\PS\Galk.xml'    }
}Write-Host "$(GD)Next time to send schedule is $addTime" -f Yellow -b Black

do {
    if ($addTime -lt (Get-Date)) {
        $addTime = $addTime.AddDays(1)
        send
        if (!$add) { $add = 1 ; $addTime = $addTime.AddHours(-2) }
        Write-Host "$(GD)Next time to send schedule is $addTime" -f Yellow -b Black
    }

    if ($host.ui.RawUi.KeyAvailable) {
        $key=$host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown,IncludeKeyUp")
        $Host.UI.RawUI.FlushInputBuffer()
        switch ($key.VirtualKeyCode) {
            <#Space#> 32 {}
            <#Esc#> 27 {return}
        } #end switch
    }
    Start-Sleep 1
} until ($key.VirtualKeyCode -eq 27)#replacing guids in $XmlFile#ReplaceGUIDs