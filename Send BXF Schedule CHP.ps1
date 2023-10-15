#Send schedule to CTC Lists using xml file prepared in advance with #TEMPLATES inside to change them to tomorrow's date, unique GUID and List (channel) name.$CTC = @('192.168.13.146','192.168.13.147')  $Login = 'local\Administrator'
  $Password = 'ADC1000hrs'
$XmlFile = 'C:\PS\xml\3877.xml'#$XmlFile = 'C:\PS\xml\Add.Pri.and.Sec.Template.One.xml'#$XmlFile = 'C:\PS\xml\Add Record Event.xml'#$XmlFile = 'C:\PS\xml\!!!CTC_bxf_Schedule_for_Soap_UI_3877.xml'#$XmlFile = 'C:\PS\xml\Add.Pri.and.Sec.Template.Shortest.xml'#Setting configuration and Getting list of ListNames from all Integration Services config files
$Url = @(foreach ($CTCip in $CTC) {'http://' + $CTCip + ':1985/SendMessage?destination_name=traffic'})

#which configuration "(Number of DS used),(Lists per one DS)"
$servers = 2 ; $SSN = 0 #SSN is Starting Server Number means starting from .. 0 means starting from first $CTC pc.
$lists = 16
$interval = 7 # OAT interval in seconds between Lists

#Date and Time for using inside bxf's
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
    "$(GD)$XmlFile now contains new GUIDs."    #Read-Host "Press Enter to exit" | Out-Null}function StartDS ($ServerNames=@()) {
    $PSSessionOption.IdleTimeout = New-TimeSpan -days 24 -Seconds 0
    Invoke-Command -ComputerName $ServerNames -InDisconnectedSession {
        Start-Process 'C:\Users\Public\Desktop\ADC Device Server.lnk'
    }  | Out-Null
    Start-Sleep -Seconds 1
}function RestartDSandServices {
    #Checking if DS and ADC Services are running on target CTC, if not - restarting them
    $Pass = ConvertTo-SecureString -AsPlainText $Password -Force
    $Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Login, $Pass
    $PSSessionOption.IdleTimeout = New-TimeSpan -days 24 -Seconds 0
    Invoke-Command -ComputerName ($CTC[$SSN..($SSN+$Servers-1)]) -Authentication Credssp -Credential $Creds -InDisconnectedSession {
        #if (!(Get-Process -Name ADC1000NT -ea SilentlyContinue)) {
        Stop-Process  -name ADC1000NT -Force
        Start-Sleep 1
        Start-Process 'C:\Users\Public\Desktop\DS 12.28.11.1M.lnk'
        Start-Sleep 1
        #}

        $services = Get-Service -Name 'ADC*'
        $statuses = ($services).Status
        if (($statuses -contains 'Stopped') -or ($statuses -contains 'Starting')) {
            "Restarting Services on $env:COMPUTERNAME"
            $services | Set-Service -StartupType Disabled
            Start-Sleep 1
            Get-Process -Name 'Harris.Automation.ADC.Services*' | Stop-Process -Force -ErrorAction SilentlyContinue
            Start-Sleep 1
            $services | Set-Service -StartupType Manual
            $services | where {$_.DisplayName -notmatch 'Integration'} | sort -Descending | Start-Service -WarningAction SilentlyContinue
            Start-Sleep 1
            $services | where {$_.DisplayName -match 'Integration'} | sort -Descending | Start-Service -WarningAction SilentlyContinue
        }
    } | Out-Null
    #return
    Write-Host "$(GD)Preparing CTC environment (30 seconds)..." -fo yellow -ba black
    Start-Sleep 30
}function StopServices {
    Write-Host "$(GD)Stopping ADC Services on target CTC to free up their CPU resources" -fo yellow -ba black
    $Pass = ConvertTo-SecureString -AsPlainText $Password -Force
    $Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Login, $Pass
    $PSSessionOption.IdleTimeout = New-TimeSpan -days 24 -Seconds 0
    Invoke-Command -ComputerName ($CTC[$SSN..($SSN+$Servers-1)]) -Authentication Credssp -Credential $Creds -InDisconnectedSession {
        $services = Get-Service -Name 'ADC*'
        $services | Set-Service -StartupType Disabled
        Start-Sleep 1
        Get-Process -Name 'Harris.Automation.ADC.Services*' | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep 1
        $services | Set-Service -StartupType Manual
    }}########################################################################################################################################RestartDSandServices$begin = (Get-Date).AddSeconds(120)for ($([int]$SN=$SSN ; $i=0) ; $SN -lt ($SSN+$servers) ; $SN++) {    for ($([int]$LN=0) ; $LN -lt $lists ; $LN++) {        #getting content for RestMethod from XmlFile replacing Dates, Lists, Start Times etc.        $Start = "{0:HH}:{0:mm}:{0:ss};00"  -f $begin.AddSeconds($i*$interval)        $Mode = 'Fixed' # Should be Fixed (AO) or Follow (A)        $List = "CHP-{0}_{1:d2}" -f ($SN+9), ($LN+1)        $Content = Get-Content $XmlFile -Raw | % {$_ -replace '#DATE',$Date -replace '#LIST',$List -replace '#TIME',$Time -replace '#START',$Start -replace '#MODE',$Mode}                "$(GD)Sending schedule for $List with OAT {1} -> {0}" -f ($Url[$SN] -replace '^.*\/(\d+\.\d+\.\d+\.\d+\:\d+).*$','$1'),$Start                #sending xml message to rest adapter        Invoke-RestMethod -Method 'post' -Uri $Url[$SN] -Body $Content            Start-Sleep -Seconds 2        #$Content | Out-File 'C:\PS\Galk.xml'        $i++    }}#return

#Write-Host "$(GD)Waiting for Integration and List Services to finish up their job..." -fo yellow -ba black
#Start-Sleep (25+$lists*5)

#StopServices

#replacing guids in $XmlFile#ReplaceGUIDs