function Get-SlackReminder
{
    <#
    .SYNOPSIS
        Gets a list Slack reminders for the current user

    .DESCRIPTION
        Gets a list Slack reminders for the current user

    .PARAMETER Token
        Token to use for the Slack API

        Default value is the value set by Set-PSSlackConfig

        This takes precedence over Uri

    .PARAMETER Proxy
        Proxy server to use

        Default value is the value set by Set-PSSlackConfig

    .PARAMETER ReminderId
        The ID of the reminder

    .EXAMPLE
        # This is a simple example on how to get a list of all reminders

        Get-SlackReminder

        # Gets a list of reminders for the current user based off of the Token

    .EXAMPLE
        # This is a simple example on how to get information on a specific reminder

        Get-SlackReminder -Id "RmAZPB1FBP"

        # Gets the information for the reminder specified by the Reminder parameter

    .LINK
        https://api.slack.com/methods/reminders.info

    .LINK
        https://api.slack.com/methods/reminders.list

    .FUNCTIONALITY
        Slack
    #>

    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Token = $Script:PSSlack.Token,
        [string]$ReminderId
    )
    begin
    {
        $ProxyParam = @{}
        if ($Proxy)
        {
            $ProxyParam.Proxy = $Proxy
        }
    }
    process
    {
        $body = @{ }

        if ($ReminderId)
        {
            $body.reminder = $ReminderId
            $method = "reminders.info"
        }
        else
        {
            $method = "reminders.list"
        }
    }
    end
    {
        Write-Verbose "Send-SlackApi"
        if ($ReminderId)
        {
            $response = Send-SlackApi @ProxyParam -Method $method -Body $body -Token $Token -ForceVerbose:$ForceVerbose
            $returnObj = $response.reminder
        }
        else
        {
            $response = Send-SlackApi @ProxyParam -Method $method -Token $Token -ForceVerbose:$ForceVerbose
            $returnObj = $response.reminders
        }
        Add-ObjectDetail -InputObject $returnObj -TypeName 'PSSlack.Reminder'
    }
}