function Remove-ADC {
    [CmdletBinding()]
    param ($toDelete,$app)  # for $toDelete use objects from Get-ADC.psm1

    if ($app) {
        switch ($app) {
            {$_ -match 'AC'} {
                $app = $app -replace '^(\w\w)\s(4|12)(.*)$','$1 4$3'
                [array]$toDelete = $all | Where-Object { $_.DisplayName -match 'ADC.*air' } | Where-Object { $_.DisplayVersion -match ($app -replace '^\w\w\s') }}
            {$_ -match 'MC'} {
                $app = $app -replace '^(\w\w)\s(4|12)(.*)$','$1 4$3'
                [array]$toDelete = $all | Where-Object { $_.DisplayName -match 'ADC.*media' } | Where-Object { $_.DisplayVersion -match ($app -replace '^\w\w\s') }}
            {$_ -match 'DS'} {
                $app = $app -replace '^(\w\w)\s(4|12)(.*)$','$1 12$3'
                [array]$toDelete = $all | Where-Object { $_.DisplayName -match 'ADC.*server' } | Where-Object { $_.DisplayVersion -match ($app -replace '^\w\w\s') }}
            {$_ -match 'CT'} {
                $app = $app -replace '^(\w\w)\s(4|12)(.*)$','$1 12$3'
                [array]$toDelete = $all | Where-Object { $_.DisplayName -match 'ADC.*config' } | Where-Object { $_.DisplayVersion -match ($app -replace '^\w\w\s') }}
        }
    }
    if ($toDelete) {
        $Report = "Removing $($toDelete.Count) installed ADC app(s):"
        foreach ($obj in $toDelete) {
            $processName = ( Get-ChildItem ( $obj.InstallLocation ) '*.exe' ).Name -replace '\.exe'
            if ( ( Get-Process $processName -ea SilentlyContinue ).ProductVersion -match $obj.DisplayVersion ) {  # stop corresponding process if any
                Get-Process $processName -ea SilentlyContinue | Stop-Process -Force
                #do {} while ( Get-Process $processName -ea SilentlyContinue )
            }
            $Report += " $($obj.DisplayName) $($obj.DisplayVersion)"
            Remove-Item -LiteralPath ( "C:\Program Files (x86)\InstallShield Installation Information\"+$obj.ProductGuid ) -Recurse -Force -ea SilentlyContinue
            Get-ChildItem $obj.InstallLocation -Recurse -File -Exclude *.INI, *.log | Remove-Item -Force -ErrorAction SilentlyContinue  # remove all files except .INI and .log
            Remove-Item -LiteralPath $obj.PSPath -Recurse -Force -ea SilentlyContinue
            $possibleName = ( $obj.DisplayName -replace '^ADC\s(\w)\w+\s(\w)\w+$','$1$2 ' ) + $obj.DisplayVersion
            Get-ChildItem -LiteralPath 'C:\Users\Public\Desktop\' | Where-Object { $_.FullName -match $possibleName } |
            Remove-Item -ea SilentlyContinue
        }
        $Report += " - Done"
        Write-Output $Report
    }
    #else { Write-Output "There is nothing to delete" }
}