$guids = Get-Content C:\PS\test
$XmlFile = 'C:\PS\Add Record Events.xml'
$x = 0
$Content = Get-Content $XmlFile | % {    if ($_ -match "<EventId>urn") { $_ = $_ -replace "GUID",$guids[$x] ; $x++ }    if ($_ -match "<InsertAfterEventId>urn") { $_ = $_ -replace "GUID",$guids[$x-2] }    $_}

$Content | Out-File $XmlFile

"[0-f]*-[0-f]*-[0-f]*-[0-f]*-[0-f]*"
"https://www.guidgenerator.com/online-guid-generator.aspx"