$folder = 'c:\PS'
"{0:N2} GB" -f ((gci –force $folder –Recurse -ErrorAction SilentlyContinue | measure Length -s).sum / 1Gb)