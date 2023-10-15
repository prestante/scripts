Clear-Host
Write-Host (Get-Service -Name 'ADCIntegrationService').Status

do
    {
}
while ((Get-Service -Name 'ADCIntegrationService').Status -eq 'Running')

Set-Service -Name 'ADCIntegrationService' -StartupType Disabled
Clear-Host
Write-Host Integration Service is DISABLED
Write-Host 'Current status is ' -NoNewline
Write-Host (Get-Service -Name 'ADCIntegrationService').Status
