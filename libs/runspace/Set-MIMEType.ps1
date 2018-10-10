function Set-MIMEType {

    param([String] $File)

    $ext = $File.Split('.')[-1]

    Switch ($ext) {
        html  {$r = 'text/html'}
        jpg   {$r = 'image/jpeg'}
        jpeg  {$r = 'image/jpeg'}
        js    {$r = 'application/x-javascript'}
        css   {$r = 'text/css'}
        png   {$r = 'image/png'}
        gif   {$r = 'image/gif'}
        
        default {$r = 'text/plain'}
    }

    Return $r
}
