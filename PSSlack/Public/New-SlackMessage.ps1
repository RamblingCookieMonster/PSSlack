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
        URL to an image to use as the icon for this message.

        If using a token, must be used in conjunction with as_user set to false, otherwise ignored.

        See authorship details: https://api.slack.com/methods/chat.postMessage#authorship

    .PARAMETER IconEmoji
        Emoji to use as the icon for this message.
        Overrides icon_url.

        If using a token, must be used in conjunction with as_user set to false, otherwise ignored

    .PARAMETER AsUser
        Use true to post the message as the authed user, instead of as a bot. Defaults to false.

        Only used when authorizing with a token

        See authorship details: https://api.slack.com/methods/chat.postMessage#authorship

    .PARAMETER LinkNames
        Find and link channel names and usernames.

    .PARAMETER Thread
        Optional thread where file is sent. Needs to be the parent thread id which is either the ts or thread_ts.

        Can find a ts by querying https://api.slack.com/methods/conversations.history

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

    .FUNCTIONALITY
        Slack
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable],[String])]
    Param
    (
        [string]$Channel,
        [string]$Text,
        [string]$Username,
        [string]$IconUrl,
        [string]$IconEmoji,
        [switch]$AsUser,
        [switch]$LinkNames,
        [string]$Thread,

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
    Begin
    {
        $AllAttachments = @()
    }
    Process
    {
        foreach($Attachment in $Attachments)
        {
            $AllAttachments += $Attachment
        }
    }
    End
    {
        $body = @{}

        switch ($psboundparameters.keys) {
            'channel'     { $body.channel      = $Channel}
            'text'        { $body.text         = $text}
            'username'    { $body.username     = $username}
            'asuser'     { $body.as_user       = $AsUser}
            'iconurl'     { $body.icon_url     = $iconurl}
            'iconemoji'   { $body.icon_emoji   = $iconemoji}
            'linknames'   { $body.link_names   = 1}
            'thread'      {$body.thread_ts = $Thread}
            'Parse'       { $body.Parse        = $Parse}
            'UnfurlLinks' { $body.Unfurl_Links = $UnfurlLinks}
            'UnfurlMedia' { $body.Unfurl_Media = $UnfurlMedia}
            'iconurl'     { $body.icon_url     = $iconurl}
            'attachments' { $body.attachments   = @($AllAttachments)}
        }

        Add-ObjectDetail -InputObject $body -TypeName PSSlack.Message
    }
}
