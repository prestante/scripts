'press any key to stop'
for (;;){

    
    if ($Host.UI.RawUI.KeyAvailable) {
        $key = $host.UI.RawUI.ReadKey()
        break

    }
}