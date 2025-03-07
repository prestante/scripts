Invoke-Command -ComputerName 'adc-ctc01.tecomgroup.ru' -ScriptBlock {
    Get-Process -Name 'ADC1000NT'
}