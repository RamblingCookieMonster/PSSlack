function New-SlackMessage
{
    <#
    .SYNOPSIS
        Construct a new Slack message

    .DESCRIPTION
        Construct a new Slack message

        Note that this does not send a message
        It produces a message to send with Send-SlackMessage

    .PARAMETER Channel
        Channel, private group, or IM channel to send message to. Can be an encoded ID, or a name.

    .PARAMETER Text
        Text of the message to send

        See formatting spec for more information.  https://api.slack.com/docs/formatting

    .PARAMETER Username
        Set your bot's user name. Must be used in conjunction with as_user set to false, otherwise ignored

        See authorship details: https://api.slack.com/methods/chat.postMessage#authorship

    .PARAMETER IconUrl
        URL to an image to use as the icon for this message. Must be used in conjunction with as_user set to false, otherwise ignored.

        See authorship details: https://api.slack.com/methods/chat.postMessage#authorship

    .PARAMETER AsUser
        Use true to post the message as the authed user, instead of as a bot. Defaults to false.
        
        See authorship details: https://api.slack.com/methods/chat.postMessage#authorship

    .PARAMETER LinkNames
        Find and link channel names and usernames.

    .PARAMETER Parse
        Change how messages are treated. Defaults to none

        If set to full, channels like #general and usernames like @bob will be linkified.

        More details here: https://api.slack.com/docs/formatting#linking_to_channels_and_users

    .PARAMETER UnfurlLinks
        Use true to enable unfurling of primarily text-based content.

    .PARAMETER UnfurlMedia	
        Use false to disable unfurling of media content.

    .PARAMETER Attachments
        Optional rich structured message attachments.

        Provide one or more hash tables created using New-SlackMessageAttachment

        See attachments spec https://api.slack.com/docs/attachments

    .FUNCTIONALITY
        Slack
    #>
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
        [string]$Parse,

        [validateset($True, $False)]
        [bool]$UnfurlLinks,
        
        [validateset($True, $False)]
        [bool]$UnfurlMedia,
        
        [Parameter(Mandatory=$true,
                   ValueFromPipeline = $true,
                   Position=1)]
        [PSTypeName('PSSlack.MessageAttachment')]
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
        
        Add-ObjectDetail -InputObject $body -TypeName PSSlack.Message

        #$json = $Notification | ConvertTo-Json -Depth 4
        #$json = [regex]::replace($json,'\\u[a-fA-F0-9]{4}',{[char]::ConvertFromUtf32(($args[0].Value -replace '\\u','0x'))})
        #$json = $json -replace "\\\\", "\"
    }
}