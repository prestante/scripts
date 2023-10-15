$CTC = '192.168.13.170','192.168.13.171','192.168.13.172','192.168.13.173','192.168.13.174','192.168.13.175','192.168.13.176','192.168.13.177','192.168.13.178','192.168.13.179','192.168.13.180','192.168.13.181','192.168.13.182','192.168.13.138','192.168.13.139','192.168.13.140','192.168.13.141','192.168.13.142','192.168.13.143','192.168.13.145','192.168.13.161','192.168.13.168','192.168.13.232','192.168.13.191'
$CTC = '192.168.13.143','192.168.13.145','192.168.13.161','192.168.13.168','192.168.13.232','192.168.13.191'
#$CTC = '192.168.13.143','192.168.13.161'


$Login = 'local\Administrator'
$Password = 'Tecom_1!'
$Pass = ConvertTo-SecureString -AsPlainText $Password -Force
$Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Login, $Pass

Invoke-Command -ComputerName $CTC -Credential $Creds -ScriptBlock {
    function GD {Get-Date -Format 'yyyy-MM-dd HH:mm:ss - '}
    do {$f = (Get-Random 15)} until (($f -ne 0) -and ($f -ne 1) -and ($f -ne 4) -and ($f -ne 5) -and ($f -ne 9) -and ($f -ne 12))

    #Start-Service -Name 'ADCSecurityService', 'ADCManagerService'

    [System.Collections.Generic.List[PSObject]]$services = Get-Service -Name 'ADC*' | where {$_.DisplayName -notmatch 'Aggregation'}
    [System.Collections.Generic.List[PSObject]]$servicesInOrder = @()

    $services | where {$_.DisplayName -match 'Data'} | % {$servicesInOrder.Add($_)}
    $services | where {$_.DisplayName -match 'Timecode'} | % {$servicesInOrder.Add($_)}
    $services | where {$_.DisplayName -match 'AsRun'} | % {$servicesInOrder.Add($_)}
    $services | where {$_.DisplayName -match 'Device'} | % {$servicesInOrder.Add($_)}
    $services | where {$_.DisplayName -match 'List'} | % {$servicesInOrder.Add($_)}
    $services | where {$_.DisplayName -match 'Error'} | % {$servicesInOrder.Add($_)}
    $services | 
     where {$_.DisplayName -notmatch 'Data'} |
     where {$_.DisplayName -notmatch 'Timecode'} |
     where {$_.DisplayName -notmatch 'AsRun'} | 
     where {$_.DisplayName -notmatch 'Device'} | 
     where {$_.DisplayName -notmatch 'List'} | 
     where {$_.DisplayName -notmatch 'Error'} | 
     where {$_.DisplayName -notmatch 'Synchro'} | 
     where {$_.DisplayName -notmatch 'Integra'} | 
     where {$_.DisplayName -notmatch 'Manager'} | 
    % {$servicesInOrder.Add($_)}
    #$services | where {$_.DisplayName -match 'Integra'} | % {$servicesInOrder.Add($_)}
    #$services | where {$_.DisplayName -match 'Synchro'} | % {$servicesInOrder.Add($_)}
    #$services | where {$_.DisplayName -match 'Manager'} | % {$servicesInOrder.Add($_)}

    $servicesInOrder | % {
        Write-Host "$(GD)$($env:COMPUTERNAME): Starting $($_.name -replace '(ADC)(.*)(Service)','$1 $2 $3')" -b Black -f $f
        Start-Service $_.name -WarningAction SilentlyContinue
    }

    Write-Host "$(GD)$($env:COMPUTERNAME): Done" -b Black -f $f
}
Sleep 2