# Create PSDrive for web server usage 
New-PSDrive -Name WebStore -PSProvider FileSystem -Root "$PSScriptRoot\www" | out-null
# Load Functions and modules
. $PSScriptRoot\libs\Invoke-URLInDefaultBrowser.ps1
. $PSScriptRoot\libs\Set-MIMEType.ps1

# Http Server
$http = [System.Net.HttpListener]::new() 

# Hostname and port to listen on
$http.Prefixes.Add("http://localhost:48080/")

# Start the Http Server 
    Try {
        $http.Start()
    } Catch {
        # Attempt to stop any running webserver before starting new HTTP session
        Invoke-WebRequest "http://localhost:48080/stop" -ErrorAction Stop
        $http = [System.Net.HttpListener]::new()
        $http.Prefixes.Add("http://localhost:48080/")
        $http.Start()
    }

# Log ready message to terminal 
if ($http.IsListening) {
    write-host "HTTP Server Ready!" -f 'black' -b 'green'
}

# Open index page
Invoke-URLInDefaultBrowser -URL "http://localhost:48080/index.html"

# Used to listen for requests
while ($http.IsListening) {

    # Get Request Url
    # When a request is made in a web browser the GetContext() method will return a request object
    # Our route below will use the request object properties to decide how to respond
    $context = $http.GetContext()
    
    # ROUTE
    # Load web pages from PSDrive
    if ($context.Request.HttpMethod -eq 'GET') {

        # We can log the request to the terminal
        write-host "$($context.Request.UserHostAddress)  =>  $($context.Request.Url)" -f 'mag'

        $URL = $Context.Request.Url.LocalPath
        $Content = Get-Content -Encoding Byte -Path "WebStore:$URL" -Raw
        $Context.Response.ContentType = (Set-MIMEType -File "WebStore:$URL")
        $Context.Response.OutputStream.Write($Content, 0, $Content.Length)
        $Context.Response.Close()
    
    }

    # ROUTE
    # Ping POST handling
    if ($context.Request.HttpMethod -eq 'POST' -and $context.Request.RawUrl -eq '/ping') {

        # decode the form post
        # html form members need 'name' attributes as in the example!
        $FormContent = [System.IO.StreamReader]::new($context.Request.InputStream).ReadToEnd() | ConvertFrom-Json

        # We can log the request to the terminal
        write-host "$($context.Request.UserHostAddress)  =>  $($context.Request.Url)" -f 'mag'
        Write-Host $FormContent -f 'Green'

        # Run network test and return results
        $result = Test-NetConnection -ComputerName $FormContent.hostname -Port $FormContent.port -InformationLevel Detailed -Verbose
        
        # Convert response to JSON>
        [string]$resp = $Result | ConvertTo-Json

        #resposed to the request
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($resp)
        $Context.Response.ContentType = 'application/json'
        $context.Response.ContentLength64 = $buffer.Length
        $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
        $context.Response.OutputStream.Close() 
    }

    # ROUTE 
    # STOP RUNNING HTTP Server
    if ($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -eq '/stop') {
        Write-Host "HTTP Server shutting down" -f 'black' -b 'green'

        [string]$html = "
        <h1>HTTP Server shutting down</h1>
        "

        #resposed to the request
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($html) 
        $context.Response.ContentLength64 = $buffer.Length
        $context.Response.OutputStream.Write($buffer, 0, $buffer.Length) 
        $context.Response.OutputStream.Close()
        $http.Stop()
    }

} 

