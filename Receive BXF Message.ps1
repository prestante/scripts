# Receive, Get or Clear Message from RabbitMQ through Integration Service$IP = '10.9.37.16'#$IP = '192.168.13.169'$Port = '1985'$Dest = 'traffic' #+ $ip -replace '192.168.13.'$Get = 'http://' + $IP + ':' + $Port + '/MessageCount?destination_name=' + $Dest$Receive= 'http://' + $IP + ':' + $Port + '/ReceiveMessage?destination_name=' + $Dest
$Clear = 'http://' + $IP + ':' + $Port + '/ClearMessageBacklog?destination_name=' + $Dest#getting MessageCount ($MSGcount)$MSGcount = Invoke-RestMethod -Method 'get' -Uri $Get | where {$_ -match "<MessageCount>(?<number>.*)</MessageCount>"} | % {$matches['number']}Write-Host "MessageCount is $MSGcount" -f 14 -b 0#Receiving Message ($Answer)if ($MSGcount -ne 0) { try {$Answer = Invoke-RestMethod -Method 'post' -Uri $Receive -TimeoutSec 3} catch {Write-Host "There are no more messages" -f 14 -b 0 ; $Answer = $null}}$MSG = $Answer.BxfMessageif ($MSG) {Write-Host "$(get-date ($msg.dateTime)): " -f 15 -b 0 -NoNewline}if ($MSG.status -eq 'error') { Write-Host "$($MSG.errorDescription)" -f 12 -b 0 }elseif ($MSG.status -eq 'warning') { Write-Host "$($MSG.errorDescription)" -f 13 -b 0 }elseif (($MSG.status -eq 'OK') -or ($MSG.status -eq $null)) {     Write-Host "$($MSG.status)" -f 15 -b 0     if ($MSG.usage -match 'AsRun') {        $AsRunsTable = New-Object System.Data.DataTable
        $AsRunsTable.Columns.Add("StartDate","string") | Out-Null
        $AsRunsTable.Columns.Add("StartTime","string") | Out-Null
        $AsRunsTable.Columns.Add("Status","string") | Out-Null
        $AsRunsTable.Columns.Add("Type","string") | Out-Null
        $AsRunsTable.Columns.Add("HouseNumber","string") | Out-Null
        $AsRunsTable.Columns.Add("Title","string") | Out-Null
        $AsRunsTable.Columns.Add("Duration","string") | Out-Null
        $AsRunsTable.Columns.Add("EventID","string") | Out-Null

        $bxf = if ($MSG.BxfQueryResponse) {$MSG.BxfQueryResponse} 
            elseif ($MSG.BxfData) {$MSG.BxfData}
        $bxf.Schedule.AsRun | %{
            $row = $AsRunsTable.NewRow()
            $row.EventID = $_.BasicAsRun.AsRunEventId.EventId -replace 'urn:uuid:'
            $row.HouseNumber = $_.BasicAsRun.Content.ContentId.HouseNumber
            $row.Title = $_.BasicAsRun.Content.Name.'#text'
            $row.Status = $_.BasicAsRun.AsRunDetail.Status
            $row.Type = $_.BasicAsRun.AsRunDetail.Type
            $row.StartDate = $_.BasicAsRun.asrundetail.StartDateTime.SmpteDateTime.broadcastDate
            $row.StartTime = $_.BasicAsRun.asrundetail.StartDateTime.SmpteDateTime.SmpteTimeCode
            $row.Duration = $_.BasicAsRun.asrundetail.Duration.SmpteDuration.SmpteTimeCode
    
            $AsRunsTable.Rows.Add($row)
        }

        if ($MSG.usage -eq 'AsRun Query Reply') {Write-Host "AsRun Query Reply for channel $($bxf.Schedule.Channel.Name.'#text') ($($bxf.Schedule.AsRun.Count) items):" -f 10 -b 0}
        if ($MSG.usage -eq 'AsRun') {Write-Host "AsRun message for channel $($bxf.Schedule.Channel.Name.'#text'):" -f 10 -b 0}
    
        $ResultingList = New-Object System.Collections.Generic.List[System.Object]
        if ($bxf.Schedule.AsRun.Count -le 34) {$ResultingList += $AsRunsTable | select -First 34 | select -Property $AsRunsTable.Columns.Caption}
        if ($bxf.Schedule.AsRun.Count -gt 34) {
            $ResultingList += $AsRunsTable | select -First 16 | select -Property $AsRunsTable.Columns.Caption
            (1..2) | %{$ResultingList += [pscustomobject]@{$AsRunsTable.Columns.Caption[0]='.....'} | select -Property $AsRunsTable.Columns.Caption}
            $ResultingList += $AsRunsTable | select -Last 16 | select -Property $AsRunsTable.Columns.Caption
        }
        $ResultingList | ft -Property $AsRunsTable.Columns.Caption
    }    elseif ($MSG.usage -match 'Playlist Query') {        $PlaylistTable = New-Object System.Data.DataTable
        $PlaylistTable.Columns.Add("StartDate","string") | Out-Null
        $PlaylistTable.Columns.Add("StartTime","string") | Out-Null
        $PlaylistTable.Columns.Add("Type","string") | Out-Null
        $PlaylistTable.Columns.Add("HouseNumber","string") | Out-Null
        $PlaylistTable.Columns.Add("Seg","string") | Out-Null
        $PlaylistTable.Columns.Add("Title","string") | Out-Null
        $PlaylistTable.Columns.Add("Duration","string") | Out-Null
        $PlaylistTable.Columns.Add("EventID","string") | Out-Null

        $bxf = if ($MSG.BxfQueryResponse) {$MSG.BxfQueryResponse} 
            elseif ($MSG.BxfData) {$MSG.BxfData}
        $bxf.Schedule.ScheduledEvent | %{
            $row = $PlaylistTable.NewRow()
            $row.StartDate = $_.EventData.StartDateTime.SmpteDateTime.broadcastDate
            $row.StartTime = $_.EventData.StartDateTime.SmpteDateTime.SmpteTimeCode
            $row.Type = $_.EventData.NonPrimaryEvent.NonPrimaryEventName
            $row.HouseNumber = $_.Content.ContentID.HouseNumber
            $row.Seg = $_.EventData.PrimaryEvent.ProgramEvent.SegmentNumber
            $row.Title = $_.Content.Name.'#text'
            $row.Duration = $_.EventData.LengthOption.Duration.SmpteDuration.SmpteTimeCode
            $row.EventID = $_.EventData.EventId.EventId -replace 'urn:uuid:'
    
            $PlaylistTable.Rows.Add($row)
        }

        Write-Host "$($MSG.usage) for channel $($MSG.BxfQueryResponse.Schedule.Channel.Name.'#text') ($($MSG.BxfQueryResponse.Schedule.ScheduledEvent.Count) items):" -f 10 -b 0    
    
        $ResultingList = New-Object System.Collections.Generic.List[System.Object]
        if ($bxf.Schedule.ScheduledEvent.Count -le 34) {$ResultingList += $PlaylistTable | select -First 34 | select -Property $PlaylistTable.Columns.Caption}
        if ($bxf.Schedule.ScheduledEvent.Count -gt 34) {
            $ResultingList += $PlaylistTable | select -First 16 | select -Property $PlaylistTable.Columns.Caption
            (1..2) | %{$ResultingList += [pscustomobject]@{$PlaylistTable.Columns.Caption[0]='.....'} | select -Property $PlaylistTable.Columns.Caption}
            $ResultingList += $PlaylistTable | select -Last 16 | select -Property $PlaylistTable.Columns.Caption
        }
        $ResultingList | ft -Property $PlaylistTable.Columns.Caption
    }    elseif ($MSG.BxfData.InnerXml) { "$($MSG.BxfData.InnerXml)" }}elseif ($MSG.status) { Write-Host "$($MSG.status)" -f 11 -b 0 }$AnswerBackup = $Answer$Answer = $nullreturnInvoke-RestMethod -Method 'post' -Uri $Clear