function Get-SlackAuth {
    <#
    .SYNOPSIS
        Checks authentication and tells you who you are.

    .DESCRIPTION
        Checks authentication and tells you who you are.

    .PARAMETER Token
        Token to use for the Slack API.

        Default value is the value set by Set-PSSlackConfig.

    .PARAMETER Raw
        Return raw output.

    .EXAMPLE
        Get-SlackAuth

        # Checks authentication and retrieves the information of the default user specified by Get-PSSlackConfig.

    .EXAMPLE
        Get-SlackAuth -Token $Token

        # Checks authentication and retrieves the information of the user specified by $Token.
    .EXAMPLE
        Get-SlackAuth -Raw

        # Checks authentication and retrieves the information of the default user specified by Get-PSSlackConfig.
        # Returns raw output.

    .EXAMPLE
        Get-SlackAuth -Raw -Token $Token

        # Checks authentication and retrieves the information of the user specified by $Token.
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
        $params = @{
            Token = $Token
            Method = 'auth.test'
        }

        $RawAuth = Send-SlackApi @params

        if($Raw)
        {
            $RawAuth
        }
        else
        {
            Parse-SlackAuth -InputObject $RawAuth       
        }
    }
}