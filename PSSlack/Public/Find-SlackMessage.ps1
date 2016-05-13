function Find-SlackMessage {
    [cmdletbinding()]
    param (
        [string]$Query,
        $Token,
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
        if($PSBoundParameters.ContainsKey('Token'))
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
                    $response
                }
                else
                {
                    Parse-SlackMessage -InputObject $Response
                }
            }
            else {
                $response
                break
            }

        } until ( $ResponsePage -eq $ResponsePageCount -or $ResponsePage -eq $MaxPages)
    }
}