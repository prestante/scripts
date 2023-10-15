#This command sets "Allow Delegating Fresh Credentials" Group Policy setting of this PC to enabled and sets all PCs (wsman/*) to be possible destinations for credentials delegation from this.

#Enable CredSSP Authentication for all destination PCs.
Enable-WSManCredSSP -Role Client -DelegateComputer *

#You can check it or set manyally by opening gpedit.msc then...
#Navigate to Computer Settings > Administrative Templates > System > Credentials Delegation
#Edit the "Allow Delegating Fresh Credentials" setting.
#Verify that it is Enabled.
#Click "Show..."
#Verify that the list contains an entry "wsman/*". If not - create it.

#Do the same manually for "Allow Delegating Fresh Credentials with NTML-only server authentication".


#also do this (don't know why. PowerShell adviced me to do that after bad attempt to use CredSSP).
winrm set winrm/config/service '@{CertificateThumbprint="<thumbprint>"}'

#and finally make all PCs as Trusted Hosts
set-item wsman:\localhost\Client\TrustedHosts -value *