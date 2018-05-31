
function New-SlackActionOption {
    <#
    .SYNOPSIS
        Creates an action option to use in a Slack action

    .DESCRIPTION
        Creates an action option to use in a Slack action

    .PARAMETER Text
        A short, user-facing string to label this option to users.
        Use a maximum of 30 characters or so for best results across, you guessed it, form factors.

    .PARAMETER Value
        A short string that identifies this particular option to your application. 
        It will be sent to your Action URL when this option is selected. 
        While there's no limit to the value of your Slack app, this value may contain up to only 2000 characters.

    .PARAMETER Description
        A user-facing string that provides more details about this option. Also should contain up to 30 characters.

    .PARAMETER ExistingActionOption
        One or more action options to add this action option to.

        Allows you to chain calls to this function:
            New-SlackActionOption ... | New-SlackActionOption ...

    .EXAMPLE
        # This is a simple example illustrating some common options
        # when constructing an action

        $WebhookUri = "https://hooks.slack.com/services/SomeUniqueId"

        $Options = New-SlackActionOption -Text "Option 1" `
                        -Value "option1" |
                     New-SlackActionOption -Text "Option 2" `
                        -Value "option2"

        $actions = New-SlackAction -Name Acknowledge `
                        -Text Menu `
                        -Type select `
                        -Options $Options

        New-SlackMessageAttachment -Color $_PSSlackColorMap.orange `
                            -Title 'Failed to process account' `
                            -Actions $actions `
                            -Fallback 'Your client is bad' |
            New-SlackMessage |
            Send-SlackMessage -Uri $WebhookUri

        # We create an action object with an menu that contains two options
        # Creates an attachment with the button created in the action object
        # Creates a message from that attachment and sents it with a uri

    .LINK
        https://github.com/RamblingCookieMonster/PSSlack

    .LINK
        https://api.slack.com/docs/interactive-message-field-guide#option_fields
    #>
    Param
    (
        [Parameter(ValueFromPipeline = $True)]
        [PSTypeName('PSSlack.ActionOption')]
        $ExistingActionOption,

        [Parameter(Mandatory = $true,
            Position = 0)]
        [ValidateLength(1, 30)]
        [String]$Text,

        [Parameter(Mandatory = $true,
            Position = 1)]
        [ValidateLength(1, 2000)]
        [String]$Value,

        [ValidateLength(1, 30)]
        [String]$Description
    )

    Process {
        $ActionOption = @{}
        switch ($PSBoundParameters.Keys) {
            'text' {$ActionOption.text = $Text}
            'value' {$ActionOption.value = $Value}
            'description' {$ActionOption.description = $Description}
        }

        Add-ObjectDetail -InputObject $ActionOption -TypeName 'PSSlack.ActionOption' -Passthru $False

        if ($ExistingActionOption) {
            @($ExistingActionOption) + $ActionOption
        }
        else {
            $ActionOption
        }
    }
}