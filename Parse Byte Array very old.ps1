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

Function Get-FileName($initialDirectory)
{
    [System.Reflection.Assembly]::LoadWithPartialName(“System.windows.forms”) | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = “lst files (*.lst)| *.lst”
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
} #end function Get-FileName

#reading .lst file to $Content byte array
$file = Get-FileName
if (!$file) { exit }
#$file = 'C:\PS\Demo1000_first100x5s.lst'
$Content = Get-Content $file -ReadCount 0 -Encoding Byte

function showBytes ($numberOfBytes) {
    for ($i=$pos ; $i -lt ($pos+$numberOfBytes) ; $i++) {
        $byte = "{0:x2} " -f $Content[$i]
        Write-Host $byte -NoNewline
    } ""
}

#creating a table of events
$table = New-Object System.Data.DataTable
$table.Columns.Add("No","int") | Out-Null
$table.Columns.Add("Date","string") | Out-Null
$table.Columns.Add("OAT","string") | Out-Null
$table.Columns.Add("Sec","string") | Out-Null
$table.Columns.Add("Type","string") | Out-Null
$table.Columns.Add("ID","string") | Out-Null
$table.Columns.Add("Seg","string") | Out-Null
$table.Columns.Add("Title","string") | Out-Null
$table.Columns.Add("DUR","string") | Out-Null
$table.Columns.Add("SOM","string") | Out-Null
$table.Columns.Add("ABOX","string") | Out-Null
$table.Columns.Add("BBOX","string") | Out-Null
$table.Columns.Add("Reconcile","string") | Out-Null
$table.Columns.Add("CompileID","string") | Out-Null
    
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
#    "Secondary $(showBytes(2))"
    $pos = $pos + 10

    $row.Reconcile =
        if ($Content[$pos] -eq 255) { '' }
        else {[System.Text.Encoding]::Default.GetString($Content[$pos..($pos+31)]) -replace '(^\s+|\s+$)',''}
#    "Reconcile $(showBytes(32))"
    $pos = $pos + 35

    $row.OAT = 
        if ($Content[$pos] -eq 255) { '' }
        else {"{0:x2}:{1:x2}:{2:x2};{3:x2}" -f $Content[$pos+3],$Content[$pos+2],$Content[$pos+1],$Content[$pos]}
#    "Time $(showBytes(4))"
    $pos = $pos + 4
        
    $row.ID = 
        [System.Text.Encoding]::UTF8.GetString($Content[$pos..($pos+31)]) -replace '(^\s+|\s+$)',''
#    "ID $(showBytes(32))"
    $pos = $pos + 32

    $row.Title = 
        [System.Text.Encoding]::UTF8.GetString($Content[$pos..($pos+31)]) -replace '(^\s+|\s+$)',''
#    "Title $(showBytes(32))"
    $pos = $pos + 32
        
    $row.SOM = 
        if ($Content[$pos] -eq 255) { '' }
        else {"{0:x2}:{1:x2}:{2:x2};{3:x2}" -f $Content[$pos+3],$Content[$pos+2],$Content[$pos+1],$Content[$pos]}
#    "SOM $(showBytes(4))"
    $pos = $pos + 4
    
    $row.DUR = 
        if ($Content[$pos] -eq 255) { '' }
        else {"{0:x2}:{1:x2}:{2:x2};{3:x2}" -f $Content[$pos+3],$Content[$pos+2],$Content[$pos+1],$Content[$pos]}
#    "DUR $(showBytes(4))"
    $pos = $pos + 5

    $row.Seg = 
        if ($Content[$pos] -eq 255) { '' }
        else {"{0:d}" -f $Content[$pos]}
#    "Segment $(showBytes(1))"
    $pos = $pos + 9

    $row.Date = 
        "{0:MM}/{0:dd}/{0:yyyy}" -f (Get-Date '01/01/1900').AddDays(($Content[$pos+1]*256 + $Content[$pos]))
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
#    "Control $(showBytes(2))"
    $pos = $pos + 6

    $row.CompileID = 
        if ($Content[$pos] -eq 255) { '' }
        else {[System.Text.Encoding]::Default.GetString($Content[$pos..($pos+31)]) -replace '(^\s+|\s+$)',''}
#    "CompileID $(showBytes(32))"
    $pos = $pos + 36

    $row.ABOX =
        if ($Content[$pos] -eq 255) { '' }
        else {[System.Text.Encoding]::Default.GetString($Content[$pos..($pos+31)]) -replace '(^\s+|\s+$)',''}
#    "ABOX $(showBytes(32))"
    $pos = $pos + 36

    $row.BBOX =
        if ($Content[$pos] -eq 255) { '' }
        else {[System.Text.Encoding]::Default.GetString($Content[$pos..($pos+31)]) -replace '(^\s+|\s+$)',''}
#    "BBOX $(showBytes(32))"
    $pos = $pos + 39

    
    if (($Content[$pos]) -or ($Content[$pos+1])) { #extEventControl
        $bitWord = [Convert]::ToString($Content[$pos+1],2).PadLeft(8,'0'),
        [Convert]::ToString($Content[$pos],2).PadLeft(8,'0') -join ''
        for ($($i = 15 ; $result='') ; $i -ge 0  ; $i-- ) {
            if ($bitWord[$i] -eq '1') { $row.Type += $refExtEventControl[$i] }
        }
        if ($row.Type -like '*Q*') { $row.Type = $row.Type -replace 'N','' }
    }
#    "extControl $(showBytes(2))"
    $pos = $pos + 92
        
    #Res_Buffer skip
    $pos = $pos + $Content[$pos] + $Content[$pos+1] * 256 + 2
    #Rating skip
    $pos = $pos + $Content[$pos] + $Content[$pos+1] * 256 + 2
    #ShowID skip
    $pos = $pos + $Content[$pos] + $Content[$pos+1] * 256 + 2
    #ShowDescr skip
    $pos = $pos + $Content[$pos] + $Content[$pos+1] * 256 + 2
    #databuffer skip
    if ($dataFlag -eq 1) { $pos = $pos + $Content[$pos] + $Content[$pos+1] * 256 + 2 ; $dataFlag = 0 }
        
    $table.Rows.Add($row)
    
    
    $event++
} while ($pos -lt $Content.Length)

$table | ft -Property $table.Columns.Caption