$CTC = '192.168.13.170','192.168.13.171','192.168.13.172','192.168.13.173','192.168.13.174','192.168.13.175','192.168.13.176','192.168.13.177','192.168.13.178','192.168.13.179','192.168.13.180','192.168.13.181','192.168.13.182','192.168.13.138','192.168.13.139','192.168.13.140','192.168.13.141','192.168.13.142','192.168.13.143','192.168.13.145','192.168.13.161','192.168.13.168','192.168.13.232','192.168.13.191'

#get current Demo Disk UseI/PPort parameter from INIs (TRUE for Rec, FALSE for Play)
Invoke-Command -ComputerName $CTC {
    $file = 'C:\server\12.28.1.1\ADC1000NT.INI'
    #$env:COMPUTERNAME
    Get-Content $file | where {$_ -like 'UseI/PPort=*'} | % {$_}
}


#backup ADC1000NT.INI
Invoke-Command -ComputerName $CTC {
    Copy-Item C:\server\12.28.1.1\ADC1000NT.INI C:\server\12.28.1.1\ADC1000NT.INI.BKU
}


#replace Demo Disk parameters with new values
$argList = @{
    'UseI/PPort'='FALSE'
    'DemoDiskIDLeadingWord' = 'Demo06'
    'DemoDiskIDNumbers' = '99'
    'BacktoBack' = '1 1 '
    'Record' = 'TRUE'
}
Invoke-Command -ComputerName $CTC -ArgumentList $argList {
    param ($argList)
    $file = 'C:\server\12.28.1.1\ADC1000NT.INI'
    $content = Get-Content $file
    foreach ($key in $argList.Keys) {
        $content = $content -replace "($key)=.*","`$1=$($argList[$key])"
    }
    $content | Out-File $file -Encoding ascii
}


#copy old ADC1000NT.INI
Invoke-Command -ComputerName $CTC {
    Copy-Item -Path 'C:\server\12.27.39.1M\ADC1000NT.INI' -Destination 'C:\server\12.28.1.1\ADC1000NT.INI'
}

