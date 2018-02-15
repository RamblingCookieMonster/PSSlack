function Remove-SlackMessage {
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
        Write-Verbose "$($PSBoundParameters | Out-String)"
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
                    $Body.ts = $MessageTS
                }
                "ByObject-History" {
                    $Body.ts = $Item.raw.ts
                }
                "ByObject-SearchResult" {
                    $Body.channel = $Item.Channel
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