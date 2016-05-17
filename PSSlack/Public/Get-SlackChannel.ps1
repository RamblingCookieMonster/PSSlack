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

    .PARAMETER ExcludeArchived
        Whether to exclude archived channels. Default is to include all.

    .PARAMETER Raw
        If specified, we provide raw output and do not parse any responses

    .FUNCTIONALITY
        Slack
    #>
    [cmdletbinding()]
    param (
        $Token = $Script:PSSlack.Token,
        [string[]]$Name,
        [switch]$ExcludeArchived,
        [switch]$Raw
    )
    end
    {
        Write-Verbose "$($PSBoundParameters | Out-String)"

        $body = @{}
        if($ExcludeArchived)
        {
            $body.add('exclude_archived', 1)
        }
        $params = @{
            Body = $body
            Token = $Token
            Method = 'channels.list'
        }
        $RawChannels = Send-SlackApi @params

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
            # torn between independent queries, or filtering channels.list
            # submit a PR if this isn't performant enough or doesn't make sense.
            $Channels = $RawChannels.channels |
                Where {$Name -Contains $_.name}
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