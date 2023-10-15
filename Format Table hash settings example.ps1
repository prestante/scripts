#Format-Table good example
gci -force $folder | ft Name, @{ Label = "Size"; Expression={"{0:N0} KB" -f ($_.length/1KB)} ; align='right'} -HideTableHeaders