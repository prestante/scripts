$ParamList = @{
    Param1 = ‘Hello’
    Param2 = ‘World’
}
$PowerShell = [powershell]::Create()

[void]$PowerShell.AddScript({
    Param ($Param1, $Param2)
    [pscustomobject]@{
        Param1 = $Param1
        Param2 = $Param2
    }
}).AddParameters($ParamList)

#Invoke the command
#$PowerShell.Invoke()
$AsyncObject = $PowerShell.BeginInvoke()

$Data = $PowerShell.EndInvoke($AsyncObject)

#Start-Sleep -Milliseconds 1000
$Data

#$PowerShell.Dispose()