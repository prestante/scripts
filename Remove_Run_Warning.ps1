Invoke-Command -ScriptBlock {

    $registryPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\EscRanges\Range1"
    $registryPath3 = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Ranges\Range1"
    $name = ":Range"
    $name2 = "file"
    $value = "192.168.12.3"
    $value2 = 1

    IF(!(Test-Path $registryPath))
      {
        New-Item -Path $registryPath -Force | Out-Null
        New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType "String" -Force | Out-Null
        New-ItemProperty -Path $registryPath -Name $name2 -Value $value2 -PropertyType DWORD -Force | Out-Null
        }
     ELSE {
        New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType "String" -Force | Out-Null
        New-ItemProperty -Path $registryPath -Name $name2 -Value $value2 -PropertyType DWORD -Force | Out-Null
        }


    IF(!(Test-Path $registryPath3))
      {
        New-Item -Path $registryPath3 -Force | Out-Null
        New-ItemProperty -Path $registryPath3 -Name $name -Value $value -PropertyType "String" -Force | Out-Null
        New-ItemProperty -Path $registryPath3 -Name $name2 -Value $value2 -PropertyType DWORD -Force | Out-Null
        }
     ELSE {
        New-ItemProperty -Path $registryPath3 -Name $name -Value $value -PropertyType "String" -Force | Out-Null
        New-ItemProperty -Path $registryPath3 -Name $name2 -Value $value2 -PropertyType DWORD -Force | Out-Null
        }

        #Get-ItemProperty -Path $registryPath -Name $name

    #Restart-Computer -Force
}