$sourceFiles = Get-ChildItem "\\wtlnas1.wtldev.net\Public\ADC\PS\bats Tecom" #| Select-Object -First 10

foreach ($sourceFile in $sourceFiles) {
    $sourceFile.FullName
    $sourcePath = $sourceFile.FullName -replace '\\bats Tecom\\([\w\s!@#$%^&()\-=]+)\.bat','\scripts\$1.ps1'
    $batFill = "PowerShell -Command `"& '$sourcePath' some argument`""
    $destPath = $sourceFile.FullName -replace '\\bats Tecom\\','\bats\'
    if (!(Get-Item $destPath -ea SilentlyContinue)) {New-Item $destPath | Out-Null}
    $batFill | Set-Content $destPath
}

# PowerShell -Command "& '\\wtlnas1\Public\ADC\PS\scripts\Any Process CPU and MEM.ps1' some argument"
