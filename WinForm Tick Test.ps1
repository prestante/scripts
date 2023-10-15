function NewGraph {
    Add-Type -assemblyName System.Windows.Forms
    Add-Type -assemblyName System.Windows.Forms.DataVisualization
    $width = ([System.Windows.Forms.Screen]::PrimaryScreen).WorkingArea.Width - 320
    $Script:i = 55

    $Form = New-Object System.Windows.Forms.Form
    $Form1 = New-Object System.Windows.Forms.Form
    $Form.Add_Shown({$Form.Activate()})
    $Form1.Add_Shown({$Form.Activate()})

    $TextBox = New-Object System.Windows.Forms.TextBox
    $TextBox.left = 100
    $TextBox.Text = $i
    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Text = 'OK'
    $OKButton.add_click({$Form.DialogResult='OK' ; $Form.Close()})
    $Form.Controls.Add($OKButton)
    $Form.Controls.Add($TextBox)

    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 1000
    $timer.Add_Tick({
        $Script:i++
        $TextBox.Text = $width
    })
    $timer.Enabled = $true


    $Form.ShowDialog()
    $Script:i
}
NewGraph
Read-Host