# Monitor-XMLChanges.ps1
# Monitors ISVariable.xml for changes and logs variable differences

param(
    [string]$FilePath = "C:\Program Files (x86)\Harris\Versio Graphics\ISVariable.xml",
    [int]$PollInterval = 1
)

# Backup functionality removed as requested

# Function to parse XML and extract variables
function Get-VariablesFromXML {
    param([string]$XMLContent)
    
    try {
        $xml = [xml]$XMLContent
        $variables = @{}
        
        foreach ($association in $xml.IconStationVariables.Association) {
            $variables[$association.Variable] = $association.Value
        }
        
        return $variables
    }
    catch {
        Write-Warning "Failed to parse XML: $($_.Exception.Message)"
        return @{}
    }
}

# Function to compare variables and find changes
function Compare-Variables {
    param(
        [hashtable]$OldVars,
        [hashtable]$NewVars
    )
    
    $changes = @()
    
    # Check for new or modified variables
    foreach ($key in $NewVars.Keys) {
        if ($OldVars.ContainsKey($key)) {
            if ($OldVars[$key] -ne $NewVars[$key]) {
                $changes += [PSCustomObject]@{
                    Variable = $key
                    OldValue = $OldVars[$key]
                    NewValue = $NewVars[$key]
                    ChangeType = "Modified"
                }
            }
        } else {
            $changes += [PSCustomObject]@{
                Variable = $key
                OldValue = $null
                NewValue = $NewVars[$key]
                ChangeType = "Added"
            }
        }
    }
    
    # Check for deleted variables
    foreach ($key in $OldVars.Keys) {
        if (!$NewVars.ContainsKey($key)) {
            $changes += [PSCustomObject]@{
                Variable = $key
                OldValue = $OldVars[$key]
                NewValue = $null
                ChangeType = "Deleted"
            }
        }
    }
    
    return $changes
}

# Function to log changes
function Write-ChangeLog {
    param([array]$Changes, [datetime]$Timestamp)
    
    if ($Changes.Count -eq 0) { return }
    
    Write-Host "`n=== XML File Changes Detected at $($Timestamp.ToString('yyyy-MM-dd HH:mm:ss')) ===" -ForegroundColor Yellow
    # Write-Host "File: $FilePath" -ForegroundColor Cyan
    
    foreach ($change in $Changes) {
        $color = switch ($change.ChangeType) {
            "Added" { "Green" }
            "Modified" { "Yellow" }
            "Deleted" { "Red" }
        }
        
        # Pad variable name to ensure consistent alignment
        $paddedVariable = $change.Variable.PadRight(20)
        $paddedOldValue = $change.OldValue.PadRight(24)
        $paddedNewValue = $change.NewValue.PadRight(24)
        
        if ($change.ChangeType -eq "Added") {
            Write-Host "[$($change.ChangeType)] $paddedVariable : (new)    $paddedNewValue" -ForegroundColor $color
        } elseif ($change.ChangeType -eq "Modified") {
            Write-Host "[$($change.ChangeType)] $paddedVariable : $paddedOldValue -> $paddedNewValue" -ForegroundColor $color
        } elseif ($change.ChangeType -eq "Deleted") {
            Write-Host "[$($change.ChangeType)] $paddedVariable : $paddedOldValue -> (deleted)" -ForegroundColor $color
        }
    }
    
    Write-Host "`n" + ("=" * 60) -ForegroundColor Yellow
}

# Main monitoring loop
Write-Host "Starting XML file monitoring..." -ForegroundColor Green
# Write-Host "Monitoring: $FilePath" -ForegroundColor Cyan
Write-Host "Poll interval: $PollInterval seconds" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop monitoring`n" -ForegroundColor Yellow

# Initialize with current file state
$currentVariables = @{}
$lastModified = $null

if (Test-Path $FilePath) {
    $currentVariables = Get-VariablesFromXML (Get-Content $FilePath -Raw)
    $lastModified = (Get-Item $FilePath).LastWriteTime
    Write-Host "Initial state loaded with $($currentVariables.Count) variables" -ForegroundColor Green
} else {
    Write-Host "File not found. Waiting for file to be created..." -ForegroundColor Yellow
}

try {
    while ($true) {
        if (Test-Path $FilePath) {
            $fileInfo = Get-Item $FilePath
            $currentModified = $fileInfo.LastWriteTime
            
            if ($lastModified -ne $currentModified) {
                # Read new content
                $newContent = Get-Content $FilePath -Raw
                $newVariables = Get-VariablesFromXML $newContent
                
                # Compare and log changes
                $changes = Compare-Variables -OldVars $currentVariables -NewVars $newVariables
                Write-ChangeLog -Changes $changes -Timestamp $currentModified
                
                # Update current state
                $currentVariables = $newVariables
                $lastModified = $currentModified
            }
        } else {
            if ($currentVariables.Count -gt 0) {
                Write-Host "File deleted at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Red
                $currentVariables = @{}
                $lastModified = $null
            }
        }
        
        Start-Sleep -Seconds $PollInterval
    }
}
catch [System.Management.Automation.PipelineStoppedException] {
    Write-Host "`nMonitoring stopped by user." -ForegroundColor Yellow
}
catch {
    Write-Host "`nError occurred: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    Write-Host "`nMonitoring ended." -ForegroundColor Green
}
