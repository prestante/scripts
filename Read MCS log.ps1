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
        if ($logfile) {$msg | Out-File $logfile -Append ascii}
    }
    else {Write-Host $msg}
}
function GD {Get-Date -Format "MM/dd/yyyy HH:mm:ss:00     "}
function Title {
    Write-Host "----------------------------------------------------------------------------" -f White -b Black
    if ($file) {Write-Host "Current Source ICONX file is '$file'" -f White -b Black}
    if ($file) {Write-Host "Logging the interpretation to '$logfile'" -f Gray -b Black}
    Write-Host "Press (SPACE) to pause/resume the script" -f DarkCyan -b Black
    Write-Host "Press (ESC) to exit" -f DarkCyan -b Black
    Write-Host "Press (F1) to get help" -f DarkCyan -b Black
    Write-Host "Press (O) to open the Select Folder dialog if you want to read ICONX files from non-default folder" -f DarkCyan -b Black
    Write-Host "Press (S) to enable/disable the system messages (like 'Get System Settings') and the showing of message IDs" -f DarkCyan -b Black
    Write-Host "----------------------------------------------------------------------------" -f White -b Black
}

$defaultFolder = 'C:\server\log\NGCMCSwitcher'
$KnownBodies = [System.Collections.ArrayList]@()
$md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
$utf8 = New-Object -TypeName System.Text.UTF8Encoding
$showSystem = 1
$pause = 0
$init = 1
$j = 0
$kk=0

do {
    $time1 = Get-Date
    if (!$pause) {
        if ($defaultFolder) {$newFile = (Get-ChildItem $defaultFolder -filter NGCMCSwitcher*.log -ea SilentlyContinue | sort -Property LastWriteTime | select -Last 1).FullName}
        #if (!$newFile) {$newFile = Get-FileName $defaultFolder}
        if ((!$newfile) -and (!$waitForO) -and ($defaultFolder)) {Write-Host "There are no MCS log files in $(if ($init){"default"}else{"selected"}) folder '$defaultFolder'. Press <O> to select another folder." -f red -b Black; $waitForO = 1; $file = $null; $init = 0; Title}
        if (($newFile) -and ($newFile -ne $file)) {
            $file = $newFile
            $defaultFolder = $file -replace '^(.*\\).*','$1'
            $logfile = "C:\PS\logs\$($file -replace '^.*\\(.*)\.log','$1') $(Get-Date -Format 'yyyy-MM-dd HH-mm-ss').log"
            New-Item -Path $logfile -ItemType file -Force | Out-Null
            if ($init) {Title} else {Write-Host "Source MCS file has been switched to '$file'" -f White -b Black; Write-Host "Logging the interpretation to '$logfile'" -f White -b Black}
            $init = 0
        }
        if ($file) {$content = Get-Content $file -Tail 1000 | Out-String} else {$content = ''}
        

        $regex = '(?s)(?<body>(?<time>\d\d\/\d\d\/\d\d\d\d \d\d:\d\d:\d\d:\d\d)  .*?>)\W*?(?=(\d\d\/\d\d\/\d\d\d\d \d\d:\d\d:\d\d:\d\d)|\z)' #body without spaces
        [regex]::Matches($content,$regex) | % {
            $body = $_.groups['body'].value
            $time = $_.groups['time'].value

            if ($KnownBodies -notcontains ([System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($body))))) {
                $KnownBodies.Add([System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($body)))) | Out-Null
                
                #try {$xml = [xml]([regex]::Match($body,'(?s)(?<=\?>)\s*(.*?)\s*(?=\z)')).Value} catch {$xml = $Null}
                $xml = [xml]([regex]::Match($body,'(?s)(?<=\?>)\s*(.*?)\s*(?=\z)')).Value

                if ($xml.MCSMessage.MCSRequest) {
                    #$rightRegex = '(?s).*?<MessageID>\s*(?<id>.*?)\s*<\/MessageID>.*?<CommandID>\s*(?<command>.*?)\s*<\/CommandID>(?=.*?<TargetState>\s*(?<target>.*?)\s*<\/TargetState>)?(?=.*?<Category>\s*(?<category>.*?)\s*<\/Category>)?(?=.*?<InstanceID>\s*(?<instance>.*?)\s*<\/InstanceID>)?(?=.*?<SourceID>\s*(?<source>.*?)\s*<\/SourceID>)?'
                    $id = $xml.MCSMessage.MCSRequest.MessageID -replace '^\s+|\s+$'
                    $command = $xml.MCSMessage.MCSRequest.Command.CommandID -replace '^\s+|\s+$'
                    $categories = $xml.GetElementsByTagName('Category').'#text' -replace '^\s+|\s+$'                    $target = $xml.GetElementsByTagName('TargetState').'#text' -replace '^\s+|\s+$'                    $instance = if (($xml.GetElementsByTagName('InstanceID').'#text').count -eq 1) {$xml.GetElementsByTagName('InstanceID').'#text' -replace '^\s+|\s+$'} else {''}
                    $source = $xml.GetElementsByTagName('SourceID').'#text' -replace '^\s+|\s+$'                    #Write-Text "$time ==> $command - $(if($target){"TargetState:$target "})$(if($categories){"Category:$($categories -join ',') "})$(if($source){"SourceID:$source "})$(if($showSystem){" ($id)"})" -b black -f green                    #if ($command -eq 'MCSStartTransition') {$body} #debug
                    switch ($command) {
                        'MCSGetStatus' {$systemRequest=1; $f = 9; $b = 0}
                        'MCSSetTransition' {$systemRequest=0; $f = 11; $b = 9}
                        'MCSStartTransition' {$systemRequest=0; $f = 10; $b = 2}
                        'MCSInitOwnership' {$systemRequest=0; $f = 5; $b = 0}
                        'MCSInitConnect' {$systemRequest=0; $f = 5; $b = 0}
                        'MCSGetPersonality' {$systemRequest=0; $f = 5; $b = 0}
                        default {Write-Text "$body" -f 12 -b 0}
                    }
                    
                    if (($showSystem) -or !($systemRequest)) {
                        #if ($category -ne 'AudioMixer') {
                            Write-Text "$time ==> $command - $(if($target){"TargetState:$target "})$(if($categories){"Category:$($categories -join ',') "})$(if($source){"SourceID:$source "})$(if($showSystem){" ($id)"})" -b $b -f $f
                            $waitID = $id
                        #}
                    }
                }

                elseif ($xml.MCSMessage.MCSResponse) {
                    #$leftRegex = '(?s).*?<MessageID>\s*(?<id>.*?)\s*<\/MessageID>.*?<CommandID>\s*(?<command>.*?)\s*<\/CommandID>.*?<RequestStatus>(?<status>.*?)<\/RequestStatus>'
                    $id = $xml.MCSMessage.MCSResponse.MessageID -replace '^\s+|\s+$'
                    $command = $xml.MCSMessage.MCSResponse.CommandID -replace '^\s+|\s+$'
                    $status = $xml.MCSMessage.MCSResponse.RequestStatus -replace '^\s+|\s+$'                    #if ($command -eq 'MCSStartTransition') {$body} #debug
                    if ($status -eq 'OK') {$f = 2 ; $b = 0} else {$f = 12 ; $b = 0}
                    if ($command -eq 'MCSGetStatus') {$systemResponse=1} else {$systemResponse=0}
                    if ((($showSystem) -or !($systemResponse)) -and ($id -eq $waitID)) {
                        Write-Text "$time <== $command : $status$(if($showSystem){" ($id)"})" -f $f -b $b
                        $waitID = $Null
                    }
                }
                else {Write-Text "$body" -f 12 -b 0}
            } # if ($KnownBodies -notcontains this body
        }
    
        $timeSpent = (Get-Date) - $time1
        if ($timeSpent.TotalMilliseconds -lt 1000) {sleep -Milliseconds (1000 - $timeSpent.TotalMilliseconds)}
        #Write-Host ([math]::Round(((Get-Date) - $time1).TotalMilliseconds)) -f 10 -b 2
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
    #sleep 1
} until ($key.VirtualKeyCode -eq 27)
#$content | Out-File c:\ps\content.log -Encoding ascii