# Original server names
$CTC = @('WTL-ADC-CTC-01.wtldev.net', 'WTL-ADC-CTC-02.wtldev.net', 'WTL-ADC-CTC-03.wtldev.net')

# Creating a List of PSCustomObject instead of an array
$List = New-Object 'System.Collections.Generic.List[PSCustomObject]'

foreach ($server in $CTC) {
    $obj = [PSCustomObject]@{
        ServerName = $server -replace '\.wtldev\.net$'
    }
    $List.Add($obj)
}
#Updating an Element in the List:
#Now, assuming you have a $Result object like in your initial description, you can find and replace the corresponding element in the list as follows:

# Example $Result object for demonstration
$Result = [PSCustomObject]@{
    ServerName = 'WTL-ADC-CTC-02'
    Ping       = 0
    IPaddress  = '10.9.80.105'
    DSver      = ''
    DSmem      = ''
    SEver      = '5.10.3.6'
    SEmem      = '647.06'
}

# Find the index of the item to replace
$index = $List.FindIndex({ param($item) $item.ServerName -eq $Result.ServerName })
return $index

# Replace the item if found
if ($index -ne -1) {
    $List[$index] = $Result
} else {
    Write-Host "No matching server found to update."
}