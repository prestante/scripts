#$folder = 'C:\Users\galkovsky.a\Desktop\KTTC_logs'
#$folder = '\\fs\change\galkovsky.a\scripts'
$folder = '\\fs\Shares\Engineering\ADC\QA\PS\scripts'
#$folder = 'C:\Program Files\Imagine Communications'
#$folder = 'C:\Program Files (x86)\Imagine Communications\ADC Services\log'
#$search = 'ÿ'
$search = 'galkovsky.a'
$i=0
#Get-ChildItem $folder -Recurse | ? {($_.Extension -eq '.json') -or ($_.Extension -eq '.config') -or ($_.Extension -eq '.xml')} | % {
Get-ChildItem $folder -Recurse | ? {($_.Extension -eq '.ps1')} | % {
#Get-ChildItem $folder -Recurse | ? {($_.FullName -match 'integration')} | % {
    $_.FullName
    $content = Get-Content $_.FullName -Encoding UTF8
    foreach ($string in $content) {
        if ($string -match $search) {
            Write-Host "We got '$search' in " -ba Black -fo Green -NoNewline
            Write-Host "$_" -ba DarkGray -fo Green -NoNewline
            Write-Host ". Full string:"  -ba Black -fo Green
            Write-Host "$string" -ba Black -fo Yellow
            $i++
        }
    }
}
"Number of coincidences: $i"