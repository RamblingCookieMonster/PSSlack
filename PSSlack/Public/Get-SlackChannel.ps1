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
        Whether to exclude archived channels. 1 or 0. Defaults to 0 (return all channels, including archived channels)

    .PARAMETER Raw
        If specified, we provide raw output and do not parse any responses

    .FUNCTIONALITY
        Slack
    #>
    [cmdletbinding()]
    param (
        $Token = $Script:PSSlack.Token,
        [string[]]$Name,

        [ValidateSet(0,1)]
        [int]$ExcludeArchived = 0,

        [switch]$Raw

    )
    end
    {
        Write-Verbose "$($PSBoundParameters | Out-String)"

        $body = @{exclude_archived = $ExcludeArchived}
        $params = @{
            Body = $body
            Token = $Token
            Method = 'channels.list'
        }

        if($Name -and $Name -notmatch '\*')
        {       
            # torn between independent queries, or filtering channels.list
            # submit a PR if this isn't performant enough or doesn't make sense.
            $Channels = Send-SlackApi @params |
                Where {$Name -Contains $_.name}
        }
        elseif ($Name -and $Name -match '\*')
        {
            $AllChannels = Send-SlackApi @params
            
            # allow like operator on each channel requested in the param, avoid dupes
            $ChannelHash = [ordered]@{}
            foreach($SlackChannel in $AllChannels)
            {
                foreach($Chan in $Name)
                {
                    if($SlackChannel.Name -like $Chan -and -not $ChannelHash.ContainsKey($SlackChannel.id))
                    {
                        $ChannelHash.Add($SlackChannel.Id, $SlackChannel)
                    }
                }
            }
            $Channels = $ChannelHash.Values
        }
        else # nothing specified
        {
            $Channels = Send-SlackApi @params
        }

        if($Raw)
        {
            $Channels
        }
        else
        {
            Parse-SlackChannel -InputObject $Channels
        }
    }
}