function New-ScriptBlockCallback {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
        param(
            [parameter(Mandatory)]
            [ValidateNotNullOrEmpty()]
            [scriptblock]$Callback
        )

        # Is this type already defined?
        if (-not ( 'CallbackEventBridge' -as [type])) {
            Add-Type @' 
                using System; 
 
                public sealed class CallbackEventBridge { 
                    public event AsyncCallback CallbackComplete = delegate { }; 
 
                    private CallbackEventBridge() {} 
 
                    private void CallbackInternal(IAsyncResult result) { 
                        CallbackComplete(result); 
                    } 
 
                    public AsyncCallback Callback { 
                        get { return new AsyncCallback(CallbackInternal); } 
                    } 
 
                    public static CallbackEventBridge Create() { 
                        return new CallbackEventBridge(); 
                    } 
                } 
'@
        }
        $bridge = [callbackeventbridge]::create()
        Register-ObjectEvent -InputObject $bridge -EventName callbackcomplete -Action $Callback -MessageData $args > $null
        $bridge.Callback
} #end of function New-ScriptBlockCallback

$requestListener = {
    [cmdletbinding()]
    param($result)

    [System.Net.HttpListener]$listener = $result.AsyncState;

    # Call EndGetContext to complete the asynchronous operation.
    $context = $listener.EndGetContext($result);

    # Capture the details about the request
    $Global:request = $context.Request
 
    # Setup a place to deliver a response
    $response = $context.Response
   
    cls
    sleep -Milliseconds 100
    Write-Host "$(Get-Date)" -f Yellow
    Write-Host "`nMethod: " -f Green -NoNewline ; Write-Host "$($request.HttpMethod)"
    Write-Host "`nUrl: " -f Green -NoNewline ; Write-Host "$($request.Url)"

    Write-Host "`nHeaders:" -NoNewline -f Green
    $headers = $request.Headers
    $headerList = New-Object PSCustomObject
    for ($i=0 ; $i -lt $headers.Count ; $i++ ) {$headerList | Add-Member -MemberType NoteProperty -Name $headers.GetKey($i) -Value $headers.GetValues($i)} 
    Write-Host ($headerList | fl | Out-String) -NoNewline
    
    #trying to read body from request stream
    if (($request.HasEntityBody) -and ($request.InputStream.CanRead)) {
        $input = $request.InputStream
        $buf = [byte[]]::new($request.ContentLength64)
        $input.Read($buf, 0, $buf.Length) | Out-Null
        Write-Host "Body:" -f Green 
        Write-Host "$([System.Text.Encoding]::Default.GetString($buf))`n"
    }


    $answer = 'Got it!' #Read-Host "What to answer?: "
    # Convert the returned data to JSON and set the HTTP content type to JSON
    #$result  = "<html><head><title>Response</title></head><body><h1>$answer</h1></body></html>"
    $result  = "$answer"
    $message = $result #| ConvertTo-Html; 
    #$response.ContentType = 'text/html'
 
    # Convert the data to UTF8 bytes
    [byte[]]$buffer = [System.Text.Encoding]::UTF8.GetBytes($message)
       
    # Set length of response
    $response.ContentLength64 = $buffer.length
       
    # Write response out and close
    $output = $response.OutputStream
    $output.Write($buffer, 0, $buffer.length)
    $output.Close()

    Write-Host "Sent Response:" -f Green 
    Write-Host "$message"
    Write-Host "--------------------------------------------------------------"

}
$createListener = {
    $port = "8000"
    $Global:listener = New-Object System.Net.HttpListener
    cls
    Write-host 'Preparing new listner...'

    while ((Get-NetTCPConnection -State Listen).LocalPort -contains $port) {$port = Read-Host "Port $port is busy, enter new port"}
    
    $host.ui.RawUI.WindowTitle = “$((Resolve-DnsName -Name ($env:computername) -Type ALL).ipaddress):$port” #changing window title to ip:port

    $listener.Prefixes.Add("http://+:$port/") 
    $listener.Start()
    Write-Host "Listening on port $port ..." -f Yellow -b Black
    #Write-Host "--------------------------------------------------------------"

    # Launch Async request callback for the first time
    $Global:context = $listener.BeginGetContext((New-ScriptBlockCallback -Callback $requestListener), $listener)
}

# Create a listener on empty port
& $createListener

do {
    #$context = $listener.GetContext() #bad method because it is synchronous.
    
    # Run new instance once the previous one gets filled by a request
    If ($context.IsCompleted -eq $true) {$context = $listener.BeginGetContext((New-ScriptBlockCallback -Callback $requestListener), $listener)}
         
    #looking for <Esc> or <R> or <Space> press
    if ($host.ui.RawUi.KeyAvailable) {
        $key=$host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown,IncludeKeyUp")
        $host.UI.RawUI.FlushInputBuffer()
        if ($key.keydown) {
            switch ($key.VirtualKeyCode) {
                <#C#> 67 {cls; }#Write-Host "--------------------------------------------------------------"}
                <#N#> 78 {}
                <#R#> 82 {Write-host 'Terminating current listner...'; $listener.Close(); sleep 1; & $createListener}
                <#Esc#> 27 {exit}
                <#Space#> 32 {Write-Host "--------------------------------------------------------------"}
                <#F1#> 112 {Write-Host "Press Esc to exit"}
            } #end switch
        }
    } #end if
} until (($key.VirtualKeyCode -eq 27) -or !($listener.IsListening))

#$listener.Stop()
Write-host 'Terminating the listner...'
$listener.Close()
sleep 1
