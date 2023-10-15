#remove all .log and .html files in folders, which were modified 15 days ago and earlier

gci 'c:\aclient\' -recurse -include *.log, *.html -force | where {$_.lastwritetime -lt (get-date).adddays(-15)} | remove-item -force
gci 'c:\mclient\' -recurse -include *.log, *.html -force | where {$_.lastwritetime -lt (get-date).adddays(-15)} | remove-item -force
gci 'c:\config\' -recurse -include *.log, *.html -force | where {$_.lastwritetime -lt (get-date).adddays(-15)} | remove-item -force
gci 'c:\server\' -recurse -include *.log, *.html -force | where {$_.lastwritetime -lt (get-date).adddays(-15)} | remove-item -force