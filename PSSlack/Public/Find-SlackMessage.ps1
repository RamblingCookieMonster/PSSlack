function Find-SlackMessage {
    <#
    .SYNOPSIS
        Search a Slack team for a message

    .DESCRIPTION
        Search a Slack team for a message

        Output will include details on the matching message, along with 'previous' and 'next' for context.

    .PARAMETER Query
        Search query. May contains booleans

        Messages are searched primarily inside the message text themselves,
            with a lower priority on the messages immediately before and after.

        If more than one search term is provided, user and channel are also matched at a lower priority.

        To specifically search within a channel, group, or DM, add
            in:channel_name,
            in:group_name, or
            in:username.

        To search for messages from a specific speaker, add
            from:username or
            from:botname.

        See https://api.slack.com/methods/search.messages for more information

    .PARAMETER Token
        Specify a token for authorization.

        See 'Authentication' section here for more information: https://api.slack.com/web
        Test tokens are a simple way to use this

    .PARAMETER SortDirection
        Sort asc[ending] or desc[ending]. Defaults to desc

    .PARAMETER SortBy
        Sort by score (relevance) or timestamp (date). Defaults to score

    .PARAMETER Count
        Return this many results per page. Defaults to 20

    .PARAMETER Page
        Which page to return. Defaults to 1

    .PARAMETER MaxPages
        Stop requesting search results once you hit this many pages. Defaults to the maximum value of int

    .PARAMETER Raw
        If specified, we provide raw output and do not parse any responses

    .FUNCTIONALITY
        Slack
    #>
    [cmdletbinding()]
    param (
        [string]$Query,
        $Token = $Script:PSSlack.Token,
        [validateset('asc','desc')]
        $SortDirection = 'desc',
        [validateset('score','timestamp')]
        $SortBy = 'score',
        [int]$Count = 20,
        [int]$Page = 1,
        [int]$MaxPages = [int]::MaxValue,
        [switch]$Raw
    )
    end
    {
        Write-Verbose "$($PSBoundParameters | Out-String)"

        #Initial args
        $body = @{
            query = $Query
            sort_dir = $SortDirection
            sort = $SortBy
            count = $Count
            page = $Page
        }
        $params = @{
            Body = $Body
            Method = 'search.messages'
        }
        if($Token)
        {
            $Params.Add('Token',$token)
        }

        #Pagination and parsing
        do
        {
            Write-Verbose "SendSlackApi -Params $($Params | Format-List | Out-String)"
            $response = Send-SlackApi @params
            if ($response.ok)
            {
                $link = "$($Script:PSSlack.ArchiveUri)/$($response.channel)/p$($response.ts -replace '\.')"
                $response | Add-Member -MemberType NoteProperty -Name link -Value $link
                $ResponsePage = $response.messages.paging.page
                $ResponsePageCount = $response.messages.paging.pages
                if($ResponsePage -lt $ResponsePageCount)
                {
                    $Page++
                    $Params.Body.page = $Page
                }

                if($Raw)
                {
                    $link = "$($Script:PSSlack.ArchiveUri)/$($response.channel)/p$($response.ts -replace '\.')"
                    $response | Add-Member -MemberType NoteProperty -Name link -Value $link
                    $response
                }
                else
                {
                    Parse-SlackMessage -InputObject $Response -Match
                }
            }
            else {
                $response
                break
            }

        } until ( $ResponsePage -eq $ResponsePageCount -or
                  $ResponsePage -eq $MaxPages)
    }
}