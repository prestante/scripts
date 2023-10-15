#$CTC = @('WTL-HP3B8-VDS1.WTLDEV.NET','WTL-HP3B8-VDS2.WTLDEV.NET','WTL-HP3B8-VDS3.WTLDEV.NET','WTL-HP3B8-VDS4.WTLDEV.NET','WTL-HP3B8-VDS5.WTLDEV.NET','WTL-HP3B8-VDS6.WTLDEV.NET','WTL-HP3B8-VDS7.WTLDEV.NET','WTL-HP3B8-VDS8.WTLDEV.NET','WTL-HP3B8-VDS9.WTLDEV.NET','WTL-HP3B8-VDS10.WTLDEV.NET','WTL-HP3B9-VDS1.WTLDEV.NET','WTL-HP3B9-VDS2.WTLDEV.NET','WTL-HP3B9-VDS3.WTLDEV.NET','WTL-HP3B9-VDS4.WTLDEV.NET','WTL-HP3B9-VDS5.WTLDEV.NET','WTL-HP3B9-VDS6.WTLDEV.NET','WTL-HP3B9-VDS7.WTLDEV.NET','WTL-HP3B9-VDS8.WTLDEV.NET','WTL-HP3B9-VDS9.WTLDEV.NET','WTL-HP3B9-VDS10.WTLDEV.NET')
#$CTC = @('WTL-HP3B8-VDS1.WTLDEV.NET','WTL-HP3B8-VDS2.WTLDEV.NET')
$CTC = @('adc-ctc01.tecomgroup.ru','adc-ctc02.tecomgroup.ru','adc-ctc03.tecomgroup.ru','adc-ctc04.tecomgroup.ru','adc-ctc05.tecomgroup.ru','adc-ctc06.tecomgroup.ru','adc-ctc07.tecomgroup.ru','adc-ctc08.tecomgroup.ru','adc-ctc09.tecomgroup.ru','adc-ctc10.tecomgroup.ru','adc-ctc11.tecomgroup.ru','adc-ctc12.tecomgroup.ru','adc-ctc13.tecomgroup.ru','adc-ctc14.tecomgroup.ru','adc-ctc15.tecomgroup.ru','adc-ctc16.tecomgroup.ru','adc-ctc17.tecomgroup.ru','adc-ctc18.tecomgroup.ru','adc-ctc19.tecomgroup.ru','adc-ctc20.tecomgroup.ru','adc-ctc21.tecomgroup.ru','adc-ctc22.tecomgroup.ru','adc-ctc23.tecomgroup.ru','adc-ctc24.tecomgroup.ru')
#$CTC = @('adc-ctc01.tecomgroup.ru')
$XmlFile = 'C:\PS\xml\3877.xml'#Setting configuration and Getting list of ListNames from all Integration Services config files
$Url = @(foreach ($CTCip in $CTC) {'http://' + $CTCip + ':1985/SendMessage?destination_name=traffic'})

$servers = 1
$SSN = 0 #SSN is Starting Server Number. 0 means starting from first $CTC pc.
$lists = 8
#$interval = 10 #OAT interval in seconds between Lists. Usually I set it 40.
$interval = [int](720 / ($servers * $lists)) #1 cycle in 3877 schedule is about 720 seconds. So we should divide 720 to the total number of lists to get interval
$pause = 10 #pause in seconds between sending bxf messages to same server. Pause between servers is 1 second
$add = 0 #set add to 1 if you want just to add schedule to already running lists. set to 0 if you want to restart DS and add new schedule starting with AO event

#$addTime = (Get-Date 17:00) #at which time to send schedule
$addTime = (Get-Date).AddSeconds(5) #at which time to send schedule
if ($addTime -lt (Get-Date)) {$addTime = $addTime.AddDays(1)}

function GD {Get-Date -Format 'yyyy-MM-dd HH:mm:ss - '}
function Prepare {
    Write-Host "$(GD)Preparing CTC environment (30 seconds)..." -fo yellow -ba black
    $PSSessionOption.IdleTimeout = New-TimeSpan -days 24 -Seconds 0
    Invoke-Command -ComputerName ($CTC[$SSN..($SSN+$Servers-1)]) -InDisconnectedSession -Credential ([System.Management.Automation.PSCredential]::new('local\Administrator',(ConvertTo-SecureString -AsPlainText 'Tecom_1!' -Force))) -ArgumentList $add {
        param ($add)
        if ($add -eq 0) {
            Stop-Process  -name ADC1000NT -Force ; Start-Sleep 1
            Start-Process 'C:\Users\Public\Desktop\ADC Device Server.lnk' ; Start-Sleep 1
        }

        [System.Collections.Generic.List[PSObject]]$services = Get-Service -Name 'ADC*' | where {$_.DisplayName -notmatch 'Aggregation'}
        [System.Collections.Generic.List[PSObject]]$servicesInOrder = @()

        if (($services.status -contains 'Stopped') -or ($services.status -contains 'Starting')) {
            "Restarting Services on $env:COMPUTERNAME"
            $services | Set-Service -StartupType Disabled
            Start-Sleep 1
            Get-Process -Name 'Harris.Automation.ADC.Services*' | Stop-Process -Force -ErrorAction SilentlyContinue
            Start-Sleep 1
            $services | Set-Service -StartupType Manual
        }

        $services | where {$_.DisplayName -match 'Data'} | % {$servicesInOrder.Add($_)}
        $services | where {$_.DisplayName -match 'Timecode'} | % {$servicesInOrder.Add($_)}
        $services | where {$_.DisplayName -match 'AsRun'} | % {$servicesInOrder.Add($_)}
        $services | where {$_.DisplayName -match 'Device'} | % {$servicesInOrder.Add($_)}
        $services | where {$_.DisplayName -match 'List'} | % {$servicesInOrder.Add($_)}
        $services | where {$_.DisplayName -match 'Error'} | % {$servicesInOrder.Add($_)}
        $services | 
         where {$_.DisplayName -notmatch 'Data'} |
         where {$_.DisplayName -notmatch 'Timecode'} |
         where {$_.DisplayName -notmatch 'AsRun'} | 
         where {$_.DisplayName -notmatch 'Device'} | 
         where {$_.DisplayName -notmatch 'List'} | 
         where {$_.DisplayName -notmatch 'Error'} | 
         where {$_.DisplayName -notmatch 'Synchro'} | 
         where {$_.DisplayName -notmatch 'Integra'} | 
         where {$_.DisplayName -notmatch 'Manager'} | 
        % {$servicesInOrder.Add($_)}
        #$services | where {$_.DisplayName -match 'Integra'} | % {$servicesInOrder.Add($_)}
        $services | where {$_.DisplayName -match 'Synchro'} | % {$servicesInOrder.Add($_)}
        $services | where {$_.DisplayName -match 'Manager'} | % {$servicesInOrder.Add($_)}

        $servicesInOrder | % {
            Write-Host "$(GD)Starting $($_.name -replace '(ADC)(.*)(Service)','$1 $2 $3')" -b Black -f Yellow
            Start-Service $_.name -WarningAction SilentlyContinue
        }
        start-sleep 3
        Get-Service -Name ADCIntegrationService | Start-Service -wa SilentlyContinue
    } | Out-Null
    Start-Sleep 30
}
function Send {
    $Date=(Get-Date).AddDays(0) | Get-Date -Format 'yyyy-MM-dd'
    $Time=Get-Date -Format 'ddMMyyHHmmss'
        if ($add -eq 0) {$Mode = 'Fixed'} else {$Mode = 'Follow'} #Should be Fixed (AO) or Follow (A)    $begin = (Get-Date).AddSeconds(60+($servers*$lists*1 + $servers*($lists-1)*$pause))
    for ($([int]$SN=$SSN ; $i=0) ; $SN -lt ($SSN+$servers) ; $SN++) {        for ($([int]$LN=0) ; $LN -lt $lists ; $LN++) {            #getting content for RestMethod from XmlFile replacing Dates, Lists, Start Times etc.            $Start = "{0:HH}:{0:mm}:{0:ss};00"  -f $begin.AddSeconds($i*$interval)            #$List = "CTC{0:d2}_{1:d2}" -f ($SN+1), ($LN+1)            #$List = $CTC[$SN] -replace 'wtl-hp3' -replace '.wtldev.net',"_$("{0:d2}"-f ($LN+1))"            $List = ($CTC[$SN] -replace 'adc-' -replace '.tecomgroup.ru',"_$("{0:d2}"-f ($LN+1))").toupper()            $Content = Get-Content $XmlFile -Raw | % {$_ -replace '#DATE',$Date -replace '#LIST',$List -replace '#TIME',$Time -replace '#START',$Start -replace '#MODE',$Mode}            if ($add) {Write-Host ("$(GD)Adding schedule for $List - ") -NoNewline}            else {Write-Host ("$(GD)Loading schedule for $List with OAT {0} - " -f $Start) -NoNewline}            #sending xml message to rest adapter            try {Write-Host (Invoke-RestMethod -Method 'post' -Uri $Url[$SN] -Body $Content) -NoNewline; Write-Host "Success" -b Black -f Green}            catch {                Write-Host "Fail" -b Black -f Red                Write-Host "$(GD)Failed to send bxf for $List. Retry in 20 seconds - " -b Black -f Yellow -NoNewline                sleep 20                try {Write-Host (Invoke-RestMethod -Method 'post' -Uri $Url[$SN] -Body $Content) -NoNewline ; Write-Host "Success" -b Black -f Green}                catch {Write-Host "Fail`n$(GD)Failed to send schedule for $List" -b Black -f Red}            }            if ($LN -lt $lists-1) {Start-Sleep -Seconds $pause} else {Start-Sleep -Seconds 1}            #$Content | Out-File 'C:\PS\Galk.xml'            $i++        }    }
}
function Wait {
    Write-Host "$(GD)Waiting for Integration and List Services to finish up their job..." -fo yellow -ba black
    Start-Sleep (25+$lists*5)
}
function Postpare {
    Write-Host "$(GD)Stopping ADC Services on target CTC to free up their CPU resources" -fo yellow -ba black
    Invoke-Command -ComputerName ($CTC[$SSN..($SSN+$Servers-1)]) -Credential ([System.Management.Automation.PSCredential]::new('local\Administrator',(ConvertTo-SecureString -AsPlainText 'Tecom_1!' -Force))) {
        $services = Get-Service -Name 'ADC*'
        $services | Set-Service -StartupType Disabled
        Start-Sleep 1
        Get-Process -Name 'Harris.Automation.ADC.Services*' | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep 1
        $services | Set-Service -StartupType Manual
    }
}
function ReplaceGUIDs {
    "$(GD)Preparing `$XmlFile to replace GUIDs..."
    $XmlFileContent=Get-Content $XmlFile
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
        }
        else { $sw.WriteLine($_) }
    } | Out-Null #Out-File $XmlFile -Encoding utf8
    $sw.Close()
    "$(GD)$XmlFile now contains new GUIDs."}

Write-Host "$(GD)Next time to send schedule is $addTime" -f Yellow -b Black

do {
    if ($addTime -lt (Get-Date)) {
        $addTime = $addTime.AddDays(1)
        #prepare
        send
        #wait
        #postpare
        return
        ReplaceGUIDs
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
    Start-Sleep -Milliseconds 200
} until ($key.VirtualKeyCode -eq 27)