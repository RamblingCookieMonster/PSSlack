
function New-SlackAction {
    <#
    .SYNOPSIS
        Creates an action to use in a Slack message attachment.

    .DESCRIPTION
        Creates an action to use in a Slack message attachment.

        Used to create actions for Slack message attachments.

    .PARAMETER Name
        Provide a string to give this specific action a name. 
        The name will be returned to your Action URL along with the message's callback_id when this action is invoked. 
        Use it to identify this particular response path. 
        If multiple actions share the same name, only one of them can be in a triggered state.

    .PARAMETER Text
         The user-facing label for the message button or menu representing this action. 
         Cannot contain markup. Best to keep these short and decisive. 
         Use a maximum of 30 characters or so for best results across form factors.

    .PARAMETER Type
        Provide button when this action is a message button or provide select when the action is a message menu.

    .PARAMETER Value
        Provide a string identifying this specific action. It will be sent to your Action URL along with the name and attachment's callback_id. 
        If providing multiple actions with the same name, value can be strategically used to differentiate intent. 
        Your value may contain up to 2000 characters.

    .PARAMETER Confirmation
        If you provide a JSON hash of confirmation fields, your button or menu will pop up a dialog with your 
        indicated text and choices, giving them one last chance to avoid a destructive action or other undesired outcome. 

    .PARAMETER Style
        Used only with message buttons, this decorates buttons with extra visual importance, 
        which is especially useful when providing logical default action or highlighting a destructive activity.
            default — Yes, it's the default. Buttons will look simple.
            primary — Use this sparingly, when the button represents a key action to accomplish. You should probably only ever have one primary button within a set.
            danger — Use this when the consequence of the button click will result in the destruction of something, like a piece of data stored on your servers. Use even more sparingly than primary.

    .PARAMETER Options
             Used only with message menus. The individual options to appear in this menu, provided as an array of option fields. 
             Required when data_source is static or otherwise unspecified. A maximum of 100 options can be provided in each menu.

             Options can be created using the New-SlackActionOption command

    .PARAMETER ExistingAction
        One or more actions to add this action to.

        Allows you to chain calls to this function:
            New-SlackAction ... | New-SlackAction ...

    .EXAMPLE
        # This is a simple example illustrating some common options
        # when constructing an action

        $WebhookUri = "https://hooks.slack.com/services/SomeUniqueId"

        $actions = New-SlackAction -Name Acknowledge `
                        -Text Acknowledge `
                        -Type button | 
                    New-SlackAction -Name Dismiss `
                        -Text Dismiss `
                        -Type button

        New-SlackMessageAttachment -Color $_PSSlackColorMap.orange `
                            -Title 'Failed to process account' `
                            -Actions $actions `
                            -Fallback 'Your client is bad' |
            New-SlackMessage |
            Send-SlackMessage -Uri $WebhookUri

        # We create an action object with an 'Acknowledge' button and a
        # Dismiss button.
        # Creates an attachment with the button created in the action object
        # Creates a message from that attachment and sents it with a uri

    .LINK
        https://github.com/RamblingCookieMonster/PSSlack

    .LINK
        https://api.slack.com/docs/interactive-message-field-guide#action_fields
    #>
    [OutputType([System.Collections.Hashtable])]
    Param
    (
        [Parameter(ValueFromPipeline = $True)]
        [PSTypeName('PSSlack.Action')]
        $ExistingAction,

        [Parameter(Mandatory = $true,
            Position = 0)]
        [String]$Name,

        [Parameter(Mandatory = $true,
            Position = 1)]
        [ValidateLength(1, 30)]
        [String]$Text,

        [Parameter(Mandatory = $true,
            Position = 2)]
        [ValidateSet("button",
            "select")]
        [String]$Type,

        [ValidateLength(0, 3000)]
        [String]$Value,

        [PSTypeName('PSSlack.ActionConfirmation')]
        $Confirmation,

        [ValidateSet("default",
            "primary",
            "danger")]
        [String]$Style,
        
        [PSTypeName('PSSlack.ActionOption')]
        $Options
    )

    Process {
        $Action = @{}
        switch ($PSBoundParameters.Keys) {
            'name' {$Action.name = $Name}
            'text' {$Action.text = $Text}
            'type' {$Action.type = $Type}
            'value' {$Action.value = $Value}
            'Confirmation' {$Action.confirm = $Confirmation}
            'style' { $Action.style = $Style}
            'options' { $Action.options = $Options}
        }

        Add-ObjectDetail -InputObject $Action -TypeName 'PSSlack.Action' -Passthru $False

        if ($ExistingAction) {
            @($ExistingAction) + $Action
        }
        else {
            $Action
        }
    }
}