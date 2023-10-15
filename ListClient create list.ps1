$LC = 'C:\Program Files (x86)\Imagine Communications\ADC Services\ListClient\ListClient.exe'
$text = "God"
[array]$textArr = $text -split ' '

for ($($i=0 ; $j=400 ; $t=Get-Date(0) -Second 5) ; $i -lt $textArr.Length ; $i++) {
    $HouseID = "Demo{0:d4}" -f ($i + $j)
    $tt = $t.AddSeconds($i)
    if ( ($tt.Second -eq 0) -and ($tt.Minute -ne 10) ) { $decT = [int]("0x{0:HHmmss00}" -f ($t.AddSeconds(-1))) }
    else { $decT = [int]("0x{0:HHmmss00}" -f ($t.AddSeconds($i))) }
    $dur = $decT
    $som = $decT
    $boxID = if ($textArr[$i].Length -ge 4) {("Box_" + $textArr[$i]).Substring(0,8)} else {"Box_" + $textArr[$i]}
    $NewTITLE = 
        if ( $tt.Minute -eq 0 ) { "$($tt.Second)s veedeo" }
        elseif ( ($tt.Minute -ne 0) -and ($tt.Second -eq 0) ) { "$($tt.Minute)m veedeo" }
        else { "$($tt.Minute)m$($tt.Second)s veedeo" }
    $recon = $textArr[$i]
    $params = "InsertADCEvent --list ADCS:PlayList 1 --boxid $boxID --boxsom 15 --id $HouseID --title $NewTitle --som $som --dur $dur --control AutoPlay,AutoThread,AutoSwitch --reconcileKey $recon"
    #$params = "InsertADCEvent --list ADCS:PlayList 1 --id $HouseID --title $NewTitle --som $som --dur $dur --control AutoPlay,AutoThread,AutoSwitch --reconcileKey $recon"
    & $LC $params
}
