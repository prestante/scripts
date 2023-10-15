Function Get-FileName($initialDirectory)
{
    [System.Reflection.Assembly]::LoadWithPartialName(“System.windows.forms”) | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = “All files (*.*)| *.*”
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
} #end function Get-FileName
function NewGraph {
    "Preparing the graph..."
    $Global:width = 1800
    $Global:height = 800

    # load the appropriate assemblies
    Add-Type -assemblyName System.Windows.Forms
    Add-Type -assemblyName System.Windows.Forms.DataVisualization

    # create chart object
    $Global:Chart = New-object System.Windows.Forms.DataVisualization.Charting.Chart
    $Global:Chart.Width = $width - 90
    $Global:Chart.Height = $height - 70
    $Global:Chart.Left = 0
    $Global:Chart.Top = 0
    $Global:Chart.BackColor = [System.Drawing.Color]::Transparent

    # create a chartarea to draw on and add to chart
    $Global:ChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
    $Global:Chartarea.Name = "ChartArea1"
    $Global:ChartArea.InnerPlotPosition.Width = 96
    $Global:ChartArea.InnerPlotPosition.Height = 95
    $Global:ChartArea.InnerPlotPosition.X = 4
    $Global:ChartArea.InnerPlotPosition.Y = 0
    $Global:ChartArea.AxisX.Title = "Time"
    $Global:ChartArea.AxisY.Title = "Memory,MB"
    $Global:ChartArea.AxisX.IsStartedFromZero = $true
    $Global:ChartArea.AxisX.IntervalAutoMode = 'VariableCount'
    $Global:ChartArea.AxisY.IntervalAutoMode = 'VariableCount'
    $Global:ChartArea.AxisX.MajorGrid.LineDashStyle = 'dot'
    $Global:ChartArea.AxisY.MajorGrid.LineDashStyle = 'dot'
    $Global:ChartArea.AxisY.MajorGrid.LineColor = 'Gray'
    $Global:Chart.ChartAreas.Add($ChartArea)

    # legend
    $Global:legend = New-Object system.Windows.Forms.DataVisualization.Charting.Legend
    $Global:legend.name = "Legend1"
    $Global:legend.BorderColor = "#BB9944"
    $Global:legend.Position.Width = 3.8
    $Global:legend.Position.Height = 8
    $Global:legend.Position.X = 0
    $Global:legend.Position.Y = 0
    $Global:chart.Legends.Add($legend)

    # add data to chart
    [void]$Global:Chart.Series.Add("DS")
    [void]$Global:Chart.Series.Add("CT")
    [void]$Global:Chart.Series.Add("AC")
    [void]$Global:Chart.Series.Add("MC")
    $Global:Chart.Series["DS"].ChartType = "spline"
    $Global:Chart.Series["CT"].ChartType = "spline"
    $Global:Chart.Series["AC"].ChartType = "spline"
    $Global:Chart.Series["MC"].ChartType = "spline"
    $Global:Chart.Series["DS"].color = "black"
    $Global:Chart.Series["CT"].color = "green"
    $Global:Chart.Series["AC"].color = "blue"
    $Global:Chart.Series["MC"].color = "red"
    #$Global:Chart.Series["DS"].BorderWidth = 1
    #$Global:Chart.Series["CT"].BorderWidth = 1
    #$Global:Chart.Series["AC"].BorderWidth = 1
    #$Global:Chart.Series["MC"].BorderWidth = 1
    $Global:Chart.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right -bor
                    [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
    # add the chart onto the form
    $Global:Form = New-Object System.Windows.Forms.Form
    $Global:Form.Text = "Press <Space> to hide the graph or <Escape> to exit. Powershell window should be in focus."
    $Global:Form.Width = $width
    $Global:Form.Height = $height
    $Global:Form.controls.add($Chart)
    $Global:Form.Add_Shown({$Form.Activate()})

    $Global:Form.StartPosition = "manual"
    $Global:Form.Location = "25,30"
} #end of function NewGraph
function AddDataToGraph {
    "Getting data from the log file..."
    $bigData = Import-Csv $logfile
    $i = 0 ; $outData = @() ; $divider = [math]::Round($bigData.length / $Global:width) + 1
    "Building a chart..."
    $bigData | % { if ($i%$divider -eq 0) { $outData += $_ } ; $i++ }
    $Global:memoryLog = $outData
    $Global:Chart.Series["DS"].Points.DataBindXY($memoryLog.Time, $memoryLog.DS)
    $Global:Chart.Series["CT"].Points.DataBindXY($memoryLog.Time, $memoryLog.CT)
    $Global:Chart.Series["AC"].Points.DataBindXY($memoryLog.Time, $memoryLog.AC)
    $Global:Chart.Series["MC"].Points.DataBindXY($memoryLog.Time, $memoryLog.MC)
} #end of function AddDataToGraph
function SaveImage {
    "Saving graph image to your desktop..."
    $Global:Chart.SaveImage($Env:USERPROFILE + "\Desktop\ADCv12mem $(Get-Date -Format 'yyyy-MM-dd HH-mm-ss').png", "png")
} #end of function SaveImage

$logfile = Get-FileName -initialDirectory 'C:\PS\logs'
if ($logfile) { NewGraph ; AddDataToGraph ; SaveImage ; $Form.ShowDialog() }