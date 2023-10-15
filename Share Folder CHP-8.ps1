$Login = 'ADCCHP-8\Administrator'
$Password = 'ADC1000hrs'
$Pass = ConvertTo-SecureString -AsPlainText $Password -Force
$SecureString = $Pass
$Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Login, $SecureString

#entering remote session
    Invoke-Command -ComputerName ADCCHP-8 -Authentication Credssp -Credential $Creds -ScriptBlock {
        
        New-SmbShare -Name "Imagine Communications" -Path "C:\Program Files (x86)\Imagine Communications" -ReadAccess "Everyone"
    
    }
#}