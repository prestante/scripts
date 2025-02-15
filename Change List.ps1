function Get-CRC32 {
	param(
		[Parameter(Mandatory = $False)]
		[Int]$InitialCRC = 0,
		[Parameter(Mandatory = $True)]
		[Byte[]]$Buffer
    )

	Add-Type -TypeDefinition @"
		using System;
		using System.Diagnostics;
		using System.Runtime.InteropServices;
		using System.Security.Principal;
	
		public static class CRC32
		{
			[DllImport("ntdll.dll")]
			public static extern UInt32 RtlComputeCrc32(
				UInt32 InitialCrc,
				Byte[] Buffer,
				Int32 Length);
		}
"@
	[CRC32]::RtlComputeCrc32($InitialCRC, $Buffer, $Buffer.Length)
}
function Get-FileName($initialDirectory) {
    [System.Reflection.Assembly]::LoadWithPartialName(“System.windows.forms”) | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = “lst files (*.lst)| *.lst”
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
} #end function Get-FileName
function showBytes ($numberOfBytes,$Color) {
    for ($i=$pos ; $i -lt ($pos+$numberOfBytes) ; $i++) {
        $byte = "{0:x2} " -f $Content[$i]
        if (!$color) {$color = 'white'}
        Write-Host $byte -NoNewline -fo $Color
    } ""
}
$enc = [system.Text.Encoding]::UTF8 #encoder for getting bytes from strings like this - $data1 = $enc.GetBytes($string1)

#reading .lst file into $Content byte array
$file = Get-FileName -initialDirectory 'C:\Lists\'
#$file = 'C:\Lists\!!!!.lst'
if (!$file) { exit }
#$Content = Get-Content $file -ReadCount 0 -Encoding Byte #reading file content into byte array
$Content = New-object -type System.Collections.ArrayList
(Get-Content $file -ReadCount 0 -Encoding Byte) | % {$Content.Add($_)} | Out-Null

#creating output .lst file
$outFile = 'C:\Lists\OutListResBuffer.lst'
#$outFile = $file
if (!(Test-Path $outFile)) {New-Item -Path $outFile -ItemType file -Force | Out-Null}

$days = ((Get-Date) - (Get-Date '01/01/1900')).Days #getting current date as number of days since Jan,1 1900

#$PriIDprefix = Read-Host "ID prefix (If you enter nothing, ID will not be replaced)"
#$SecIDprefix = 'SWTCH'
#$TitlePrefix = 'Title'

$CompileID = ""
$CompileSOM = ""
$Reconcile = ""
# $ReconcilePrefix = Read-Host "New Reconcile prefix"
$ABOX = ""
$ABOXSOM = ""
$BBOX = ""
$BBOXSOM = ""
# $newResBuffer = "ASDB:NoteContent=ss;ASSEG:NoteContent=ms;" # omg! wtf is this???

#setting starting position to 64 (skipping .lst file header)
$pos = 64
$event = 1
$PriEvent = 1
$SecEvent = 1

do {
<#
    #first 16 events will get different Reconciles
    switch ($event) { #
        1 {$ReconcilePrefix = "{0:d4}" -f ($event) ; $TitlePrefix = '4-Digit Reconcile'}
        2 {$ReconcilePrefix = "{0:d4}" -f ($event) ; $TitlePrefix = '4-Digit Reconcile'}
        3 {$ReconcilePrefix = "{0:d8}" -f ($event) ; $TitlePrefix = '8-Digit Reconcile'}
        4 {$ReconcilePrefix = "{0:d8}" -f ($event) ; $TitlePrefix = '8-Digit Reconcile'}
        5 {$ReconcilePrefix = 'Rccl' ; $TitlePrefix = '4-Char Reconcile'}
        6 {$ReconcilePrefix = 'Rccl' ; $TitlePrefix = '4-Char Reconcile'}
        7 {$ReconcilePrefix = 'Reconcil' ; $TitlePrefix = '8-Char Reconcile'}
        8 {$ReconcilePrefix = 'Reconcil' ; $TitlePrefix = '8-Char Reconcile'}
        9 {$ReconcilePrefix = "Rccl{0:d4}" -f ($event) ; $TitlePrefix = 'Mixed Reconcile CD'}
        10 {$ReconcilePrefix = "Rccl{0:d4}" -f ($event) ; $TitlePrefix = 'Mixed Reconcile CD'}
        11 {$ReconcilePrefix = "{0:d4}rccl" -f ($event) ; $TitlePrefix = 'Mixed Reconcile DC'}
        12 {$ReconcilePrefix = "{0:d4}rccl" -f ($event) ; $TitlePrefix = 'Mixed Reconcile DC'}
        13 {$ReconcilePrefix = "{0:dd}{0:MM}{0:yyyy}_{1}_{2}_{3:d7}" -f (Get-Date),(Get-Random 10),[char](65+(Get-Random 26)),(Get-Random 10000000) ; $TitlePrefix = 'Long Mixed Reconcile'}
        14 {$ReconcilePrefix = "{0:dd}{0:MM}{0:yyyy}_{1}_{2}_{3:d7}" -f (Get-Date),(Get-Random 10),[char](65+(Get-Random 26)),(Get-Random 10000000) ; $TitlePrefix = 'Long Mixed Reconcile'}
        15 {$ReconcilePrefix = '' ; $TitlePrefix = 'Empty Reconcile (0xFF)'}
        16 {$ReconcilePrefix = '' ; $TitlePrefix = 'Empty Reconcile (0xFF)'}
    }
#>
    #Event type - 2 bytes
    if (!$Content[$pos]) { $Primary = 1 } else { $Primary = 0 } #setting Primary flag
    if ($Content[$pos+1] -eq 1) { $dataFlag = 1 } #data with data sec event flag on
    $pos = $pos + 2 ; $pos = $pos + 8

    #Reconcile - 32 bytes
    if ($ReconcilePrefix -or $Reconcile) {
        Write-Host "Event $event Reconcile before $(showbytes -numberOfBytes 32 -Color Red)" -fo Gray
        $filler = [byte]0x20
        $Reconcile = if ($Reconcile) {$Reconcile} else {"$ReconcilePrefix{0:d4}" -f ($event)}
        if ($Reconcile.Length -gt 32) {$Reconcile = $Reconcile.Substring(0,32)} #truncate if longer than 32 chars
        for ($i=0; $i -lt $Reconcile.Length; $i++) {$content[$pos+$i] = [byte][char]$Reconcile[$i]} #writing Reconcile
        for ($i=$i; $i -lt 32; $i++) {$content[$pos+$i] = $filler} #writing filler bytes up to 32 bytes
        Write-Host "Event $event Reconcile after $(showbytes -numberOfBytes 32 -Color Green)" -fo White
    }
    $pos = $pos + 32 ; $pos = $pos + 3

    #OAT - 4 bytes
    #Write-Host "Event $event OAT before $(showbytes -numberOfBytes 4 -Color Red)" -fo Gray
    if ($Primary) {$time = "{0:HH}:{0:mm}:{0:ss};26"  -f (Get-Date).AddSeconds(60+$PriEvent*15).AddHours(4)}
    else {$time = "00:00:00:00"}
    $time -match '(\d\d).(\d\d).(\d\d).(\d\d)' | Out-Null
    for ($i=0; $i -lt 4; $i++) {$content[$pos+3-$i] = [byte]"0x$($Matches.($i+1))"}
    #Write-Host "Event $event OAT after $(showbytes -numberOfBytes 4 -Color Green)" -fo White
    $pos = $pos + 4

    #ID - 32 bytes
    if ($PriIDprefix) {
        if ($Primary) {$ID = "$PriIDprefix{0:d4}" -f $PriEvent} else {$ID = "$SecIDprefix{0:d1}" -f $SecEvent}
        if ($ID.Length -gt 32) {$ID = $ID.Substring(0,32)} #truncate if longer than 32 chars
        for ($i=0; $i -lt $ID.Length; $i++) {$content[$pos+$i] = [byte][char]$ID[$i]} #writing ID
        for ($i=$i; $i -lt 32; $i++) {$content[$pos+$i] = [byte]"0x20"} #writing filler bytes up to 32 bytes
    }
    #else {
    #    $filler = [byte]0xFF
    #    for ($i=0; $i -lt 32; $i++) {$content[$pos+$i] = $filler} #writing filler bytes up to 32 bytes
    #}
    $pos = $pos + 32

    #Title - 32 bytes
    if ($TitlePrefix) {
        $Title = "$TitlePrefix"#{0:d4}" -f $event
        if ($Title.Length -gt 32) {$Title = $Title.Substring(0,32)} #truncate if longer than 32 chars
        for ($i=0; $i -lt $Title.Length; $i++) {$content[$pos+$i] = [byte][char]$Title[$i]} #writing ID
        for ($i=$i; $i -lt 32; $i++) {$content[$pos+$i] = [byte]"0x20"} #writing filler bytes up to 32 bytes
    }
    #else {
    #    $filler = [byte]0xFF
    #    for ($i=0; $i -lt 32; $i++) {$content[$pos+$i] = $filler} #writing filler bytes up to 32 bytes
    #}
    $pos = $pos + 32

    #SOM - 4 bytes
#    $time = "03:00:40:00"
#    $time -match '(\d\d).(\d\d).(\d\d).(\d\d)' | Out-Null
#    for ($i=0; $i -lt 4; $i++) {$content[$pos+3-$i] = [byte]"0x$($Matches.($i+1))"}
    $pos = $pos + 4

    #DUR - 4 bytes
#    $time = "00:00:40:00"
#    $time -match '(\d\d).(\d\d).(\d\d).(\d\d)' | Out-Null
#    for ($i=0; $i -lt 4; $i++) {$content[$pos+3-$i] = [byte]"0x$($Matches.($i+1))"}
    $pos = $pos + 4 ; $pos = $pos + 1

    #Segment - 1 byte
    if ($Content[$pos] -eq [byte]0) {$Content[$pos] = [byte]255}
    $pos = $pos + 1 ; $pos = $pos + 7

    #sSP - 1 byte
    #[byte]"$event" #I don't remember wtf
    #$content[$pos] = [byte]"$event"
    $pos = $pos + 1

    #Air Date - 2 bytes
    $content[$pos] = [System.BitConverter]::GetBytes($days)[0]
    $content[$pos+1] = [System.BitConverter]::GetBytes($days)[1]
    $pos = $pos + 2

    #Event Control - 2 bytes
    $pos = $pos + 2 ; $pos = $pos + 4

    #CompileID - 32 bytes
    #if ($CompileID) {
        if ($CompileID) {$filler = [byte]0x20} else {$filler = [byte]0xFF}
        if ($CompileID.Length -gt 32) {$CompileID = $CompileID.Substring(0,32)} #truncate if longer than 32 chars
        for ($i=0; $i -lt $CompileID.Length; $i++) {$content[$pos+$i] = [byte][char]$CompileID[$i]} #writing CompileID
        for ($i=$i; $i -lt 32; $i++) {$content[$pos+$i] = $filler} #writing filler bytes up to 32 bytes
    #}
    $pos = $pos + 32
    
    #CompileSOM
    if ($CompileSOM) {
        $CompileSOM -match '(\d\d).(\d\d).(\d\d).(\d\d)' | Out-Null
        for ($i=0; $i -lt 4; $i++) {$content[$pos+3-$i] = [byte]"0x$($Matches.($i+1))"}
    }
    $pos = $pos + 4

    #ABOX
    if ($ABOX) {
        if ($ABOX) {$filler = [byte]0x20} else {$filler = [byte]0xFF}
        if ($ABOX.Length -gt 32) {$ABOX = $ABOX.Substring(0,32)} #truncate if longer than 32 chars
        for ($i=0; $i -lt $ABOX.Length; $i++) {$content[$pos+$i] = [byte][char]$ABOX[$i]} #writing ABOX
        for ($i=$i; $i -lt 32; $i++) {$content[$pos+$i] = $filler} #writing filler bytes up to 32 bytes
    }
    $pos = $pos + 32

    #ABOXSOM
    if ($ABOXSOM) {
        $ABOXSOM -match '(\d\d).(\d\d).(\d\d).(\d\d)' | Out-Null
        for ($i=0; $i -lt 4; $i++) {$content[$pos+3-$i] = [byte]"0x$($Matches.($i+1))"}
    }
    $pos = $pos + 4

    #BBOX - 32 bytes
    if ($BBOX) {
        if ($BBOX) {$filler = [byte]0x20} else {$filler = [byte]0xFF}
        if ($BBOX.Length -gt 32) {$BBOX = $BBOX.Substring(0,32)} #truncate if longer than 32 chars
        for ($i=0; $i -lt $BBOX.Length; $i++) {$content[$pos+$i] = [byte][char]$BBOX[$i]} #writing BBOX
        for ($i=$i; $i -lt 32; $i++) {$content[$pos+$i] = $filler} #writing filler bytes up to 32 bytes
    }
    $pos = $pos + 32
    
    #BBOXSOM
    if ($BBOXSOM) {
        $BBOXSOM -match '(\d\d).(\d\d).(\d\d).(\d\d)' | Out-Null
        for ($i=0; $i -lt 4; $i++) {$content[$pos+3-$i] = [byte]"0x$($Matches.($i+1))"}
    }
    $pos = $pos + 4
    $pos = $pos + 3

     
    #ExtControl - 2 bytes
    $pos = $pos + 2 ; $pos = $pos + 90

    #Res_Buffer skip
    #$pos = $pos + $Content[$pos] + $Content[$pos+1] * 256 + 2
    $RBL = [int]($Content[$pos] + $Content[$pos+1] * 256) #ResBuffer Length
    $pos += 2
    if ($RBL) {$oldResBuffer = [System.Text.Encoding]::Default.GetString($Content[$pos..($pos+$RBL-1)]) -replace '(^\s+|\s+$)',''} #ResBuffer content
    if ($RBL) {"OldResBuffer $(showBytes($RBL))"}
    if ($newResBuffer -ne $null) {
        $Content.RemoveRange($pos,$RBL) #cut old ResBuffer
        $newRBL = [int]$newResBuffer.Length
        $Content[$pos-2] = [byte]($newRBL % 256) #writing new ResBuffer size low byte
        $Content[$pos-1] = [byte]([math]::Floor($newRBL / 256)) #writing new ResBuffer size high byte
        $i = 0
        $enc.GetBytes($newResBuffer) | % {$Content.Insert(($pos+$i++),([byte]$_))}
        "NewResBuffer $(showBytes($newRBL))"
        $pos += $newRBL
    } else {$pos += $RBL}

    #Rating skip
    #$pos = $pos + $Content[$pos] + $Content[$pos+1] * 256 + 2
    #$newRating = "qwe"
    #$newRating = $null #in case if $newRating is $null, the Rating will not be touched
    $SRL = [int]($Content[$pos] + $Content[$pos+1] * 256) #Rating_Buffer Length
    $pos += 2
    if ($SRL) {$oldRating = [System.Text.Encoding]::Default.GetString($Content[$pos..($pos+$SRL-1)]) -replace '(^\s+|\s+$)',''} #Rating content
    #if ($SRL) {"OldRating $(showBytes($SRL))"}
    if ($newRating -ne $null) {
        $Content.RemoveRange($pos,$SRL) #cut old Rating
        $newSRL = [int]$newRating.Length
        $Content[$pos-2] = [byte]($newSRL % 256) #writing new Rating Buffer size low byte
        $Content[$pos-1] = [byte]([math]::Floor($newSRL / 256)) #writing new Rating Buffer size high byte
        $i = 0
        $enc.GetBytes($newRating) | % {$Content.Insert(($pos+$i++),([byte]$_))}
        $pos += $newSRL
    } else {$pos += $SRL}

    #ShowID skip
    #$pos = $pos + $Content[$pos] + $Content[$pos+1] * 256 + 2
    #$newShowID = "asd"
    #$newShowID = $null #in case if $newShowID is $null, the ShowID will not be touched
    $SIL = [int]($Content[$pos] + $Content[$pos+1] * 256) #ShowID_Buffer Length
    $pos += 2
    if ($SIL) {$oldShowID = [System.Text.Encoding]::Default.GetString($Content[$pos..($pos+$SIL-1)]) -replace '(^\s+|\s+$)',''} #ShowID content
    #if ($SIL) {"OldShowID $(showBytes($SIL))"}
    if ($newShowID -ne $null) {
        $Content.RemoveRange($pos,$SIL) #cut old ShowID
        $newSIL = [int]$newShowID.Length
        $Content[$pos-2] = [byte]($newSIL % 256) #writing new Show ID Buffer size low byte
        $Content[$pos-1] = [byte]([math]::Floor($newSIL / 256)) #writing new Show ID Buffer size high byte
        $i = 0
        $enc.GetBytes($newShowID) | % {$Content.Insert(($pos+$i++),([byte]$_))}
        $pos += $newSIL
    } else {$pos += $SIL}
    
    #ShowDescr skip
    #$pos = $pos + $Content[$pos] + $Content[$pos+1] * 256 + 2
    #$newShowDescr = "zxc"
    #$newShowDescr = $null #in case if $newShowDescr is $null, the ShowDescr will not be touched
    $SDL = [int]($Content[$pos] + $Content[$pos+1] * 256) #ShowDescription_Buffer Length
    $pos += 2
    if ($SDL) {$oldShowDescr = [System.Text.Encoding]::Default.GetString($Content[$pos..($pos+$SDL-1)]) -replace '(^\s+|\s+$)',''} #ShowDescr content
    #if ($SDL) {"OldShowDescr $(showBytes($SDL))"}
    if ($newShowDescr -ne $null) {
        $Content.RemoveRange($pos,$SDL) #cut old ShowDescr
        $newSDL = [int]$newShowDescr.Length
        $Content[$pos-2] = [byte]($newSDL % 256) #writing new Show Description Buffer size low byte
        $Content[$pos-1] = [byte]([math]::Floor($newSDL / 256)) #writing new Show Description Buffer size high byte
        $i = 0
        $enc.GetBytes($newShowDescr) | % {$Content.Insert(($pos+$i++),([byte]$_))}
        $pos += $newSDL
    } else {$pos += $SDL}
    
    #databuffer skip
    if ($dataFlag -eq 1) { $pos = $pos + $Content[$pos] + $Content[$pos+1] * 256 + 2 ; $dataFlag = 0 }

    $event++
    if ($Primary) {$PriEvent++} else {$SecEvent++}
} while ($pos -lt $Content.Count)

#Import-Module -Name 'C:\PS\scripts\get-crc32.ps1' #loading function from another .ps1
#Import-Module -Name '\\fs\change\galkovsky.a\scripts\get-crc32.ps1' #loading function from another .ps1
$intResult = Get-CRC32 -Buffer $content[64..($Content.Count-1)] #calculating CRC32 int32 value
$hexResult = "{0:x8}" -f $intResult #converting CRC32 int32 to 4 bytes (8 heximals)
$hexResult -match '(..)(..)(..)(..)' | Out-Null #dividing CRC32 for 4 separate bytes and placing them into auto $Matches variable

$Content[60] = [Byte]"0x$($Matches.4)" #writing each CRC32 byte into corresponding checksum byte of .lst file
$Content[61] = [Byte]"0x$($Matches.3)"
$Content[62] = [Byte]"0x$($Matches.2)"
$Content[63] = [Byte]"0x$($Matches.1)"

$Content | Set-Content $outFile -Encoding Byte #replacing original file with resulting (changed) bytes

Write-Host "Done" -fo Green -ba Black
Start-Sleep 1
