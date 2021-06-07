function Send-SlackMessage {
    <#
    .SYNOPSIS
        Send a Slack message

    .DESCRIPTION
        Send a Slack message

        You can use the parameters here to build the message, or
        provide a SlackMessage created with New-SlackMessage

    .PARAMETER Token
        Token to use for the Slack API

        Default value is the value set by Set-PSSlackConfig

        This takes precedence over Uri

    .PARAMETER Uri
        Uri to use for an incoming webhook

        Default value is the value set by Set-PSSlackConfig

        If Token is set, this is ignored

    .PARAMETER Proxy
        Proxy server to use

        Default value is the value set by Set-PSSlackConfig

    .PARAMETER SlackMessage
        A SlackMessage created by New-SlackMessage

    .PARAMETER Channel
        Channel, private group, or IM channel to send message to. Can be an encoded ID, or a name.

    .PARAMETER Text
        Text of the message to send

        See formatting spec for more information.  https://api.slack.com/docs/formatting

    .PARAMETER Username
        Set your bot's user name.

        If using a Token, must be used in conjunction with as_user set to false, otherwise ignored

        See authorship details: https://api.slack.com/methods/chat.postMessage#authorship

    .PARAMETER Thread
        The id of the parent message you want to thread. This is usually seen as ts or thread_ts in a response.

        Can find a ts by querying https://api.slack.com/methods/conversations.history

    .PARAMETER IconUrl
        URL to an image to use as the icon for this message.

        If using a Token, must be used in conjunction with as_user set to false, otherwise ignored.

        See authorship details: https://api.slack.com/methods/chat.postMessage#authorship

    .PARAMETER IconEmoji
        Emoji to use as the icon for this message.
        Overrides icon_url.

        Must be used in conjunction with as_user set to false, otherwise ignored

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

    .PARAMETER ForceVerbose
        If specified, don't explicitly remove verbose output from Invoke-RestMethod

        *** WARNING ***
        This will expose your token in verbose output

    .EXAMPLE
        # This example shows a crudely crafted message without any attachments,
        # using parameters from Send-SlackMessage to construct the message.

        #Previously set up Uri from https://<YOUR TEAM>.slack.com/apps/A0F7XDUAZ
        $Uri = "Some incoming webhook uri from Slack"

        Send-SlackMessage -Uri $Uri `
                          -Channel '@wframe' `
                          -Parse full `
                          -Text 'Hello @wframe, join me in #devnull!'

        # Send a message to @wframe (not a channel), parsing the text to linkify usernames and channels

    .EXAMPLE
        # This is a simple example illustrating some common options
        # when constructing a message attachment
        # giving you a richer message
        $Token = 'A token. maybe from https://api.slack.com/docs/oauth-test-tokens'

        New-SlackMessageAttachment -Color $_PSSlackColorMap.red `
                                   -Title 'The System Is Down' `
                                   -TitleLink https://www.youtube.com/watch?v=TmpRs7xN06Q `
                                   -Text 'Please Do The Needful' `
                                   -Pretext 'Everything is broken' `
                                   -AuthorName 'SCOM Bot' `
                                   -AuthorIcon 'http://ramblingcookiemonster.github.io/images/tools/wrench.png' `
                                   -Fallback 'Your client is bad' |
            New-SlackMessage -Channel '@wframe' `
                             -IconEmoji :bomb: |
            Send-SlackMessage -Token $Token

        # Create a message attachment with details about an alert
        # Attach this to a slack message sending to the devnull channel
        # Send the newly created message using a token

    .EXAMPLE
        # This example demonstrates that you can chain new attachments
        # together to form a multi-attachment message

        $Token = 'A token. maybe from https://api.slack.com/docs/oauth-test-tokens'

        New-SlackMessageAttachment -Color $_PSSlackColorMap.red `
                                   -Title 'The System Is Down' `
                                   -TitleLink https://www.youtube.com/watch?v=TmpRs7xN06Q `
                                   -Text 'Everybody panic!' `
                                   -Pretext 'Everything is broken' `
                                   -Fallback 'Your client is bad' |
            New-SlackMessageAttachment -Color $_PSSlackColorMap.orange `
                                       -Title 'The Other System Is Down' `
                                       -TitleLink https://www.youtube.com/watch?v=TmpRs7xN06Q `
                                       -Text 'Please Do The Needful' `
                                       -Fallback 'Your client is bad' |
            New-SlackMessage -Channel '@wframe' `
                             -IconEmoji :bomb: `
                             -AsUser `
                             -Username 'SCOM Bot' |
            Send-SlackMessage -Token $Token

        # Create an attachment, create another attachment,
        # add these to a message,
        # and send with a token

    .EXAMPLE

        # This example illustrates a pattern where you might
        # want to send output from a script; you might
        # include errors, successful items, or other output

        # Pretend we're in a script, and caught an exception of some sort
        $Fail = [pscustomobject]@{
            samaccountname = 'bob'
            operation = 'Remove privileges'
            status = "An error message"
            timestamp = (Get-Date).ToString()
        }

        # Create an array from the properties in our fail object
        $Fields = @()
        foreach($Prop in $Fail.psobject.Properties.Name)
        {
            $Fields += @{
                title = $Prop
                value = $Fail.$Prop
                short = $true
            }
        }

        $Token = 'A token. maybe from https://api.slack.com/docs/oauth-test-tokens'

        # Construct and send the message!
        New-SlackMessageAttachment -Color $_PSSlackColorMap.orange `
                                   -Title 'Failed to process account' `
                                   -Fields $Fields `
                                   -Fallback 'Your client is bad' |
            New-SlackMessage -Channel 'devnull' |
            Send-SlackMessage -Uri $uri

        # We build up a pretend error object, and send each property to a 'Fields' array
        # Creates an attachment with the fields from our error
        # Creates a message fromthat attachment and sents it with a uri

    .NOTES

    ON AUTHORIZATION:

        We don't get fancy with ParameterSets.  Here's a breakdown of how we pick Uri or Token:

            Parameters are used before Set-PSSlackConfig settings
            Tokens are used before Uri

            Examples:
                Uri parameter specified, token exists in Set-PSSlackConfig: Uri is used
                Uri and token exist in Set-PSSlackConfig: token is used
                Token and Uri parameters are specified: Token is used

    ON OUTPUT:

        The Slack API and Incoming Webhook alter the output Send-SlackMessage will provide.

        If you use a Uri for an Incoming Webhook, Slack will return a string:
           "ok" if the call succeeded
           An error string if something went wrong

        If you use a token, we get a bit more detail back:
            ok      : True
            channel : D0ST7FE6Q
            ts      : 1463254594.000027
            message : @{text=; username=Slack API Tester; icons=; attachments=System.Object[]; type=message;...
            link    : ArchiveUri.From.Set-PSSlackConfig/D0ST7FE6Q/p1463254594000027

        If you use a token and things don't go so well, the OK field will not be true:
            ok      error
            --      -----
            False   channel_not_found

    .FUNCTIONALITY
        Slack
    #>

    [cmdletbinding(DefaultParameterSetName = 'SlackMessage')]
    param (

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Token = $Script:PSSlack.Token,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Uri = $Script:PSSlack.Uri,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Proxy = $Script:PSSlack.Proxy,

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
        $Thread,

        [parameter(ParameterSetName = 'Param',
                   ValueFromPipelineByPropertyName = $True)]
        $IconUrl,

        [parameter(ParameterSetName = 'Param',
                   ValueFromPipelineByPropertyName = $True)]
        $IconEmoji,

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
        [System.Collections.Hashtable[]]$Attachments,

        [switch]$ForceVerbose = $Script:PSSlack.ForceVerbose
    )
    begin
    {
        Write-Debug "Send-SlackMessage Bound parameters: $($PSBoundParameters | Remove-SensitiveData | Out-String)`nParameterSetName $($PSCmdlet.ParameterSetName)"
        $Messages = @()
        $ProxyParam = @{}
        if($Proxy)
        {
            $ProxyParam.Proxy = $Proxy
        }
    }
    process
    {
        if($PSCmdlet.ParameterSetName -eq 'Param')
        {
            $body = @{ }

            switch ($psboundparameters.keys)
            {
                'channel'     {$body.channel = $channel }
                'text'        {$body.text     = $text}
                'thread'      {$body.thread_ts = $Thread}
                'username'    {$body.username = $username}
                'asuser'      {$body.as_user = $AsUser}
                'iconurl'     {$body.icon_url = $iconurl}
                'iconemoji'   {$body.icon_emoji   = $iconemoji}
                'linknames'   {$body.link_names = 1}
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
                    $Message.attachments = ConvertTo-Json -InputObject @($Message.attachments) -Depth 6 -Compress
                }

                Write-Verbose "Send-SlackApi -Body $($Message | Format-List | Out-String)"
                $response = Send-SlackApi @ProxyParam -Method chat.postMessage -Body $Message -Token $Token -ForceVerbose:$ForceVerbose

                if ($response.ok)
                {
                    $link = "$($Script:PSSlack.ArchiveUri)/$($response.channel)/p$($response.ts -replace '\.')"
                    $response | Add-Member -MemberType NoteProperty -Name link -Value $link
                }

                $response
            }
            elseif($Uri -or $Script:PSSlack.Uri)
            {
                if(-not $ForceVerbose) {
                    $ProxyParam.Add('Verbose', $False)
                }
                if($ForceVerbose) {
                    $ProxyParam.Add('Verbose', $true)
                }
                $json = ConvertTo-Json -Depth 6 -Compress -InputObject $Message
                Invoke-RestMethod @ProxyParam -Method Post -Body $json -Uri $Uri
            }
            else
            {
                Throw 'No Uri or Token specified.  Specify a Uri or Token in the parameters or via Set-PSSlackConfig'
            }
        }
    }
}
