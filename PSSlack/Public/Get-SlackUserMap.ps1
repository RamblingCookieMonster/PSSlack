function Get-SlackUserMap {
    <#
    .SYNOPSIS
        Get a map of Slack IDs to friendly names

    .DESCRIPTION
        Get a map of Slack IDs to friendly names

    .PARAMETER Token
        Token to use for the Slack API

        Default value is the value set by Set-PSSlackConfig

    .Parameter Update
        If specified, update PSSlack's cached map of names and IDs

    .Parameter Raw
        Return raw output.  If specified, Name parameter is ignored

    .EXAMPLE
        Get-SlackUserMap
        # Get map of names to IDs from cached PSSlack data

    .EXAMPLE
        Get-SlackUserMap -Update
        # Get map of names to IDs from Slack, and update cached PSSlack data

    .FUNCTIONALITY
        Slack
    #>
    [cmdletbinding(DefaultParameterSetName = 'Content')]
    param (
        [string]$Token = $Script:PSSlack.Token,
        [switch]$Raw,
        [switch]$Update
    )
    begin
    {
        if(-not $Update)
        {
            return $Script:_PSSlackUserMap
        }
        $params = @{
            Token = $Token
            Method = 'users.list'
        }
        if($body.keys.count -gt 0)
        {
            $params.add('body', $Body)
        }
        $RawUsers = Send-SlackApi @params
        $AllUsers = $RawUsers.members
        foreach($SlackUser in $RawUsers.members)
        {
            $UID = $SlackUser.id
            $Name = $SlackUser.name
            if($Script:_PSSlackUserMap.ContainsKey($Name))
            {
                $Script:_PSSlackUserMap[$Name] = $UID
            }
            else
            {
                $Script:_PSSlackUserMap.add($Name, $UID)
            }
        }
        $Script:_PSSlackUserMap
    }
}