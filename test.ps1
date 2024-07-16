function Get-FileName($initialDirectory) {
    [System.Reflection.Assembly]::LoadWithPartialName(“System.windows.forms”) | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = “log files (*.log)| *.log”
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
}
function Get-Folder($initialDirectory) {
    [System.Reflection.Assembly]::LoadWithPartialName(“System.windows.forms”) | Out-Null
    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
    $foldername.Description = "Select a folder with ICONX log files"
    $foldername.rootfolder = "MyComputer"
    $foldername.SelectedPath = $initialDirectory
    $caller = [System.Windows.Forms.NativeWindow]::new()
    $caller.AssignHandle([System.Diagnostics.Process]::GetCurrentProcess().MainWindowHandle)
    if (($foldername.ShowDialog($caller)) -eq [System.Windows.Forms.DialogResult]::OK.value__)
        {
            $out = $foldername.SelectedPath;
        }
    #Cleanup Disposabe Objects
    Get-Variable -ErrorAction SilentlyContinue -Scope 0  | Where-Object {($_.Value -is [System.IDisposable]) -and ($_.Name -notmatch "PS\s*")} | ForEach-Object {$_.Value.Dispose(); $_ | Clear-Variable -ErrorAction SilentlyContinue -PassThru | Remove-Variable -ErrorAction SilentlyContinue -Force;}
    return $out
}
function Write-Text ($msg, $f, $b) {
    if (($f -ne $null) -and ($b -ne $null)) {
        $msg = $msg -replace '\r$'
        Write-Host $msg -f $f -b $b
        #$msg | Out-File $logfile -Append ascii
    }
    else {Write-Host $msg}
}
function GD {Get-Date -Format "HH:mm:ss:00     "}
function Title {
    Write-Host "----------------------------------------------------------------------------" -f White -b Black
    if ($file) {Write-Host "Current Source ICONX file is '$file'" -f White -b Black}
    if ($file) {Write-Host "Logging the interpretation to '$logfile'" -f Gray -b Black}
    Write-Host "Press (SPACE) to pause/resume the script" -f DarkCyan -b Black
    Write-Host "Press (ESC) to exit" -f DarkCyan -b Black
    Write-Host "Press (F1) to get help" -f DarkCyan -b Black
    Write-Host "Press (O) to open Select Folder dialog if you want to read ICONX files from non-default folder" -f DarkCyan -b Black
    Write-Host "Press (S) to enable/disable system messages (like 'Get System Settings') and showing of message IDs" -f DarkCyan -b Black
    Write-Host "----------------------------------------------------------------------------" -f White -b Black
}

$defaultFolder = 'C:\server\log\IconStationX'
#$defaultFolder = 'C:\server\12.28.24.1M\log\IconStationX\' #########################################################################################################
#$defaultFolder = 'Z:\12.28.33.1M\log\IconStationX'

$KnownBodies = [System.Collections.ArrayList]@()
$md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
$utf8 = New-Object -TypeName System.Text.UTF8Encoding
$showSystem = 0
$init = 1

do {
    if (!$pause) {
        if ($defaultFolder) {$newFile = (Get-ChildItem $defaultFolder -filter IconStationX*.log -ea SilentlyContinue | sort -Property LastWriteTime | select -Last 1).FullName}
        #if (!$newFile) {$newFile = Get-FileName $defaultFolder}
        if ((!$newfile) -and (!$waitForO) -and ($defaultFolder)) {Write-Host "There are no ICONX log files in $(if ($init){"default"}else{"selected"}) folder '$defaultFolder'. Press <O> to select another folder." -f red -b Black; $waitForO = 1; $file = $null; $init = 0; Title}
        if (($newFile) -and ($newFile -ne $file)) {
            $file = $newFile
            $defaultFolder = $file -replace '^(.*\\).*','$1'
            $logfile = "C:\PS\logs\$($file -replace '^.*\\(.*)\.log','$1') $(Get-Date -Format 'yyyy-MM-dd HH-mm-ss').log"
            New-Item -Path $logfile -ItemType file -Force | Out-Null
            if ($init) {Title} else {Write-Host "Source ICONX file has been switched to '$file'" -f White -b Black; Write-Host "Logging the interpretation to '$logfile'" -f White -b Black}
            $init = 0
        }

        if ($file) {$content = Get-Content $file -Tail 1000 | Out-String} else {$content = ''}

        $regex = '(?s)(?<body>(?<time>\d\d:\d\d:\d\d:\d\d)(?<direction>\s|<|=|-).*?)((?=\n\r)|(?=\s\d\d:\d\d:\d\d:\d\d))'
        [regex]::Matches($content,$regex) | ForEach-Object {
            #$full = $_.groups['0'].value
            $time = $_.groups['time'].value
            $body = $_.groups['body'].value
            $direction = $_.groups['direction'].value

            if ($KnownBodies -notcontains ([System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($body))))) {
                $KnownBodies.Add([System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($body)))) | Out-Null
                
                if ($direction -eq ' ') {
                    $subRegex = '(?s)\d\d:\d\d:\d\d:\d\d\s(?<media>.*)'
                    [regex]::Matches($body,$subRegex) | % {$media = $_.groups['media'].value}
                    #if ($showSystem) {Write-Text "$time     $media" -f 13 -b 0}
                    Write-Text "$time     $media" -f 5 -b 0
                }
                if ($direction -eq '-') {
                    $subRegex = '(?s)\d\d:\d\d:\d\d:\d\d-DIAG- (?<media>.*)'
                    [regex]::Matches($body,$subRegex) | % {$media = $_.groups['media'].value}
                    if ($showSystem) {Write-Text "$time     $media" -f 8 -b 0}
                }

                $regexBody = '(?s)(?<subbody><\?xml.*?(<\w+-IconStation-(?<type>\w+)>).*?<\/\w+-\w+-\w+)'
                [regex]::Matches($body,$regexBody) | % {
                    $subbody = $_.groups['subbody'].value
                    if ($direction -ne ' ') {$type = $_.groups['type'].value} else {$type = ''}
        
                    if ($type -eq 'Request') {
                        $regexRequest = '(?s).*?<ID>\s*(?<id>.*?)\s*<\/ID>.*?<Command>\s*(?<command>.*?)\s*<\/Command>(?=.*?(<Layout>\s*(?<layout>.*?)\s*<\/Layout>))?(?=.*?(<Item>\s*(?<item>[\w\s]*?)\s*<\/Item>))?.*?(?=.*?(<LayerNumber>\s*(?<layer>.*?)\s*<\/LayerNumber>))?.*?(?=.*?(<RegionFile>\s*<(?<regionFile>.*?)>\s*<\/RegionFile>))?(?=.*?(<Name>\s*(?<name>.*?)\s*<\/Name>))?(?=.*?(<Text>\s*(?<text>.*?)\s*<\/Text>))?(?=.*?(<Salvo>\s*(?<salvo>.*?)\s*<\/Salvo>))?(?=.*?(<Path>\s*<(?<path>.*?)>\s*<\/Path>))?'
                        [regex]::Matches($subbody,$regexRequest) | % {
                            $id = $_.groups['id'].value
                            $command = $_.groups['command'].value
                            $item = $_.groups['item'].value
                            $layer = $_.groups['layer'].value
                            $layout = $_.groups['layout'].value
                            $regionFile = $_.groups['regionFile'].value
                            $name = $_.groups['name'].value
                            $text = $_.groups['text'].value
                            $salvo = $_.groups['salvo'].value
                            $path = $_.groups['path'].value
                        }
                        if (($command -eq 'get all items') -or ($command -eq 'get loaded layouts') -or ($command -eq 'get system settings') -or ($command -eq 'get all salvos') -or ($command -eq 'get all layouts')) {$systemRequest=1; $f=9; $b=0} else {$systemRequest=$systemResponse=0; $f=11; $b=9}
                        if (($showSystem) -or !($systemRequest)) {Write-Text "$time ==> $command$(if ($salvo) {" '$salvo'"})$(if ($item) {" '$item'"})$(if ($layer) {" on Layer $layer"})$(if ($layout) {" from Layout '$layout'"})$(if ($regionFile) {" to '$regionFile'"})$(if ($name) {": Change '$name'"})$(if ($text) {" to '$text'"})$(if ($path) {" '$path'"})$(if($showSystem){" ($id)"})" -f $f -b $b}
                    }

                    if ($type -eq 'Response') {
                        $regexResponse = '(?s)<Status>\s*(?<status>.*?)\s*<\/Status>\s*<RequestID>\s*(?<id>.*?)\s*<\/RequestID>\s*<RequestCommand>\s*(?<command>.*?)\s*<\/RequestCommand>(?=.*?(<Available>\s*(?<available>.*?)\s*<\/Available>))?'
                        [regex]::Matches($subbody,$regexResponse) | % {
                            $id = $_.groups['id'].value
                            $status = $_.groups['status'].value
                            $command = $_.groups['command'].value
                            $available = $_.groups['available'].value
                        }
                        if ($status -eq 'Request Executed Successfully') {$f = 2 ; $b = 0} else {$f = 12 ; $b = 0}
                        if (($command -eq 'get all items') -or ($command -eq 'get loaded layouts') -or ($command -eq 'get system settings') -or ($command -eq 'get all salvos') -or ($command -eq 'get all layouts')) {$systemResponse=1} else {$systemRequest=$systemResponse=0}
                        if (($showSystem) -or !($systemResponse)) {
                            if (!$available) {Write-Text "$time <== $status$(if($showSystem){" ($id)"})" -f $f -b $b}
                            elseif ($available -eq 'True') {Write-Text "$time <== $status`: Available$(if($showSystem){" ($id)"})" -f $f -b $b}
                            elseif ($available -eq 'False') {Write-Host "$time <== $status`:" -f $f -b $b -NoNewline; Write-Host " Not Available$(if($showSystem){" ($id)"})" -f 12 -b 0; "$time <== $status`: Not Available$(if($showSystem){" ($id)"})" | Out-File $logfile -Append ascii}
                        }
                    }

                    if ($type -eq 'Message') {
                        $f = 13
                        $b = 5
                        $regexMessage = '(?s)(?<mediabody>.*?<ID>\s*(?<id>.*?)\s*<\/ID>\s*(<Session>.*?<\/Session>\s*)?<(?<subtype>.*?)>.*?\/Inscriber-IconStation-Message)'
                        [regex]::Matches($subbody,$regexMessage) | % {
                            $id = $_.groups['id'].value
                            $subtype = $_.groups['subtype'].value
                            $mediabody = $_.groups['mediabody'].value
                            switch ($subtype) {
                                'RegionUpdateNotify' {
                                    $subRegex = '(?s)(?=<Layout>\s*(?<layout>.*?)\s*<\/Layout>).*?(?=<Region>\s*(?<region>.*?)\s*<\/Region>)'
                                    [regex]::Matches($mediabody,$subRegex) | % {$layout = $_.groups['layout'].value ; $region = $_.groups['region'].value}
                                    Write-Text "$time <== Region '$region' was updated on Layout '$layout'$(if($showSystem){" ($id)"})" -f $f -b $b
                                }
                                'PlayStatus' {
                                    $subRegex = '(?s)<ID>\s*(?<id>.*?)\s*<\/ID>(?=.*?<PlayStatus>\s*(?<status>.*?)\s*<\/PlayStatus>).*?(?=<Layout>\s*(?<layout>.*?)\s*<\/Layout>).*?(?=<Item>\s*(?<item>.*?)\s*<\/Item>).*?(?=<LayerNumber>\s*(?<layer>.*?)\s*<\/LayerNumber>)'
                                    [regex]::Matches($mediabody,$subRegex) | % {
                                        $id = $_.groups['id'].value ; $status = $_.groups['status'].value ; $layout = $_.groups['layout'].value ; $item = $_.groups['item'].value ;$layer = $_.groups['layer'].value
                                        Write-Text "$time <== $status the Item '$item' from Layout '$layout' on Layer $layer$(if($showSystem){" ($id)"})" -f $f -b $b
                                    }
                        
                                }
                                'SetupAck' {
                                    $subRegex = '(?s)\/SetupAll(?=.*?<ItemName>\s*(?<item>.*?)\s*<\/ItemName>)?(?=.*?<LayoutName>\s*(?<layout>.*?)\s*<\/LayoutName>)?'
                                    [regex]::Matches($mediabody,$subRegex) | % {$layout = $_.groups['layout'].value ; $item = $_.groups['item'].value}
                                    if ($layout) {Write-Text "$time <== SetupAck: all the Items from Layout '$layout' $(if($showSystem){"($id)"})" -f $f -b $b}
                                    elseif ($item) {Write-Text "$time <== SetupAck: the Item '$item'$(if($showSystem){" ($id)"})" -f $f -b $b}
                                    else {Write-Text "$mediabody" -f Yellow -b Black}
                                }
                                'LoadInProgress' {
                                    $subRegex = '(?s)\/ID(?=.*?<LayoutName>\s*(?<layout>.*?)\s*<\/LayoutName>)?'
                                    [regex]::Matches($mediabody,$subRegex) | % {$layout = $_.groups['layout'].value}
                                    Write-Text "$time <== $subtype`: Layout '$layout'$(if($showSystem){" ($id)"})" -f $f -b $b
                                }
                                'UnloadInProgress' {
                                    $subRegex = '(?s)\/ID(?=.*?<LayoutName>\s*(?<layout>.*?)\s*<\/LayoutName>)?'
                                    [regex]::Matches($mediabody,$subRegex) | % {$layout = $_.groups['layout'].value}
                                    Write-Text "$time <== $subtype`: Layout '$layout'$(if($showSystem){" ($id)"})" -f $f -b $b
                                }
                                'SalvoAddNotification' {
                                    $subRegex = '(?s)\/ID(?=.*?<LayoutName>\s*(?<layout>.*?)\s*<\/LayoutName>)?.*?(?=.*?<SalvoName>\s*(?<salvo>.*?)\s*<\/SalvoName>)?'
                                    [regex]::Matches($mediabody,$subRegex) | % {$layout = $_.groups['layout'].value; $salvo = $_.groups['salvo'].value}
                                    Write-Text "$time <== $subtype`: Layout '$layout'; Salvo '$salvo' added$(if($showSystem){" ($id)"})" -f $f -b $b
                                }
                                'SalvoDeleteNotification' {
                                    $subRegex = '(?s)\/ID(?=.*?<LayoutName>\s*(?<layout>.*?)\s*<\/LayoutName>)?.*?(?=.*?<SalvoName>\s*(?<salvo>.*?)\s*<\/SalvoName>)?'
                                    [regex]::Matches($mediabody,$subRegex) | % {$layout = $_.groups['layout'].value; $salvo = $_.groups['salvo'].value}
                                    Write-Text "$time <== $subtype`: Layout '$layout'; Salvo '$salvo' deleted$(if($showSystem){" ($id)"})" -f $f -b $b
                                }
                                'LayoutUpdateNotification' {
                                    $subRegex = '(?s)\/ID(?=.*?<LayoutName>\s*(?<layout>.*?)\s*<\/LayoutName>)?'
                                    [regex]::Matches($mediabody,$subRegex) | % {$layout = $_.groups['layout'].value}
                                    Write-Text "$time <== $subtype`: Layout '$layout' updated$(if($showSystem){" ($id)"})" -f $f -b $b
                                }
                                'LayoutDeleteNotification' {
                                    $subRegex = '(?s)\/ID(?=.*?<LayoutName>\s*(?<layout>.*?)\s*<\/LayoutName>)?'
                                    [regex]::Matches($mediabody,$subRegex) | % {$layout = $_.groups['layout'].value}
                                    Write-Text "$time <== $subtype`: Layout '$layout' deleted$(if($showSystem){" ($id)"})" -f $f -b $b
                                }
                                'RegionDeleteNotify' {
                                    $subRegex = '(?s)\/ID(?=.*?<Layout>\s*(?<layout>.*?)\s*<\/Layout>)?.*?(?=.*?<Region>\s*(?<region>.*?)\s*<\/Region>)?'
                                    [regex]::Matches($mediabody,$subRegex) | % {$layout = $_.groups['layout'].value; $region = $_.groups['region'].value}
                                    Write-Text "$time <== $subtype`: Layout '$layout'; Region '$region' deleted$(if($showSystem){" ($id)"})" -f $f -b $b
                                }
                                default {Write-Text "$mediabody" -f Red -b Black}
                            }
                        }
                    }
                    if ( ( -not $systemRequest ) -and ( -not $systemResponse ) ) { $body | Out-File $logfile -Append ascii }
                }
            }
        }
    }

    #looking for <Esc> or <R> or <Space> press
    if ($host.ui.RawUi.KeyAvailable) {
        $key=$host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown,IncludeKeyUp")
        $host.UI.RawUI.FlushInputBuffer()
        if ($key.keydown) {
            switch ($key.VirtualKeyCode) {
                <#C#> 67 {}
                <#O#> 79 {$waitForO = 0; $defaultFolder = Get-Folder 'C:\server\'; if (!$defaultFolder) {$waitForO = 1}}
                <#S#> 83 {if ($showSystem) {Write-Text "$(GD)System messages are disabled" -f Yellow -b Black; $showSystem = 0} else {Write-Text "$(GD)System messages are enabled" -f Yellow -b Black; $showSystem = 1}}
                <#Esc#> 27 {exit}
                <#Space#> 32 {if ($pause) {Write-Text "$(GD)Pause OFF" -f yellow -b black; $pause=0} else {Write-Text "$(GD)Pause ON" -f yellow -b black; $pause=1}}
                <#F1#> 112 {Title}
            } #end switch
        }
    } #end if
    #break
    sleep 1

} until ($key.VirtualKeyCode -eq 27)



