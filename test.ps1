Param($param1 = 1, [int]$param2 = 2)
"param1: $param1 ($($param1.gettype().Name))"
"param2: $param2 ($($param2.gettype().Name))"
if ( $Host.Name -notmatch 'Visual Studio') { Read-Host }