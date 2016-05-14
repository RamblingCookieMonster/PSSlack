function Set-PSSlackConfig {
    <#
    .SYNOPSIS
        Set PSSlack module configuration.

    .DESCRIPTION
        Set PSSlack module configuration, and $PSSlack module variable.

        This data is used as the default Token and Uri for most commands.

        If a command takes either a token or a uri, tokens take precedence.

        WARNING: Use this to store the token or uri on a filesystem at your own risk.
                 These are sensitive data that should be encrypted where appropriate.

    .PARAMETER Token
        Specify a Token to use

    .PARAMETER Uri
        Specify a Uri to use

    .PARAMETER ArchiveUri
        Archive URI. Generally, https://<TEAMNAME>.slack.com/archives/

        Used to generate a link to a specific archive URI, where appropriate

    .FUNCTIONALITY
        Slack
    #>
    [cmdletbinding()]
    param(
        [string]$Uri,
        [string]$Token,
        [string]$ArchiveUri
    )

    Switch ($PSBoundParameters.Keys)
    {
        'Uri'{ $Script:PSSlack.Uri = $Uri }
        'Token'{ $Script:PSSlack.Token = $Token }
        'ArchiveUri'{ $Script:PSSlack.ArchiveUri = $ArchiveUri }
    }

    #Write the global variable and the xml
    $Script:PSSlack | Export-Clixml -Path "$PSScriptRoot\PSSlack.xml" -force

}
