for ($i=0 ; $i -lt 16 ; $i++) {
    Write-Host ("{0:d2}" -f $i) -NoNewline
    Write-Host "                         " -b $i
}
# Ask for input if not in the IDE
if ($Host.Name -notlike "*Code*") {
    Read-Host "Press Enter to continue..."
}

#write-host "Test string with numbers 123456 --------- 23259195. OK?" -f 13 -b 5