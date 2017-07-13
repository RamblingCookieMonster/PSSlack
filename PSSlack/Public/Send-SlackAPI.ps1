function Send-SlackApi
{
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
        Slack token to use

    .PARAMETER Proxy
        Proxy server to use

    .FUNCTIONALITY
        Slack
    #>
    [OutputType([String])]
    [cmdletbinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Method,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Body = @{ },

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            if (-not $_ -and -not $Script:PSSlack.Token)
            {
                throw 'Please supply a Slack Api Token with Set-SlackApiToken.'
            }
            else
            {
                $true
            }
        })]
        [string]$Token = $Script:PSSlack.Token,

        [string]$Proxy = $Script:PSSlack.Proxy
    )
    $Params = @{
        Uri = "https://slack.com/api/$Method"
    }
    if($Proxy)
    {
        $Params['Proxy'] = $Proxy
    }
    $Body.token = $Token
    Invoke-RestMethod @Params -body $Body
}
