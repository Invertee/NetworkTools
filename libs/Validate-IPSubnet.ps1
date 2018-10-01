<#

 .Synopsis
   
   Validates an ipaddress is in a given subnet based on CIDR notation

.DESCRIPTION
  
  Clone to the c# code given in http://social.msdn.microsoft.com/Forums/en-US/29313991-8b16-4c53-8b5d-d625c3a861e1/ip-address-validation-using-cidr?forum=netfxnetcom

.EXAMPLE
   
   IS-InSubnet -ipaddress 10.20.20.0 -Cidr 10.20.20.0/16
 .Author
  Srinivasa Rao Tumarada
#>

Function Validate-IPSubnet {

[CmdletBinding()]
[OutputType([bool])]
Param(
                    [Parameter(Mandatory=$true,
                     ValueFromPipelineByPropertyName=$true,
                     Position=0)]
                    [validatescript({([System.Net.IPAddress]$_).AddressFamily -match 'InterNetwork'})]
                    [string]$IPADDRESS="",
                    [Parameter(Mandatory=$true,
                     ValueFromPipelineByPropertyName=$true,
                     Position=1)]
                    [validatescript({(([system.net.ipaddress]($_ -split '/'|select -first 1)).AddressFamily -match 'InterNetwork') -and (0..32 -contains ([int]($_ -split '/'|select -last 1) )) })]
                    [string]$CIDR=""
    )
Begin{
        [int]$BaseAddress=[System.BitConverter]::ToInt32((([System.Net.IPAddress]::Parse(($cidr -split '/'|select -first 1))).GetAddressBytes()),0)
        [int]$Address=[System.BitConverter]::ToInt32(([System.Net.IPAddress]::Parse($ipaddress).GetAddressBytes()),0)
        [int]$mask=[System.Net.IPAddress]::HostToNetworkOrder(-1 -shl (32 - [int]($cidr -split '/' |select -last 1)))
}
Process{
        if( ($BaseAddress -band $mask) -eq ($Address -band $mask))
        {

            $status=$True
        }else {

        $status=$False
        }
}
end { Write-output $status }
}
