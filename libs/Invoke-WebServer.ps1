Function Invoke-WebServer
{
    [CmdletBinding()]
    Param(
        [Parameter( Mandatory=$False )]
        [ValidateRange(1,65535)]
        [Int]$Port=48080,

        [Parameter( Mandatory=$False )]
        [Int]$MaxThreads = (Get-CimInstance Win32_Processor | Measure-Object -Sum -Property NumberOfLogicalProcessors).Sum      
    )
    
    Begin
    {
        $SessionState = [Management.Automation.Runspaces.InitialSessionState]::CreateDefault()

        $Functions = Get-ChildItem $Root.RunspaceFn -Filter '*.ps1'
        foreach ($Function in $Functions) {
            . $Function.FullName
        }

        Get-ChildItem Function:\ | Where-Object { $_.name -notlike "*:*" } |  select name -ExpandProperty name | ForEach-Object {       
            # Get the function code
            $Definition = Get-Content "function:\$_"
            # Create a sessionstate function with the same name and code
            $SessionStateFunction = New-Object System.Management.Automation.Runspaces.SessionStateFunctionEntry -ArgumentList "$_", $Definition
            # Add the function to the session state
            $SessionState.Commands.Add($SessionStateFunction)
        }

        # Import OUI for IPScanning
        $OUIlist = Get-Content "$($Root.RunspaceFn)\oui.txt" 

        # Opens the index page in the default browser
        Invoke-URLInDefaultBrowser -URL "http://localhost:48080/index.html"

        $Pool = [RunspaceFactory]::CreateRunspacePool(1, $MaxThreads, $SessionState, $Host)
        $Pool.ApartmentState  = 'STA'
        if ( $PSVersionTable.PSVersion.Major -gt 2 ) 
            { $Pool.CleanupInterval = 2 * [timespan]::TicksPerMinute }
        $Pool.Open()

        $Root.Listener.Prefixes.Add("http://localhost:$Port/")       

        $Root.Listener.Start()

        $Jobs = New-Object Collections.Generic.List[PSCustomObject]

        #region RequestProcessing 
        $RequestCallback = { 
            Param ( $ThreadID, $Root, $OUIListPath)

            $MIME           = ''
            $Command        = ''
            $HadError       = $false
            $ShouldStop     = $false
            $StatusCode     = 202
            $ConsoleOutput  = ''
             
            $Context  = $Root.Listener.GetContext()
            $Request  = $Context.Request
            $URL = ($Request.Url.LocalPath).Replace("/","\") 
            $URLFullPath = ($Root.WWWRoot.toString() + $URL).replace(' ','')
            $Response = $Context.Response
            $Response.Headers.Add('Server','Powershell')
            $Response.Headers.Add('X-Powered-By','Microsoft PowerShell')

            # Routes #
            # HTTP Server
            if ($Request.HttpMethod -eq 'GET')
            {
                $StatusCode    = 200
                $ResponseData  = Get-Content -Encoding Byte -Path $URLFullPath -Raw
                $MIME        = (Set-MIMEType -File $URL)
                $ConsoleOutput = "$($Request.UserHostAddress)  =>  $($Url)"
                $HadError      = $false
            }

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

                $StatusCode    = 200
                $ResponseData  = [System.Text.Encoding]::UTF8.GetBytes($resp)
                $MIME        = 'application/json'
                $ConsoleOutput = "$($Request.UserHostAddress)  =>  $($Url)"
                $HadError      = $false
            }

            # ROUTE
            # IP Scan POST handling
            if ($Request.HttpMethod -eq 'POST' -and $Request.RawUrl -eq '/ipscan') {

                # decode the form post
                $FormContent = [System.IO.StreamReader]::new($Request.InputStream).ReadToEnd() | ConvertFrom-Json

                # We can log the request to the terminal
                write-host "$($Request.UserHostAddress)  =>  $($Request.Url)" -f 'mag'
                #Write-Host $FormContent -f 'Green'

                # Run network test and return results
                $result = Invoke-IPv4Scan -StartIPv4Address $FormContent.StartIP -EndIPv4Address $FormContent.EndIP -EnableMACResolving -ExtendedInformations -OUI $OUIListPath 
                
                # Convert response to JSON>
                [string]$resp = $Result | ConvertTo-Json 

                $StatusCode    = 200
                $ResponseData  = [System.Text.Encoding]::UTF8.GetBytes($resp)
                $MIME          = 'application/json'
                $ConsoleOutput = "$($Request.UserHostAddress)  =>  $($Url)"
                $HadError      = $false
            }
            
            # Route
            # Handle requests when no files are found.
            if (!$ResponseData) 
            { 
                $StatusCode    = 404
                $ResponseData  = Get-Content -Encoding Byte -Path ($Root.WWWRoot + "\404.html") -Raw
                $MIME          = 'text/html'
                $ConsoleOutput = "$($Request.UserHostAddress)  =>  $($Url)"
                $HadError      = $false
            }

            # Routes End # 
            
            $Response.ContentType = $MIME
            $Response.OutputStream.Write($ResponseData, 0, $ResponseData.Length)
            $Response.Close()


            # Return data to console
            New-Object -TypeName PSObject -Property @{
                ThreadID      = $ThreadID
                Stop          = $ShouldStop
                HadError      = $HadError
                StatusCode    = $StatusCode
                Command       = $Command
                MIME          = $MIME
                ConsoleOutput = $ConsoleOutput
            }
        }
        #endregion
    }

    Process
    {
        # Build initial ThreadQueue
        for ($i = 0 ; $i -lt $MaxThreads ; $i++) 
        {
            $Pipeline = [PowerShell]::Create()
            $Pipeline.RunspacePool = $Pool
            [void]$Pipeline.AddScript($RequestCallback)

            # Params to pass to runspaces
            $Params =   @{ 
                ThreadID    = $i
                Root    = $Root
                OUIListPath = $OUIlist
            }
        
            [void]$Pipeline.AddParameters($Params)

            $Jobs.Add((New-Object PSObject -Property @{
                Pipeline = $Pipeline
                Job      = $Pipeline.BeginInvoke()
            }))
            
        }
        
        Write-Output "Starting Listener Threads: $($Jobs.Count)"
		
        while ($Jobs.Count -gt 0) 
        {   
            $AwaitingRequest = $true
		    while ($AwaitingRequest)
		    {                
		        if ([Console]::KeyAvailable) 
                {
                    $Key = [Console]::ReadKey($true)
                    if (($Key.Modifiers -band [ConsoleModifiers]'control') -and ($Key.Key -eq 'C'))
                    {                    
                        $Root.Listener.Stop()
                        $Root.Listener.Close()
                        $Root.Clear()
                        
                        $Jobs | Foreach {
                            [void]$_.Pipeline.EndInvoke($_.Job)
                            $_.Pipeline.Dispose()
                            $_.Job = $null
                            $_.Pipeline = $null 
                        }
                        
                        $Jobs.Clear()
                        $Pool.Close()
                        $Pool.Dispose()
                        Remove-Variable -Name Jobs -Force
                        [GC]::Collect()
                        
                        exit
                    }
                } 	    
        
                $Jobs | Foreach {
                    if ($_.Job.IsCompleted)
				    {
                        $AwaitingRequest = $False
                        $JobIndex = $Jobs.IndexOf($_)
       
                        break
				    }
                }
		    }

            $Results = $Jobs.Item($JobIndex).Pipeline.EndInvoke($Jobs.Item($JobIndex).Job)

            if ($Pipeline.HadErrors)
            {
                $Pipeline.Streams.Error.ReadAll() | 
                    Foreach { Write-Error $_ }
            }
            else 
            {
                $Results | 
                    Foreach { 
                    Write-Output "Command: $($_.Command)`r`nOutput: $($_.ConsoleOutput)`r`n"
                }
            }
            
            $Jobs.Item($JobIndex).Pipeline.Dispose()
            $Jobs.RemoveAt($JobIndex)

            $Pipeline = [PowerShell]::Create()
            $Pipeline.RunspacePool = $Pool
            [void]$Pipeline.AddScript($RequestCallback)
 
            $Params =   @{ 
                ThreadID  = $JobIndex 
                Root  = $Root
                OUIListPath = $OUIlist
            }
 
            [void]$Pipeline.AddParameters($Params)

            $Jobs.Insert($JobIndex, (New-Object PSObject -Property @{
                Pipeline = $Pipeline
                Job      = $Pipeline.BeginInvoke()
            }))
        }
    }

    End
    {
        if (-not $Pool.IsDisposed)
        {
            $Pool.Close()
            $Pool.Dispose()
        }
    }

}
