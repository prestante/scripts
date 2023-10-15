$sourceFiles = Get-ChildItem "\\wtlnas1.wtldev.net\Public\ADC\PS\bats Tecom" | Where-Object {$_.Name -match 'test.bat'}

foreach ($sourceFile in $sourceFiles) {
    $sourceFile.FullName
    $sourcePath = $sourceFile.FullName -replace '\\bats Tecom\\([\w\s!@#$%^&()\-=]+)\.bat','\scripts\$1.ps1'
    $batFill = "PowerShell -Command `"& '$sourcePath' some argument`""
    $destPath = $sourceFile.FullName -replace '\\bats Tecom\\','\bats\'
    if (!(Get-Item $destPath)) {New-Item $destPath}
    $batFill | Set-Content $destPath
}

# PowerShell -Command "& '\\wtlnas1\Public\ADC\PS\scripts\Any Process CPU and MEM.ps1' some argument"
