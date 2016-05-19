function Get-SlackUser {
    <#
    .SYNOPSIS
        Get info on a Slack user

    .DESCRIPTION
        Get info on a Slack user

    .PARAMETER Token
        Token to use for the Slack API

        Default value is the value set by Set-PSSlackConfig

    .PARAMETER Presence
        Whether to include presence information

    .Parameter Name
        Optional. One or more names to search for. Accepts wildcards.

    .EXAMPLE
        Get-SlackUser -Token $Token `
                      -Name ps*

        # Get users with name starting 'ps'

    .EXAMPLE
        Get-SlackUser -Token $Token

        # Get all users in the team, including bots

    .FUNCTIONALITY
        Slack
    #>

    [cmdletbinding(DefaultParameterSetName = 'Content')]
    param (
        [string]$Token = $Script:PSSlack.Token,
        [string[]]$Name,
        [switch]$Presence,
        [switch]$ExcludeBots
    )
    begin
    {
        $body = @{}
        if($Presence)
        {
            $body.add('presence', 1)
        }
        $params = @{
            Body = $body
            Token = $Token
            Method = 'users.list'
        }
        $RawUsers = Send-SlackApi @params

        $HasWildCard = $False
        foreach($Item in $Name)
        {
            if($Item -match '\*')
            {
                $HasWildCard = $true
                break
            }
        }

        if($Name -and -not $HasWildCard)
        {       
            # torn between independent queries, or filtering users.list
            # submit a PR if this isn't performant enough or doesn't make sense.
            $Users = $RawUsers.members |
                Where {$Name -Contains $_.name}
        }
        elseif ($Name -and $HasWildCard)
        {
            $AllUsers = $RawUsers.members
            
            # allow like operator on each channel requested in the param, avoid dupes
            $UserHash = [ordered]@{}
            foreach($SlackUser in $AllUsers)
            {
                foreach($Username in $Name)
                {
                    if($SlackUser.Name -like $Username -and -not $UserHash.Contains($SlackUser.id))
                    {
                        $UserHash.Add($SlackUser.Id, $SlackUser)
                    }
                }
            }
            $Users = $UserHash.Values
        }
        else # nothing specified
        {
            $Users = $RawUsers.members
        }

        if($Raw)
        {
            $RawUsers
        }
        else
        {
            Parse-SlackUser -InputObject $Users
        }
    }
}