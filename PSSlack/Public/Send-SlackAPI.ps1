function Send-SlackApi {
    <#
    .SYNOPSIS
        Send a message to the Slack API endpoint

    .DESCRIPTION
        Send a message to the Slack API endpoint

        This function is used by other PSSlack functions.
        It's a simple wrapper you could use for calls to the Slack API

    .PARAMETER Method
        Slack API method to call.

        Reference: https://api.slack.com/methods

    .PARAMETER Body
        Hash table of arguments to send to the Slack API.

    .PARAMETER Token

    .FUNCTIONALITY
        Slack
    #>
    [OutputType([String])]
    [cmdletbinding()]
    param (
        $Method,
        $Body = @{},
        $Token = $Script:PSSlack.Token
    )

    if ([string]::isnullorempty($token)){
        throw "Please supply a Slack Api Token with Set-SlackApiToken."
    }

    $Body.token = $Token
    Invoke-RestMethod -Uri "https://slack.com/api/$method" -body $Body
}