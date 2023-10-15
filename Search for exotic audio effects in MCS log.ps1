$file = 'C:\server\log\NGCMCSwitcher\NGCMCSwitcher-2022.03.16 19-14-45.422.log'
$content = Get-Content $file -raw
$regex = '(?s)(<AudioTransitionEffect>\s+)(?!Fade\r|Cut\r)(?<effect>\w+)' #to find any audio effect except cut and fade
#$regex = '(?s)(<AudioTransitionEffect>\s+)(?=Cut\r)(?<effect>\w+)' #to find all Audio Cut effect
#$regex = '(?s)(<AudioTransitionEffect>\s+)(?=Fade\r)(?<effect>\w+)' #to find all Audio Fade effect
#$regex = '(?s)(<VideoTransitionEffect>\s+)(?!Fade\r|Cut\r)(?<effect>\w+)' #to find any video effect except cut and fade

$findings = ([regex]::Matches($content,$regex))
Write-Host "Found $($findings.Count) cases"
if ($findings.Count -ge 5) {
    Write-Host "Last 5 of them:"
    $findings | select -Last 5 | %{[pscustomobject]@{Index=$_.Index; Effect=$_.Groups['effect'].Value}} | ft
}
