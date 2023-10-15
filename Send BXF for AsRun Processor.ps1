$ip = '192.168.13.69'#$ip = '192.168.13.169'$port = '1985'$List = 'ADCS_01'#$List = 'GALK_01'
$XmlFile  = 'C:\PS\xml\AsRun Query.xml'
$Url = "http://$ip`:$port/SendMessage?destination_name=traffic"

$Time=Get-Date -Format 'ddMMyyHHmmss'

function GD {Get-Date -Format 'yyyy-MM-dd HH:mm:ss - '}
function Send {
    #getting content for RestMethod from XmlFile replacing Dates, Lists, Start Times etc.    $DateGT = "{0:yyyy-MM-ddTHH:mm:ssK}" -f ((Get-Date).AddDays(-1).AddHours(0))    #$DateGT = "{0:yyyy-MM-ddTHH:mm:ssK}" -f ((Get-Date).AddYears(-1))    $DateLT = "{0:yyyy-MM-ddTHH:mm:ssK}" -f ((Get-Date).AddDays(+1))    $Content = Get-Content $XmlFile -Raw | % {$_ -replace '#CHANNEL',$List -replace '#DATEGT',$DateGT -replace '#DATELT',$DateLT}                Write-Host "$(GD)AsRun request for channel $List sent to $ip`:$port - " -NoNewline            #sending xml message to rest adapter    try {Write-Host (Invoke-RestMethod -Method 'post' -Uri $Url -Body $Content) -NoNewline; Write-Host "Success" -b Black -f Green}    catch {        Write-Host "Fail" -b Black -f Red        Write-Host "$(GD)Failed to send bxf for $List. Retry in 20 seconds - " -b Black -f Yellow -NoNewline        sleep 20        try {Write-Host (Invoke-RestMethod -Method 'post' -Uri $Url[$SN] -Body $Content) -NoNewline ; Write-Host "Success" -b Black -f Green}        catch {Write-Host "Fail`n$(GD)Failed to send schedule for $List" -b Black -f Red}    }}

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
    #Start-Sleep 1
#} until ($key.VirtualKeyCode -eq 27)