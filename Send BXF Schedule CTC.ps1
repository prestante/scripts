$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net', 'WTL-ADC-CTC-03.wtldev.net', 'WTL-ADC-CTC-04.wtldev.net', 'WTL-ADC-CTC-05.wtldev.net', 'WTL-ADC-CTC-06.wtldev.net', 'WTL-ADC-CTC-07.wtldev.net', 'WTL-ADC-CTC-08.wtldev.net', 'WTL-ADC-CTC-09.wtldev.net', 'WTL-ADC-CTC-10.wtldev.net', 'WTL-ADC-CTC-11.wtldev.net', 'WTL-ADC-CTC-12.wtldev.net', 'WTL-ADC-CTC-13.wtldev.net', 'WTL-ADC-CTC-14.wtldev.net', 'WTL-ADC-CTC-15.wtldev.net', 'WTL-ADC-CTC-16.wtldev.net', 'WTL-ADC-CTC-17.wtldev.net', 'WTL-ADC-CTC-18.wtldev.net', 'WTL-ADC-CTC-19.wtldev.net', 'WTL-ADC-CTC-20.wtldev.net', 'WTL-ADC-CTC-21.wtldev.net', 'WTL-ADC-CTC-22.wtldev.net', 'WTL-ADC-CTC-23.wtldev.net', 'WTL-ADC-CTC-24.wtldev.net', 'WTL-ADC-CTC-25.wtldev.net', 'WTL-ADC-CTC-26.wtldev.net', 'WTL-ADC-CTC-27.wtldev.net', 'WTL-ADC-CTC-28.wtldev.net', 'WTL-ADC-CTC-29.wtldev.net', 'WTL-ADC-CTC-30.wtldev.net', 'WTL-ADC-CTC-31.wtldev.net', 'WTL-ADC-CTC-32.wtldev.net')

# $CredsLocal = [System.Management.Automation.PSCredential]::new('local\imagineLocal',(ConvertTo-SecureString -AsPlainText $env:imgLocPW -Force))
$CredsDomain = [System.Management.Automation.PSCredential]::new('wtldev.net\vadc',(ConvertTo-SecureString -AsPlainText $env:VADC_PASSWORD -Force))

# $XmlFile = '\\wtlnas1\public\ADC\PS\resources\xml\3877.xml'
$XmlFile = '\\wtlnas1\public\ADC\PS\resources\xml\Add.Pri.and.Sec.Template.One.xml'

#Setting configuration and Getting list of ListNames from all Integration Services config files
$Url = @(foreach ($CTCip in $CTC) {'http://' + $CTCip + ':1985/SendMessage?destination_name=traffic'})
$servers =  2   # Number of CTCs to send schedule to
$SSN =      0   # SSN is Starting Server Number. 0 means starting from first $CTC pc.
$lists =    1   # Number of Lists to send schedule to
$interval = 40  # OAT interval in seconds between Lists
$pause =    2   # Pause in seconds between sending bxf messages
$add =      0   # Set add to 1 if you want just to add schedule to already running lists. set to 0 if you want to restart DS and add new schedule starting with AO event
$once =     0   # Do the cycle just once

# $addTime = (Get-Date 14:30) #at which time to send schedule
$addTime = (Get-Date).AddSeconds(-5) #at which time to send schedule
# if ($addTime -lt (Get-Date)) {$addTime = $addTime.AddDays(1)}

$Date=(Get-Date).AddDays(0) | Get-Date -Format 'yyyy-MM-dd'
$Time=Get-Date -Format 'ddMMyyHHmmss'

function GD {Get-Date -Format 'yyyy-MM-dd HH:mm:ss - '}
function Prepare {
    Write-Host "$(GD)Preparing CTC environment (30 seconds)..." -fo yellow -ba black
    $PSSessionOption.IdleTimeout = New-TimeSpan -days 24 -Seconds 0
    Invoke-Command -ComputerName ($CTC[$SSN..($SSN+$Servers-1)]) -InDisconnectedSession -ArgumentList $add -Credential $CredsDomain {
        param ($add)
        if ($add -eq 0) {
            Stop-Process  -name ADC1000NT -Force ; Start-Sleep 1
            Start-Process 'C:\Users\Public\Desktop\ADC Device Server.lnk' ; Start-Sleep 1
        }

        [System.Collections.Generic.List[PSObject]]$services = @(Get-Service -Name 'ADC*'; Get-Service -Name 'OData*') | Where-Object {$_.DisplayName -notmatch 'Aggregation'}
        [System.Collections.Generic.List[PSObject]]$servicesInOrder = @()

        if (($services.status -contains 'Stopped') -or ($services.status -contains 'Starting')) {
            "Restarting Services on $env:COMPUTERNAME"
            $services | Set-Service -StartupType Disabled
            Start-Sleep 1
            Get-Process -Name 'Harris.Automation.ADC.Services*' | Stop-Process -Force -ErrorAction SilentlyContinue
            Start-Sleep 1
            $services | Set-Service -StartupType Manual
        }

        $services | Where-Object {$_.DisplayName -match 'Data'} | ForEach-Object {$servicesInOrder.Add($_)}
        $services | Where-Object {$_.DisplayName -match 'Timecode'} | ForEach-Object {$servicesInOrder.Add($_)}
        $services | Where-Object {$_.DisplayName -match 'AsRun'} | ForEach-Object {$servicesInOrder.Add($_)}
        $services | Where-Object {$_.DisplayName -match 'Device'} | ForEach-Object {$servicesInOrder.Add($_)}
        $services | Where-Object {$_.DisplayName -match 'List'} | ForEach-Object {$servicesInOrder.Add($_)}
        $services | Where-Object {$_.DisplayName -match 'Error'} | ForEach-Object {$servicesInOrder.Add($_)}
        $services | 
         Where-Object {$_.DisplayName -notmatch 'Data'} |
         Where-Object {$_.DisplayName -notmatch 'Timecode'} |
         Where-Object {$_.DisplayName -notmatch 'AsRun'} | 
         Where-Object {$_.DisplayName -notmatch 'Device'} | 
         Where-Object {$_.DisplayName -notmatch 'List'} | 
         Where-Object {$_.DisplayName -notmatch 'Error'} | 
         Where-Object {$_.DisplayName -notmatch 'Synchro'} | 
         Where-Object {$_.DisplayName -notmatch 'Integra'} | 
         Where-Object {$_.DisplayName -notmatch 'Manager'} | 
        ForEach-Object {$servicesInOrder.Add($_)}
        #$services | Where-Object {$_.DisplayName -match 'Integra'} | ForEach-Object {$servicesInOrder.Add($_)}
        $services | Where-Object {$_.DisplayName -match 'Synchro'} | ForEach-Object {$servicesInOrder.Add($_)}
        $services | Where-Object {$_.DisplayName -match 'Manager'} | ForEach-Object {$servicesInOrder.Add($_)}

        $servicesInOrder | ForEach-Object {
            Write-Host "$(GD)Starting $($_.name -replace '(ADC)(.*)(Service)','$1 $2 $3')" -b Black -f Yellow
            Start-Service $_.name -WarningAction SilentlyContinue
        }
        Start-Sleep 3
        Get-Service -Name ADCIntegrationService | Start-Service -wa SilentlyContinue
    } | Out-Null
    Start-Sleep 30
}
function Send {
    if ($add -eq 0) {$Mode = 'Fixed'} else {$Mode = 'Follow'} #Should be Fixed (AO) or Follow (A)
    $begin = (Get-Date).AddSeconds(60+($servers*$lists*($pause+2)))
    for ($([int]$SN=$SSN ; $i=0) ; $SN -lt ($SSN+$servers) ; $SN++) {
        for ($([int]$LN=0) ; $LN -lt $lists ; $LN++) {

            #getting content for RestMethod from XmlFile replacing Dates, Lists, Start Times etc.
            $Start = "{0:HH}:{0:mm}:{0:ss};00"  -f $begin.AddSeconds($i*$interval)
            $List = "CTC-{0:d2}:{1:d2}" -f ($SN+1), ($LN+1)
            $Content = Get-Content $XmlFile -Raw | ForEach-Object {$_ -replace '#DATE',$Date -replace '#LIST',$List -replace '#TIME',$Time -replace '#START',$Start -replace '#MODE',$Mode}
        
            if ($add) {Write-Host ("$(GD)Adding schedule for $List -> {0} - " -f ($Url[$SN] -replace '^.*\/(\d+\.\d+\.\d+\.\d+\:\d+).*$','$1')) -NoNewline}
            else {Write-Host ("$(GD)Loading schedule for $List with OAT {1} -> {0} - " -f ($Url[$SN] -replace '^.*\/(\d+\.\d+\.\d+\.\d+\:\d+).*$','$1'),$Start) -NoNewline}
        
            #sending xml message to rest adapter
            try {Write-Host (Invoke-RestMethod -Method 'post' -Uri $Url[$SN] -Body $Content) -NoNewline; Write-Host "Success" -b Black -f Green}
            catch {
                Write-Host "Fail" -b Black -f Red
                Write-Host "$(GD)Failed to send bxf for $List. Retry in 20 seconds - " -b Black -f Yellow -NoNewline
                Start-Sleep 20
                try {Write-Host (Invoke-RestMethod -Method 'post' -Uri $Url[$SN] -Body $Content) -NoNewline ; Write-Host "Success" -b Black -f Green}
                catch {Write-Host "Fail`n$(GD)Failed to send schedule for $List" -b Black -f Red}
            }
            
            Start-Sleep -Seconds $pause
            #$Content | Out-File 'C:\PS\Galk.xml'
            $i++
        }
    }
}
function Wait {
    $waitTime = 25 + $lists * 5
    Write-Host "$(GD)Waiting $waitTime seconds for Integration and List Services to finish up their job..." -fo yellow -ba black
    Start-Sleep $waitTime
}
function Postpare {
    Write-Host "$(GD)Stopping ADC Services on target CTC to free up their CPU resources" -fo yellow -ba black
    Invoke-Command -ComputerName ($CTC[$SSN..($SSN+$Servers-1)]) -Credential $CredsDomain {
        $services = Get-Service -Name 'ADC*'
        $services | Set-Service -StartupType Disabled
        Start-Sleep 1
        @(Get-Process -Name 'Harris.Automation.ADC.Services*'; Get-Process -Name 'OData*') | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep 1
        $services | Set-Service -StartupType Manual
    }
}
function ReplaceGUIDs {
    "$(GD)Preparing `$XmlFile to replace GUIDs..."
    $XmlFileContent=Get-Content $XmlFile #'C:\PS\xml\!!!CTC_bxf_Schedule_for_Soap_UI_3877.xml'  
    #$XmlFileContent = $content -split "\n"
    $sw = New-Object System.IO.StreamWriter $XmlFile
    "$(GD)Replacing GUIDs..."
    $XmlFileContent | ForEach-Object { 
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
    "$(GD)$XmlFile now contains new GUIDs."
    #Read-Host "Press Enter to exit" | Out-Null
}

Write-Host "$(GD)Next time to send schedule is $addTime" -f Yellow -b Black

do {
    if ($addTime -lt (Get-Date)) {
        $addTime = $addTime.AddDays(1)
        prepare
        send
        wait
        postpare
        ReplaceGUIDs
        if ($once) { return }  # Doing the cycle just once
        if (-not $add) { $add = 1 ; $addTime = $addTime.AddHours(-2) }  # If it was a fresh hard-started schedule ($add=0), we prepare for the next day list append
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
} until ($key.VirtualKeyCode -eq 27)