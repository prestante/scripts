$IP = '192.168.13.62'
Invoke-RestMethod -Method Delete -Uri "http://$IP/ContentService/api/contents/?q=*&limit=120000"