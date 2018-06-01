
function New-SlackActionConfirmation
{
    <#
    .SYNOPSIS
        Creates an action confirmation to use in a Slack action.

    .DESCRIPTION
        Creates an action confirmation to use in a Slack action.

    .PARAMETER Text
        Describe in detail the consequences of the action and contextualize your button text choices. 
        Use a maximum of 30 characters or so for best results across form factors.

    .PARAMETER Title
        Title the pop up window. Please be brief.
        
    .PARAMETER OkText
        The text label for the button to continue with an action. Keep it short. Defaults to Okay.

    .PARAMETER DismissText
        The text label for the button to cancel the action. Keep it short. Defaults to Cancel.

    .EXAMPLE

        # This example illustrates a pattern where you might
        # want to add an action (button or menu) to your Slack attachment.
        # This can be useful when working with Slack bots or integrations that
        # make calls out with the action data.  Activating the button pops up a 
        # confirmation dialog.

        # Create an action using the New-SlackAction command
        $confirmation = New-SlackActionConfirmation -Text "Are you sure?"

        $action = New-SlackAction -Name Acknowledge `
                                -Text Acknowledge `
                                -Type button `
                                -Confirmation $confirmation

        $WebhookUri = "https://hooks.slack.com/services/SomeUniqueId"

        # Construct and send the message!
        New-SlackMessageAttachment -Color $_PSSlackColorMap.orange `
                                   -Title 'Failed to process account' `
                                   -Actions $action
                                   -Fallback 'Your client is bad' |
            New-SlackMessage |
            Send-SlackMessage -Uri $WebhookUri

        # We create an action object with an 'Acknowledge' button
        # Creates an attachment with the button created in the action object
        # Creates a message from that attachment and sents it with a uri
        
    .LINK
        https://github.com/RamblingCookieMonster/PSSlack

    .LINK
        https://api.slack.com/docs/interactive-message-field-guide#confirmation_fields
    #>
    [OutputType([System.Collections.Hashtable])]
    Param
    (
        [Parameter(Mandatory = $true,
            Position = 0)]
        [ValidateLength(1, 30)]
        [String]$Text,

        [String]$Title,

        [String]$OkText,

        [String]$DismissText
    )

    Process
    {
        $ActionConfirmation = @{}
        switch ($PSBoundParameters.Keys)
        {
            'text' {$ActionConfirmation.text = $Text}
            'title' {$ActionConfirmation.title = $Title}
            'oktext' {$ActionConfirmation.ok_text = $OkText}
            'dismissText' {$ActionConfirmation.dismiss_text = $DismissText}
        }

        Add-ObjectDetail -InputObject $ActionConfirmation -TypeName 'PSSlack.ActionConfirmation' -Passthru $False

        $ActionConfirmation
    }
}