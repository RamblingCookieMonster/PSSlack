#Borrowed from https://github.com/jgigler/Powershell.Slack - thanks @jgigler et al!
function New-SlackMessageAttachment
{
    <#
    .SYNOPSIS
        Creates a rich notification (Attachment) to use in a Slack message.

    .DESCRIPTION
        Creates a rich notification (Attachment) to use in a Slack message.

        Used to create Atachment message payloads for Slack.
        Attachemnts are a way of crafting richly-formatted messages in Slack.
        They can be as simple as a single plain text message,
            to as complex as a multi-line message with pictures, links and tables. 

    .PARAMETER Fallback
        A plain-text summary of the attachment. This text will be used in clients that don't show formatted text (eg. IRC, mobile notifications) and should not contain any markup.

    .PARAMETER Severity
        This value is used to color the border along the left side of the message attachment. This parameter cannot be used in conjunction with the "Color" parameter.

        Only good, bad and warning are accepted by this parameter.

    .PARAMETER Color
        This value is used to color the border along the left side of the message attachment.

        There are two options for this value:

            Use Hex Web Colors to define the color. e.g. -Color #FF0000
            Use $_PSSlackColorMap.                  e.g. -Color $_PSSlackColorMap.orange

            See $_PSSlackColorMap for a full list of colors.

        This parameter cannot be used in conjuction with the Severity Parameter.

    .PARAMETER Pretext
        This is optional text that appears above the message attachment block.

    .PARAMETER AuthorName
        Small text used to display the author's name.

    .PARAMETER AuthorLink
        A valid URL that will hyperlink the AuthorName text mentioned above.

        Will only work if AuthorName is present.

    .PARAMETER AuthorIcon
        A valid URL that displays a small 16x16px image to the left of the AuthorName text.

        Will only work if AuthorName is present.

    .PARAMETER Title
        The title is displayed as larger, bold text near the top of the message attachment.

    .PARAMETER TitleLink
        If the title link is specified then it turns the Title into a hyperlink that the user can click. 

    .PARAMETER Text
        This is the main text in a message attachment, and can contain standard message markup.
        Not to be confused with Pretext which would appear above this.

    .PARAMETER ImageURL
        A valid URL to an image file that will be displayed inside a message attachment.

    .PARAMETER ThumbURL
        A valid URL to an image file that will be displayed as a thumbnail on the right side of a message attachment.

    .PARAMETER Fields
        One or more hashtables contained provided here will be displayed in a table inside the message attachment.

        Each hashtable provided must contain a "title" key and a "value" key.
        Optionally it may also contain "Short" which is a boolean parameter.

    .PARAMETER Actions
        A collection of actions (buttons or menus) to include in the attachment. 
        Required when using message buttons or message menus. A maximum of 5 actions per attachment may be provided.
        Actions can be created with the New-SlackAction command

    .PARAMETER CallbackId
        The provided string will act as a unique identifier for the collection of buttons within the attachment. 
        It will be sent back to your message button action URL with each invoked action. 
        This field is required when the attachment contains message buttons. 
        It is key to identifying the interaction you're working with.

    .PARAMETER MarkDownFields
        One or more fields (text, pretext, fields) to enable markdown-esque formatting in.

        The formatting is described here: https://get.slack.help/hc/en-us/articles/202288908-How-can-I-add-formatting-to-my-messages-

    .PARAMETER ExistingAttachment
        One or more attachments to add this attachment to.

        Allows you to chain calls to this function:
            New-SlackMessageAttachment ... | New-SlackMessageAttachment ...

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
            Send-SlackMessage -Token $Token

        # We build up a pretend error object, and send each property to a 'Fields' array
        # Creates an attachment with the fields from our error
        # Creates a message fromthat attachment and sents it with a uri

    .EXAMPLE

        # This example illustrates a pattern where you might
        # want to add an action (button or menu) to your Slack attachment.
        # This can be useful when working with Slack bots or integrations that
        # make calls out with the action data

        # Create an action using the New-SlackAction command
        $action = New-SlackAction -Name Acknowledge -Text Acknowledge -Type button

        $WebhookUri = "https://hooks.slack.com/services/SomeUniqueId"

        # Construct and send the message!
        New-SlackMessageAttachment -Color $_PSSlackColorMap.orange `
                                   -Title 'Failed to process account' `
                                   -Actions $action `
                                   -Fallback 'Your client is bad' |
            New-SlackMessage |
            Send-SlackMessage -Uri $WebhookUri

        # We create an action object with an 'Acknowledge' button
        # Creates an attachment with the button created in the action object
        # Creates a message from that attachment and sents it with a uri

    .LINK
        https://github.com/RamblingCookieMonster/PSSlack

    .LINK
        https://api.slack.com/docs/attachments

    .LINK
        https://api.slack.com/docs/interactive-message-field-guide

    .LINK
        https://api.slack.com/methods/chat.postMessage
    #>
    [CmdletBinding(DefaultParameterSetName='Severity')]
    [OutputType([System.Collections.Hashtable])]
    Param
    (
        [Parameter(ValueFromPipeline = $True)]
        [PSTypeName('PSSlack.MessageAttachment')]
        $ExistingAttachment,

        [Parameter(Mandatory=$true,
                   Position=0)]
        [String]$Fallback,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Severity')]
        [ValidateSet("good",
                     "warning",
                     "danger")]
        [String]$Severity,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Color')]
        [Alias("Colour")]
        $Color,

        [String]$AuthorName,
        [String]$Pretext,
        [String]$AuthorLink,
        [String]$AuthorIcon,
        [String]$Title,
        [String]$TitleLink,
        [Parameter(Position=1)]
        [String]$Text,
        [String]$ImageURL,
        [String]$ThumbURL,
        [validatescript({
            foreach($key in $_.keys){
                if('title', 'short', 'value' -notcontains $key)
                {
                    throw "$Key is invalid, must be 'title', 'value', or 'short'"
                }
            }
            $true
        })]
        [System.Collections.Hashtable[]]$Fields,
        [System.Collections.Hashtable[]]$Actions,
        [string]$CallBackId,
        [validateset('text','pretext','fields')]
        [string[]]$MarkDownFields # https://get.slack.help/hc/en-us/articles/202288908-How-can-I-add-formatting-to-my-messages-
    )

    Begin
    {
        if(-not $Actions -and $CallBackId)
        {
            throw "The Actions parameter is required when the CallbackId parameter is used"
        }
        elseif(-not $CallBackId -and $Actions)
        {
            throw "The CallBackId parameter is required when the Actions parameter is used"
        }
    }
    Process
    {
        #consolidate the colour and severity parameters for the API.
        if($PSCmdlet.ParameterSetName -like 'Severity')
        {
            $Color = $Severity
        }

        $Attachment = @{}
        switch($PSBoundParameters.Keys)
        {
            'fallback' {$Attachment.fallback = $Fallback}
            'color' {$Attachment.color = $Color}
            'pretext'{$Attachment.pretext = $Pretext}
            'AuthorName'{$Attachment.author_name = $AuthorName}
            'AuthorLink' {$Attachment.author_link = $AuthorLink}
            'AuthorIcon' { $Attachment.author_icon = $AuthorIcon}
            'Title' { $Attachment.title = $Title}
            'TitleLink' { $Attachment.title_link = $TitleLink }
            'Text' {$Attachment.text = $Text}
            'fields' { $Attachment.fields = $Fields } #Fields are defined by the user as an Array of HashTables.
            'actions' { $Attachment.actions = $Actions } #Actions are defined by the user as an Array of HashTables.
            'CallbackId' { $Attachment.callback_id = $CallbackId }
            'ImageUrl' {$Attachment.image_url = $ImageURL}
            'ThumbUrl' {$Attachment.thumb_url = $ThumbURL}
            'MarkDownFields' {$Attachment.mrkdwn_in = @($MarkDownFields)}
        }

        Add-ObjectDetail -InputObject $Attachment -TypeName 'PSSlack.MessageAttachment' -Passthru $False

        if($ExistingAttachment)
        {
            @($ExistingAttachment) + $Attachment
        }
        else
        {
            $Attachment
        }
    }
}