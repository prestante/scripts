Clear-Host

Start-Service -Name ADCAggregationService
Write-Host (Get-Date -Format 'yyyy-MM-dd HH:mm:ss - ') -NoNewline
Write-Host 'ADCAggregationService is ' -NoNewline
Write-Host (Get-Service -Name ADCAggregationService).Status
Start-Sleep 60

Start-Service -Name ADCIntegrationService
Write-Host (Get-Date -Format 'yyyy-MM-dd HH:mm:ss - ') -NoNewline
Write-Host 'ADCIntegrationService is ' -NoNewline
Write-Host (Get-Service -Name ADCIntegrationService).Status
Start-Sleep 240

for ($i=0 ; ((((Get-Process -Name Harris.Automation.ADC.Services.AggregationServiceHost).WorkingSet64) / 1048576) -lt 4000) ; $i++)
{
    Write-Host (Get-Date -Format 'yyyy-MM-dd HH:mm:ss - ') -NoNewline
    Write-Host 'Stopping ADCIntegrationService'
    Stop-Service -Name ADCIntegrationService
    Write-Host (Get-Date -Format 'yyyy-MM-dd HH:mm:ss - ') -NoNewline
    Write-Host 'ADCIntegrationService is ' -NoNewline
    Write-Host (Get-Service -Name ADCIntegrationService).Status
    Write-Host (Get-Date -Format 'yyyy-MM-dd HH:mm:ss - ') -NoNewline
    Write-Host 'AS memory consumption is ' -NoNewline
    Write-Host ([math]::Round((Get-Process -Name Harris.Automation.ADC.Services.AggregationServiceHost).WorkingSet64 / 1048576)) -NoNewline
    Write-Host ' MB'
    Start-Sleep 600
    
    Write-Host (Get-Date -Format 'yyyy-MM-dd HH:mm:ss - ') -NoNewline
    Write-Host 'Starting ADCIntegrationService'
    Start-Service -Name ADCIntegrationService
    Write-Host (Get-Date -Format 'yyyy-MM-dd HH:mm:ss - ') -NoNewline
    Write-Host 'ADCIntegrationService is ' -NoNewline
    Write-Host (Get-Service -Name ADCIntegrationService).Status
    Write-Host (Get-Date -Format 'yyyy-MM-dd HH:mm:ss - ') -NoNewline
    Write-Host 'AS memory consumption is ' -NoNewline
    Write-Host ([math]::Round((Get-Process -Name Harris.Automation.ADC.Services.AggregationServiceHost).WorkingSet64 / 1048576)) -NoNewline
    Write-Host ' MB'
    Start-Sleep 600
}

Write-Host (Get-Date -Format 'yyyy-MM-dd HH:mm:ss - ') -NoNewline
Write-Host 'AS memory consumption is ' -NoNewline
Write-Host ([math]::Round((Get-Process -Name Harris.Automation.ADC.Services.AggregationServiceHost).WorkingSet64 / 1048576)) -NoNewline
Write-Host ' MB'

Stop-Service -Name ADCIntegrationService -Force -ErrorAction SilentlyContinue
Stop-Process -Name Harris.Automation.ADC.Services.IntegrationServiceHost -Force -ErrorAction SilentlyContinue
Stop-Service -Name ADCAggregationService -Force -ErrorAction SilentlyContinue
Stop-Process -Name Harris.Automation.ADC.Services.AggregationServiceHost -Force -ErrorAction SilentlyContinue

Write-Host 'Done. IS was restarted ' -NoNewline
Write-Host $i -NoNewline
Write-Host ' times.'