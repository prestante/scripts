$files = gci "\\wtl-hp3b7-plc1.wtldev.net\Shared\bats" #| where {$_.Name -match 'test'}

foreach ($file in $files) {

    (Get-Content $file.FullName) -replace '\\Change\\galkovsky\.a','\Shared' -replace '\\\\fs\\change','\\wtl-hp3b7-plc1.wtldev.net\Shared' -replace '\\\\fs','\\wtl-hp3b7-plc1.wtldev.net' -replace '\\\\192\.168\.12\.3\\change','\\10.9.37.116\Shared' -replace '\\\\192\.168\.12\.3','\\10.9.37.116' -replace 'Cannot reach \\\\fs','Cannot reach \\wtl-hp3b7-plc1.wtldev.net' | Set-Content $file.FullName

}


