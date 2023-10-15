$folder = 'C:\Program Files (x86)'

$array= @() 
Get-ChildItem  $folder -Force | #Where-Object { $_.PSIsContainer } |
ForEach-Object {
    try {
        $obj = New-Object PSObject
        if ($_.PSIsContainer) {
            $Size = [Math]::Round((Get-ChildItem $_.FullName -Force -Recurse -ea Stop | Measure-Object Length -Sum -ea Stop).Sum / 1MB)
            $isDir = 'Dir'
        }
        else { $Size = [Math]::Round($_.Length / 1MB) ; $isDir = '' }
        $obj | Add-Member -MemberType NoteProperty -Name "Path" $_.FullName
        $obj | Add-Member -MemberType NoteProperty -Name "Dir" $isDir
        $obj | Add-Member -MemberType NoteProperty -Name "Size,MB" $Size
        $obj | Add-Member -MemberType NoteProperty -Name "DateModified" $_.LastWritetime
        $array +=$obj
    } catch {}
} 
 
$array | select Path,Dir,"Size,MB",DateModified | sort -Property "Size,MB"
"-----------------------------------------------"
"Total size of '$folder' is {0} MB" -f (($array | select -Property "Size,MB" | Measure-Object "Size,MB" -Sum).Sum + 0)
