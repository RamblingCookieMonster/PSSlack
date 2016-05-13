function New-SlackMessage
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    Param
    (        
        [string]$Channel,
        [string]$Text,
        [string]$Username, 
        [string]$IconUrl, 
        [switch]$AsUser,
        [switch]$LinkNames,

        [validateset('full','none')]
        [string]$Parse = 'none',

        [validateset($True, $False)]
        [bool]$UnfurlLinks,
        
        [validateset($True, $False)]
        [bool]$UnfurlMedia,
        
        [Parameter(Mandatory=$true,
                   ValueFromPipeline = $true,
                   Position=1)]
        [System.Collections.Hashtable[]]
        $Attachments
    )
    Process
    {
    
        $body = @{}

        switch ($psboundparameters.keys) {
            'channel'     { $body.channel      = $Channel}
            'text'        { $body.text         = $text}
            'username'    { $body.username     = $username}
            'as_user'     { $body.asuser       = $AsUser}
            'iconurl'     { $body.icon_url     = $iconurl}
            'link_names'  { $body.link_names   = 1}
            'Parse'       { $body.Parse        = $Parse}
            'UnfurlLinks' { $body.Unfurl_Links = $UnfurlLinks}
            'UnfurlMedia' { $body.Unfurl_Media = $UnfurlMedia}
            'iconurl'     { $body.icon_url     = $iconurl}
            'attachments' { $body.attachments   = @($Attachments)}
        }
        $body

        #$json = $Notification | ConvertTo-Json -Depth 4
        #$json = [regex]::replace($json,'\\u[a-fA-F0-9]{4}',{[char]::ConvertFromUtf32(($args[0].Value -replace '\\u','0x'))})
        #$json = $json -replace "\\\\", "\"
    }
}