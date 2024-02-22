$ComputerName = 'wtl-adc-ctc-04'
$Creds = [System.Management.Automation.PSCredential]::new('local\imagineLocal',(ConvertTo-SecureString -AsPlainText '!!!!!!' -Force))
#$Creds = [System.Management.Automation.PSCredential]::new('local\imagineLocal')

Invoke-Command -ComputerName $ComputerName -Credential $Creds {
    "$(HOSTNAME.EXE)"
    Add-Computer -WorkgroupName "CTC"
    Restart-Computer -Force
}

Start-Sleep 20

Invoke-Command -ComputerName $ComputerName -Credential $Creds {
    "$(HOSTNAME.EXE)"
    Add-Computer -WorkgroupName "CTC"
    Restart-Computer -Force
}
