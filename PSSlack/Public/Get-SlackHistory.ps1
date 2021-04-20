function Get-SlackHistory {
    <#
    .SYNOPSIS
        Get history from a Slack channel

    .DESCRIPTION
        Get history from a Slack channel

    .PARAMETER Token
        Specify a token for authorization.

        See 'Authentication' section here for more information: https://api.slack.com/web
        Test tokens are a simple way to use this

    .PARAMETER Id
        One or more channel IDs to extract history from.

    .PARAMETER Before
        Return history from before this date

    .PARAMETER After
        Return history from after this date

    .PARAMETER Inclusive
        If specified, include history from the date specified in Before and/or After parameters

    .PARAMETER Count
        Maximum number of messages to return per query (see 'limit' on API docs).  Defaults to 100.  Max 1000

    .PARAMETER Paging
        If specified, and more data is available with a given 'Count', continue querying Slack until
            we have retrieved all the data available.

        WARNING: This parameter is experimental

    .PARAMETER MaxQueries
        Limit the count of API queries to this number.  Only used if you enable -Paging

    .PARAMETER Raw
        If specified, we provide raw output and do not parse any responses

    .FUNCTIONALITY
        Slack
    #>
    [cmdletbinding()]
    param (
        $Token = $Script:PSSlack.Token,
        [parameter( ValueFromPipelineByPropertyName = $True)] # a bit iffy... ID is common...
        [Alias('ID')]
        [string[]]$ChannelID,

        [ValidateRange(1,1000)]
        [int]$Count = 100,
        [switch]$Inclusive,
        [datetime]$Before,
        [datetime]$After,
        [switch]$Paging,
        [int]$MaxQueries,
        [switch]$Raw

    )
    begin
    {
        Write-Verbose "$($PSBoundParameters | Remove-SensitiveData | Out-String)"
        $body = @{
            channel = $null
            limit = $count
        }
        if($Paging)
        {
            $PageDirection = 'Backward'
        }
        $BeforeTS = $null
        $AfterTS = $null
        if($PSBoundParameters.ContainsKey('Before'))
        {
            $BeforeTS = Get-UnixTime -Date $Before
            $body.add('latest', $BeforeTS)
        }
        if($PSBoundParameters.ContainsKey('After'))
        {
            $AfterTS = Get-UnixTime -Date $After
            $body.add('oldest', $AfterTS)
            if(-not $PSBoundParameters.ContainsKey('Before') -and $Paging)
            {
                $PageDirection = 'Forward'
            }
        }
        if($Inclusive)
        {
            $body.add('inclusive', 1)
        }
        $params = @{
            Token = $Token
            Method = 'conversations.history'
            Body = $body
        }
        $Queries = 1

    }
    process
    {
        foreach($ID in $ChannelID)
        {
            $has_more = $false
            $Params.body.channel = $ID
            do
            {
                if($has_more)
                {
                    if($Params.Body.oldest)
                    {
                        [void]$Params.Body.remove('oldest')
                    }
                    if($Params.Body.latest)
                    {
                        [void]$Params.Body.remove('latest')
                    }
                    if($PageDirection -eq 'Forward')
                    {

                        $ts = $response.messages.ts | Sort-Object | 
                            Microsoft.PowerShell.Utility\Select-Object -last 1
                        $Params.body.oldest = $ts
                        Write-Debug "Paging Forward.`n$(
                            [pscustomobject]@{
                                After = $After
                                Before = $Before
                                LastTS = $response.messages[-1].ts
                                SortLast = $response.messages.ts | Sort-Object | 
                                    Microsoft.PowerShell.Utility\Select-Object -last 1
                                SortFirst = $response.messages.ts | Sort-Object | 
                                    Microsoft.PowerShell.Utility\Select-Object -first 1
                                ts = $ts
                            } | Out-String
                        )"
                    }
                    elseif($PageDirection -eq 'Backward')
                    {
                        $ts = $response.messages[-1].ts
                        if($AfterTS -and $ts -lt $AfterTS)
                        {
                            Write-Debug "TS is less than AfterTS, breaking!"
                            break
                        }
                        $Params.body.latest = $ts
                        Write-Debug "Paging Forward.`n$(
                            [pscustomobject]@{
                                After = $After
                                Before = $Before
                                LastTS = $response.messages[-1].ts
                                SortLast = $response.messages.ts | Sort-Object | 
                                    Microsoft.PowerShell.Utility\Select-Object -last 1
                                SortFirst = $response.messages.ts | Sort-Object | 
                                    Microsoft.PowerShell.Utility\Select-Object -first 1
                                ts = $ts
                            } | Out-String
                        )"
                    }

                    $has_more = $false
                    Write-Debug "Body is now:$($params.body | out-string)"
                }
                $response = Send-SlackApi @params

                Write-Debug "$($Response | Format-List -Property * | Out-String)"

                if ($response.ok)
                {

                    if($response.psobject.properties.name -contains 'has_more' -and $response.has_more)
                    {
                        Write-Debug 'Paging engaged!'
                        $has_more = $true
                    }

                    if($Raw)
                    {
                        $link = "$($Script:PSSlack.ArchiveUri)/$($response.channel)/p$($response.ts -replace '\.')"
                        $response | Add-Member -MemberType NoteProperty -Name link -Value $link
                        $response
                    }
                    else
                    {
                        #Order our messages appropriately according to page direction
                        if($Paging -and $PageDirection -eq 'Forward')
                        {
                            Parse-SlackMessage -InputObject $Response | Sort-Object TimeStamp
                        }
                        else
                        {
                            Parse-SlackMessage -InputObject $Response
                        }
                    }
                }
                else
                {
                    $response
                }
                $Queries++
            }
            until (
                -not $Paging -or
                -not $has_more -or
                ($MaxQueries -and $Queries -gt $MaxQueries)
            )
        }
    }
}