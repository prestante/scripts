$body = Get-Content 'C:\PS\xml\columbus.xml'
Invoke-WebRequest -Method Post -Uri 'http://localhost/AdcServices/DATG_ADC_Proxy.asmx' -Body $body -ContentType text/xml -Headers (@{SOAPAction="http://disney.com/datg/services/media/AutomationSchedule/v1_10/receiveSubmitSchedule"})
