$CTC = '192.168.13.170','192.168.13.171','192.168.13.172','192.168.13.173','192.168.13.174','192.168.13.175','192.168.13.176','192.168.13.177','192.168.13.178','192.168.13.179','192.168.13.180','192.168.13.181','192.168.13.182','192.168.13.138','192.168.13.139','192.168.13.140','192.168.13.141','192.168.13.142','192.168.13.143','192.168.13.145','192.168.13.161','192.168.13.168','192.168.13.232','192.168.13.191'
$properties =
'ListControlNotifyFrames',
'Lookahead',
'Pack',
'Preroll' | sort

$regex = "(?s)\[LIST(?<List>\d{1,2})]"
foreach ($prop in $properties) {
    $regex += ".*?$prop=(?<$prop>.*?)\r"
} $regex += ".*?UseBackup"

$time1 = Get-Date

for ($i=0 ; $i -lt $CTC.Length ; $i++) {
    "CTC{0:d2}" -f ($i+1)
   
    $buildFolder = Get-ChildItem ('\\' + $CTC[$i] + '\server\') | where {$_.name -match '^12\.\d\d\.\d.*$'} | sort -property LastWriteTime | select -Last 1 -ExpandProperty FullName
    $ListConfINI = $buildFolder + '\LISTCONF.INI'
    $content = Get-Content $ListConfINI -Raw

    $lists = [System.Collections.ArrayList]@()
    [regex]::Matches($content,$regex) | % {
        $list = [int]$_.groups['List'].value
        if ($list -le 16) {
            $obj = [PSCustomObject] @{List=$list}
            foreach ($prop in $properties) {
                $obj | Add-Member -NotePropertyName $prop -NotePropertyValue $_.groups[$prop].value
            }
            $lists.add($obj)  | Out-Null
        }
    }
    $lists | sort -Property List | ft
}

"`n{0:ss}:{0:fff}" -f ((Get-Date) - $time1)