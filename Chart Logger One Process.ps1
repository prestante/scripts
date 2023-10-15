$Processes = 
'dotnet';
$ProcNames = $Processes -replace 'ADC1000NTCFG','CT' -replace 'ACLNT32','AC' -replace 'MCLIENT','MC' -replace 'ADC1000NT','DS'

$logfile="C:\PS\logs\Powershell $(Get-Date -Format 'yyyy-MM-dd HH-mm-ss').csv"
New-Item -Path $logfile -ItemType file -Force | Out-Null

Function Get-FileName($initialDirectory)
{
    [System.Reflection.Assembly]::LoadWithPartialName(“System.windows.forms”) | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = “All files (*.*)| *.*”
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
} #end function Get-FileName
Function mem {
    foreach ($Process in $Processes) {
        try {[int][math]::Round(((Get-Process $Process -ea Stop).WorkingSet64) / 1MB)}
        catch { 0 }
    }
}
function GD {Get-Date -Format "ddd HH:mm:ss"}
function NewGraph ($logfile,$mode='full') {
    # load appropriate assemblies
    Add-Type -assemblyName System.Windows.Forms
    Add-Type -assemblyName System.Windows.Forms.DataVisualization
    [System.Windows.Forms.Application]::EnableVisualStyles() # for text on form to look good
    $font = new-object system.drawing.font("calibri",12,[system.drawing.fontstyle]::Regular)
    
    # read screen resolution width and height
    $width = ([System.Windows.Forms.Screen]::PrimaryScreen).WorkingArea.Width - 320
    $height = ([System.Windows.Forms.Screen]::PrimaryScreen).WorkingArea.Height - 180
        
    # load header of log file
    $header = (Get-Content $logfile -TotalCount 1) -split ','

    # load all data from the log file and divide it into $width parts creating shortLog
    $content = @() ; $content += $header -join ','
    if ($mode -match 'full') {
        $lines = 0 ; Get-Content $logfile -ReadCount 1000 | % { $lines += $_.count }
        if ($lines/$width*4 -ge 2) {$i=0;$shortLog=@();$divider = [math]::Round($lines/$width*4)}
        else {$divider = 1}
        $reader = New-Object System.IO.StreamReader $logfile ; $reader.ReadLine() | Out-Null
        while ($read=$reader.ReadLine()){if($i%$divider -eq 0){$content += $read};$i++}
        $reader.Close()
    }
    if (($mode -match 'last') -or ($mode -match 'real')) {
        $content += get-content $logfile -tail ($width/4)
        if ($content[1] -eq ($header -join ',')) {$junk,$content=$content}
    }
    $shortLog = $content | ConvertFrom-Csv
    
    # create chart object
    $Chart = New-object System.Windows.Forms.DataVisualization.Charting.Chart
    $Chart.Width = $width #- 50
    $Chart.Height = $height - 70
    $Chart.Left = 0
    $Chart.Top = 0
    $Chart.BackColor = [System.Drawing.Color]::Transparent

    # create a chartarea to draw on and add to chart
    $ChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
    $Chartarea.Name = "ChartArea1"
    $ChartArea.InnerPlotPosition.Width = 96
    $ChartArea.InnerPlotPosition.Height = 95
    $ChartArea.InnerPlotPosition.X = 4
    $ChartArea.InnerPlotPosition.Y = 0
    $ChartArea.AxisX.IsStartedFromZero = $false
    $ChartArea.AxisX.IntervalAutoMode = 'VariableCount'
    $ChartArea.AxisY.IntervalAutoMode = 'VariableCount'
    $ChartArea.AxisX.MajorGrid.LineDashStyle = 'dot'
    $ChartArea.AxisY.MajorGrid.LineDashStyle = 'dot'
    $ChartArea.AxisX.MajorGrid.LineColor = 'silver'
    $ChartArea.AxisY.MajorGrid.LineColor = 'silver'
    $ChartArea.AxisX.LabelStyle.Font = $font
    $ChartArea.AxisY.LabelStyle.Font = $font
    $ChartArea.AxisX.TitleFont = $font
    $ChartArea.AxisY.TitleFont = $font
    $ChartArea.AxisY.IsLogarithmic = 1
    $ChartArea.AxisY.LogarithmBase = 2
    $ChartArea.AxisY.Minimum = 1
    $Chart.ChartAreas.Add($ChartArea)

    # create legend
    $legend = New-Object system.Windows.Forms.DataVisualization.Charting.Legend
    $legend.name = "Legend1"
    $legend.BorderColor = "#BB9944"
    $legend.DockedToChartArea = $ChartArea.Name
    $legend.Docking = 'right'
    $legend.Alignment = 'far'
    #$legend.TitleFont = $font
    $legend.Font = $font
    $Chart.Legends.Add($legend)

    # add data to chart
    $colors = 'black','limegreen','blue','red','magenta','orange','darkgray','pink'
    for ($i = 1 ; $i -lt $header.Length ; $i++ ) {
        [void]$Chart.Series.Add($header[$i])
        $Chart.Series[$header[$i]].XValueMember = $header[0]
        $Chart.Series[$header[$i]].YValueMembers = $header[$i]
        $Chart.Series[$header[$i]].ChartType = "line"
        $Chart.Series[$header[$i]].color = $colors[$i-9]
        $Chart.Series[$header[$i]].BorderDashStyle = 5 - [math]::Round(($i-4)/8,0)
        $Chart.Series[$header[$i]].ToolTip = "$($header[$i]), #AXISLABEL, #VAL"
        $Chart.Series[$header[$i]].BorderWidth = 2
    }
    $Chart.DataSource = $shortLog
    $Chart.DataBind()
    $Chart.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right -bor
                    [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
    
    # add save img button
    $SaveButton = New-Object System.Windows.Forms.Button
    $SaveButton.Text = "Save Img to Desktop"
    $SaveButton.Left = $width - 150
    $SaveButton.Top = $height - 70
    $SaveButton.Width = 125
    $SaveButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
    $SaveButton.add_click({$Chart.SaveImage([Environment]::GetFolderPath("Desktop") + "\ADCv12mem $(Get-Date -Format 'yyyy-MM-dd HH-mm-ss').tiff", "tiff")})
    
    # add timer to update Chart in real time
    if ($mode -match 'real') {
        $timer = New-Object System.Windows.Forms.Timer
        $timer.Interval = 2000
        $timer.Add_Tick({
            $content = @() ; $content += $header -join ','
            $content += get-content $logfile -tail ($width/4)
            if ($content[1] -eq ($header -join ',')) {$junk,$content=$content}
            $shortLog = $content | ConvertFrom-Csv
            $Chart.DataSource = $shortLog
            $Chart.DataBind()
        })
        $timer.Enabled = $true
    }

    # create a form and add the chart onto it
    $Form = New-Object System.Windows.Forms.Form
    $Form.Text = "Graph"
    $Form.Width = $width
    $Form.Height = $height
    $form.WindowState = 'Maximized'
    $Form.controls.add($Chart)
    $Form.controls.add($SaveButton)
    $Form.Add_Shown({$Form.Activate()})
    $Form.StartPosition = "manual"
    "Done"
    $Form.ShowDialog()
} #end of function NewGraph
function Title {
"Current logfile is in $logfile"
"Press <Enter> to build current graph (full)."
"Press <Space> to build current graph (last few minutes)."
"Press <R> to show last few minutes of current graph in real time."
"Press <O> to build full graph from external csv file."
"Press <Esc> to exit."
} #end of function Title

$table = New-Object System.Data.DataTable
$table.Columns.Add("Time","string") | Out-Null
foreach ($ProcName in $ProcNames) {
    $table.Columns.Add($ProcName,"string") | Out-Null
}
$row = $table.NewRow()
$table.Rows.Add($row)

$Title = [string]'Time'
foreach ($ProcName in $ProcNames) {
    $Title += ",$ProcName"
}
$Title | Out-File $logfile -Append utf8

#main cycle
do {
    $row.Time = GD
    $mem = mem ; $i = 0
    foreach ($ProcName in $ProcNames) {
        $row.$ProcName = $mem[$i]
        $i++
    }
    "$($row.Time),$($(foreach ($ProcName in $ProcNames){$row.$ProcName}) -join ',')" | Out-File $logfile -Append utf8
    
    cls
    Title
    $table | fl

    #looking for <Esc> or <r> or <Space> press
    if ($host.ui.RawUi.KeyAvailable) {
        $key=$host.ui.RawUI.ReadKey("NoEcho,IncludeKeyUp")
        $Host.UI.RawUI.FlushInputBuffer()
        switch ($key.VirtualKeyCode) {
            <#L#> 76 {}
            <#R#> 82 {$j = Start-job $function:NewGraph -ArgumentList @($logfile,'real')}
            <#S#> 83 {}
            <#Enter#> 13 {$j = Start-job $function:NewGraph -ArgumentList $logfile}
            <#Esc#> 27 {exit}
            <#F1#> 112 {Title}
            <#F2#> 113 {Receive-Job (Get-Job) -Keep}
            <#Space#> 32 {$j = Start-job $function:NewGraph -ArgumentList @($logfile,'last')}
            <#O#> 79 {$j = Start-job $function:NewGraph -ArgumentList (Get-FileName 'C:\PS\logs')}
        } #end switch
    } #end if
    #$Host.UI.RawUI.FlushInputBuffer()
    if (($j.state -eq 'Running') -and ((Receive-Job $j.Name -keep) -ne "Done")) {
        "Please wait. Graph is under construction..." 
    }
    Start-Sleep -milliseconds 1000
} until ($key.VirtualKeyCode -eq 27)