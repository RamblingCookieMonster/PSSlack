function Get-SlackGroup {
    <#
    .SYNOPSIS
        Get information about Slack groups

    .DESCRIPTION
        Get information about Slack groups

    .PARAMETER Token
        Specify a token for authorization.

        See 'Authentication' section here for more information: https://api.slack.com/web
        Test tokens are a simple way to use this

    .PARAMETER Name
        One or more group names to return.  Defaults to all.  Accepts wildcards.

    .PARAMETER ExcludeArchived
        Whether to exclude archived groups. Default is to include all.

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
        Write-Verbose "$($PSBoundParameters | Remove-SensitiveData | Out-String)"
        $body = @{
            types = 'private_channel';
        };
        if($ExcludeArchived)
        {
            $body['exclude_archived'] = 1
        }
        else
        {
            $body['exclude_archived'] = 0
        }
        $params = @{
            Body = $body
            Token = $Token
            Method = 'users.conversations'
        }
        $RawGroups = Send-SlackApi @params

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
            # torn between independent queries, or filtering users.conversations
            # submit a PR if this isn't performant enough or doesn't make sense.
            $Groups = $RawGroups.channels |
                Where-Object {$Name -Contains $_.name}
        }
        elseif ($Name -and$HasWildCard)
        {
            $AllGroups = $RawGroups.channels

            # allow like operator on each group requested in the param, avoid dupes
            $GroupHash = [ordered]@{}
            foreach($SlackGroup in $AllGroups)
            {
                foreach($Chan in $Name)
                {
                    if($SlackGroup.Name -like $Chan -and -not $GroupHash.Contains($SlackGroup.id))
                    {
                        $GroupHash.Add($SlackGroup.Id, $SlackGroup)
                    }
                }
            }
            $Groups = $GroupHash.Values
        }
        else # nothing specified
        {
            $Groups = $RawGroups.channels
        }

        if($Raw)
        {
            $RawGroups
        }
        else
        {
            Parse-SlackGroup -InputObject $Groups
        }
    }
}