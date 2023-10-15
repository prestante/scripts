#$CpuCores = (Get-WMIObject Win32_ComputerSystem).NumberOfLogicalProcessors * 0.8 #multiplier for matching taskmgr value
$CpuCores = 1
$properties=@(
    #@{Name="Process Name"; Expression = {$_.name}},
    @{Name="CPU (%)"; Expression = {$_.PercentProcessorTime}}   
    #@{Name="Memory (MB)"; Expression = {[Math]::Round(($_.workingSetPrivate / 1mb),2)}}
)
$name='ADC1000NT'

function Proc {
#Get-WmiObject -class Win32_PerfFormattedData_PerfProc_Process -filter "Name='$name'" | % {[Decimal]::Round(($_.PercentProcessorTime), 2)}
((Get-Counter "\Process($name)\% Processor Time").CounterSamples) | % {[Math]::Round(($_.CookedValue / $CpuCores), 0)}
}

function GD {Get-Date -Format 'yyyy-MM-dd HH:mm:ss - '}
function Title {"------------------------"
"Press <Esc> to exit."
"------------------------"
}

do {
    for ($i=1 ; 1 ; $i++) {
        "$(GD) $($name) CPU {0,3} %" -f (Proc) #| Tee-Object $logfile -Append
        #looking for <Esc> or <F1> press
        if ($host.ui.RawUi.KeyAvailable) {
            $key=$host.ui.RawUI.ReadKey("NoEcho,IncludeKeyUp")
            $Host.UI.RawUI.FlushInputBuffer()
            switch ($key.VirtualKeyCode) {
                27 {exit} #<Esc>
                112 {Title} #<F1>
            }
        }
        #Start-Sleep -milliseconds 500
    }
    $Host.UI.RawUI.FlushInputBuffer()
} until ($key.VirtualKeyCode -eq 27)