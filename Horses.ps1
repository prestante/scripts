$FormatEnumerationLimit = 5
$tries = @()

function reset {
    $hash = @{}
    $Global:horse=@()
    $Global:horse += ''

    #getting 25 unique numbers
    do {
        $a = Get-Random -Minimum 10 -Maximum 99
        try { $hash.Add($a,$a) } Catch {}

    } while ($hash.Count -lt 25)

    #adding them to $horse array
    $hash.GetEnumerator() | % { $Global:horse += $_.value }

    #dividing them into 5 groups
    $Global:gr1 = $horse[1..5]
    $Global:gr2 = $horse[6..10]
    $Global:gr3 = $horse[11..15]
    $Global:gr4 = $horse[16..20]
    $Global:gr5 = $horse[21..25]
}

function swap {
    $bestindex1 = [int]$gr1.IndexOf($best1)
    $bestindex2 = [int]$gr2.IndexOf($best2)
    $bestindex3 = [int]$gr3.IndexOf($best3)
    $bestindex4 = [int]$gr4.IndexOf($best4)
    $bestindex5 = [int]$gr5.IndexOf($best5)

    $Global:gr1[$bestindex1] = $best5
    $Global:gr2[$bestindex2] = $best1
    $Global:gr3[$bestindex3] = $best2
    $Global:gr4[$bestindex4] = $best3
    $Global:gr5[$bestindex5] = $best4
}

reset

do {
    cls
    "best horses: {0}" -f (($horse | Sort-Object -Descending| select -First 5) -join ', ')
    $origsum = ($horse | Sort-Object -Descending| select -First 5 | Measure-Object -Sum).Sum
    "sum: {0}`n" -f $origsum
    
    $best1 = [int]($gr1 | Measure-Object -Maximum).Maximum
    $best2 = [int]($gr2 | Measure-Object -Maximum).Maximum
    $best3 = [int]($gr3 | Measure-Object -Maximum).Maximum
    $best4 = [int]($gr4 | Measure-Object -Maximum).Maximum
    $best5 = [int]($gr5 | Measure-Object -Maximum).Maximum

    $total = New-Object psobject -Property @{ gr1 = $gr1 ; gr2 = $gr2 ; gr3 = $gr3 ; gr4 = $gr4 ; gr5 = $gr5 }
    $total | Select-Object -Property gr1,gr2,gr3,gr4,gr5

    "best groups: {0}, {1}, {2}, {3}, {4}" -f $best1, $best2, $best3, $best4, $best5
    $bestsum = ($best1, $best2, $best3, $best4, $best5 | Measure-Object -Sum).Sum
    "sum: {0}" -f $bestsum

    $avg = ($tries | Measure-Object -Average).Average
    if ( $max -lt $swaps ) { $max = $swaps }

    "`$tries = $tries"
    "`$swaps = $swaps"
    "`$avg = $avg"
    "`$max = $max"
    

    #looking for <Esc> or <R> or <Space> press
    if ($host.ui.RawUi.KeyAvailable) {
        $key=$host.ui.RawUI.ReadKey("NoEcho,IncludeKeyUp")
        $Host.UI.RawUI.FlushInputBuffer()
        if ($key.VirtualKeyCode -eq 27) {exit}            #<Esc>
        if ($key.VirtualKeyCode -eq 32) {swap}            #<Space>
        if ($key.VirtualKeyCode -eq 13) {reset}           #<Enter>
    }

    if ($origsum -ne $bestsum) {"Swapping..."}
    if ($origsum -eq $bestsum) {"Resetting..."}
    Start-Sleep -Milliseconds 5
    if ($origsum -ne $bestsum) {$swaps++ ; swap}
    if ($origsum -eq $bestsum) {$tries += $swaps ; $swaps = 0 ; reset}

} until ($key.VirtualKeyCode -eq 27)