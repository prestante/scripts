cls$XmlFile = 'C:\PS\!!!CTC_bxf_Schedule_for_Soap_UI_3877.xml'#$XmlFile = 'C:\PS\Add.Pri.and.Sec.Template.xml'
function GD {get-date -Format "MMdd-HHmm-ss'ff'-"}

$i=0$time1=Get-Date
#-------------------------------------------------------------------------------------------------------
'Adding xml file content to Hash Table...'
$rawguids = Get-Content $XmlFile # -raw | Select-String "\w{8}-\w{4}-\w{4}-\w{4}-\w{12}" -AllMatches
$guidhash = $null
$guidhash = @{}
foreach ($q in $rawguids) { $guidhash.add($i,$q) ; $i++ }

'Processing new GUIDs...'
for ($i=0 ; $i -le $guidhash.Count ; $i++) { 
    if ($guidhash[$i] -match "\w{8}-\w{4}-\w{4}-\w{4}-\w{12}") {
        $guid = '00000000-'+(GD)+("{0:000000}" -f ($i))        $guidhash[$i] = $guidhash[$i] -replace "\w{8}-\w{4}-\w{4}-\w{4}-\w{12}",$guid
        #$old = $fresh; $fresh = $guid        #'guid: ' ; $guid        #'old: ' ; $old        #$i        #$guids.value[$i]        #'b';$content = $content -replace $guids.Matches.value[$i],$old        #        #$i        #$guids.Matches.value[$i]
    }
}'Writing result to $content variable...'$content = $guidhash.Keys | Sort-Object | % { $guidhash[$_] } | % ToString #| Out-File 'C:\PS\Conte'#$content#-------------------------------------------------------------------------------------------------------Write-Host 'Done in ' -nonewline
"{0:mm}:{0:ss}" -f ((Get-Date) - $time1)
Read-Host "Press Enter to exit" | Out-Null