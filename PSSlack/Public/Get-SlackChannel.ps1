function Get-SlackChannel {
    <#
    .SYNOPSIS
        Get information about Slack channels

    .DESCRIPTION
        Get information about Slack channels

    .PARAMETER Token
        Specify a token for authorization.

        See 'Authentication' section here for more information: https://api.slack.com/web
        Test tokens are a simple way to use this

    .PARAMETER Name
        One or more channel names to return.  Defaults to all.  Accepts wildcards.

    .PARAMETER Types
        Mix and match channel types by providing array of any combination of public_channel, private_channel, mpim, im

    .PARAMETER ExcludeArchived
        Whether to exclude archived channels. Default is to include all.

    .PARAMETER Raw
        If specified, we provide raw output and do not parse any responses

    .PARAMETER Paging
        If specified, and more data is available when a paging cursor is returned, continue querying Slack until
            we have retrieved all the data available.

    .PARAMETER MaxQueries
        Limit the count of API queries to this number.  Only used if you enable -Paging

    .FUNCTIONALITY
        Slack
    #>
    [cmdletbinding()]
    param (
        $Token = $Script:PSSlack.Token,
        [string[]]$Name,
        [ValidateSet('public_channel', 'private_channel', 'mpim', 'im')]
        [string[]]$Types,
        [switch]$ExcludeArchived,
        [switch]$Raw,
        [switch]$Paging,
        [int]$MaxQueries
    )
    end
    {
        Write-Verbose "$($PSBoundParameters | Remove-SensitiveData | Out-String)"
        $body = @{
            limit = 200
        }
        if ($ExcludeArchived)
        {
            $body.Add("exclude_archived",1)
        }
        else
        {
            $body.Add("exclude_archived",0)
        }

        if ($Types)
        {
            $body.add("types",$($Types -join ","))
        }
        else
        {
            $body.add("types","public_channel,private_channel")
        }

        $RawChannels = @()
        $has_more    = $false
        $Queries     = 0
        do {
            $params = @{
                Body   = $body
                Token  = $Token
                Method = 'conversations.list'
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
            $RawChannels += $response
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

        if($Name -and -not $HasWildCard)
        {
            # torn between independent queries, or filtering conversations.list
            # submit a PR if this isn't performant enough or doesn't make sense.
            $Channels = $RawChannels.channels |
                Where-Object {$Name -Contains $_.name}
        }
        elseif ($Name -and$HasWildCard)
        {
            $AllChannels = $RawChannels.Channels

            # allow like operator on each channel requested in the param, avoid dupes
            $ChannelHash = [ordered]@{}
            foreach($SlackChannel in $AllChannels)
            {
                foreach($Chan in $Name)
                {
                    if($SlackChannel.Name -like $Chan -and -not $ChannelHash.Contains($SlackChannel.id))
                    {
                        $ChannelHash.Add($SlackChannel.Id, $SlackChannel)
                    }
                }
            }
            $Channels = $ChannelHash.Values
        }
        else # nothing specified
        {
            $Channels = $RawChannels.channels
        }

        if($Raw)
        {
            $RawChannels
        }
        else
        {
            Parse-SlackChannel -InputObject $Channels
        }
    }
}
