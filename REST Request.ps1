$server = 'http://192.168.13.69'

$Ts = '10045/api/AdcServices/help/index' #swagger page
$Ls = '10046/api/ListService/help/index' #swagger page
$Ds = '10047/api/AdcServices/help/index' #swagger page
$Ms = '10048/api/MaterialService/help/index' #swagger page

$Tp = '10045/api/TimecodeService/GetAvailableDeviceServers'
#$Tp = '10045/api/TimecodeService/GetCurrentDateTimecode?server=ADCS'

$Lp = '10046/api/ListService/GetAvailableDeviceServers'
#$Lp = '10046/api/ListService/GetListPage?server=ADCS&listIndex=1'
#$Lp = '10046/api/ListService/GetAllListsFromServer?server=ADCS'
#$Lp = '10046/api/ListService/PutListControlCommand'
$body = '{
"Server": "GALK",
"List": 1,
"ActionType": "Play"
}' #| ConvertTo-Json; 
#call -method put -uri "$server`:$Lp" -body $body

$Dp = '10047/api/DeviceService/GetAvailableDeviceServers'
#$Dp = '10047/api/DeviceService/GetDevices?server=ADCS'

$Mp = '10048/api/MaterialService/GetStoragesList?server=CTC12'
#$Mp = '10048/api/MaterialService/GetStoragesList?server=ADCS'


#$Content = Get-Content 'C:\PS\xml\Add AU event.xml' -Raw$Content = 'hello'$message = $Content  #| ConvertTo-Json; function call {    param ($method = 'get', $uri, $body)    Write-Host $method.ToUpper() -f 10 -b 0    Write-Host $uri -f 11 -b 0    if ($body) {Write-Host $body -f 8 -b 0}    Write-Host "||" -f 10 -b 0    try {$Global:response = Invoke-RestMethod -Method $method -Uri $uri -Body $body -ContentType application/json        #($response | ft -HideTableHeaders | Out-String).Trim()        $response | ft -property ($response | gm -MemberType NoteProperty).Name        Write-Host "*******************************************************************************************************************" -f 14 -b 0    }    catch {Write-Host $Error[0].Exception -f 12 -b 0}}function help {"
1 - $server`:$Ts
2 - $server`:$Ls
3 - $server`:$Ds
4 - $server`:$Ms

T - $server`:$Tp
L - $server`:$Lp
D - $server`:$Dp
M - $server`:$Mp
Esc - exit"}#Invoke-RestMethod -Method 'get' -Uri "$url`:$Lswag" #-ContentType 'application/json' helpWrite-Host "*******************************************************************************************************************" -f 14 -b 0
#return
do {
    
         
    #looking for <Esc> or <R> or <Space> press
    if ($host.ui.RawUi.KeyAvailable) {
        $key=$host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown,IncludeKeyUp")
        $host.UI.RawUI.FlushInputBuffer()
        if ($key.keydown) {
            switch ($key.VirtualKeyCode) {
                <#C#> 67 {cls}

                <#1#> 49 {call -method get -uri "$server`:$Ts"}
                <#2#> 50 {call -method get -uri "$server`:$Ls"}
                <#3#> 51 {call -method get -uri "$server`:$Ds"}
                <#4#> 52 {call -method get -uri "$server`:$Ms"}

                <#T#> 84 {call -method get -uri "$server`:$Tp"}
                <#L#> 76 {call -method get -uri "$server`:$Lp"}
                <#D#> 68 {call -method get -uri "$server`:$Dp"}
                <#M#> 77 {call -method get -uri "$server`:$Mp"}
                <#Esc#> 27 {exit}
                <#Space#> 32 {Write-Host "*******************************************************************************************************************" -f 14 -b 0}
                <#F1#> 112 {help}
            } #end switch
        }
    } #end if
} until ($key.VirtualKeyCode -eq 27)<#Timecode: http://localhost:10045/api/TimecodeService/help/index#!/TimecodeService/
List: http://localhost:10046/api/ListService/help/index#!/ListService/
Device: http://localhost:10047/api/DeviceService/help/index#!/DeviceService/ 
Material: http://localhost:10048/api/MaterialService/help/index#!/MaterialService/
3.	Verify that swagger is not working
4.	Try to use some REST methods from browser :
Timecode: http://localhost:10045/api/TimecodeService/GetCurrentDateTimecode?server=VASILYEV 
List: http://localhost:10046/api/ListService/GetAvailableDeviceServers
Device: http://localhost:10047/api/DeviceService/GetAvailableDeviceServers
Material: http://localhost:10048/api/MaterialService/GetStoragesList?server=VASILYEV
#>