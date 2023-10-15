# Create a listener on port 8008
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add('http://+:8008/') 
$listener.Start()
Write-Host "Listening ..." -f Yellow -b Black

# Run until you send a GET request to /end
#do {
    $context = $listener.GetContext()
 
    # Capture the details about the request
    $request = $context.Request
 
    # Setup a place to deliver a response
    $response = $context.Response
   
    Write-Host "`nMethod: " -f Green -NoNewline ; Write-Host "$($request.HttpMethod)"
    Write-Host "`nUrl: " -f Green -NoNewline ; Write-Host "$($request.Url)"

    Write-Host "`nHeaders:" -NoNewline -f Green
    $headers = $request.Headers
    $headerList = New-Object PSCustomObject
    for ($i=0 ; $i -lt $headers.Count ; $i++ ) {$headerList | Add-Member -MemberType NoteProperty -Name $headers.GetKey($i) -Value $headers.GetValues($i)} 
    $headerList | fl

    #trying to read from request stream
    if (($request.HasEntityBody) -and ($request.InputStream.CanRead)) {
        $input = $request.InputStream
        $buf = [byte[]]::new($request.ContentLength64)
        $input.Read($buf, 0, $buf.Length) | Out-Null
        Write-Host "Body:" -f Green "$([System.Text.Encoding]::Default.GetString($buf))"
    }

    Write-Host "--------------------------------------------------------------"

    # Convert the returned data to JSON and set the HTTP content type to JSON
    $result = 'got it'
    $message = $result #| ConvertTo-Json; 
    #$response.ContentType = 'application/json';
 
    # Convert the data to UTF8 bytes
    [byte[]]$buffer = [System.Text.Encoding]::UTF8.GetBytes($message)
       
    # Set length of response
    $response.ContentLength64 = $buffer.length
       
    # Write response out and close
    $output = $response.OutputStream
    $output.Write($buffer, 0, $buffer.length)
    $output.Close()

    #looking for <Esc> or <R> or <Space> press
    if ($host.ui.RawUi.KeyAvailable) {
        $key=$host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown,IncludeKeyUp")
        $host.UI.RawUI.FlushInputBuffer()
        if ($key.keydown) {
            switch ($key.VirtualKeyCode) {
                <#C#> 67 {zero}
                <#N#> 78 {newProcs ; zero}
                <#Esc#> 27 {exit}
                <#Space#> 32 {}
                <#F1#> 112 {$infoCounter = 5}
            } #end switch
        }
    } #end if
#} until ($key.VirtualKeyCode -eq 27)

$listener.Stop()
