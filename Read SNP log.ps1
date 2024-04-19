function Get-FileName($initialDirectory) {
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = �log files (*.log)| *.log�
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
}
function Get-Folder($initialDirectory) {
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
    $foldername.Description = "Select a folder with log files"
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
    if (($null -ne $f) -and ($null -ne $b)) {
        $msg = $msg -replace '\r$'
        Write-Host $msg -f $f -b $b
        if ($logfile) {$msg | Out-File $logfile -Append ascii}
    }
    else {Write-Host $msg}
}
function GD {Get-Date -Format "MM/dd/yyyy HH:mm:ss:00     "}
function Title {
    Write-Host "----------------------------------------------------------------------------" -f White -b Black
    if ($file) {Write-Host "Current Source file is '$file'" -f White -b Black}
    if ($file) {Write-Host "Logging the interpretation to '$logfile'" -f Gray -b Black}
    Write-Host "Press (SPACE) to pause/resume the script" -f DarkCyan -b Black
    Write-Host "Press (ESC) to exit" -f DarkCyan -b Black
    Write-Host "Press (F1) to get help" -f DarkCyan -b Black
    Write-Host "Press (O) to open the Select Folder dialog if you want to read log files from non-default folder" -f DarkCyan -b Black
    Write-Host "Press (S) to enable/disable the system messages (like 'Get System Settings') and the showing of message IDs" -f DarkCyan -b Black
    Write-Host "----------------------------------------------------------------------------" -f White -b Black
}

#$defaultFolder = 'C:\server\12.29.20.1\log\SNP1#3-SNPMC'
$defaultFolder = 'C:\server\log\'
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
        if (Test-Path $defaultFolder) {$newFile = (Get-ChildItem $defaultFolder -filter *.log -ea SilentlyContinue | Sort-Object -Property LastWriteTime | Select-Object -Last 1).FullName}
        #if (!$newFile) {$newFile = Get-FileName $defaultFolder}
        if ((-not $newfile) -and (-not $waitForO) -and ($defaultFolder)) {Write-Host "There are no log files in $(if ($init){"default"}else{"selected"}) folder '$defaultFolder'. Press <O> to select another folder." -f red -b Black; $waitForO = 1; $file = $null; $init = 0; Title}
        if (($newFile) -and ($newFile -ne $file)) {  # if new log file appears
            $file = $newFile
            $defaultFolder = $file -replace '^(.*\\).*','$1'
            $logfile = "C:\PS\logs\$($file -replace '^.*\\(.*)\.log','$1') $(Get-Date -Format 'yyyy-MM-dd HH-mm-ss').log"
            New-Item -Path $logfile -ItemType file -Force | Out-Null
            if ($init) {Title} else {Write-Host "Source log file has been switched to '$file'" -f White -b Black; Write-Host "Logging the interpretation to '$logfile'" -f White -b Black}
            $init = 0
        }
        if ($file) {$content = Get-Content $file -Tail 10 | Out-String} else {$content = ''}
        

        $regex = '(?s)(?<body>(?<time>\d\d:\d\d:\d\d\.\d\d-\d\d\d) (?<direction>.{3})\s*(?<command>\w*)\s(?<params>.*?)(?=\t)\s*(?<hex>.*?)(?<wtf>.))(?=\n)'
        [regex]::Matches($content,$regex) | ForEach-Object {
            $body = $_.groups['body'].value
            $time = $_.groups['time'].value
            $direction = $_.groups['direction'].value
            $command = $_.groups['command'].value
            $params = $_.groups['params'].value
            $hex = ($_.groups['hex'].value) ; $hex = $hex.Substring(0,$hex.Length - 1)
            $wtf = $_.groups['wtf'].value

            if ($KnownBodies -notcontains ([System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($body))))) {
                $KnownBodies.Add([System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($body)))) | Out-Null
                
                if ($direction -eq '- >') {
                    #Write-Text "$time ==> $command - $(if($target){"TargetState:$target "})$(if($categories){"Category:$($categories -join ',') "})$(if($source){"SourceID:$source "})$(if($showSystem){" ($id)"})" -b black -f green
                    switch ($command) {
                        'SUBSCRIPTION'      {$systemRequest=1; $f = 8; $b = 0; $t = 2}
                        'AUTO_STAT'         {$systemRequest=1; $f = 8; $b = 0; $t = 2}
                        'TX_START'          {$systemRequest=0; $f = 1; $b = 0; $t = 3}
                        'XPT_TAKE'          {$systemRequest=0; $f = 3; $b = 0; $t = 3}
                        'TX_TYPE'           {$systemRequest=0; $f = 5; $b = 0; $t = 3}
                        'TX_NEXT'           {$systemRequest=0; $f = 13; $b = 0; $t = 3}
                        'KEY_ENABLE'        {$systemRequest=0; $f = 10; $b = 0; $t = 2}
                        'LOGO_SELECT_KEY'   {$systemRequest=0; $f = 2; $b = 0; $t = 1}
                        'OVER_SELECT'       {$systemRequest=1; $f = 6; $b = 0; $t = 2}
                        default { Write-Text "$body" -f 12 -b 8 }
                    }
                    
                    if ($showSystem -or -not $systemRequest) {
                        #Write-Text "$time - > $command $params `t`t " -b $b -f $f
                        $tabs = "`t" * $t
                        Write-Host "$time - > $command $params$tabs$hex" -b $b -f $f -NoNewline
                        $wait = 1
                    }
                }

                elseif ($direction -eq '< -') {
                    if ($command -eq 'ACK') { $f = 2 ; $b = 0 }
                    elseif ($command -eq 'NAK') { $f = 4 ; $b = 0 }
                    elseif ( $command -eq 'AUTO_ENABLE' ) { $f = 8 ; $b = 0 }
                    
                    if ($wait) { Write-Host "$command $params" -f $f -b $b ; $wait = 0}
                    #elseif ( $showSystem ) { Write-Host ''}
                }

                else {Write-Text "`n$body" -f 12 -b 0} # unknown direction
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