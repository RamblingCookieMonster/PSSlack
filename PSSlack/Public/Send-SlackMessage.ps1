function Send-SlackMessage {
    <#
    .SYNOPSIS
        Send a Slack message

    .DESCRIPTION
        Send a Slack message

        You can use the parameters here to build the message, or
        provide a SlackMessage created with New-SlackMessage

    .PARAMETER SlackMessage
        A SlackMessage created by New-SlackMessage

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

    [cmdletbinding(DefaultParameterSetName = 'SlackMessage')]
    param (
        [string]$Token = $Script:PSSlack.Token,
        [string]$Uri,

        [PSTypeName('PSSlack.Message')]
        [parameter(ParameterSetName = 'SlackMessage',
                   ValueFromPipeline = $True)]
        $SlackMessage,

        $Channel,

        [parameter(ParameterSetName = 'Param',
                   ValueFromPipelineByPropertyName = $True,
                   Position = 1)]
        $Text,

        [parameter(ParameterSetName = 'Param',
                   ValueFromPipelineByPropertyName = $True)]
        $Username, 

        [parameter(ParameterSetName = 'Param',
                   ValueFromPipelineByPropertyName = $True)]
        $IconUrl, 

        [parameter(ParameterSetName = 'Param',
                   ValueFromPipelineByPropertyName = $True)]
        [switch]$AsUser,

        [parameter(ParameterSetName = 'Param',
                   ValueFromPipelineByPropertyName = $True)]
        [switch]$LinkNames,

        [parameter(ParameterSetName = 'Param',
                   ValueFromPipelineByPropertyName = $True)]
        [validateset('full','none')]
        [string]$Parse = 'none',

        [parameter(ParameterSetName = 'Param',
                   ValueFromPipelineByPropertyName = $True)]
        [validateset($True, $False)]
        [bool]$UnfurlLinks,

        [parameter(ParameterSetName = 'Param',
                   ValueFromPipelineByPropertyName = $True)]
        [validateset($True, $False)]
        [bool]$UnfurlMedia,

        [parameter(ParameterSetName = 'Param',
                   ValueFromPipelineByPropertyName = $True)]
        [PSTypeName('PSSlack.MessageAttachment')]
        [System.Collections.Hashtable[]]$Attachments
    )
    begin
    {
        $Messages = @()
    }
    process
    {
        if($PSCmdlet.ParameterSetName -eq 'Param')
        {

            $body = @{ channel = $channel }
            
            switch ($psboundparameters.keys) {
                'text'        {$body.text     = $text}
                'username'    {$body.username = $username}
                'as_user'     {$body.asuser = $AsUser}
                'iconurl'     {$body.icon_url = $iconurl}
                'link_names'  {$body.link_names = 1}
                'parse'       {$body.parse = $Parse}
                'UnfurlLinks' {$body.unfurl_links = $UnfurlLinks}
                'UnfurlMedia' {$body.unfurl_media = $UnfurlMedia}
                'attachments' {$body.attachments = $Attachments}
            }
            $Messages += $Body
        }
        else
        {
            foreach($Message in $SlackMessage)
            {
                $Messages += $SlackMessage
            }
        }
    }
    end
    {
        foreach($Message in $Messages)
        {
            if($Token -or ($Script:PSSlack.Token -and -not $Uri))
            {
            
                if($Message.attachments)
                {
                    $Message.attachments = ConvertTo-Json -InputObject @($Message.attachments) -Depth 4 -Compress
                }
                
                Write-Verbose "Send-SlackApi -Body $($Message | Format-List | Out-String)"
                $response = Send-SlackApi -Method chat.postMessage -Body $Message -Token $Token
            
                if ($response.ok)
                {
                    $link = "$($Script:PSSlack.ArchiveUri)/$($response.channel)/p$($response.ts -replace '\.')"
                    $response | Add-Member -MemberType NoteProperty -Name link -Value $link
                }
            
                $response
            }
            Elseif($Uri -or $Script:PSSlack.Uri)
            {
                $json = ConvertTo-Json -Depth 4 -Compress -InputObject $Message
                Invoke-RestMethod -Method Post -Body $json -Uri $Uri
            }
            else
            {
                Throw 'No Uri or Token specified.  Specify a Uri or Token in the parameters or via Set-PSSlackConfig'
            }
        }
    }
}