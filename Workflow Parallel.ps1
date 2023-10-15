workflow RunScripts {
    parallel {
        InlineScript { C:\myscript.ps1 }   
        InlineScript { C:\myotherscript.ps1 }
    }
}

#keep in mind that a workflow behaves like a function. 
#so it needs to be loaded into the cache first, and then called by running the RunScripts command.

