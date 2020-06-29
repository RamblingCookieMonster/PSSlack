function Remove-SlackMessage {
    <#
    .SYNOPSIS
        Deletes Slack messages
    .DESCRIPTION
        This cmdlet invokes the "chat.delete" Slack API method to delete messages from a given Slack channel.
    .EXAMPLE
        # Remove a message sent to a channel with ID C1W2X3Y4Z at Saturday, August 5, 2017 8:19:05 PM
        PS> Remove-SlackMessage -ChannelID "C1W2X3Y4Z" -TimeStamp 1501964345.000481

        # Using a pipeline, Remove all messages sent to a channel by a specific bot/user
        # (Multilined for clarity)
        PS> Get-SlackChannel -name "TargetChannel" |
                Get-SlackHistory -Count 1000 |
                Where-Object Username -match "MalfunctioningBot" |
                Remove-SlackMessage -ChannelID "C5H8XBUMV"
    .INPUTS
        The message(s) to delete. These can be specified individually using their timestamps, or piped in from Get-SlackHistory or Find-SlackMessage.
    .OUTPUTS
        The object returned by the Slack API. The "ok" field indicates whether or not the operation was successful.
    .PARAMETER ChannelID
        The ID of the channel where the target message is to be deleted from. This must be specified as the channel's ID, not its name.
    .PARAMETER TimeStamp
        The timestamp (message ID) of the message(s) to be deleted. This is a Unix epoch timestamp with microsecond resolution (6 decimal places).
    .PARAMETER HistoryObject
        A PSSlack.History object returned from Get-SlackHistory. This is intended for use in pipelined scenarios.
    .PARAMETER SearchResultObject
        A PSSlack.SearchResult object returned from Find-SlackMessage. This is intended for use in pipelined scenarios.
    .PARAMETER AsUser
        Delete the message as the authed user associated with this request's token, using the "chat:write:user" scope. Bot users in this context are considered authed users.

        If not specified, the message will be deleted with the "chat:write:bot" scope.
    .PARAMETER Token
        The Slack API Token to use for authorizing this request.
    .PARAMETER Force
        Skip confirmation prompts for deleting messages.
    .NOTES
        When used with a typical user or bot user token, this cmdlet may only delete messages posted by that user.

        When used with an admin user's user token, this cmdlet may delete most messages posted in a channel/workspace. Use with caution.

        For information on the chat.delete method, visit the Slack API documentation page: https://api.slack.com/methods/chat.delete
    .FUNCTIONALITY
        Slack
    .LINK
        https://api.slack.com/methods/chat.delete
    #>
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact="High")]
    param (
        # The ID of the channel where the target message is to be deleted from.
        [Parameter(
            ValueFromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [Alias(
            "Channel"
        )]
        [string]$ChannelID,

        # The timestamp of the message to be deleted.
        [Parameter(
            ValueFromPipelineByPropertyName = $true,
            Mandatory = $true,
            ParameterSetName = "ByParameter"

        )]
        [ValidateNotNullOrEmpty()]
        [Alias(
            "ts"
        )]
        [string]$TimeStamp,

        # The history item (from Get-SlackHistory) referencing the message to be deleted.
        [Parameter(
            ValueFromPipeline = $true,
            Mandatory = $true,
            ParameterSetName = "ByObject-History"
        )]
        [ValidateNotNullOrEmpty()]
        [PSTypeName("PSSlack.History")]
        $HistoryObject,

        # The message search result (from Find-SlackMessage) referencing the message to be deleted.
        [Parameter(
            ValueFromPipeline = $true,
            Mandatory = $true,
            ParameterSetName = "ByObject-SearchResult"
        )]
        [ValidateNotNullOrEmpty()]
        [PSTypeName("PSSlack.SearchResult")]
        $SearchResultObject,

        # A switch to delete the message using the currently auth'd user (via the chat:write:user scope)
        # See https://api.slack.com/methods/chat.delete for more info
        [switch]$AsUser,

        # Disable confirmation prompts when deleting messages.
        [Switch]$Force,

        [string]$Token = $Script:PSSlack.Token
    )

    begin {
        Write-Verbose "$($PSBoundParameters | Remove-SensitiveData | Out-String)"
        $RejectAll = $false
        $ConfirmAll = $false
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            "ByParameter"           { $PrimaryIterator = $TimeStamp }
            "ByObject-History"      { $PrimaryIterator = $HistoryObject }
            "ByObject-SearchResult" { $PrimaryIterator = $SearchResultObject }
        }

        # Get generic for a brief moment so we can use one loop for all three cases.
        foreach ($item in $PrimaryIterator) {
            $Body = @{
                as_user = $AsUser
                channel = $ChannelID
            }
            switch ($PSCmdlet.ParameterSetName) {
                "ByParameter" {
                    $Body.ts = $TimeStamp
                }
                "ByObject-History" {
                    $Body.ts = $Item.raw.ts
                }
                "ByObject-SearchResult" {
                    $Body.channel = $Item.raw.channel.id
                    $Body.ts = $Item.raw.ts
                }
            }
            $Params = @{
                Body = $Body
                Method = "chat.delete"
                Token = $Token
            }
            If (($Force -and -not $WhatIfPreference) -or
                $PSCmdlet.ShouldProcess(
                    "Removed the message [$($Body.ts)] from channel $($Body.channel)",
                    "Remove the message [$($Body.ts)] from channel $($Body.channel)?",
                    "Removing messages"
            )) {
                If (($Force -and -not $WhatIfPreference) -or
                    $PSCmdlet.ShouldContinue(
                        "Are you sure you want to remove message [$($Body.ts)] from channel $($Body.channel)?",
                        "Removing Slack message",
                        $true,
                        [ref]$ConfirmAll,
                        [ref]$RejectAll
                )) {
                    Send-SlackApi @Params
                }
            }
        }
    }
}
