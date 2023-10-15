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
        $msg | Out-File $logfile -Append ascii
    }
    else {Write-Host $msg}
}
function GD {Get-Date -Format "HH:mm:ss:00     "}
function Title {
    Write-Host "----------------------------------------------------------------------------" -f White -b Black
    if ($file) {Write-Host "Current Source IS750 file is '$file'" -f White -b Black}
    if ($file) {Write-Host "Logging the interpretation to '$logfile'" -f Gray -b Black}
    Write-Host "Press (SPACE) to pause/resume the script" -f DarkCyan -b Black
    Write-Host "Press (ESC) to exit" -f DarkCyan -b Black
    Write-Host "Press (F1) to get help" -f DarkCyan -b Black
    Write-Host "Press (O) to open the Select Folder dialog if you want to read IS750 files from non-default folder" -f DarkCyan -b Black
    Write-Host "Press (S) to enable/disable the system messages (like 'Get System Settings') and the showing of message IDs" -f DarkCyan -b Black
    Write-Host "Press (A) to show all Alarms" -f DarkCyan -b Black
    Write-Host "----------------------------------------------------------------------------" -f White -b Black
}

$defaultFolder = 'C:\config\log'
$defaultFolder = 'C:\config\12.28.17.0M\log\' #########################################################################################################
$KnownBodies = [System.Collections.ArrayList]@()
$alarms = [System.Collections.ArrayList]@()
$md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
$utf8 = New-Object -TypeName System.Text.UTF8Encoding
$showSystem = 0
$init = 1
$firstAlarm = 1

do {
    if (!$pause) {
        if ($defaultFolder) {$newFile = (Get-ChildItem $defaultFolder -filter IS750*.log -ea SilentlyContinue | sort -Property LastWriteTime | select -Last 1).FullName}
        #if (!$newFile) {$newFile = Get-FileName $defaultFolder}
        if ((!$newfile) -and (!$waitForO) -and ($defaultFolder)) {Write-Host "There are no ICONX log files in $(if ($init){"default"}else{"selected"}) folder '$defaultFolder'. Press <O> to select another folder." -f red -b Black; $waitForO = 1; $file = $null; $init = 0}
        if (($newFile) -and ($newFile -ne $file)) {
            $file = $newFile
            $defaultFolder = $file -replace '^(.*\\).*','$1'
            $logfile = "C:\PS\logs\$($file -replace '^.*\\(IS750 - Channel \d{1,2}).*?\.log','$1 -') $(Get-Date -Format 'yyyy-MM-dd HH-mm-ss').log"
            New-Item -Path $logfile -ItemType file -Force | Out-Null
            if ($init) {Title} else {Write-Host "Source IS750 file has been switched to '$file'" -f White -b Black; Write-Host "Logging the interpretation to '$logfile'" -f White -b Black}
            $init = 0
            $firstAlarm = 1
            $KnownBodies = [System.Collections.ArrayList]@()
            $alarms = [System.Collections.ArrayList]@()
        }

        if ($file) {$content = Get-Content $file -Tail 50 -Encoding Unknown| Out-String} else {$content = ''}

        $regex = '(?s)(?<body>(?<time>\d\d:\d\d:\d\d.\d\d)--(?<id>\d+) (?<direction><R|<-|->|S>).*?)(?=\n)'
        [regex]::Matches($content,$regex) | % {
            $body = $_.groups['body'].value
            $time = $_.groups['time'].value
            $id = $_.groups['id'].value
            $direction = $_.groups['direction'].value

            #$body
            if ($KnownBodies -notcontains ([System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($body))))) {
                $KnownBodies.Add([System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($body)))) | Out-Null
                if ($direction -match '>') {$f=11;$b=9} else {$f=10;$b=2}
                if (($body -match '-> 05 \d\d') -or ($body -match '-> 06 \d\d')) {
                    if (!$firstAlarm) {
                        #$f=15;$b=9
                        $oldstx = $stx
                        $stx = $Matches[0] -replace '-> 0\d '
                        if ($stx -eq $oldstx) {$alarms += [PSCustomObject]@{time=$time; id=$id}; Write-Text "A L A R M" -f 12 -b 0}
                    } else {$firstAlarm = 0}
                }
                if ($body -notmatch 'Enquire System Status') {
                    if ($body -notmatch '> Cut ') {
                        if ($body -notmatch 'ACK\d') {
                            Write-Text "$body" -f $f -b $b
                            $counter++; if ($counter%30 -eq 0) {Write-Host "Alarms: $($alarms.count)"}
                        }
                    }
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
                <#A#> 65 {Write-Host "Showing all Alarms ($($alarms.count)):"; $alarms | ft -AutoSize}
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



