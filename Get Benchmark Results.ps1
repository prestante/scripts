$result9 = Get-Content C:\PS\Report9.txt | where {$_ -match 'Xeon Gold 5122'} | % {$_ -match '\d+.{0,10}$' | Out-Null ; $Matches.Values -replace ' .*'}
$result29 = Get-Content C:\PS\Report29.txt  | where {$_ -match 'E5-2680 v3'} | % {$_ -match '\d+.{0,10}$' | Out-Null ; $Matches.Values -replace ' .*'}
$result30 = Get-Content C:\PS\Report30.txt  | where {$_ -match 'Xeon Gold 6132'} | % {$_ -match '\d+.{0,10}$' | Out-Null ; $Matches.Values -replace ' .*'}
$result238 = Get-Content C:\PS\Report238.txt  | where {$_ -match 'EPYC 7302P'} | % {$_ -match '\d+.{0,10}$' | Out-Null ; $Matches.Values -replace ' .*'}
$result238old = Get-Content C:\PS\Report238old.txt  | where {$_ -match 'EPYC 7351P'} | % {$_ -match '\d+.{0,10}$' | Out-Null ; $Matches.Values -replace ' .*'}
$result238old2016 = Get-Content C:\PS\Report238old2016.txt  | where {$_ -match 'EPYC 7351P'} | % {$_ -match '\d+.{0,10}$' | Out-Null ; $Matches.Values -replace ' .*'}
$result238new2016 = Get-Content C:\PS\Report238new2016.txt  | where {$_ -match 'EPYC 7302P'} | % {$_ -match '\d+.{0,10}$' | Out-Null ; $Matches.Values -replace ' .*'}
$result238bios = Get-Content C:\PS\Report238bios.txt | where {$_ -match 'EPYC 7302P'} | % {$_ -match '\d+.{0,10}$' | Out-Null ; $Matches.Values -replace ' .*'}
$resultKevin = Get-Content C:\PS\ReportKevin.txt | where {$_ -match 'EPYC 7302P'} | % {$_ -match '\d+.{0,10}$' | Out-Null ; $Matches.Values -replace ' .*'}
$resultSplitImage = Get-Content 'C:\PS\Report238 Win2016 Split Image.txt' | where {$_ -match 'EPYC 7302P'} | % {$_ -match '\d+.{0,10}$' | Out-Null ; $Matches.Values -replace ' .*'}
$result238525 = Get-Content 'C:\PS\Report238-5-25.txt' | where {$_ -match 'EPYC 7302P'} | % {$_ -match '\d+.{0,10}$' | Out-Null ; $Matches.Values -replace ' .*'}
$result2385252 = Get-Content 'C:\PS\Report238-525-2.txt' | where {$_ -match 'EPYC 7302P'} | % {$_ -match '\d+.{0,10}$' | Out-Null ; $Matches.Values -replace ' .*'}

$list = 'Memory Read(MB/s)','Memory Write(MB/s)','Memory Copy(MB/s)','Memory Latency(ns)','CPU Queen','CPU PhotoWorxx(MPixel/s)','CPU Zlib(MB/s)','CPU AES(MB/s)','CPU SHA3(MB/s)','FPU Julia','FPU Mandel','FPU SinJulia','FP32 Ray-Trace(KRay/s)','FP64 Ray-Trace(KRay/s)'

$csvfile = New-Item -Path C:\PS\Bench.csv -ItemType file -Force
"Test,CHP-9,Versio29,Versio30,ADCSERVICES-HP,ADCSERVICES-HP(old)" | Out-File $csvfile -Append ascii
for ($i=0; $i-lt $list.Length; $i++) {
    "{0},{1},{2},{3},{4},{5}" -f $list[$i], $result9[$i], $result29[$i], $result30[$i], $result238[$i], $result238old[$i] | Out-File $csvfile -Append ascii
}
