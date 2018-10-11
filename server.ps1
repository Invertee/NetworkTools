$Root                 = [Hashtable]::Synchronized(@{})
$Root.ScriptDirectory = "$PSScriptRoot\libs"
$Root.Handlers        = "$PSScriptRoot\libs\handlers"  
$Root.RunspaceFn      = "$PSScriptRoot\libs\Runspace"
$Root.WWWRoot         = "$PSScriptRoot\www" 

Get-ChildItem ("$($Root.ScriptDirectory)\*.ps1") | 
    ForEach { . $_.FullName }

Try
{
    $Root.Listener = New-Object Net.HttpListener
    Invoke-WebServer -Port 48080
}
catch 
{ 
    Write-Error "An error occurred" 
    $_.Exception.Message    
}
finally 
{ 
    $Root.Listener.Stop() 
}
