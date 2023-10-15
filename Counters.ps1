#Write-Host "Reading CPU properties..." -fo Yellow -ba Black
#$Processor = Get-WmiObject Win32_Processor
#$Cores = $Processor | Measure -Property  NumberOfCores -Sum
#$Cores = $Cores.Sum
#$LogicalCPUs = $Processor | Measure -Property  NumberOfLogicalProcessors -Sum
#$LogicalCPUs = $LogicalCPUs.sum

#do {
    #$time1 = Get-Date

   #((Get-Counter ($Processes.Name | %{"\process($_)\% processor time"})).CounterSamples.CookedValue | %{[math]::Round(($_/$LogicalCPUs),2)})
    
#    [gc]::Collect()
    #Get-Counter -ListSet process

    #"$([math]::round(((Get-Date) - $time1).totalmilliseconds)) ms"
#} while (1)



#$processes = get-process -Name chrome
#(Get-Counter (($Processes.Name) | %{"\process($_)\% processor time"})).CounterSamples.CookedValue
#$all = Get-Counter -ListSet process 
#$all.PathsWithInstances | ?{$_ -match 'chronos'}

#Get-Counter '\Process(chrome#9)\% Processor Time'
#Get-Counter '\Process(chrome#9)\id process'
#Get-Counter -ListSet 'Process'

$time1 = Get-Date
#($counter = Get-Counter '\Process(chrome#9)\% Processor Time').CounterSamples.CookedValue

#$list = New-Object System.Collections.Generic.List[System.Object]
0..((Get-Process -Name 'chrome').Count - 1) | %{$list += "\Process(chrome#$_)\id process"}
#(Get-Counter -ListSet process).PathsWithInstances | ? {$_ -match 'chrome.+id pro'} | %{}
#Get-Counter $list
#((Get-Counter -ListSet memory).Paths | Get-Counter).countersamples | %{ [pscustomobject]@{Path=$_.Path; CounterType=$_.CounterType; CookedValue=($_.CookedValue/1MB)}} | ft
((Get-Counter ((($Processes.Name + 'idle') | %{"\process($_)\% processor time"}) + '\memory\standby cache normal priority bytes') -ErrorAction Stop).CounterSamples.CookedValue | %{[decimal]($_/$LogicalCPUs/$HT)})
#(Get-Counter '\memory\available bytes').CounterSamples.CookedValue/1MB
#(systeminfo | Select-String 'Total Physical Memory:').ToString().Split(':')[1].Trim()
(Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).sum /1mb

"$([math]::round(((Get-Date) - $time1).totalmilliseconds)) ms"


