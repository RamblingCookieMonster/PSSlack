function Set-SlackReminderComplete
{
    <#
    .SYNOPSIS
        Sets the status of a Slack reminder to complete

    .DESCRIPTION
        Sets the status of a Slack reminder to complete based on the reminder object or reminder id passed to the function

    .PARAMETER Token
        Token to use for the Slack API

        Default value is the value set by Set-PSSlackConfig

        This takes precedence over Uri

    .PARAMETER Proxy
        Proxy server to use

        Default value is the value set by Set-PSSlackConfig

    .PARAMETER ReminderId
        The ID of the reminder that will be deleted.

    .PARAMETER ReminderObject
        One or more objects of type PSSlack.Reminder. This is intended for use in pipelined scenarios.

    .EXAMPLE
        # This is a simple example on how to set the status to complete on a Slack reminder

        Set-SlackReminderComplete -ReminderId "RmAZPB1FBP"

        # Sets a Slack reminder with an ID of "RmAZPB1FBP" to complete status

    .EXAMPLE
        # This is a simple example on how to set the status to complete on a reminder by searching 
        # and filtering the existing reminders
        # The returned reminder object is then passed to Set-SlackReminder

        New-SlackReminder -Text "you should complete me soon" -Time (get-date).AddMinutes(10)

        Get-SlackReminder | 
            Where-Object {$_.Text -like "*complete me*"} |
            Set-SlackReminderComplete

        # We create a reminder
        # We then search for that reminder and set the status on it to complete by piping it into Set-SlackReminder

    .EXAMPLE
        # This is a simple example on how to set the status to complete on multiple reminders 
        # by searching and filtering the existing reminders
        # The returned reminder object array is then passed to Set-SlackReminder

        New-SlackReminder -Text "you should complete me soon" -Time (get-date).AddMinutes(10)
        New-SlackReminder -Text "you should complete me soon too" -Time (get-date).AddMinutes(10)

        Get-SlackReminder | 
            Where-Object {$_.Text -like "*complete me*"} |
            Set-SlackReminderComplete

        # We create two reminders
        # We then search for the reminders and set the status on them to complete by piping them into Set-SlackReminder

    .LINK
        https://api.slack.com/methods/reminders.complete

    .FUNCTIONALITY
        Slack
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByParameter')]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Token = $Script:PSSlack.Token,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Proxy = $Script:PSSlack.Proxy,

        [Parameter(ValueFromPipeline = $True)]
        [Parameter(ParameterSetName = 'ByObject')]
        [PSTypeName('PSSlack.Reminder')]
        $ReminderObject,

        [Parameter(ParameterSetName = 'ByParameter')]
        [Alias("Reminder")]
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
        if ($ReminderObject)
        {
            foreach ($object in $ReminderObject)
            {
                $body = @{ }
                $body.reminder = $object.ID
                Write-Verbose "Send-SlackApi"
                Send-SlackApi @ProxyParam -Method reminders.complete -Body $body -Token $Token -ForceVerbose:$ForceVerbose
            }
        }
        else
        {
            $body = @{ }
            $body.reminder = $ReminderId
            Write-Verbose "Send-SlackApi"
            Send-SlackApi @ProxyParam -Method reminders.complete -Body $body -Token $Token -ForceVerbose:$ForceVerbose
        }
    }
}