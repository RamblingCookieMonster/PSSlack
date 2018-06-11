function New-SlackReminder
{
    <#
    .SYNOPSIS
        Creates a Slack reminder

    .DESCRIPTION
        Creates a Slack reminder

    .PARAMETER Token
        Token to use for the Slack API

        Default value is the value set by Set-PSSlackConfig

        This takes precedence over Uri

    .PARAMETER Proxy
        Proxy server to use

        Default value is the value set by Set-PSSlackConfig

    .PARAMETER Text
        The content of the reminder

    .PARAMETER Time
        When this reminder should happen.  Must be passed in a valid datetime format.

    .PARAMETER User
        The user who will receive the reminder. If no user is specified, 
        the reminder will go to user who created it.

        Note: This is not the user's name in Slack but rather the unique user identifier.

    .EXAMPLE
        # This is a simple example on how to create a reminder

        New-SlackReminder -Text "Do some things" -Time (Get-Date).AddMinutes(1)

        # Creates a reminder with the name "Do some things" set for 1 minute from now

    .LINK
        https://api.slack.com/methods/reminders.add

    .FUNCTIONALITY
        Slack
    #>

    param (

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Token = $Script:PSSlack.Token,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Proxy = $Script:PSSlack.Proxy,

        [Parameter(Mandatory = $true,
            Position = 0)]
        [String]$Text,

        [Parameter(Mandatory = $true,
            Position = 1)]
        [validatescript( {$_ -gt (Get-Date) -and $_ -le (Get-Date).AddYears(5)})]
        [datetime]$Time,

        [string]$User

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

        switch ($psboundparameters.keys)
        {
            'text' {$body.text = $text}
            'time' {$body.time = [Math]::Floor([decimal](Get-Date($time).ToUniversalTime()-uformat "%s"))}
            'user' {$body.user = $User}
        }
    }
    end
    {
        Write-Verbose "Send-SlackApi -Body $body"
        $response = Send-SlackApi @ProxyParam -Method reminders.add -Body $body -Token $Token -ForceVerbose:$ForceVerbose

        Add-ObjectDetail -InputObject $response.reminder -TypeName 'PSSlack.Reminder'
    }
}