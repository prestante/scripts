do {
    $services = Get-Service -Name ADC* | where {$_.Name -notmatch 'Aggr'}
    Start-Sleep -Milliseconds 100
} while (($services.status -contains 'Stopped') -or ($services.status -contains 'Starting'))

$processes = Get-Process -Name Harris*

foreach ($process in $processes) {
    $PA = [int64]($process | select -Property ProcessorAffinity).processoraffinity
    $PAstr = [convert]::ToString($PA,2).padleft(64,'0')
    "Old Processor Affinity of $($process.Name -replace 'Harris.Automation.ADC.Services.'): $PAstr"

   #$newStr = '0000000011111111111111111111111111110000000000000000000000000000' # 2 x 28-core CPU's for a total of 56 cores on Versio150
    $newStr = '0000000000000000000000000000111111110000000000000000000000000000' # 2 x 28-core CPU's for a total of 56 cores on Versio150
    $newAff = [convert]::ToInt64($newStr,2)
    $process.ProcessorAffinity = $newAff

    $PAnew = [int64]($process | select -Property ProcessorAffinity).processoraffinity
    $PAstrNew = [convert]::ToString($PAnew,2).padleft(64,'0')
    "New Processor Affinity of $($process.Name -replace 'Harris.Automation.ADC.Services.'): $PAstrNew"
}
Start-Sleep 5