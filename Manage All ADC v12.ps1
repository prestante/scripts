$buildsFolder = '\\wtlnas5.wtldev.net\Public\Releases\ADC\ADC1000\QATEST'

# checking network path
Write-Host "Please wait. Checking network path..." -BackgroundColor Black -ForegroundColor Yellow
if (!(Test-Path $buildsFolder)) {
    Write-Host "Cannot access $buildsFolder." -ba Black -fo Red
    if ($buildsFolder -match '\\\\fs') {
        Write-Host "Trying to bypass DNS..." -fo Yellow -ba Black
        $buildsFolder = $buildsFolder -replace '\\fs\\','\192.168.12.3\'
        if (!(Test-Path $buildsFolder)) {
            Write-Host "Cannot access $buildsFolder." -ba Black -fo Red
            Write-Host "Please correct the path or fix your network." -ba Black -fo Red
            Read-Host}
    } else {Write-Host "Please correct the path or fix your network." -ba Black -fo Red ; Read-Host}
}

function get-ADC ($message) {
    Write-Host "$message" -BackgroundColor Black -ForegroundColor Yellow
    #get all software installed in system
    [string[]]$regKeyApplications = 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
    [psobject[]]$regKeyApplication = @()
    ForEach ($regKey in $regKeyApplications) {
        If (Test-Path -LiteralPath $regKey -ErrorAction 'SilentlyContinue' -ErrorVariable '+ErrorUninstallKeyPath') {
            [psobject[]]$UninstallKeyApps = Get-ChildItem -LiteralPath $regKey -ErrorAction 'SilentlyContinue' -ErrorVariable '+ErrorUninstallKeyPath'
            ForEach ($UninstallKeyApp in $UninstallKeyApps) {
                Try {
                    [psobject]$regKeyApplicationProps = Get-ItemProperty -LiteralPath $UninstallKeyApp.PSPath -ErrorAction 'Stop'
                        
                    If ($regKeyApplicationProps.DisplayName) { 
                        [psobject[]]$regKeyApplication += $regKeyApplicationProps                         
                    }
                }
                Catch{
                    Write-Host "Unable to enumerate properties from registry key path [$($UninstallKeyApp.PSPath)]."
                    Continue
                }
            }
        }
    }
    #adding last launch date member
    $regKeyApplication | Where{($_.displayname -match 'ADC.*air') -or ($_.displayname -match 'ADC.*media') -or ($_.displayname -match 'ADC.*config') -or ($_.displayname -match 'ADC.*server')} | %{
        $launchDate = if (Test-Path ($_.installLocation + '\NETWORK.INI')) {"{0:yyyyMMdd}" -f ((Get-Item ($_.InstallLocation + '\NETWORK.INI')).LastWriteTime)}
                    elseif (Test-Path $_.installLocation) {"{0:yyyyMMdd}" -f ((Get-Item ($_.InstallLocation)).LastWriteTime)}
                    else {'n/a'}
        Add-Member -InputObject $_ -MemberType NoteProperty -Force -Name LastLaunch -Value $launchDate
    } | Out-Null
    #adding calculated size member
    $totalSize = 0
    $regKeyApplication | Where{($_.displayname -match 'ADC.*air') -or ($_.displayname -match 'ADC.*media') -or ($_.displayname -match 'ADC.*config') -or ($_.displayname -match 'ADC.*server')} | %{
        $size1 = [Math]::Round((Get-ChildItem -Recurse $_.InstallLocation | Measure-Object Length -Sum -ErrorAction SilentlyContinue).Sum / 1MB) 
        $size2 = [Math]::Round((Get-ChildItem -Recurse ("C:\Program Files (x86)\InstallShield Installation Information\"+$_.ProductGuid) | Measure-Object Length -Sum -ErrorAction SilentlyContinue).Sum / 1MB) 
        $size = $size1 + $size2
        $totalSize += $size
        Add-Member -InputObject $_ -MemberType NoteProperty -Force -Name Size -Value $size
    }

    #filter ADC v12 software from all software
    [psobject[]]$AllAC = $regKeyApplication | where {$_.displayname -match 'ADC.*air'} | sort -Property displayversion
    [psobject[]]$AllMC = $regKeyApplication | where {$_.displayname -match 'ADC.*media'} | sort -Property displayversion
    [psobject[]]$AllCT = $regKeyApplication | where {$_.displayname -match 'ADC.*config'} | sort -Property displayversion
    [psobject[]]$AllDS = $regKeyApplication | where {$_.displayname -match 'ADC.*server'} | sort -Property displayversion
    [psobject[]]$All = $regKeyApplication | where {($_.displayname -match 'ADC.*air') -or ($_.displayname -match 'ADC.*media') -or ($_.displayname -match 'ADC.*config') -or ($_.displayname -match 'ADC.*server')} | sort -Property displayversion

    $AllACVersions = $AllAC.displayversion
    $AllACBranches = $AllAC.displayversion -replace '(^\d+\.\d+).*','$1' | select -Unique
    $lastACinEachBranch = foreach ($branch in $AllACBranches) {
        $max = ($AllACVersions.Where({$_ -match "$branch\.\d+\..+"}) -replace '\d+\.\d+\.(\d+).+','$1' | %{[int]$_} | sort | Measure-Object -Maximum).Maximum
        $allACVersions.Where({$_ -match "$branch\.$max.+"})
    }
    [psobject[]]$AllACexceptLast = $AllAC.Where({$_.displayversion -notmatch ($lastACinEachBranch -join '|')})

    $AllMCVersions = $AllMC.displayversion
    $AllMCBranches = $AllMC.displayversion -replace '(^\d+\.\d+).*','$1' | select -Unique
    $lastMCinEachBranch = foreach ($branch in $AllMCBranches) {
        $max = ($AllMCVersions.Where({$_ -match "$branch\.\d+\..+"}) -replace '\d+\.\d+\.(\d+).+','$1' | %{[int]$_} | sort | Measure-Object -Maximum).Maximum
        $allMCVersions.Where({$_ -match "$branch\.$max.+"})
    }
    [psobject[]]$AllMCexceptLast = $AllMC.Where({$_.displayversion -notmatch ($lastMCinEachBranch -join '|')})

    $AllCTVersions = $AllCT.displayversion
    $AllCTBranches = $AllCT.displayversion -replace '(^\d+\.\d+).*','$1' | select -Unique
    $lastCTinEachBranch = foreach ($branch in $AllCTBranches) {
        $max = ($AllCTVersions.Where({$_ -match "$branch\.\d+\..+"}) -replace '\d+\.\d+\.(\d+).+','$1' | %{[int]$_} | sort | Measure-Object -Maximum).Maximum
        $allCTVersions.Where({$_ -match "$branch\.$max.+"})
    }
    [psobject[]]$AllCTexceptLast = $AllCT.Where({$_.displayversion -notmatch ($lastCTinEachBranch -join '|')})

    $AllDSVersions = $AllDS.displayversion
    $AllDSBranches = $AllDS.displayversion -replace '(^\d+\.\d+).*','$1' | select -Unique
    $lastDSinEachBranch = foreach ($branch in $AllDSBranches) {
        $max = ($AllDSVersions.Where({$_ -match "$branch\.\d+\..+"}) -replace '\d+\.\d+\.(\d+).+','$1' | %{[int]$_} | sort | Measure-Object -Maximum).Maximum
        $allDSVersions.Where({$_ -match "$branch\.$max.+"})
    }
    [psobject[]]$AllDSexceptLast = $AllDS.Where({$_.displayversion -notmatch ($lastDSinEachBranch -join '|')})

    [psobject[]]$AllADCexceptLast = $AllACexceptLast + $AllMCexceptLast + $AllCTexceptLast + $AllDSexceptLast

    Write-Host "$($All.Count) ADC v12 apps were found in the system. Their total size is $totalSize MB." -BackgroundColor Black -ForegroundColor Green
    return @{All = $All ; AllADCexceptLast = $AllADCexceptLast ; totalSize = $totalSize}
} #end function get-ADC
function get-selectedInstallers ($build,$app) { #get AC,MC,DS,CT installers for selected build
    if ($build) {
        $buildFolder = Get-ChildItem $Global:buildsFolder | where {$_.Name -match $build} | select -First 1
        $standardFolder = 
            if (Test-Path ($buildFolder.FullName +'\Standard\')) {$buildFolder.FullName +'\Standard\'}
            else {$buildFolder.FullName}
        if ($standardFolder){ 
            $ACinstaller = Get-ChildItem ($standardFolder) AIRCLIENT*exe
            $MCinstaller = Get-ChildItem ($standardFolder) MEDIACLIENT*exe
            $DSinstaller = Get-ChildItem ($standardFolder) SERVER_QATEST*exe
            $CTinstaller = Get-ChildItem ($standardFolder) CONFIG*exe
            return @{ACInstaller=$ACinstaller;MCinstaller=$MCinstaller;DSinstaller=$DSinstaller;CTinstaller=$CTinstaller}}
        else {Write-Host "There is no folder $standardFolder" -ba Black -fo Red}
    }
    if ($app) {
        $build = $app -replace '^\w\w\s' -replace '^4','12'
        $buildFolder = Get-ChildItem $Global:buildsFolder | where {$_.Name -match $build} | select -First 1
        $standardFolder = 
            if (Test-Path ($buildFolder.FullName +'\Standard\')) {$buildFolder.FullName +'\Standard\'}
            else {$buildFolder.FullName}
        if ($standardFolder) { 
            if ($app -match 'AC') {
                $app = $app -replace '^(\w\w)\s(4|12)(.*)$','$1 4$3'
                $ACinstaller = Get-ChildItem ($standardFolder) AIRCLIENT*exe
                if ($ACinstaller){return @{ACInstaller=$ACinstaller}}
                else {Write-Host "There is no $app installer in folder $standardFolder" -ba Black -fo Red}}
            if ($app -match 'MC') {
                $app = $app -replace '^(\w\w)\s(4|12)(.*)$','$1 4$3'
                $MCinstaller = Get-ChildItem ($standardFolder) MEDIACLIENT*exe
                if ($MCinstaller){return @{MCInstaller=$MCinstaller}}
                else {Write-Host "There is no $app installer in folder $standardFolder" -ba Black -fo Red}}
            if ($app -match 'DS') {
                $app = $app -replace '^(\w\w)\s(4|12)(.*)$','$1 12$3'
                $DSinstaller = Get-ChildItem ($standardFolder) SERVER_QATEST*exe
                if ($DSinstaller){return @{DSInstaller=$DSinstaller}}
                else {Write-Host "There is no $app installer in folder $standardFolder" -ba Black -fo Red}}
            if ($app -match 'CT') {
                $app = $app -replace '^(\w\w)\s(4|12)(.*)$','$1 12$3'
                $CTinstaller = Get-ChildItem ($standardFolder) CONFIG*exe
                if ($CTinstaller){return @{CTInstaller=$CTinstaller}}
                else {Write-Host "There is no $app installer in folder $standardFolder" -ba Black -fo Red}}
        }
        else {Write-Host "There is no folder $standardFolder" -ba Black -fo Red}
        
    }
} #end function get-selectedInstallers
function get-lastInstallers { #get AC,MC,DS,CT installers for last found build
    Write-Host "Getting all installers of the last ADC v12 build..." -BackgroundColor Black -ForegroundColor Yellow
    $exceptions = @('\\wtlnas5.wtldev.net\Public\Releases\ADC\ADC1000\QATEST\12.29.30.0', '\\wtlnas5.wtldev.net\Public\Releases\ADC\ADC1000\QATEST\12.29.13.1E')
    $allBuildFolders = Get-ChildItem $Global:buildsFolder | where {$_.Name -match '^12\.\d\d\.\d{1,3}\..{1,3}$'} | select -ExpandProperty FullName
    $lastBranchNumber = ($allBuildFolders -replace '.*\\12\.(\d\d)\..*','$1' | %{[int]$_} | sort | Measure-Object -Maximum).Maximum
    $lastBranchFolders = $allBuildFolders.Where({$_ -match ".*\\12\.$lastBranchNumber\..*$"}) | Where-Object { $_ -notin $exceptions }
    $lastBuildNumber = ($lastBranchFolders -replace '.*\.(\d{1,3})\..{1,3}$','$1' | %{[int]$_} | sort | Measure-Object -Maximum).Maximum
    $lastBuildFolder = $allBuildFolders.Where({$_ -match "^.*\.$lastBranchNumber\.$lastBuildNumber\..{1,3}$"}) | select -Last 1
    $standardFolder = 
        if (Test-Path ($lastBuildFolder +'\Standard\')) {$lastBuildFolder +'\Standard\'}
        else {$lastBuildFolder}
    $ACinstaller = Get-ChildItem ($standardFolder) AIRCLIENT*exe
    $MCinstaller = Get-ChildItem ($standardFolder) MEDIACLIENT*exe
    $DSinstaller = Get-ChildItem ($standardFolder) SERVER_QATEST*exe
    $CTinstaller = Get-ChildItem ($standardFolder) CONFIG*.exe
    return @{ACInstaller=$ACinstaller;MCinstaller=$MCinstaller;DSinstaller=$DSinstaller;CTinstaller=$CTinstaller}}
function install ($installers) {
    if ($installers.Keys) {
        Write-Host "Next installers were found:" -fo Yellow -ba Black
        $installers.values.Name
        $name = if($env:COMPUTERNAME -match '^WTL-ADC-.*') {$env:COMPUTERNAME -replace '^WTL-ADC-'}  # short name taken from COMPUTERNAME to use as DS and clients launch name
        elseif ($env:COMPUTERNAME -match 'ADCS') {'ADCS'}
        elseif ($env:COMPUTERNAME -match 'GALK') {'GALK'}
        elseif ($env:COMPUTERNAME -match '^WTL-') {$env:COMPUTERNAME -replace '^WTL-'}
        else {$env:COMPUTERNAME}

        Write-Host "Starting installation process..." -fo Yellow -ba Black
        $Global:refresh = 1
    } else {Write-Host "There is nothing to install." -fo Yellow -ba Black}

    if ($installers.ACinstaller) {
        $existingACs = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -eq 'ADC Air Client'}
        if ($existingACs.DisplayVersion -match $installers.ACinstaller.VersionInfo.ProductVersion) {
            Write-Host "AC version $($installers.ACinstaller.VersionInfo.ProductVersion) is already installed." -fo Yellow -ba Black
        }
        else {
            Write-Host "Installing $($installers.ACinstaller.Name)..." -fo Green -ba Black -NoNewline
            $InstallPath = 'C:\aclient\' + ($installers.ACinstaller.Name -replace '^.+_(.*)\.exe$','$1')
            $Parameters = '\s \target"' + $InstallPath + '" \client"' + $name + '_AC"' + ' \server"' + $name + '" /NT'
            Start-Process $installers.ACinstaller.FullName -ArgumentList $Parameters -NoNewWindow -Wait
            $lastACfolder = ($All | where {$_.displayname -match 'ADC.*air'} | sort -Property LastLaunch | select -Last 1).InstallLocation
            if ($lastACfolder) {try {Copy-Item ($lastACfolder | gci | where {$_.name -cmatch 'NETWORK.INI'}).FullName -Destination $InstallPath -Force}catch{}}
            Rename-Item -Path "C:\Users\Public\Desktop\ADC Air Client.lnk" -NewName ("AC " + ($installers.ACinstaller.Name -replace '^.+_(.*)\.exe$','$1') + ".lnk")
            Write-Host "Done" -fo Green -ba Black
        }
    }

    if ($installers.MCinstaller) {
        $existingMCs = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -eq 'ADC Media Client'}
        if ($existingMCs.DisplayVersion -match $installers.MCinstaller.VersionInfo.ProductVersion) {
            Write-Host "MC version $($installers.MCinstaller.VersionInfo.ProductVersion) is already installed." -fo Yellow -ba Black
        }
        else {
            Write-Host "Installing $($installers.MCinstaller.Name)..." -fo Green -ba Black -NoNewline
            $InstallPath = 'C:\mclient\' + ($installers.MCinstaller.Name -replace '^.+_(.*)\.exe$','$1')
            $Parameters = '\s \target"' + $InstallPath + '" \client"' + $name + '_MC"' + ' \server"' + $name + '" /NT'
            Start-Process $installers.MCinstaller.FullName -ArgumentList $Parameters -NoNewWindow -Wait
            $lastMCfolder = ($All | where {$_.displayname -match 'ADC.*media'} | sort -Property LastLaunch | select -Last 1).InstallLocation
            if ($lastMCfolder) {try{Copy-Item ($lastMCfolder | gci | where {$_.name -cmatch 'NETWORK.INI'}).FullName -Destination $InstallPath -Force}catch{}}
            Rename-Item -Path "C:\Users\Public\Desktop\ADC Media Client.lnk" -NewName ("MC " + ($installers.MCinstaller.Name -replace '^.+_(.*)\.exe$','$1') + ".lnk")
            Write-Host "Done" -fo Green -ba Black
        }
    }

    if ($installers.DSinstaller) {
        $existingDSs = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -eq 'ADC Device Server'}
        if ($existingDSs.DisplayVersion -match $installers.DSinstaller.VersionInfo.ProductVersion) {
            Write-Host "DS version $($installers.DSinstaller.VersionInfo.ProductVersion) is already installed." -fo Yellow -ba Black
        }
        else {
            Write-Host "Installing $($installers.DSinstaller.Name)..." -fo Green -ba Black -NoNewline
            $InstallPath = 'C:\server\' + ($installers.DSinstaller.Name -replace '^.+_(.*)\.exe$','$1')
            $Parameters = '\s \target"' + $InstallPath + '" \server"' + $name + '"'
            Start-Process $installers.DSinstaller.FullName -ArgumentList $Parameters -NoNewWindow -Wait
            $lastDSfolder = ($All | where {$_.displayname -match 'ADC.*device'} | sort -Property LastLaunch | select -Last 1).InstallLocation
            if ($lastDSfolder) {try{Copy-Item ($lastDSfolder | gci | where {$_.name -cmatch 'NETWORK.INI'}).FullName -Destination $InstallPath -Force}catch{}}
            Rename-Item -Path "C:\Users\Public\Desktop\ADC Device Server.lnk" -NewName ("DS " + ($installers.DSinstaller.Name -replace '^.+_(.*)\.exe$','$1') + ".lnk")
            Write-Host "Done" -fo Green -ba Black
        }
    }

    if ($installers.CTinstaller) {
        $existingCTs = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -eq 'ADC Config Tool'}
        if ($existingCTs.DisplayVersion -match $installers.CTinstaller.VersionInfo.ProductVersion) {
            Write-Host "CT version $($installers.CTinstaller.VersionInfo.ProductVersion) is already installed." -fo Yellow -ba Black
        }
        else {
            Write-Host "Installing $($installers.CTinstaller.Name)..." -fo Green -ba Black -NoNewline
            $InstallPath = 'C:\config\' + ($installers.CTinstaller.Name -replace '^.+_(.*)\.exe$','$1')
            $Parameters = '\s \target"' + $InstallPath + '" \client"' + $name + '_CT"'
            Start-Process $installers.CTinstaller.FullName -ArgumentList $Parameters -NoNewWindow -Wait
            $lastCTfolder = ($All | where {$_.displayname -match 'ADC.*config'} | sort -Property LastLaunch | select -Last 1).InstallLocation
            if ($lastCTfolder) {try{Copy-Item ($lastCTfolder | gci | where {$_.name -cmatch 'NETWORK.INI'}).FullName -Destination $InstallPath -Force}catch{}}
            Rename-Item -Path "C:\Users\Public\Desktop\ADC Config Tool.lnk" -NewName ("CT " + ($installers.CTinstaller.Name -replace '^.+_(.*)\.exe$','$1') + ".lnk")
            Write-Host "Done" -fo Green -ba Black
        }
    }
} #end function install
function show($apps,$noTitles) {
    if (!$noTitles) {Write-Host "Showing all ADC v12 apps found in the system. Sorted by $sorting." -BackgroundColor Black -ForegroundColor Green}
    $apps | select -Property displayname,displayversion,installdate,lastlaunch,size | sort -Property $sorting | ft -AutoSize
    if (!$noTitles) {Write-Host "The list of $($All.Count) ADC v12 apps found in the system is above. Their total size is $totalSize MB." -BackgroundColor Black -ForegroundColor Green}}
function delete($toDelete,$app) {
    if ($app) {
        switch ($app) {
            {$_ -match 'AC'} {
                $app = $app -replace '^(\w\w)\s(4|12)(.*)$','$1 4$3'
                [array]$toDelete = $all | where {$_.displayname -match 'ADC.*air'} | where {$_.displayversion -match ($app -replace '^\w\w\s')}}
            {$_ -match 'MC'} {
                $app = $app -replace '^(\w\w)\s(4|12)(.*)$','$1 4$3'
                [array]$toDelete = $all | where {$_.displayname -match 'ADC.*media'} | where {$_.displayversion -match ($app -replace '^\w\w\s')}}
            {$_ -match 'DS'} {
                $app = $app -replace '^(\w\w)\s(4|12)(.*)$','$1 12$3'
                [array]$toDelete = $all | where {$_.displayname -match 'ADC.*server'} | where {$_.displayversion -match ($app -replace '^\w\w\s')}}
            {$_ -match 'CT'} {
                $app = $app -replace '^(\w\w)\s(4|12)(.*)$','$1 12$3'
                [array]$toDelete = $all | where {$_.displayname -match 'ADC.*config'} | where {$_.displayversion -match ($app -replace '^\w\w\s')}}
        }
    }
    if ($toDelete) {
        show -apps $toDelete -noTitles 1
        Write-Host "All software listed above will be deleted. Is it OK? (y/n):" -fo White -ba Blue -NoNewline
        $confirm = Read-Host

        if ($confirm -match '^y$|^Y$') {
            foreach ($obj in $toDelete) {
                $processName = (Get-ChildItem ($obj.InstallLocation) '*.exe').Name -replace '\.exe'
                if ((Get-Process $processName -ea SilentlyContinue).ProductVersion -match $toDelete.displayversion) {
                    Write-Host "Stopping $processName..." -fo Yellow -ba Black
                    Get-Process $processName | Stop-Process -Force
                    do {} while (Get-Process $processName -ea SilentlyContinue)
                }
                Remove-Item -LiteralPath ("C:\Program Files (x86)\InstallShield Installation Information\"+$obj.ProductGuid) -Recurse -Force -ea SilentlyContinue
                Remove-Item -LiteralPath $obj.InstallLocation -Recurse -Force -ea SilentlyContinue
                Remove-Item -LiteralPath $obj.PSPath -Recurse -Force -ea SilentlyContinue
                $possibleName = ($obj.DisplayName -replace '^ADC\s(\w)\w+\s(\w)\w+$','$1$2 ') + $obj.DisplayVersion
                Get-ChildItem -LiteralPath 'C:\Users\Public\Desktop\' | where {$_.FullName -match $possibleName} |
                Remove-Item -ea SilentlyContinue
            }
            Write-Host "$($toDelete.count) apps were successfully deleted from the system." -fo Yellow -ba Black ; $Global:refresh = 1
        } else {Write-Host "Nothing will be deleted since you didn't confirm your intention." -ba Black -fo Red}
    }
    else {Write-Host "There is nothing to delete." -fo Yellow -ba Black}
} #end function delete
function Title {Write-Host "<Space> - Show me all ADC v12 apps found
<Esc> --- Exit
<F5> ---- Refresh the list of installed software
<I> ----- Install one particular application...
<U> ----- Delete one particular application...
<L> ----- Install all ADC v12 apps of the last build
<P> ----- Install all ADC v12 apps of the particular build...
<D> ----- Delete all apps installed before chosen date...
<Z> ----- Delete all apps which size is larger than...
<E> ----- Delete all apps that were executed before chosen date...
<N> ----- Delete all apps except newest versions in each branch
<A> ----- Delete all ADC v12 apps found
<B> ----- Delete all ADC v12 apps of specific build number...
<S> ----- Sort by..." -f Gray -b Black } #end function Title
function sortLegend {
Write-Host "
Sort by:
1 - DisplayName
2 - DisplayVersion
3 - InstallDate
4 - LastLaunch
5 - Size
Answer:" -fo White -ba Blue -NoNewline} #end function sortLegend

$sorting='InstallDate'
get-ADC ("Please wait. Searching for ADC v12 software...") | %{$All = $_.All ; $AllADCexceptLast = $_.AllADCexceptLast ; $totalSize = $_.totalSize}
Title

#main cycle
do { if ($host.ui.RawUi.KeyAvailable) {
    $key=$host.ui.RawUI.ReadKey("NoEcho,IncludeKeyUp")
    $Host.UI.RawUI.FlushInputBuffer()
    switch ($key.VirtualKeyCode) {
        <#Space#> 32 {show -apps $All ; Title}
        <#Esc#> 27 {return}
        <#F5#> 116 {
            get-ADC ("Refreshing the list of installed ADC v12 software...") | %{$All = $_.All ; $AllADCexceptLast = $_.AllADCexceptLast ; $totalSize = $_.totalSize} 
            Title}
        <#I#> 73 {
            Write-Host "What app to install (examples: AC 4.28.6 or DS 12.27.42):" -fo White -ba Blue -NoNewline
            $selectedApp = Read-Host
            if ($selectedApp -match '^(AC|MC|DS|CT) (4|12)\.\d\d\.\d{1,2}$') {install(get-selectedInstallers -app $selectedApp)}
            else {Write-Host "Wrong build number" -ba Black -fo Red}
            if ($refresh) {
                get-ADC ("Refreshing the list of installed ADC v12 software...") |
                %{$All = $_.All ; $AllADCexceptLast = $_.AllADCexceptLast ; $totalSize = $_.totalSize}
                $refresh = 0
            }
            Title}
        <#U#> 85 {
            Write-Host "What app to delete (examples: AC 4.28.6 or DS 12.27.42):" -fo White -ba Blue -NoNewline
            $selectedApp = Read-Host
            if ($selectedApp -match '^(AC|MC|DS|CT) (4|12)\.\d\d\.\d{1,2}$') {
                delete -app $selectedApp
                if ($refresh) {
                    get-ADC ("Refreshing the list of installed ADC v12 software...") |
                    %{$All = $_.All ; $AllADCexceptLast = $_.AllADCexceptLast ; $totalSize = $_.totalSize}
                    $refresh = 0
                }
            }
            else {Write-Host "Wrong build number" -ba Black -fo Red}
            Title}
        <#L#> 76 {
            install -installers (get-lastInstallers)
            if ($refresh) {
                get-ADC ("Refreshing the list of installed ADC v12 software...") |
                %{$All = $_.All ; $AllADCexceptLast = $_.AllADCexceptLast ; $totalSize = $_.totalSize}
                $refresh = 0
            }
            Title}
        <#P#> 80 {
            Write-Host "Enter build number in format 12.XX.Y(Y) (examples: 12.27.46 or 12.28.3):" -fo White -ba Blue -NoNewline
            $selectedBuild = Read-Host
            if ($selectedBuild -match '^12\.\d\d\.\d{1,2}$') {install -installers (get-selectedInstallers -build ($selectedBuild))}
            else {Write-Host "Wrong build number" -ba Black -fo Red}
            if ($refresh) {
                get-ADC ("Refreshing the list of installed ADC v12 software...") |
                %{$All = $_.All ; $AllADCexceptLast = $_.AllADCexceptLast ; $totalSize = $_.totalSize}
                $refresh = 0
            }
            Title}
        <#B#> 66 {
            Write-Host "Enter build number in format 12.XX.Y(Y) (examples: 12.27.46 or 12.28.3):" -fo White -ba Blue -NoNewline
            $deleteSpecificBuild = Read-Host
            if ($deleteSpecificBuild -match '^12\.\d\d\.\d{1,2}$') {
                $suffix = $deleteSpecificBuild -replace '^12'
                delete -toDelete ($All | where {$_.displayversion -match "^(4|12)$suffix"})
                if ($refresh) {
                    get-ADC ("Refreshing the list of installed ADC v12 software...") |
                    %{$All = $_.All ; $AllADCexceptLast = $_.AllADCexceptLast ; $totalSize = $_.totalSize}
                    $refresh = 0
                }
            }
            else {Write-Host "Wrong build number" -ba Black -fo Red}
            Title
            }
        <#Z#> 90 {
            Write-Host "Enter size in MB:" -fo White -ba Blue -NoNewline
            $deleteAfterSize = Read-Host
            try {
                $deleteAfterSize.ToInt32($null)
                delete -toDelete ($All | where {$_.size -gt $deleteAfterSize})
                if ($refresh) {
                    get-ADC ("Refreshing the list of installed ADC v12 software...") |
                    %{$All = $_.All ; $AllADCexceptLast = $_.AllADCexceptLast ; $totalSize = $_.totalSize}
                    $refresh = 0
                }
            }
            catch {Write-Host "Wrong size" -ba Black -fo Red}
            Title}
        <#E#> 69 {
            Write-Host "Enter date in format YYYYMMDD (example: 20170629):" -fo White -ba Blue -NoNewline
            $deleteBeforeLaunchDate = Read-Host
            if ($deleteBeforeLaunchDate -match '^[1-2]\d\d\d(0[1-9]|1[0-2])(0[1-9]|[1-2]\d|3[0-1])$') {
                delete -toDelete ($All | where {$_.lastlaunch -lt $deleteBeforeLaunchDate})
                if ($refresh) {
                    get-ADC ("Refreshing the list of installed ADC v12 software...") |
                    %{$All = $_.All ; $AllADCexceptLast = $_.AllADCexceptLast ; $totalSize = $_.totalSize}
                    $refresh = 0
                }
            }
            else {Write-Host "Wrong date" -ba Black -fo Red}
            Title}
        <#N#> 78 {
            delete -toDelete ($AllADCexceptLast)
            if ($refresh) {
                get-ADC ("Refreshing the list of installed ADC v12 software...") |
                %{$All = $_.All ; $AllADCexceptLast = $_.AllADCexceptLast ; $totalSize = $_.totalSize}
                $refresh = 0
            }
            Title}
        <#A#> 65 {
            delete -toDelete ($All)
            if ($refresh) {
                get-ADC ("Refreshing the list of installed ADC v12 software...") |
                %{$All = $_.All ; $AllADCexceptLast = $_.AllADCexceptLast ; $totalSize = $_.totalSize}
                $refresh = 0
            }
            Title}
        <#D#> 68 {
            Write-Host "Enter date in format YYYYMMDD (example: 20170629):" -fo White -ba Blue -NoNewline
            $deleteBeforeInstallDate = Read-Host
            if ($deleteBeforeInstallDate -match '^[1-2]\d\d\d(0[1-9]|1[0-2])(0[1-9]|[1-2]\d|3[0-1])$') {
                delete -toDelete ($All | where {$_.installdate -lt $deleteBeforeInstallDate})
                if ($refresh) {
                    get-ADC ("Refreshing the list of installed ADC v12 software...") |
                    %{$All = $_.All ; $AllADCexceptLast = $_.AllADCexceptLast ; $totalSize = $_.totalSize}
                    $refresh = 0
                }
            }
            else {Write-Host "Wrong date" -ba Black -fo Red}
            Title}
        <#S#> 83 {
            sortLegend
            $answer = Read-Host 
            $sorting = switch ($answer) {
                '1' {'DisplayName'}
                '2' {'DisplayVersion'}
                '3' {'InstallDate'}
                '4' {'LastLaunch'}
                '5' {'Size'}
                default {Write-Host "Wrong answer" -ba Black -fo Red ; return}
            }
            show($All) ; Title}
    } #end switch
}} until ($key.VirtualKeyCode -eq 27)
