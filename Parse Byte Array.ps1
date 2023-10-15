$startEvent = 1
$eventsToShow = 10

$show = @{  # hash table of keys to show/don't show bytes for each event field
showEventType = 0
showKey = 0
showReconcile = 0
showEffects = 0
showOnAirTime = 0
showID = 0
showTitle = 0
showSOM = 0
showDUR = 0
showChannel = 0
showSeg = 0
showIndexes = 0
showSsp = 0
showDateToAir = 0
showControl = 0
showStatus = 0
showCompileID = 0
showCompileSOM = 0
showABOX = 0
showABOXSOM = 0
showBBOX = 0
showBBOXSOM = 0
showIndexes2 = 0
showExtControl = 0
showClosedCaption = 0
showAFD_Bar_Data = 0
showDialNorm = 0
showDBKey = 0
showFieldsFromSource = 0
showFieldsToSource = 0
showReserved = 0
showOrigTime = 0
showOrigDate = 0
showEvtType = 0
showTriggeredLists = 0
showPort = 0
showEventChanged = 0
showBookmark = 0
showEventTrigger = 0
showResBufferSize = 0
showResBuffer = 0
showRatingSize = 0
showRating = 0
showShowIDSize = 0
showShowID = 0
showShowDescriptionSize = 0
showShowDescription = 0
showDataBufferSize = 0
showDataBuffer = 0
}
foreach ($key in @($show.Keys)) {$show.$key = 0}  # override all show keys to 1 or 0 to show/don't show corresponding bytes


# reference tables
$refType = @{
    [byte]32 = '?'
    [byte]33 = 'sSYN'
    [byte]128 = 'sAV'
    [byte]129 = 'SECAUDIOEVENT'
    [byte]130 = 'SECVIDEOEVENT'
    [byte]131 = 'sKEY'
    [byte]132 = 'sTKY'
    [byte]133 = 'bAV'
    [byte]134 = 'SECAVEVENTWITHKEY' 
    [byte]136 = 'bGPI'
    [byte]137 = 'sGPI'
    [byte]144 = 'sTAO'
    [byte]145 = 'sAOV'
    [byte]146 = 'SECAVEVENTWITHAUDIOOVER'
    [byte]160 = 'sDAT'
    [byte]164 = 'sSYS'
    [byte]165 = 'bSYS'
    [byte]176 = 'sRSW'
    [byte]177 = 'sXP'
    [byte]178 = 'sAXP'
    [byte]181 = 'sREC'
    [byte]224 = '****'
    [byte]225 = 'cmID'
    [byte]226 = 'SECAPPFLAG'
    [byte]227 = 'sBAR'
    [byte]228 = 'HEADER' # I added it myself
}
$refTypeBuffer = @{
    [byte]128 = 'vDT'
    [byte]160 = 'sDAT'
}
$refEventControl = @{
    15 = 'P' #'autoplay'
    14 = 'T' #'autothread'
    13 = 'S' #'autoswitch'
    12 = 'R' #'autorecord'
    11 = 'O' #'autotimed'
    10 = 'X' #'autoexception'
    9 =  'U' #'autoupcount'
    8 =  'M' #'manualstart'
    7 =  'C' #'autocontactstart'
    6 =  'N' #'automarktime'
    5 =  'D' #'autodeadroll'
    4 =  'V' #'switchvideoonly'
    3 =  'I' #'switchaudioonly'
    2 =  'J' #'switchrejoin'
    1 =  '?' #'userbitonly'
    0 =  'E' #'switchAudioVideoIndependent'
}
$refExtEventControl = @{
    5 = 'Q' #tAudibleAutoMarktime
    4 = '?' #tFrameDropped
    3 = '?' #tCountedRoundDF
    2 = '>' #tStartEventEndTimed
    1 = '<' #tStartEventBacktimed
    0 = '=' #tMatchPrimaryDuration
}

Function Get-FileName($initialDirectory) {
    [System.Reflection.Assembly]::LoadWithPartialName(“System.windows.forms”) | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = “lst files (*.lst)| *.lst”
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
} #end function Get-FileName

# reading .lst file to $Content byte array
#$file = 'C:\Lists\!!!!.lst'
#$file = 'C:\Lists\List12500 PL Clear.lst'
$file = Get-FileName('C:\Lists')
if (!$file) { exit }

#$time1 = Get-Date
#$Content = New-object -type System.Collections.ArrayList
#(Get-Content $file -ReadCount 0 -Encoding Byte) | % {$Content.Add($_)} | Out-Null # read entire list
#(Get-Content $file -TotalCount 7000 -Encoding Byte) | % {$Content.Add($_)} | Out-Null #read first 7000 bytes ~10-20 events
#(Get-Content $file -TotalCount (750*$eventsToShow) -Encoding Byte) | % {$Content.Add($_)} | Out-Null # read approximate number of bytes corresponding to $eventsToShow
#(Get-Content $file -TotalCount (750*($startEvent + $eventsToShow)) -Encoding Byte) | % {$Content.Add($_)} | Out-Null # read approximate number of bytes corresponding to $startEvent plus $eventsToShow
$Content = Get-Content $file -Raw -Encoding Byte
#"{0} seconds ({1} ms)" -f[math]::Round(((Get-Date) - $time1).TotalSeconds, 1), [int]((Get-Date) - $time1).TotalMilliseconds ; return

function showBytes ([int]$numberOfBytes, [string]$name) {
    if ($event -lt $startEvent) {return}
    for ($i=$pos ; $i -lt ($pos+$numberOfBytes) ; $i++) {
        if ($i -ne $pos) {Write-Host " " -NoNewline} # if not 1st iteration adding space before next Byte
        $byte = "{0:x2}" -f $Content[$i]
        Write-Host $byte -NoNewline
    } Write-Host "  --  $name"
}

$table = New-Object System.Data.DataTable  # creating a table of events
$table.Columns.Add("No","int") | Out-Null
$table.Columns.Add("DateToAir","string") | Out-Null
$table.Columns.Add("OnAirTime","string") | Out-Null
$table.Columns.Add("OrigDate","string") | Out-Null
$table.Columns.Add("OrigTime","string") | Out-Null
$table.Columns.Add("Sec","string") | Out-Null
$table.Columns.Add("Type","string") | Out-Null
$table.Columns.Add("ID","string") | Out-Null
$table.Columns.Add("Seg","string") | Out-Null
$table.Columns.Add("Title","string") | Out-Null
$table.Columns.Add("DUR","string") | Out-Null
$table.Columns.Add("SOM","string") | Out-Null
$table.Columns.Add("ABOX","string") | Out-Null
$table.Columns.Add("ABOXSOM","string") | Out-Null
$table.Columns.Add("BBOX","string") | Out-Null
$table.Columns.Add("BBOXSOM","string") | Out-Null
$table.Columns.Add("Reconcile","string") | Out-Null
$table.Columns.Add("CompileID","string") | Out-Null
$table.Columns.Add("CompileSOM","string") | Out-Null
$table.Columns.Add("sSP","string") | Out-Null
$table.Columns.Add("EvtType","string") | Out-Null
$table.Columns.Add("ResBuffer","string") | Out-Null
$table.Columns.Add("Content","string") | Out-Null
$table.Columns.Add("Rating","string") | Out-Null
$table.Columns.Add("ShowID","string") | Out-Null
$table.Columns.Add("ShowDescription","string") | Out-Null

$pos = 64  # setting starting position to 64 (skipping .lst file header)
$event = 1
$time0 = Get-Date
do {
    $row = $table.NewRow()
    $row.No = $event
    

    #  EventType
    $row.Sec = 
        if (!$Content[$pos]) { '' }  # Primary
        elseif ($Content[$pos]) {  # Secondary
            if ($Content[$pos+1] -ne 1) { $refType[$Content[$pos]] }  # sec event except data with data
            elseif ($Content[$pos+1] -eq 1) { $refTypeBuffer[$Content[$pos]] ; $dataFlag = 1 }  # data with data sec event
        }
    if ($show.showEventType) {showBytes 2 -name 'EventType']}
    $pos = $pos + 2
    

    if ($show.showKey) {showBytes 8 -name 'Key']}
    $pos = $pos + 8  # 8 bytes for fKey (Used within the automation as Local Unique ID)


    $row.Reconcile =
        if ($Content[$pos] -eq 255) { '' }
        else {[System.Text.Encoding]::Default.GetString($Content[$pos..($pos+31)]) -replace '(^\s+|\s+$)',''}
    if ($show.showReconcile) {showBytes 32 -name Reconcile}
    $pos = $pos + 32


    if ($show.showEffects) {showBytes 3 -name Effects}
    $pos = $pos + 3  # foaday, foamonth, foayear - these three bytes actually contain effect 1, 2, 3 fields. Probably speed and type of transition
    

    $row.OnAirTime = 
        if (($Content[$pos..($pos+3)] | measure -Sum).Sum -eq 1020) { '' } # if all 4 bytes are FF, make field empty in table
        else {"{0:x2}:{1:x2}:{2:x2};{3:x2}" -f $Content[$pos+3],$Content[$pos+2],$Content[$pos+1],$Content[$pos]}
    if ($show.showOnAirTime) {showBytes 4 -name OnAirTime}
    $pos = $pos + 4
    

    $row.ID = 
        [System.Text.Encoding]::UTF8.GetString($Content[$pos..($pos+31)]) -replace '(^\s+|\s+$)',''
    if ($show.showID) {showBytes 32 -name ID}
    $pos = $pos + 32


    $row.Title = 
        [System.Text.Encoding]::UTF8.GetString($Content[$pos..($pos+31)]) -replace '(^\s+|\s+$)',''
    if ($show.showTitle) {showBytes 32 -name Title}
    $pos = $pos + 32
    

    $row.SOM = 
        if (($Content[$pos..($pos+3)] | measure -Sum).Sum -eq 1020) { '' } # if all 4 bytes are FF, make field empty in table
        else {"{0:x2}:{1:x2}:{2:x2};{3:x2}" -f $Content[$pos+3],$Content[$pos+2],$Content[$pos+1],$Content[$pos]}
    if ($show.showSOM) {showBytes 4 -name SOM}
    $pos = $pos + 4
    

    $row.DUR = 
        if (($Content[$pos..($pos+3)] | measure -Sum).Sum -eq 1020) { '' } # if all 4 bytes are FF, make field empty in table
        else {"{0:x2}:{1:x2}:{2:x2};{3:x2}" -f $Content[$pos+3],$Content[$pos+2],$Content[$pos+1],$Content[$pos]}
    if ($show.showDUR) {showBytes 4 -name DUR}
    $pos = $pos + 4  # fedurf, fedurs, fedurm, fedurh


    if ($show.showChannel) {showBytes 1 -name Channel}
    $pos = $pos + 1  # fechannel
    

    $row.Seg = 
        if ($Content[$pos] -eq 255) { '' }
        else {"{0:d}" -f $Content[$pos]}
    if ($show.showSeg) {showBytes 1 -name Segment}
    $pos = $pos + 1  # 1 segment


    if ($show.showIndexes) {showBytes 7 -name 'femsindex felsindex fehibin felobin fqualifier1 fqualifier2 fqualifier3'}
    $pos = $pos + 7  # femsindex felsindex fehibin felobin fqualifier1 fqualifier2 fqualifier3


    $row.sSP =  # fqualifier4 in old Misha doc
        $Content[$pos]
    if ($show.showSsp) {showBytes 1 -name sSP}
    $pos = $pos + 1


    $row.DateToAir = 
        "{0:MM}/{0:dd}/{0:yyyy}" -f (Get-Date '01/01/1900').AddDays(($Content[$pos+1]*256 + $Content[$pos]))
    if ($show.showDateToAir) {showBytes 2 -name DateToAir}
    $pos = $pos + 2
    

    #  eventControl
    $row.Type =
        if ((!$Content[$pos]) -and (!$Content[$pos+1])) { '' }
        else { 
            $bitWord = [Convert]::ToString($Content[$pos+1],2).PadLeft(8,'0'),
            [Convert]::ToString($Content[$pos],2).PadLeft(8,'0') -join ''

            for ($($i = 15 ; $result='') ; $i -ge 0  ; $i-- ) {
                if ($bitWord[$i] -eq '1') { $result += $refEventControl[$i] }
            }
            if ($result -like '*TS*') {$result = $result -replace 'TS','ST'}
            if ($result -like 'PST*') {$result -replace 'PST','A'}
            else {$result}
        }
    if ($show.showControl) {showBytes 2 -name Control}
    $pos = $pos + 2


    if ($show.showStatus) {showBytes 4 -name Status}
    $pos = $pos + 4


    $row.CompileID = 
        if (($Content[$pos..($pos+31)] | measure -Sum).Sum -eq 8160) { '' } # if all 32 bytes are FF, make field empty in table
        else {[System.Text.Encoding]::Default.GetString($Content[$pos..($pos+31)]) -replace '(^\s+|\s+$)',''}
    if ($show.showCompileID) {showBytes 32 -name CompileID}
    $pos = $pos + 32


    $row.CompileSOM = 
        if (($Content[$pos..($pos+3)] | measure -Sum).Sum -eq 1020) { '' } # if all 4 bytes are FF, make field empty in table
        else {"{0:x2}:{1:x2}:{2:x2};{3:x2}" -f $Content[$pos+3],$Content[$pos+2],$Content[$pos+1],$Content[$pos]}
    if ($show.showCompileSOM) {showBytes 4 -name CompileSOM}
    $pos = $pos + 4


    $row.ABOX =
        if (($Content[$pos..($pos+31)] | measure -Sum).Sum -eq 8160) { '' } # if all 32 bytes are FF, make field empty in table
        else {[System.Text.Encoding]::Default.GetString($Content[$pos..($pos+31)]) -replace '(^\s+|\s+$)',''}
    if ($show.showABOX) {showBytes 32 -name ABOX}
    $pos = $pos + 32


    $row.ABOXSOM = 
        if (($Content[$pos..($pos+3)] | measure -Sum).Sum -eq 1020) { '' } # if all 4 bytes are FF, make field empty in table
        else {"{0:x2}:{1:x2}:{2:x2};{3:x2}" -f $Content[$pos+3],$Content[$pos+2],$Content[$pos+1],$Content[$pos]}
    if ($show.showABOXSOM) {showBytes 4 -name ABOXSOM}
    $pos = $pos + 4


    $row.BBOX =
        if (($Content[$pos..($pos+31)] | measure -Sum).Sum -eq 8160) { '' } # if all 32 bytes are FF, make field empty in table
        else {[System.Text.Encoding]::Default.GetString($Content[$pos..($pos+31)]) -replace '(^\s+|\s+$)',''}
    if ($show.showBBOX) {showBytes 32 -name BBOX}
    $pos = $pos + 32


    $row.BBOXSOM = 
        if (($Content[$pos..($pos+3)] | measure -Sum).Sum -eq 1020) { '' } # if all 4 bytes are FF, make field empty in table
        else {"{0:x2}:{1:x2}:{2:x2};{3:x2}" -f $Content[$pos+3],$Content[$pos+2],$Content[$pos+1],$Content[$pos]}
    if ($show.showBBOXSOM) {showBytes 4 -name BBOXSOM}
    $pos = $pos + 4


    if ($show.showIndexes2) {showBytes 3 -name 'fmspotcontrol fbackupemsindex fbackupelsindex'}
    $pos = $pos + 3  # fmspotcontrol fbackupemsindex fbackupelsindex


    #  extEventControl
    if (($Content[$pos]) -or ($Content[$pos+1])) {
        $bitWord = [Convert]::ToString($Content[$pos+1],2).PadLeft(8,'0'),
        [Convert]::ToString($Content[$pos],2).PadLeft(8,'0') -join ''
        for ($($i = 15 ; $result='') ; $i -ge 0  ; $i-- ) {
            if ($bitWord[$i] -eq '1') { $row.Type += $refExtEventControl[$i] }
        }
        if ($row.Type -like '*Q*') { $row.Type = $row.Type -replace 'N','' }
    }
    if ($show.showExtControl) {showBytes 2 -name ExtControl}
    $pos = $pos + 2

    
    if ($show.showClosedCaption) {showBytes 1 -name ClosedCaption}
    $pos = $pos + 1


    if ($show.showAFD_Bar_Data) {showBytes 1 -name AFD_Bar_Data}
    $pos = $pos + 1


    if ($show.showDialNorm) {showBytes 4 -name DialNorm}
    $pos = $pos + 4


    if ($show.showDBKey) {showBytes 4 -name DBKey}
    $pos = $pos + 4
    
    
    if ($show.showFieldsFromSource) {showBytes 8 -name FieldsFromSource}
    $pos = $pos + 8
    
    
    if ($show.showFieldsToSource) {showBytes 8 -name FieldsToSource}
    $pos = $pos + 8


    if ($show.showReserved) {showBytes 50 -name Reserved50}  # Originally it was 59 Reserved bytes in old Misha doc
    $pos = $pos + 50  # unknown to me. Misha wanted to update Streamed Event v12 Structure doc
    

    $row.OrigTime =  # forigframe, forigsec, forigmin, forighour: byte (1 byte each)
        if (($Content[$pos..($pos+3)] | measure -Sum).Sum -eq 1020) { '' }  # if all 4 bytes are FF, make field empty in table
        else {"{0:x2}:{1:x2}:{2:x2};{3:x2}" -f $Content[$pos+3],$Content[$pos+2],$Content[$pos+1],$Content[$pos]}
    if ($show.showOrigTime) {showBytes 4 -name OrigTime}
    $pos = $pos + 4
    

    $row.OrigDate =  # forigdatetoair: word (2 bytes)
        if (($Content[$pos..($pos+1)] | measure -Sum).Sum -eq 510) { '' }  # if all 2 bytes are FF, make field empty in table
        else {"{0:MM}/{0:dd}/{0:yyyy}" -f (Get-Date '01/01/1900').AddDays(($Content[$pos+1]*256 + $Content[$pos]))}
    if ($show.showOrigDate) {showBytes 2 -name OrigDate}
    $pos = $pos + 2
    

    $row.EvtType = [char]$Content[$pos]  # fEvtType: AnsiChar (1 byte) - undefined / single spot / ms and so on
    if ($show.showEvtType) {showBytes 1 -name EvtType}
    $pos = $pos + 1 
    

    if ($show.showTriggeredLists) {showBytes 2 -name TriggeredLists}  # fetriggeredlists: word (2 bytes)
    $pos = $pos + 2
    

    if ($show.showPort) {showBytes 2 -name Port}
    $pos = $pos + 2


    if ($show.showEventChanged) {showBytes 1 -name EventChanged}
    $pos = $pos + 1
    

    if ($show.showBookmark) {showBytes 1 -name Bookmark}
    $pos = $pos + 1


    if ($show.showEventTrigger) {showBytes 1 -name EventTrigger}
    $pos = $pos + 1


    #  Res_Buffer
    $RBL = $Content[$pos] + $Content[$pos+1] * 256  #Res_Buffer Length
    if ($show.showResBufferSize) {showBytes 2 -name ResBufferSize}
    $pos = $pos + 2

    if ($RBL) {
        $RBC = [System.Text.Encoding]::Default.GetString($Content[$pos..($pos+$RBL-1)])  # ResBuffer content
        $row.ResBuffer = $RBC
        if ($show.showResBuffer) {showBytes $RBL -name ResBuffer}
    } else {$RBC = $Null}
    if ($RBC -match '(;|^)Content=(?<content>.*?);') {$row.Content = $Matches['content']}
    $pos += $RBL


    #  Rating
    $RTL = $Content[$pos] + $Content[$pos+1] * 256 #Rating_Buffer Length
    if ($show.showRatingSize) {showBytes 2 -name RatingBufferSize}
    $pos = $pos + 2
    if ($RTL) {
        $row.Rating = [System.Text.Encoding]::Default.GetString($Content[$pos..($pos+$RTL-1)]) -replace '(^\s+|\s+$)',''  # Rating Buffer content
        if ($show.showRating) {showBytes $RTL -name Rating}
    }
    $pos += $RTL


    #  ShowID
    $SIL = $Content[$pos] + $Content[$pos+1] * 256  # ShowID_Buffer Length
    if ($show.showShowIDSize) {showBytes 2 -name ShowIDBufferSize}
    $pos = $pos + 2
    if ($SIL) {
        $row.ShowID = [System.Text.Encoding]::Default.GetString($Content[$pos..($pos+$SIL-1)]) -replace '(^\s+|\s+$)',''  # ShowID Buffer content
        if ($show.showShowID) {showBytes $SIL -name ShowID}
    }
    $pos += $SIL
    

    #  ShowDescription
    $SDL = $Content[$pos] + $Content[$pos+1] * 256  # ShowDescription_Buffer Length
    if ($show.showShowDescriptionSize) {showBytes 2 -name ShowDescriptionBufferSize}
    $pos = $pos + 2
    if ($SDL) {
        $row.ShowDescription = [System.Text.Encoding]::Default.GetString($Content[$pos..($pos+$SDL-1)]) -replace '(^\s+|\s+$)',''  # ShowDescription Buffer content
        if ($show.showShowDescription) {showBytes $SDL -name ShowDescription}
    }
    $pos += $SDL


    #  DataBuffer
    if ($dataFlag -eq 1) {
        $DBL = $Content[$pos] + $Content[$pos+1] * 256
        if ($show.showDataBufferSize) {showBytes 2 -name DataBufferSize}
        $pos = $pos + 2
        if ($show.showDataBuffer) {showBytes $DBL -name DataBuffer}
        $pos = $pos + $DBL
        $dataFlag = 0
    }
    

    if ($event -ge $startEvent) {$table.Rows.Add($row)}# ; write-host "-----------------------------------------------------------------------------------------------------"}
    
    $event++
} while (($pos -lt $Content.Count) -and ($event -lt ($startEvent + $eventsToShow)))
#} while (($pos -lt $Content.Count))


#$table | ft -Property $table.Columns.Caption
#$table | select -First 26 | ft -Property ($table.Columns.Caption | ? {$_ -notmatch 'content|show|rating|ssp|title'})
$table | ft -Property ($table.Columns.Caption | ? {$_ -notmatch '^ABOX$|^BBOX$|BBOXSOM|CompileSOM|CompileID|Rating|ShowID|ShowDescription|Content'})

#"{0} seconds ({1} ms)" -f[math]::Round(((Get-Date) - $time0).TotalSeconds, 1), [int]((Get-Date) - $time0).TotalMilliseconds
if ($Host.Name -ne 'Windows PowerShell ISE Host') {read-host}  # if not Powershell_ISE - wait for an input
