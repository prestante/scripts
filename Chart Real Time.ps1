function Update($Chart)
{
    $memoryLog = Import-Csv $file
    $Chart.Series["DS"].Points.DataBindXY($memoryLog.Time, $memoryLog.DS)
    $Chart.Series["CT"].Points.DataBindXY($memoryLog.Time, $memoryLog.CT)
    $Chart.Series["AC"].Points.DataBindXY($memoryLog.Time, $memoryLog.AC)
    $Chart.Series["MC"].Points.DataBindXY($memoryLog.Time, $memoryLog.MC)
    $Chart.Series["PL"].Points.DataBindXY($memoryLog.Time, $memoryLog.PL)

}
Function Get-FileName($initialDirectory)
{
    [System.Reflection.Assembly]::LoadWithPartialName(“System.windows.forms”) | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = “All files (*.*)| *.*”
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
} #end function Get-FileName
$width = 1800
$height = 800
#$file = get-filename -initialDirectory 'C:\PS\logs'
$file = (gci 'C:\PS\logs\' -Filter *.csv | Sort-Object -Property LastWriteTime | select -Last 1).fullname
$memoryLog = Import-Csv $file

# load the appropriate assemblies
Add-Type -assemblyName System.Windows.Forms
Add-Type -assemblyName System.Windows.Forms.DataVisualization

# create chart object
$Chart = New-object System.Windows.Forms.DataVisualization.Charting.Chart
$Chart.Width = $width - 90
$Chart.Height = $height - 70
$Chart.Left = 0
$Chart.Top = 0
# change chart area colour
$Chart.BackColor = [System.Drawing.Color]::Transparent

# create a chartarea to draw on and add to chart
$ChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
$Chartarea.Name = "ChartArea1"
$ChartArea.InnerPlotPosition.Width = 96
$ChartArea.InnerPlotPosition.Height = 95
$ChartArea.InnerPlotPosition.X = 4
$ChartArea.InnerPlotPosition.Y = 0
$ChartArea.AxisX.Title = "Time"
$ChartArea.AxisY.Title = "Memory,MB"
#$chartarea.AxisY.Interval = 100
#$chartarea.AxisX.Interval = 1800
$ChartArea.AxisX.IsStartedFromZero = $true
$ChartArea.AxisX.IntervalAutoMode = 'VariableCount'
$ChartArea.AxisY.IntervalAutoMode = 'VariableCount'
$Chart.ChartAreas.Add($ChartArea)

# add title and axes labels
#$Chart.Titles.Add("Top 5 European Cities by Population")

# legend
$legend = New-Object system.Windows.Forms.DataVisualization.Charting.Legend
$legend.name = "Legend1"
$legend.BorderColor = "#BB9944"
$legend.Position.Width = 3.8
$legend.Position.Height = 10
$legend.Position.X = 0
$legend.Position.Y = 0
$chart.Legends.Add($legend)

# add data to chart
[void]$Chart.Series.Add("DS")
[void]$Chart.Series.Add("CT")
[void]$Chart.Series.Add("AC")
[void]$Chart.Series.Add("MC")
[void]$Chart.Series.Add("PL")
$Chart.Series["DS"].ChartType = "line"
$Chart.Series["CT"].ChartType = "line"
$Chart.Series["AC"].ChartType = "line"
$Chart.Series["MC"].ChartType = "line"
$Chart.Series["PL"].ChartType = "line"
$Chart.Series["DS"].color = "#111111" #black
$Chart.Series["CT"].color = "#BBBBBB" #gray
$Chart.Series["AC"].color = "#52A5FF" #blue
$Chart.Series["MC"].color = "#FF2626" #red
$Chart.Series["PL"].color = "#f29122" #orange
$Chart.Series["DS"].BorderWidth = 3
$Chart.Series["CT"].BorderWidth = 3
$Chart.Series["AC"].BorderWidth = 3
$Chart.Series["MC"].BorderWidth = 3
$Chart.Series["PL"].BorderWidth = 3
$Chart.Series["DS"].Points.DataBindXY($memoryLog.Time, $memoryLog.DS)
$Chart.Series["CT"].Points.DataBindXY($memoryLog.Time, $memoryLog.CT)
$Chart.Series["AC"].Points.DataBindXY($memoryLog.Time, $memoryLog.AC)
$Chart.Series["MC"].Points.DataBindXY($memoryLog.Time, $memoryLog.MC)
$Chart.Series["PL"].Points.DataBindXY($memoryLog.Time, $memoryLog.PL)

# display the chart on a form
$Chart.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right -bor
                [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$Form = New-Object Windows.Forms.Form
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000
$timer.Add_Tick({Update $Chart})
$timer.Enabled = $true
$Form.Text = "PowerShell Chart"
$Form.Width = $width
$Form.Height = $height
$Form.controls.add($Chart)
$Form.Add_Shown({$Form.Activate()})

# add a save button
$SaveButton = New-Object Windows.Forms.Button
$SaveButton.Text = "Save"
$SaveButton.Top = $height - 70
$SaveButton.Left = $width - 100
$SaveButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
$SaveButton.add_click({$Chart.SaveImage($Env:USERPROFILE + "\Desktop\Chart.png", "PNG")})
$Form.controls.add($SaveButton)
#$Chart.SaveImage($Env:USERPROFILE + "\Desktop\Chart.png", "png")
$Form.ShowDialog()