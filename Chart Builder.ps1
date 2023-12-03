param(
    [string]$logfile, # = "C:\PS\logs\18MB 2023-11-23 10-16-38.csv",
    [string]$mode = 'full'
)
$logfile = "C:\PS\logs\18MB 2023-11-23 10-16-38.csv"
#$mode = 'full'


# load appropriate assemblies
Add-Type -assemblyName System.Windows.Forms
Add-Type -assemblyName System.Windows.Forms.DataVisualization
#[System.Windows.Forms.Application]::EnableVisualStyles() # for text on form to look good
#$font = new-object system.drawing.font("calibri",12,[system.drawing.fontstyle]::Regular)

# read screen resolution width and height
#$width = ([System.Windows.Forms.Screen]::PrimaryScreen).WorkingArea.Width - 320  # for some reason it gives me 2048 instead of 2560
#$height = ([System.Windows.Forms.Screen]::PrimaryScreen).WorkingArea.Height - 180
$width = (Get-WmiObject -Class Win32_VideoController).CurrentHorizontalResolution #- 320
$height = (Get-WmiObject -Class Win32_VideoController).CurrentVerticalResolution #- 180
    
# load header of log file
$header = (Get-Content $logfile -TotalCount 1) -split ','

# load all data from the log file and divide it into $width parts creating shortLog
$content = @() ; $content += $header -join ','
if ($mode -match 'full') {
    $lines = 0 ; Get-Content $logfile -ReadCount 1000 | % { $lines += $_.count }
    if ($lines/$width -ge 2) {$i=0; $step = [math]::Round($lines/$width)}
    else {$step = 1}
    $reader = New-Object System.IO.StreamReader $logfile ; $reader.ReadLine() | Out-Null
    while ($read = $reader.ReadLine()) { if ($i % $step -eq 0) {$content += $read} ; $i++}
    $reader.Close()
}
elseif (($mode -match 'last') -or ($mode -match 'real')) {
    $content += get-content $logfile -tail ($width)  # in the 2019 I took tail of $width/4 for some reason...
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
#$ChartArea.AxisX.LabelStyle.Font = $font
#$ChartArea.AxisY.LabelStyle.Font = $font
#$ChartArea.AxisX.TitleFont = $font
#$ChartArea.AxisY.TitleFont = $font
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
#$legend.Font = $font
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
$SaveButton.Left = $width - 200
$SaveButton.Top = $height - 70
$SaveButton.Width = 160
$SaveButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
$SaveButton.add_click({
    #$imagePath = $logfile -replace '.csv$','.png'
    $imagePath = 'C:\Users\prest\OneDrive\Desktop\test.png'
    $bitmap = New-Object Drawing.Bitmap($chart.Width, $chart.Height)  # Create a bitmap

    # looks like this does not make any difference
    #$graphics = [Drawing.Graphics]::FromImage($bitmap)  # Create a Graphics object from the bitmap
    # Set rendering quality
    #$graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::HighQuality
    #$graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    #$graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    $rectangle = New-Object Drawing.Rectangle(0, 0, $chart.Width, $chart.Height)
    $chart.DrawToBitmap($bitmap, $rectangle)  # Draw the chart onto the bitmap
    $bitmap.Save($imagePath, [Drawing.Imaging.ImageFormat]::Png)  # Save the bitmap as an image file
    $bitmap.Dispose(); #$graphics.Dispose()  # Clean up resources

    #Start-Process -FilePath $imagePath
    #"Picture saved to $imagePath"
    #return
})

# add timer and PAUSE button to update Chart in real time
if ($mode -match 'real') {
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 1000
    $timer.Add_Tick({
        $content = @() ; $content += $header -join ','
        $content += get-content $logfile -tail ($width/4)
        if ($content[1] -eq ($header -join ',')) {$junk,$content=$content}
        $shortLog = $content | ConvertFrom-Csv
        $Chart.DataSource = $shortLog
        $Chart.DataBind()
    })
    $timer.Enabled = $true
    $PauseButton = New-Object System.Windows.Forms.Button
    $PauseButton.Text = "Pause/Resume"
    $PauseButton.Left = $width - 250
    $PauseButton.Top = $height - 70
    $PauseButton.Width = 95
    $PauseButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
    $PauseButton.add_click({if ($timer.Enabled){$timer.Stop()} else {$timer.Start()}})
}

# create a form and add the chart onto it
$Form = New-Object System.Windows.Forms.Form
if ($mode -match 'full') {$Form.Text = "Full Graph"}
elseif ($mode -match 'last') {$Form.Text = "Last Few Minutes Graph"}
elseif ($mode -match 'real') {$Form.Text = "Real Time Graph"}
$Form.Width = $width
$Form.Height = $height
$form.WindowState = 'Maximized'
$Form.controls.add($Chart)
$Form.controls.add($SaveButton)
if ($mode -match 'real') {$Form.controls.add($PauseButton)}
$Form.Add_Shown({$Form.Activate()})
$Form.StartPosition = "manual"
"Done"
$Form.ShowDialog()
