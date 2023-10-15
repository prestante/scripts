$CTC = '192.168.13.170','192.168.13.171','192.168.13.172','192.168.13.173','192.168.13.174','192.168.13.175','192.168.13.176','192.168.13.177','192.168.13.178','192.168.13.179','192.168.13.180','192.168.13.181','192.168.13.182','192.168.13.138','192.168.13.139','192.168.13.140','192.168.13.141','192.168.13.142','192.168.13.143','192.168.13.145','192.168.13.161','192.168.13.168','192.168.13.232','192.168.13.191'
#$CTC = '192.168.13.182','192.168.13.138','192.168.13.139','192.168.13.140','192.168.13.141','192.168.13.142','192.168.13.143','192.168.13.145','192.168.13.161','192.168.13.168','192.168.13.232','192.168.13.191'
#$CTC = '192.168.13.181'
#$CTC = @('192.168.13.170','192.168.13.171','192.168.13.232','192.168.13.191')

$Login = 'local\Administrator'
$Password = 'Tecom_1!'
$Pass = ConvertTo-SecureString -AsPlainText $Password -Force
$Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Login, $Pass

$results = Invoke-Command -ComputerName $CTC -Credential $Creds -ScriptBlock {

    $path1 = 'C:\Program Files\Imagine Communications\Playlist'
    $path2 = 'C:\Users\Administrator\AppData\Local\Imagine Communications\Playlist'
    #Remove-Item -Recurse -Force -LiteralPath $path1 -ea SilentlyContinue
    #Remove-Item -Recurse -Force -LiteralPath $path2 -ea SilentlyContinue
    
    $folder1 = try {Get-Item $path1 -ea Stop} catch {1 | select Name}
    $folder1 | Add-Member NoteProperty Computer $env:COMPUTERNAME
    $NumberOfItems1 = try {@(Get-Childitem $path1 -ea Stop).Length} catch {0}
    $folder1 | Add-Member NoteProperty NumberOfItems $NumberOfItems1
    $folder1 | Add-Member NoteProperty Path $path1
    
    $folder2 = try {Get-Item $path2 -ea Stop} catch {1 | select Name}
    $folder2 | Add-Member NoteProperty Computer $env:COMPUTERNAME
    $NumberOfItems2 = try {@(Get-Childitem $path2 -ea Stop).Length} catch {0}
    $folder2 | Add-Member NoteProperty NumberOfItems $NumberOfItems2
    $folder2 | Add-Member NoteProperty Path $path2
    
    return $folder1, $folder2 | Select-Object Computer,Path,LastWriteTime,NumberOfItems
    
}

$results | select Computer,Path,LastWriteTime,NumberOfItems | Sort-Object Computer | ft 