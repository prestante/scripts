'One #END# Two Three Four #END# Five Six' -match '.*(?=#END#)'
#returns 'One #END# Two Three Four '

'One #END# Two Three Four #END# Five Six' -match '.*?(?=#END#)'
#returns 'One '

'One #START# Two Three Four #START# Five Six' -match '(?<=#START#).*'
#returns ' Two Three Four #START# Five Six'
#means There should be #START# right before .*

'One #START# Two Three Four #END# Five Six #START# Seven Eight #END# Nine' -match '(?<=#START#).*?(?=#END#)'
#returns ' Two Three Four '

'One #START# Two Three Four #END# Five Six #START# Seven Eight #END# Nine' -match '(?<=#START#).*(?=#END#)'
#returns ' Two Three Four #END# Five Six #START# Seven Eight '

'HaroldAndKumarGoToWhiteCastle' -split '((?=[A-Z])(?<=[a-z]))'
'HaroldAndKumarGoToWhiteCastle' -match '(?<=[a-z])(?=[A-Z])'
'20142301 Starting_LOC1SVR14' -replace '(LOC[0-9]+)','$0 '

'domain\username' -replace '\w\w',''

[regex]::matches('domain\username','(?<=\\).+$').value
[regex]::matches(‘this\is\a string’,'\\[^\\].+?\s').value
[regex]::matches(‘this\is\a string’,'\\[^\\].+?\s').value.trim('\ ')

Write-Host (
    [regex]::matches(‘this\is\a string’,'(?<=\\).+?(?=\s)').value
) -f Red -b Black

'The last logged on user was CONTOSO\jsmith' -match '((.+was )(.+))'

$string = 'href="dermatitis&gt;" "blah blah blah &gt;" href="lichen-planus&gt;"'
$value = '&gt;"'
$regex = 'href=".+?(' + $value + ')'
([regex]::matches($string,$regex).groups.value) | ? {$_ -eq $value}
