function Get-CRC32 {
    param(
        [Parameter(Mandatory = $False)]
        [Int]$InitialCRC = 0,
        [Parameter(Mandatory = $True)]
        [Byte[]]$Buffer
    )

    Add-Type -TypeDefinition @"
        using System;
        public static class CRC32 {
            [System.Runtime.InteropServices.DllImport("ntdll.dll")]
            public static extern UInt32 RtlComputeCrc32(
                UInt32 InitialCrc,
                Byte[] Buffer,
                Int32 Length);
        }
"@
    [CRC32]::RtlComputeCrc32($InitialCRC, $Buffer, $Buffer.Length)
}

function New-LstFile {
    param(
        [Parameter(Mandatory = $True)]
        [string]$OutputPath,
        [Parameter(Mandatory = $True)]
        [int]$NumberOfEvents,
        [Parameter(Mandatory = $True)]
        [string]$TitlePrefix
    )

    # Create array for the entire file
    $content = New-Object System.Collections.ArrayList

    # Add header
    $hexHeader60 = "50 4c 41 59 4c 49 53 54 56 45 52 31 32 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 04 2b 39 3a 17 8e e5 40"
    $byteHeader60 = $hexHeader60 -split ' ' | ForEach-Object { [byte]("0x$_") }
    foreach ($byte in $byteHeader60) {
        $content.Add($byte) | Out-Null
    }
    # $content.Add($byteHeader60) | Out-Null

    # Add 4 placeholder bytes to complete the header. Later they will be replaced with CRC32
    1..4 | ForEach-Object { $content.Add([byte]0) } | Out-Null

    for($evt = 1; $evt -le $NumberOfEvents; $evt++) {
        # Event Type (2 bytes)
        # If event number is odd - it's Primary, if even - Secondary
        $isPrimary = $evt % 2 -eq 1
        $content.Add([byte]$(if ($isPrimary) {0} else {1})) | Out-Null
        $content.Add([byte]0) | Out-Null

        # Skip 8 bytes
        1..8 | ForEach-Object { $content.Add([byte]0) } | Out-Null

        # Reconcile (32 bytes)
        $reconcile = "REC{0:d4}" -f $evt
        $reconcileBytes = [System.Text.Encoding]::ASCII.GetBytes($reconcile)
        $reconcileBytes | ForEach-Object { $content.Add($_) } | Out-Null
        1..(32 - $reconcileBytes.Length) | ForEach-Object { $content.Add([byte]0x20) } | Out-Null

        # Skip 3 bytes
        1..3 | ForEach-Object { $content.Add([byte]0) } | Out-Null

        # OAT (4 bytes) - current time
        $time = "{0:HH}:{0:mm}:{0:ss}:00" -f (Get-Date)
        $time -match '(\d\d).(\d\d).(\d\d).(\d\d)' | Out-Null
        for ($i = 3; $i -ge 0; $i--) { 
            $content.Add([byte]"0x$($Matches.($i+1))") | Out-Null 
        }

        # ID (32 bytes)
        $id = if ($isPrimary) { "PRI{0:d4}" -f $evt } else { "SEC{0:d4}" -f $evt }
        $idBytes = [System.Text.Encoding]::ASCII.GetBytes($id)
        $idBytes | ForEach-Object { $content.Add($_) } | Out-Null
        1..(32 - $idBytes.Length) | ForEach-Object { $content.Add([byte]0x20) } | Out-Null

        # Title (32 bytes)
        $title = "$TitlePrefix {0:d4}" -f $evt
        $titleBytes = [System.Text.Encoding]::ASCII.GetBytes($title)
        $titleBytes | ForEach-Object { $content.Add($_) } | Out-Null
        1..(32 - $titleBytes.Length) | ForEach-Object { $content.Add([byte]0x20) } | Out-Null

        # Add remaining fixed structure (190 bytes including SOM, DUR, etc.)
        1..190 | ForEach-Object { $content.Add([byte]0) } | Out-Null

        # Empty buffers (ResBuffer, Rating, ShowID, ShowDescr - each 2 bytes for length)
        1..8 | ForEach-Object { $content.Add([byte]0) } | Out-Null
    }

    # Calculate and update CRC32
    $crcValue = Get-CRC32 -Buffer $content[64..($content.Count-1)]
    $crcBytes = [System.BitConverter]::GetBytes($crcValue)
    for($i = 0; $i -lt 4; $i++) {
        $content[60 + $i] = $crcBytes[$i]
    }

    # Write to file
    $content | Set-Content $OutputPath -Encoding Byte
    Write-Host "Created LST file with $NumberOfEvents events at $OutputPath" -ForegroundColor Green
}

# Example usage:
New-LstFile -OutputPath "\\wtlnas1\Public\Galkovsky\Lists\!!!Generated.lst" -NumberOfEvents 2 -TitlePrefix "TEST"