$eventsToShow = 10

#reference tables
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

#reading .lst file to $Content byte array
#$file = 'C:\Lists\!!!!.lst'
$file = Get-FileName('C:\Lists')
if (!$file) { exit }

$Content = New-object -type System.Collections.ArrayList
#(Get-Content $file -ReadCount 0 -Encoding Byte) | % {$Content.Add($_)} | Out-Null # read entire list
#(Get-Content $file -TotalCount 7000 -Encoding Byte) | % {$Content.Add($_)} | Out-Null #read first 7000 bytes ~10-20 events
(Get-Content $file -TotalCount (750*$eventsToShow) -Encoding Byte) | % {$Content.Add($_)} | Out-Null # read approximate number of bytes corresponding to $eventsToShow

function showBytes ($numberOfBytes) {
    for ($i=$pos ; $i -lt ($pos+$numberOfBytes) ; $i++) {
        $byte = "{0:x2} " -f $Content[$i]
        Write-Host $byte -NoNewline
    } ""
}

#creating a table of events
$table = New-Object System.Data.DataTable
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

$showID = 0
$showSecondary = 0
$showReconcile = 0
$showOnAirDate = 0
$showOnAirTime = 0
$showTitle = 0
$showSOM = 0
$showDUR = 0
$showSeg = 0
$showDateToAir = 0
$showControl = 0
$showStatus = 0
$showCompileID = 0
$showCompileSOM = 0
$showABOX = 0
$showABOXSOM = 0
$showBBOX = 0
$showBBOXSOM = 0
$showExtControl = 0
$showReserved = 0
$showOrigTime = 1
$showOrigDate = 1
$showEvtType = 1
$showTriggeredLists = 1
$showPort = 1
$showResBuffer = 1
$showContent = 0
$showRating = 0
$showShowID = 0
$showShowDescription = 0


#setting starting position to 64 (skipping .lst file header)
$pos = 64
$event = 1

$time = Get-Date
$bin = @()
$j=0

do {
    $row = $table.NewRow()
    
    $row.No = $event
    
    $row.Sec = 
        if (!$Content[$pos]) { '' } #Primary
        elseif ($Content[$pos]) { #Secondary
            if ($Content[$pos+1] -ne 1) { $refType[$Content[$pos]] } #sec event except data with data
            elseif ($Content[$pos+1] -eq 1) { $refTypeBuffer[$Content[$pos]] ; $dataFlag = 1 } #data with data sec event
        }
    if ($showSecondary) {"Secondary $(showBytes(2))"}
    $pos = $pos + 10

    $row.Reconcile =
        if ($Content[$pos] -eq 255) { '' }
        else {[System.Text.Encoding]::Default.GetString($Content[$pos..($pos+31)]) -replace '(^\s+|\s+$)',''}
    if ($showReconcile) {"Reconcile $(showBytes(32))"}
    $pos = $pos + 32

    $pos = $pos + 3 # OADate = these three bytes actually contain effect 1, 2, 3 fields. Probably speed and type of transition
    
    $row.OnAirTime = 
        if ($Content[$pos] -eq 255) { '' }
        else {"{0:x2}:{1:x2}:{2:x2};{3:x2}" -f $Content[$pos+3],$Content[$pos+2],$Content[$pos+1],$Content[$pos]}
    if ($showOnAirTime) {"OnAirTime $(showBytes(4))"}
    $pos = $pos + 4
        
    $row.ID = 
        [System.Text.Encoding]::UTF8.GetString($Content[$pos..($pos+31)]) -replace '(^\s+|\s+$)',''
    if ($showID) {"ID $(showBytes(32))"}
    $pos = $pos + 32

    $row.Title = 
        [System.Text.Encoding]::UTF8.GetString($Content[$pos..($pos+31)]) -replace '(^\s+|\s+$)',''
    if ($showTitle) {"Title $(showBytes(32))"}
    $pos = $pos + 32
        
    $row.SOM = 
        if ($Content[$pos] -eq 255) { '' }
        else {"{0:x2}:{1:x2}:{2:x2};{3:x2}" -f $Content[$pos+3],$Content[$pos+2],$Content[$pos+1],$Content[$pos]}
    if ($showSOM) {"SOM $(showBytes(4))"}
    $pos = $pos + 4
    
    $row.DUR = 
        if ($Content[$pos] -eq 255) { '' }
        else {"{0:x2}:{1:x2}:{2:x2};{3:x2}" -f $Content[$pos+3],$Content[$pos+2],$Content[$pos+1],$Content[$pos]}
    if ($showDUR) {"DUR $(showBytes(4))"}
    $pos = $pos + 5

    $row.Seg = 
        if ($Content[$pos] -eq 255) { '' }
        else {"{0:d}" -f $Content[$pos]}
    if ($showSeg) {"Segment $(showBytes(1))"}
    $pos = $pos + 8

    $row.sSP = 
        $Content[$pos]
    $pos = $pos + 1

    $row.DateToAir = 
        "{0:MM}/{0:dd}/{0:yyyy}" -f (Get-Date '01/01/1900').AddDays(($Content[$pos+1]*256 + $Content[$pos]))
    if ($showDateToAir) {"DateToAir $(showBytes(2))"}
    $pos = $pos + 2
    
    $row.Type = #eventControl
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
    if ($showControl) {"Control $(showBytes(2))"}
    $pos = $pos + 2

    if ($showStatus) {"Status $(showBytes(4))"}
    $pos = $pos + 4

    $row.CompileID = 
        if ($Content[$pos] -eq 255) { '' }
        else {[System.Text.Encoding]::Default.GetString($Content[$pos..($pos+31)]) -replace '(^\s+|\s+$)',''}
    if ($showCompileID) {"CompileID $(showBytes(32))"}
    $pos = $pos + 32

    $row.CompileSOM = 
        if ($Content[$pos] -eq 255) { '' }
        else {"{0:x2}:{1:x2}:{2:x2};{3:x2}" -f $Content[$pos+3],$Content[$pos+2],$Content[$pos+1],$Content[$pos]}
    if ($showCompileSOM) {"CompileSOM $(showBytes(4))"}
    $pos = $pos + 4

    $row.ABOX =
        if ($Content[$pos] -eq 255) { '' }
        else {[System.Text.Encoding]::Default.GetString($Content[$pos..($pos+31)]) -replace '(^\s+|\s+$)',''}
    if ($showABOX) {"ABOX $(showBytes(32))"}
    $pos = $pos + 32

    $row.ABOXSOM = 
        if ($Content[$pos] -eq 255) { '' }
        else {"{0:x2}:{1:x2}:{2:x2};{3:x2}" -f $Content[$pos+3],$Content[$pos+2],$Content[$pos+1],$Content[$pos]}
    if ($showABOXSOM) {"ABOXSOM $(showBytes(4))"}
    $pos = $pos + 4

    $row.BBOX =
        if ($Content[$pos] -eq 255) { '' }
        else {[System.Text.Encoding]::Default.GetString($Content[$pos..($pos+31)]) -replace '(^\s+|\s+$)',''}
    if ($showBBOX) {"BBOX $(showBytes(32))"}
    $pos = $pos + 32

    $row.BBOXSOM = 
        if ($Content[$pos] -eq 255) { '' }
        else {"{0:x2}:{1:x2}:{2:x2};{3:x2}" -f $Content[$pos+3],$Content[$pos+2],$Content[$pos+1],$Content[$pos]}
    if ($showBBOXSOM) {"BBOXSOM $(showBytes(4))"}
    $pos = $pos + 7

    if (($Content[$pos]) -or ($Content[$pos+1])) { #extEventControl
        $bitWord = [Convert]::ToString($Content[$pos+1],2).PadLeft(8,'0'),
        [Convert]::ToString($Content[$pos],2).PadLeft(8,'0') -join ''
        for ($($i = 15 ; $result='') ; $i -ge 0  ; $i-- ) {
            if ($bitWord[$i] -eq '1') { $row.Type += $refExtEventControl[$i] }
        }
        if ($row.Type -like '*Q*') { $row.Type = $row.Type -replace 'N','' }
    }
    if ($showExtControl) {"ExtControl $(showBytes(2))"}
    $pos = $pos + 28

    #if ($showReserved) {"Reserved $(showBytes(59))"}  Original Reserved 59 bytes as in doc
    if ($showReserved) {"Reserved $(showBytes(50))"}
    $pos = $pos + 45 
    "Last5Reserved $(showBytes(5))" # last 5 Reserved bytes
    $pos = $pos + 5 # unknown to me. Misha wanted to update Streamed Event v12 Structure
    
    $row.OrigTime = # forigframe, forigsec, forigmin, forighour: byte (1 byte each)
        if ($Content[$pos] -eq 255) { '' }
        else {"{0:x2}:{1:x2}:{2:x2};{3:x2}" -f $Content[$pos+3],$Content[$pos+2],$Content[$pos+1],$Content[$pos]}
    if ($showOrigTime) {"OrigTime $(showBytes(4))"}
    $pos = $pos + 4
    
    $row.OrigDate = # forigdatetoair: word (2 bytes)
        "{0:MM}/{0:dd}/{0:yyyy}" -f (Get-Date '01/01/1900').AddDays(($Content[$pos+1]*256 + $Content[$pos]))
    if ($showOrigDate) {"OrigDate $(showBytes(2))"}
    $pos = $pos + 2
    
    $row.EvtType = [char]$Content[$pos] # fEvtType: AnsiChar (1 byte) - undefined / single spot / ms and so on
    if ($showEvtType) {"EvtType $(showBytes(1))"}
    $pos = $pos + 1 
    
    $pos = $pos + 2 # fetriggeredlists: word (2 bytes)
    if ($showTriggeredLists) {"TriggeredLists $(showBytes(2))"}

    if ($showPort) {"Port $(showBytes(2))"}
    $pos = $pos + 2

    "eventChanged,bookmark,eventTrigger $(showBytes(3))" # feventchanged, fbookmark, feventtrigger
    $pos = $pos + 3    

    #Res_Buffer skip (Content is here)
    #$pos = $pos + $Content[$pos] + $Content[$pos+1] * 256 + 2
    #Res_Buffer read (Content is here)
    $RBL = $Content[$pos] + $Content[$pos+1] * 256 #Res_Buffer Length
    "ResBufferSize $(showBytes(2))"
    $pos += 2
    if ($RBL) {
        if ($showResBuffer) {"ResBuffer $(showBytes($RBL))"} #Show Res_Buffer bytes
        $RBC = [System.Text.Encoding]::Default.GetString($Content[$pos..($pos+$RBL-1)]) #-replace '(^\s+|\s+$)',''
        $row.ResBuffer = $RBC
    } else {$RBC = $Null} #Res_Buffer content
    if ($RBC -match '(;|^)Content=(?<content>.*?);') {$row.Content = $Matches['content']}
    if ($showContent) {"Content $(showBytes($RBL))"}
    $pos += $RBL

    #Rating skip
    #$pos = $pos + $Content[$pos] + $Content[$pos+1] * 256 + 2
    $RTL = $Content[$pos] + $Content[$pos+1] * 256 #Rating_Buffer Length
    $pos += 2
    if ($RTL) {
        if ($showRating) {"Rating $(showBytes($RTL))"}
        $row.Rating = [System.Text.Encoding]::Default.GetString($Content[$pos..($pos+$RTL-1)]) -replace '(^\s+|\s+$)','' #Rating_Buffer content
    }
    $pos += $RTL

    #ShowID skip
    #$pos = $pos + $Content[$pos] + $Content[$pos+1] * 256 + 2
    $SIL = $Content[$pos] + $Content[$pos+1] * 256 #ShowID_Buffer Length
    $pos += 2
    if ($SIL) {
        if ($showShowID) {"ShowID $(showBytes($SIL))"}
        $row.ShowID = [System.Text.Encoding]::Default.GetString($Content[$pos..($pos+$SIL-1)]) -replace '(^\s+|\s+$)',''} #ShowID_Buffer content
    $pos += $SIL
    
    #ShowDescription skip
    #$pos = $pos + $Content[$pos] + $Content[$pos+1] * 256 + 2
    $SDL = $Content[$pos] + $Content[$pos+1] * 256 #ShowDescription_Buffer Length
    $pos += 2
    if ($SDL) {
        if ($showShowDescription) {"ShowDescription $(showBytes($SDL))"}
        $row.ShowDescription = [System.Text.Encoding]::Default.GetString($Content[$pos..($pos+$SDL-1)]) -replace '(^\s+|\s+$)','' #Res_Buffer content
    }
    $pos += $SDL


    #databuffer skip
    if ($dataFlag -eq 1) { $pos = $pos + $Content[$pos] + $Content[$pos+1] * 256 + 2 ; $dataFlag = 0 }
        
    $table.Rows.Add($row)
    
    
    $event++
    write-host "-----------------------------------------------------------------------------------------------------"
} while (($pos -lt $Content.Count) -and ($event -le $eventsToShow))
#} while (($pos -lt $Content.Count))


#$table | ft -Property $table.Columns.Caption
#$table | select -First 26 | ft -Property ($table.Columns.Caption | ? {$_ -notmatch 'content|show|rating|ssp|title'})
$table | ft -Property ($table.Columns.Caption | ? {$_ -notmatch '^ABOX$|^BBOX$|BBOXSOM|Reconcile|CompileSOM|CompileID|Rating|ShowID|ShowDescription'})

read-host