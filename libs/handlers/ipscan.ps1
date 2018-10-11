            # ROUTE
            # IP Scan POST handling
            if ($Request.HttpMethod -eq 'POST' -and $Request.RawUrl -eq '/ipscan') {

                # decode the form post
                $FormContent = [System.IO.StreamReader]::new($Request.InputStream).ReadToEnd() | ConvertFrom-Json

                # We can log the request to the terminal
                write-host "$($Request.UserHostAddress)  =>  $($Request.Url)" -f 'mag'
                #Write-Host $FormContent -f 'Green'

                # Run network test and return results
                $result = Invoke-IPv4Scan -StartIPv4Address $FormContent.StartIP -EndIPv4Address $FormContent.EndIP -EnableMACResolving -ExtendedInformations -OUI $Root.OUIlist 
                
                # Convert response to JSON>
                [string]$resp = $Result | ConvertTo-Json 

                $results = @{
                StatusCode    = 200
                ResponseData  = [System.Text.Encoding]::UTF8.GetBytes($resp)
                MIME          = 'application/json'
                ConsoleOutput = "$($Request.UserHostAddress)  =>  $($Url)"
                HadError      = $false
                }
                Return $results
            }