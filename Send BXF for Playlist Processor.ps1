$ip = '192.168.13.69'$ip = '192.168.13.170'$ip = '10.9.37.116'$port = '1985'$List = "PLC1_01"
$XmlFile  = 'C:\PS\xml\Playlist Query.xml'
$Url = "http://$ip`:$port/SendMessage?destination_name=traffic"

function GD {Get-Date -Format 'yyyy-MM-dd HH:mm:ss - '}
function Send {
    #getting content for RestMethod from XmlFile replacing Dates, Lists, Start Times etc.    $Content = Get-Content $XmlFile -Raw | % {$_ -replace '#CHANNEL',$List -replace '#TIME',$Time}                Write-Host "$(GD)Playlist Query request for channel $List sent to $ip`:$port - " -NoNewline            #sending xml message to rest adapter    try {Write-Host (Invoke-RestMethod -Method 'post' -Uri $Url -Body $Content) -NoNewline; Write-Host "Success" -b Black -f Green -NoNewline}    catch {        Write-Host "Fail" -b Black -f Red        Write-Host "$(GD)Failed to send bxf for $List. Retry in 20 seconds - " -b Black -f Yellow -NoNewline        sleep 20        try {Write-Host (Invoke-RestMethod -Method 'post' -Uri $Url[$SN] -Body $Content) -NoNewline ; Write-Host "Success" -b Black -f Green}        catch {Write-Host "Fail`n$(GD)Failed to send schedule for $List" -b Black -f Red}    }}
$process1 = Get-Process -Name Harris.Automation.ADC.Services.IntegrationServiceHost
$ii = 0
$time2 = (Get-Date)
do {
    $Time = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.ff'
    $time1 = (Get-Date)

#    send
#    return

    if ((Get-Date).Second % 10 -eq 0) {
        #$List = if ((Get-Date).Second % 2 -eq 0) {$List1} else {$List2}
        send
        $ii++
        Write-Host " $ii"
    }

    if ($host.ui.RawUi.KeyAvailable) {
        $key=$host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown,IncludeKeyUp")
        $Host.UI.RawUI.FlushInputBuffer()
        switch ($key.VirtualKeyCode) {
            <#Space#> 32 {}
            <#Esc#> 27 {return}
        } #end switch
    }
    
    $logContent = Get-Content 'C:\Program Files (x86)\Imagine Communications\ADC Services\log\IntegrationService.log' -raw
    $err = [regex]::Match($logContent,'(?i)error|fatal')
    if ($err.Success) {Write-Host ($logContent[($err.Index-50)..($err.Index+200)] -join '') -f 12 -b 0; return}
    
    $process2 = Get-Process -Name Harris.Automation.ADC.Services.IntegrationServiceHost
    if ($process1.Id -ne $process2.Id) {Write-Host "Integration Service was restarted. Old Id=$($process1.Id), new Id=$($process2.Id)" -f 13 -b 0; return}
    #((Get-Date) - $time1).TotalMilliseconds

    if (((Get-Date) - $time1).TotalMilliseconds -lt 950) {sleep -Milliseconds (950 - ((Get-Date) - $time1).TotalMilliseconds)}
} until (
    ($key.VirtualKeyCode -eq 27) -or 
    #(((Get-Date) - $time2).totalhours -ge 2) -or
    ($process1.Id -ne $process2.Id) -or
    ($err.Success)
)