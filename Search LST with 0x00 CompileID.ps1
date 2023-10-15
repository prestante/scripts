$dir = 'C:\Lists'

Get-ChildItem $dir -Filter *.lst | % {
    $Content = Get-Content $_.FullName -ReadCount 0 -Encoding Byte
    if ($Content[203] -eq 0) {$_.Name} #203 CompileID, 74 Reconcile
}