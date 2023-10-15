$server = '192.168.13.69'
$port = '10049'
$url = "http://$server`:$port/api/AsRunService/GenerateAsRunListRedundancy"
$swagger = "http://$server`:$port/api/ADCServices/help/index#!/AsRunService/AsRunService_GenerateAsRunListRedundancy"
$params = @{
    PrimaryServer='ADCS'
    PrimaryList='1'
    FollowerServer='GALK'
    FollowerList='1'
    DayReport=get-date '2022-10-27 14:00:00'
    FileName='C:\AsRunLog\Rls-REST'
}
$paramsString = ($params.GetEnumerator() | %{$_.name + '=' + $_.value}) -join '&'
$curl = "$url`?$paramsString"
#$curl = "$url`?PrimaryServer=ADCS&PrimaryList=1&FollowerServer=ADCS&FollowerList=2&DayReport=2022-09-29 14:57:00&FileName=C:\AsRunLog\1REST"
#$curl = "$url`?PrimaryServer=ADCS&PrimaryList=1&FollowerServer=ADCS&FollowerList=2&DayReport=2022-09-29%2014%3A57%3A00&FileName=C%3A%5CAsRunLog%5C1REST"


function call {    param ($method = 'get', $uri, $body)    Write-Host $method.ToUpper() -f 10 -b 0    Write-Host $uri -f 11 -b 0    if ($body) {Write-Host $body -f 8 -b 0}    Write-Host "||" -f 10 -b 0    try {$Global:response = Invoke-RestMethod -Method $method -Uri $uri -Body $body -ContentType application/json        #($response | ft -HideTableHeaders | Out-String).Trim()        $response | ft -property ($response | gm -MemberType NoteProperty).Name        Write-Host "*******************************************************************************************************************" -f 14 -b 0    }    catch {Write-Host $Error[0].Exception -f 12 -b 0}}function help {"
Esc - exit"}helpWrite-Host "*******************************************************************************************************************" -f 14 -b 0
call -method post -uri $curl
return
do {
    
         
    #looking for <Esc> or <R> or <Space> press
    if ($host.ui.RawUi.KeyAvailable) {
        $key=$host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown,IncludeKeyUp")
        $host.UI.RawUI.FlushInputBuffer()
        if ($key.keydown) {
            switch ($key.VirtualKeyCode) {
                <#C#> 67 {cls}

                <#1#> 49 {}
                <#2#> 50 {}
                <#3#> 51 {}
                <#4#> 52 {}

                <#T#> 84 {}
                <#L#> 76 {}
                <#D#> 68 {}
                <#M#> 77 {}
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