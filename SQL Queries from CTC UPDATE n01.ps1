$scriptPath = '\\wtl-hp3b7-plc1.wtldev.net\Shared\scripts\SQL Queries from CTC UPDATE.ps1'
$argumentList = @('WTL-HPX-325-N01.WTLDEV.NET')
Invoke-Expression "& `"$scriptPath`" $argumentList"