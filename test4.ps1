$EndTime = (Get-Date).AddSeconds(1)

do {
    if ((Get-Date).Millisecond -gt 500) {
        continue
    }
    Get-Date -Format 'HH:mm:ss:fff'
    Start-Sleep -Milliseconds 100
} until ( (Get-Date) -ge $EndTime )