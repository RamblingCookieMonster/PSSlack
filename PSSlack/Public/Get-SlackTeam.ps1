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

        # Gets the default Slack team specified by Get-PSSlackConfig.

    .EXAMPLE
        Get-SlackTeam -Token $Token

        # Gets the  Slack team specified by $Token.
    .EXAMPLE
        Get-SlackTeam -Raw

        # Gets the default Slack team specified by Get-PSSlackConfig.
        # Returns raw output.

    .EXAMPLE
        Get-SlackTeam -Raw -Token $Token

        # Gets the  Slack team specified by $Token.
        # Returns raw output.

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
            $Team = $RawTeam.team

            [PSCustomObject] @{
                PSTypeName = 'PSSlack.Team'
                ID = $Team.id
                Name = $Team.name
                Domain = $Team.domain
                EmailDomain = ($Team.email_domain -split ',')
                Icon = [Ordered] @{
                    Image34 = $Team.icon.image_34
                    Image44 = $Team.icon.image_44
                    Image68 = $Team.icon.image_68                    
                    Image88 = $Team.icon.image_88
                    Image102 = $Team.icon.image_102
                    Image132 = $Team.icon.image_132
                    Image230 = $Team.icon.image_230
                    ImageDefault = $Team.icon.image_default
                }
            }
        }
    }
}