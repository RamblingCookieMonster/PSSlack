function Get-SlackTeam {
    <#
    .SYNOPSIS
        Get info about the current Slack team.

    .DESCRIPTION
        Get info about the current Slack team.

    .PARAMETER Token
        Token to use for the Slack API.

        Default value is the value set by Set-PSSlackConfig.

    .PARAMETER Raw
        Return raw output.

    .EXAMPLE
        Get-SlackTeam

    .FUNCTIONALITY
        Slack

    .LINK
        https://api.slack.com/methods/team.info
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
            Method = 'team.info'
        }

        $RawTeam = Send-SlackApi @params

        if($Raw)
        {
            $RawTeam
        }
        else
        {
            $RawTeam
        }
    }
}