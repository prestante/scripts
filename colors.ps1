for ($i=0 ; $i -lt 16 ; $i++) {
    Write-Host ("{0:d2}" -f $i) -NoNewline
    Write-Host "                         " -b $i
}
Read-Host

#write-host "Test string with numbers 123456 --------- 23259195. OK?" -f 13 -b 5