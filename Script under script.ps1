Write-Host "PID:$PID"
sleep 1
Write-Host "Executing another script..."
& "$PSScriptRoot\test.ps1"
