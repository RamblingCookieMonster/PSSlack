function Get-SlackFile {
    <#
    .SYNOPSIS
        Get Slack files
    .DESCRIPTION
        Get Slack files
    .PARAMETER Token
        Token to use for the Slack API
        Default value is the value set by Set-PSSlackConfig
    .PARAMETER Channel
        If specified, search for files in this channel (ID)
    .PARAMETER Before
        If specified, search for files created before this date
    .PARAMETER After
        If specified, search for files created after this date
    .PARAMETER Types
        If specified, search for files of this type:
            all - All files
            spaces - Posts
            snippets - Snippets
            images - Image files
            gdocs - Google docs
            zips - Zip files
            pdfs - PDF files
    .PARAMETER User
        If specified, search for files by this user
    .Parameter Raw
        Return raw output.  If specified, Name parameter is ignored
    .PARAMETER Paging
        If specified, and more data is available, continue querying Slack until we have retrieved all the data available.
    .PARAMETER Count
        Number of messages to return per query.  Defaults to 100
    .PARAMETER MaxQueries
        Limit the count of API queries to this number.  Only used if you enable -Paging
    .EXAMPLE
        Get-SlackFile
        # Lists up to 100 files
    .EXAMPLE
        Get-SlackFile -Paging
        # Lists all files, querying 100 at a time
    .EXAMPLE
        Get-SlackFile -User wframe -Type csv -Paging
        # Lists all CSV files uploaded by wframe
    .EXAMPLE
        Get-SlackFile -User wframe -Channel C58AHBEPJ
        # Lists up to 100 files from channel C58AHBEPJ
    .EXAMPLE
        Get-SlackFile -Before (Get-Date).AddDays(-7) -After (Get-Date).AddDays(-14) -Paging
        # Get all files from a week ago
    .FUNCTIONALITY
        Slack
    #>
    [cmdletbinding()]
    param (
        [string]$Token = $Script:PSSlack.Token,
        [string]$Channel,
        [datetime]$Before,
        [datetime]$After,
        [validateset('all','spaces','snippets','images','gdocs','zips','pdfs')]
        [string[]]$Types,
        [string]$User,
        [switch]$Paging,
        [ValidateRange(1,1000)]
        [int]$Count = 100,
        [switch]$Raw,
        [int]$MaxQueries
    )
    begin
    {
        Write-Verbose "$($PSBoundParameters | Out-String)"
        $body = @{
            count = $count
        }
        if($User)
        {
            $u = $null
            if($Script:_PSSlackUserMap.ContainsKey($User)){
                $u = $Script:_PSSlackUserMap[$User]
            }
            else {
                $map = Get-SlackUserMap -Update -Token $Token
                if($map.ContainsKey($User))
                {
                    $u = $map[$User]
                }
                else
                {
                    Write-Warning "Could not find user [$User].  Check Get-SlackUserMap for valid names"
                }
            }
            if($u)
            {
                $body.add('user', $u)
            }
        }
        if($PSBoundParameters.ContainsKey('Channel'))
        {
            $body.add('channel', $Channel)
        }
        if($PSBoundParameters.ContainsKey('Types'))
        {
            $body.add('types', $($Types -join ','))
        }
        $BeforeTS = $null
        $AfterTS = $null
        if($PSBoundParameters.ContainsKey('Before'))
        {
            $BeforeTS = Get-UnixTime -Date $Before
            $body.add('ts_to', $BeforeTS)
        }
        if($PSBoundParameters.ContainsKey('After'))
        {
            $AfterTS = Get-UnixTime -Date $After
            $body.add('ts_from', $AfterTS)
        }
        $params = @{
            Token = $Token
            Method = 'files.list'
            Body = $body
        }
        $Queries = 1
        $has_more = $false
        do
        {
            $response = Send-SlackApi @params
            Write-Debug "$($Response | Format-List -Property * | Out-String)"
            if ($response.ok)
            {
                if($response.psobject.properties.name -contains 'paging' -and $response.paging.page -lt $response.paging.pages)
                {
                    Write-Debug 'Paging engaged!'
                    $has_more = $true
                    $Params.body.page = 1 + $response.paging.page
                }
                elseif ($response.psobject.properties.name -contains 'paging' -and $response.paging.page -like $response.paging.pages)
                {
                    $has_more = $false
                }
                else {
                    # Might need this case later - is paging always included?  Is this an error?
                    $has_more = $false
                }
                if($Raw)
                {
                    $response
                }
                else
                {
                    Parse-SlackFile -InputObject $Response 
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