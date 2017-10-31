function Test-SlackAuth {
    <#
    .SYNOPSIS
        Checks if you're authenticated.

    .DESCRIPTION
        Checks if you're authenticated.

    .PARAMETER Token
        Token to use for the Slack API.

        Default value is the value set by Set-PSSlackConfig.

    .PARAMETER Raw
        Return raw output.

    .EXAMPLE
        Test-SlackAuth

        # Checks if the default user specified by Get-PSSlackConfig is authenticated.

    .EXAMPLE
        Test-SlackAuth -Token $Token

        # Checks if the user specified by $Token is authenticated.
    .EXAMPLE
        Get-SlackAuth -Raw

        # Checks if the default user specified by Get-PSSlackConfig is authenticated.
        # Returns raw output.

    .EXAMPLE
        Get-SlackAuth -Raw -Token $Token

        # Checks if the default user specified by $Token is authenticated.
        # Returns raw output.

    .FUNCTIONALITY
        Slack

    .LINK
        https://api.slack.com/methods/auth,test
    #>

    [CmdletBinding()]
    param (
        [string]$Token = $Script:PSSlack.Token,
        [switch]$Raw
    )
    end
    {
        $RawAuth = Get-SlackAuth @PSBoundParameters

        if($Raw)
        {
            $RawAuth
        }
        else
        {
            $RawAuth.IsAuthenticated
        }
    }
}