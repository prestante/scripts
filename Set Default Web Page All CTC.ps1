﻿$CTC = '192.168.13.170','192.168.13.171','192.168.13.172','192.168.13.173','192.168.13.174','192.168.13.175','192.168.13.176','192.168.13.177','192.168.13.178','192.168.13.179','192.168.13.180','192.168.13.181','192.168.13.182','192.168.13.138','192.168.13.139','192.168.13.140','192.168.13.141','192.168.13.142','192.168.13.143','192.168.13.145'

Invoke-Command -ComputerName $CTC -ScriptBlock {
$path = 'HKCU:\Software\Microsoft\Internet Explorer\Main\'

$name = 'start page'

$value = 'http://localhost:8091'

Set-Itemproperty -Path $path -Name $name -Value $value

}