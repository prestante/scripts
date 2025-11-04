param(
	[string]$FilePath = "C:\Program Files (x86)\Harris\Versio Graphics\ISVariable.xml",
	[int]$PollIntervalMs = 300
)

function Get-VariableValueFromXml {
	param(
		[xml]$XmlDoc,
		[string]$VariableName
	)
	try {
		if ($XmlDoc.IconStationVariables -and $XmlDoc.IconStationVariables.Association) {
			foreach ($assoc in $XmlDoc.IconStationVariables.Association) {
				if ([string]::Equals([string]$assoc.Variable, $VariableName, [System.StringComparison]::InvariantCultureIgnoreCase)) {
					$val = [string]$assoc.Value
					if ($null -ne $val -and $val -ne '') { return [PSCustomObject]@{ Found = $true; Value = $val } }
					return [PSCustomObject]@{ Found = $true; Value = '' }
				}
			}
		}
	}
	catch {}

	try {
		$allNodes = $XmlDoc.SelectNodes("//*")
		foreach ($node in $allNodes) {
			if ($node.Attributes) {
				$nameAttr = $node.Attributes.GetNamedItem('name')
				if ($nameAttr -and [string]::Equals([string]$nameAttr.Value, $VariableName, [System.StringComparison]::InvariantCultureIgnoreCase)) {
					if ($node.Attributes.GetNamedItem('value')) {
						return [PSCustomObject]@{ Found = $true; Value = [string]$node.Attributes.GetNamedItem('value').Value }
					}
					return [PSCustomObject]@{ Found = $true; Value = [string]$node.InnerText }
				}
			}
		}
	}
	catch {}

	try {
		$allNodes2 = $XmlDoc.SelectNodes("//*")
		foreach ($node in $allNodes2) {
			if ([string]::Equals([string]$node.LocalName, $VariableName, [System.StringComparison]::InvariantCultureIgnoreCase)) {
				return [PSCustomObject]@{ Found = $true; Value = [string]$node.InnerText }
			}
		}
	}
	catch {}

	return [PSCustomObject]@{ Found = $false; Value = $null }
}

function Pad-Fixed {
	param(
		[string]$Text,
		[int]$Width
	)
	if ($null -eq $Text) { $Text = '' }
	if ($Text.Length -gt $Width) { return $Text.Substring(0, $Width - 3) + '...' }
	return $Text.PadRight($Width)
}

$variableName = Read-Host "Enter variable name (case-insensitive, e.g. next.starttime)"
if ([string]::IsNullOrWhiteSpace($variableName)) { Write-Host "No variable provided." -ForegroundColor Red; exit 1 }

if (-not (Test-Path -LiteralPath $FilePath)) {
	Write-Host "XML file not found at '$FilePath'. Enter full path or Ctrl+C to quit." -ForegroundColor Yellow
	$FilePath = Read-Host "ISVariable.xml path"
}

if (-not (Test-Path -LiteralPath $FilePath)) { Write-Host "File not found." -ForegroundColor Red; exit 1 }

# in-memory state only
$state = [PSCustomObject]@{ variable = $variableName; lastValue = $null; lastChangeUtc = $null; firstSeenUtc = $null }

Write-Host "Monitoring '$variableName' in '$FilePath' every ${PollIntervalMs}ms. Press Ctrl+C to stop." -ForegroundColor Cyan

try {
	while ($true) {
		$xmlContent = $null
		try { $xmlContent = Get-Content -LiteralPath $FilePath -ErrorAction Stop -Raw } catch { $xmlContent = $null }
		$xmlDoc = $null
		if ($xmlContent) { try { $xmlDoc = [xml]$xmlContent } catch { $xmlDoc = $null } }

		$found = $false; $value = $null
		if ($xmlDoc) {
			$result = Get-VariableValueFromXml -XmlDoc $xmlDoc -VariableName $variableName
			$found = $result.Found
			$value = $result.Value
		}

		$nowUtc = [DateTime]::UtcNow
		if ($found) {
			if ($null -eq $state.firstSeenUtc) { $state.firstSeenUtc = $nowUtc.ToString('o') }
			if ($state.lastValue -cne $value) {
				$state.lastValue = $value
				$state.lastChangeUtc = $nowUtc.ToString('o')
			}
		}

		$lastWrite = ''
		try { $lastWrite = (Get-Item -LiteralPath $FilePath).LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss') } catch {}
		Clear-Host
		Write-Host "ISVariable Monitor" -ForegroundColor Green
		Write-Host ("-" * 50)
		Write-Host ("File: " + $FilePath)
		Write-Host ("File Last Write: " + $lastWrite)
		Write-Host ""

		$lastChangeLocal = if ($state.lastChangeUtc) { [DateTime]::Parse($state.lastChangeUtc).ToLocalTime().ToString('yyyy-MM-dd HH:mm:ss') } else { 'n/a' }
		$valDisp = if ($found) { ($value -as [string]) } else { '(not found)' }
		$chgDisp = if ($found) { $lastChangeLocal } else { 'n/a' }
		$col1Width = 30; $col2Width = 48; $col3Width = 19

		$header = (Pad-Fixed 'Variable' $col1Width) + (Pad-Fixed 'Value' $col2Width) + (Pad-Fixed 'Last Change' $col3Width)
		Write-Host $header -ForegroundColor Cyan
		Write-Host ('-' * ($col1Width + $col2Width + $col3Width))
		$row = (Pad-Fixed $variableName $col1Width) + (Pad-Fixed $valDisp $col2Width) + (Pad-Fixed $chgDisp $col3Width)
		Write-Host $row -ForegroundColor White

		Write-Host ""
		Write-Host ("Updated: " + (Get-Date).ToString('HH:mm:ss.fff')) -ForegroundColor DarkCyan

		Start-Sleep -Milliseconds $PollIntervalMs
	}
}
catch [System.Management.Automation.PipelineStoppedException] {
	Write-Host "Monitoring stopped." -ForegroundColor Yellow
}
catch {
	Write-Host ("Error: " + $_.Exception.Message) -ForegroundColor Red
}
