#$files = gci "\\wtl-hp3b7-plc1.wtldev.net\Shared" | sort -Property CreationTime | where {$_.Name -match 'Report-'}
$files = gci "C:\PS" | sort -Property CreationTime | where {$_.Name -match 'Report69'}
$list = 'Server','Memory Read(MB/s)','Memory Write(MB/s)','Memory Copy(MB/s)','Memory Latency(ns)','CPU Queen','CPU PhotoWorxx(MPixel/s)','CPU Zlib(MB/s)','CPU AES(MB/s)','CPU SHA3(MB/s)','FPU Julia','FPU Mandel','FPU SinJulia','FP32 Ray-Trace(KRay/s)','FP64 Ray-Trace(KRay/s)'

$all = foreach ($file in $files) {
    $result = @(Get-Content $file.FullName | where {$_ -match '\sComputer\s*(.*?)(\s\(|$)'} | % {$Matches.1})
    $result += Get-Content $file.FullName | where {$_ -match '((?<!Quick Report )\[ TRIAL VERSION)|(VMware Virtual Platform)'} | % {$_ -match '\d+.{0,10}$' | Out-Null ; $Matches.Values -replace ' .*$'}
    $result
}



$csvfile = New-Item -Path C:\PS\Bench.csv -ItemType file -Force

for ($i = 0; $i -lt $list.Count; $i++) {
    #"$($list[$i]),$(for ($j = 0; $j -le $all.Count/$list.Count; $j++) {"$($all[$i*$j]),"})" | Out-File
    [string]$string = "$($list[$i]),"
    for ($j = 0; $j -lt $all.Count/$list.Count; $j++) {$string +="$($all[$i+$j*($list.Count)]),"}
    $string | Out-File $csvfile -Append ascii
}


