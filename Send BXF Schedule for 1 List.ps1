$ip = '10.9.37.116'$ip = 'wtl-hp3b8-vds7.wtldev.net'$port = '1985'$List = ($ip -replace 'wtl-hp3' -replace '.wtldev.net','_01').ToUpper()$add = 1$XmlFile  = 'C:\PS\xml\Add.Pri.and.Sec.Template.One.xml'
$XmlFile = 'C:\PS\xml\3877.xml'
$Url = "http://$ip`:$port/SendMessage?destination_name=traffic"

$Date=(Get-Date).AddDays(0) | Get-Date -Format 'yyyy-MM-dd'
$Time=Get-Date -Format 'ddMMyyHHmmss'

function GD {Get-Date -Format 'yyyy-MM-dd HH:mm:ss - '}

function Send {
    if ($add -eq 0) {$Mode = 'Fixed'} else {$Mode = 'Follow'} #Should be Fixed (AO) or Follow (A)    $Start = "{0:HH}:{0:mm}:{0:ss};00"  -f (get-date).AddSeconds(600)    $Content = Get-Content $XmlFile -Raw | % {$_ -replace '#DATE',$Date -replace '#LIST',$List -replace '#TIME',$Time -replace '#START',$Start -replace '#MODE',$Mode}                if ($add) {Write-Host "$(GD)Adding schedule for $List -> $ip`:$port - " -NoNewline}    else {Write-Host "$(GD)Loading schedule for $List -> $ip`:$port - " -NoNewline}            #sending xml message to rest adapter    try {Write-Host (Invoke-RestMethod -Method 'post' -Uri $Url -Body $Content) -NoNewline; Write-Host "Success" -b Black -f Green}    catch {        Write-Host "Fail" -b Black -f Red        Write-Host "$(GD)Failed to send bxf for $List. Retry in 20 seconds - " -b Black -f Yellow -NoNewline        sleep 20        try {Write-Host (Invoke-RestMethod -Method 'post' -Uri $Url -Body $Content) -NoNewline ; Write-Host "Success" -b Black -f Green}        catch {Write-Host "Fail`n$(GD)Failed to send schedule for $List" -b Black -f Red}    }                #$Content | Out-File 'C:\PS\Galk.xml'}

#do {
    send

    if ($host.ui.RawUi.KeyAvailable) {
        $key=$host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown,IncludeKeyUp")
        $Host.UI.RawUI.FlushInputBuffer()
        switch ($key.VirtualKeyCode) {
            <#Space#> 32 {}
            <#Esc#> 27 {return}
        } #end switch
    }
#} until ($key.VirtualKeyCode -eq 27)