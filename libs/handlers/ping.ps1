if ($Request.HttpMethod -eq 'POST' -and $Request.RawUrl -eq '/ping') 
{
    # decode the form post
    $FormContent = [System.IO.StreamReader]::new($Request.InputStream).ReadToEnd() | ConvertFrom-Json

    # We can log the request to the terminal
    write-host "$($context.Request.UserHostAddress)  =>  $($context.Request.Url)" -f 'mag'
    #Write-Host $FormContent -f 'Green'

    # Run network test and return results
    if ($FormContent.port -eq 0) {
        $TestRes = Test-NetConnection -ComputerName $FormContent.hostname -InformationLevel Detailed
    } else {
        $TestRes = Test-NetConnection -ComputerName $FormContent.hostname -Port $FormContent.port -InformationLevel Detailed
    }
    
    $result = @{
        Computername     = $TestRes.ComputerName
        RemoteAddress    = $TestRes.RemoteAddress.IpAddresstoString
        RemotePort       = $TestRes.RemotePort
        InterfaceAlias   = $TestRes.InterfaceAlias
        SourceAddress    = $TestRes.SourceAddress.IPAddress
        PingSucceeded    = $TestRes.PingSucceeded
        TcpTestSucceeded = $TestRes.TcpTestSucceeded
        RoundTripTime    = $TestRes.PingReplyDetails.RoundtripTime
        NextHop          = $TestRes.NetRoute.NextHop
    }

    # Convert response to JSON>
    [string]$resp = $Result | ConvertTo-Json 
    
    $results = @{
    StatusCode    = 200
    ResponseData  = [System.Text.Encoding]::UTF8.GetBytes($resp)
    MIME        = 'application/json'
    ConsoleOutput = "$($Request.UserHostAddress)  =>  $($Url)"
    HadError      = $false
    }
    Return $results
}