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

    #Write-Host "$($All.Count) ADC v12 apps were found in the system. Their total size is $totalSize MB." -BackgroundColor Black -ForegroundColor Green
    return @{All = $All ; AllADCexceptLast = $AllADCexceptLast ; totalSize = $totalSize ; AllDS = $AllDS}
}