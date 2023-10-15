$registryPath = 'Registry::HKEY_CLASSES_ROOT\Microsoft.PowerShellScript.1\Shell\open\command\'
$value = '"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -noLogo -ExecutionPolicy unrestricted -file "%1"'
Set-Item -Path $registryPath -Value $value