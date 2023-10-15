function goForm
{
  [void][reflection.assembly]::LoadWithPartialName("System.Windows.Forms")

  $file = (get-item ($env:USERPROFILE + '\Desktop\ADCv12mem 2019-10-28 17-52-45.png'))
  
  $img = [System.Drawing.Image]::Fromfile($file);

  # This tip from http://stackoverflow.com/questions/3358372/windows-forms-look-different-in-powershell-and-powershell-ise-why/3359274#3359274
  #[System.Windows.Forms.Application]::EnableVisualStyles();
  $form = new-object Windows.Forms.Form
  $form.Text = "Image Viewer"
  $form.Width = $img.Size.Width;
  $form.Height =  $img.Size.Height;
  $pictureBox = new-object Windows.Forms.PictureBox
  $pictureBox.Width =  $img.Size.Width;
  $pictureBox.Height =  $img.Size.Height;

  $pictureBox.Image = $img;
  $form.controls.add($pictureBox)
  $form.Add_Shown( { $form.Activate() } )
  $form.ShowDialog()
}

Clear-Host

start-job $function:goForm | Out-Null

$name = Read-Host "What is you name"
Write-Host "your name is $name"