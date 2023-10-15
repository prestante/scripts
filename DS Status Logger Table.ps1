$CTC = '192.168.13.170','192.168.13.171','192.168.13.172','192.168.13.173','192.168.13.174','192.168.13.175','192.168.13.176','192.168.13.177','192.168.13.178','192.168.13.179','192.168.13.180','192.168.13.181','192.168.13.182','192.168.13.138','192.168.13.139','192.168.13.140','192.168.13.141','192.168.13.142','192.168.13.143','192.168.13.145','192.168.13.161','192.168.13.168','192.168.13.232','192.168.13.191'
#$CTC = @('192.168.13.170','192.168.13.14')

$Login = 'local\Administrator'
$Password = 'Tecom_1!'
$Pass = ConvertTo-SecureString -AsPlainText $Password -Force
$Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Login, $Pass

$avg = $low = $high = 0
$qt = 0


do {
    $time1 = (Get-Date)
    $qt++
    $all = Invoke-Command -ComputerName $CTC -Credential $Creds -ArgumentList $server,$ping -ScriptBlock {
        param ($server,$ping)
        [pscustomobject]@{
            Server = $server
            Ping = $ping
            DSver = if (Test-Path 'C:\Users\Public\Desktop\ADC Device Server.lnk') {
                $sh = New-Object -ComObject WScript.Shell
                ((gci $sh.CreateShortcut('C:\Users\Public\Desktop\ADC Device Server.lnk').Targetpath).VersionInfo).ProductVersion
            } else {''}
            DSmem = if ((Get-Process -Name ADC1000NT -ea SilentlyContinue).Count) {
                "{0:n2}" -f [math]::round(((Get-Process -Name ADC1000NT -ea SilentlyContinue).WorkingSet64 | Measure-Object -Sum).Sum/1MB,2)
            } else {''}            
            SEver = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -eq 'ADC Services'} | Select-Object -Property DisplayVersion).DisplayVersion
            SEmem = if ((Get-Process -Name Harris* -ea SilentlyContinue).Count) {
                "{0:n2}" -f [math]::Round((((Get-Process -Name Harris*).WorkingSet64 | Measure-Object -Sum).Sum/1MB),2)
            } else {''}
    <#
            PLmem = if ((Get-Process -Name Playlist -ea SilentlyContinue).Count) {
                "{0:n2}" -f [math]::Round((((Get-Process -Name Playlist).WorkingSet64 | Measure-Object -Sum).Sum/1MB),2)
            } else {''}
            CTmem = if ((Get-Process -Name ADC1000NTCFG -ea SilentlyContinue).Count) {
                "{0:n2}" -f [math]::Round((((Get-Process -Name ADC1000NTCFG -ea SilentlyContinue).WorkingSet64 | Measure-Object -Sum).Sum/1MB),2)
            } else {''}
    #>  
        }
    }

    $spent = ((Get-Date) - $time1).TotalMilliseconds
    $avg = ($avg*($qt-1)+$spent)/$qt
    $low = if (($spent -lt $low) -or !($low)) {$spent} else {$low}
    $high = if ($spent -gt $high) {$spent} else {$high}

    if ($qt%10 -eq 0) {Write-Host "Low: $low  Avg: $avg  High: $high"; $low = $high = 0}
    #"$(((Get-Date) - $time1).TotalMilliseconds) ms"

} until ($qt -gt 1000)

