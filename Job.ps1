function getA ($c) {
    "$c"
}

<#for ($i=1 ; 1 ; $i++) {
    #logging DS status
    $b=get-date
    Test-Connection -Count 1 -ComputerName 192.168.13.172 -Quiet | Out-Null
    $c=get-date
    "$(($c-$b).TotalMilliseconds) ms."
    $list.Add(($c-$b).TotalMilliseconds)
    #looking for <Esc> or <R> or <Space> press
    if ($i%5 -eq 0) {"Average time is {0}." -f ($list | Measure-Object -Average).Average}
    if ($host.ui.RawUi.KeyAvailable) {
        $key=$host.ui.RawUI.ReadKey("NoEcho,IncludeKeyUp")
        $Host.UI.RawUI.FlushInputBuffer()
        if ($key.VirtualKeyCode -eq 27) {exit}             #<Esc>
        if ($key.VirtualKeyCode -eq 112) {Title}           #F1
        if ($key.VirtualKeyCode -eq 13) {                  #<Enter>
            "Average time is {0}." -f ($list | Measure-Object -Average).Average
        }
    }
    #Start-Sleep 1
}#>

$a = 128
$j = Start-Job $Function:getA -ArgumentList $a

#$j | Format-List -Property * 
#Receive-Job $j
Get-job -name $j.Name
Start-Sleep -Milliseconds 200
if ($j.HasMoreData) {Receive-Job $j -Keep}