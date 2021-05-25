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

    .PARAMETER Billing
        Whether to include billing info

    .Parameter Name
        Optional. One or more names to search for. Accepts wildcards.

    .Parameter Raw
        Return raw output.  If specified, Name parameter is ignored

    .PARAMETER Paging
        If specified, and more data is available when a paging cursor is returned, continue querying Slack until
            we have retrieved all the data available.

    .PARAMETER MaxQueries
        Limit the count of API queries to this number.  Only used if you enable -Paging

    .EXAMPLE
        Get-SlackUser -Token $Token `
                      -Name ps*

        # Get users with name starting 'ps'

    .EXAMPLE
        Get-SlackUser -Token $Token -Presence -Billing

        # Get all users in the team, including bots, as well as presence and billing info

    .FUNCTIONALITY
        Slack
    #>

    [cmdletbinding(DefaultParameterSetName = 'Content')]
    param (
        [string]$Token = $Script:PSSlack.Token,
        [string[]]$Name,
        [switch]$Presence,
        [switch]$Billing,
        [switch]$ExcludeBots,
        [switch]$Raw,
        [switch]$Paging,
        [int]$MaxQueries
    )
    begin
    {
        $body = @{}
        if($Presence)
        {
            $body.add('presence', 1)
        }

        $RawUsers = @()
        $has_more    = $false
        $Queries     = 0
        do {
            $params = @{
                Token  = $Token
                Method = 'users.list'
            }
            if($body.keys.count -gt 0)
            {
                $params.add('Body', $body)
            }
            $response = Send-SlackApi @params
            $Queries++
            if (-not [string]::IsNullOrEmpty($response.response_metadata.next_cursor))
            {
                $has_more = $true
                $body['cursor'] = $response.response_metadata.next_cursor
            }
            else
            {
                $has_more = $false
            }
            $RawUsers += $response
        } until (
            -not $Paging -or
            -not $has_more -or
            ($MaxQueries -and $Queries -ge $MaxQueries)
        )

        $HasWildCard = $False
        foreach($Item in $Name)
        {
            if($Item -match '\*')
            {
                $HasWildCard = $true
                break
            }
        }

        if($Billing)
        {
            $BillingInfo = Send-SlackApi -Token $Token -Method team.billableInfo
            $UserIDs = $BillingInfo.billable_info.psobject.properties.name
            foreach($User in $RawUsers.members)
            {
                $UserId = $User.Id
                if($UserIDs -contains $UserId)
                {
                    Add-Member -InputObject $User -MemberType NoteProperty -Name BillingActive -Value $BillingInfo.billable_info.$UserId.billing_active -Force
                }
            }
        }

        if($Name -and -not $HasWildCard)
        {
            # torn between independent queries, or filtering users.list
            # submit a PR if this isn't performant enough or doesn't make sense.
            $Users = $RawUsers.members |
                Where-Object {$Name -Contains $_.name}
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