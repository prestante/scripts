#This script adds all PCs as Trusted Hosts for current PC

set-item wsman:\localhost\Client\TrustedHosts -value *

#on server PC (works even on domain PC)
winrm qc
#after this please restart WinRM Service (Windows Remote Management (WS-Management))