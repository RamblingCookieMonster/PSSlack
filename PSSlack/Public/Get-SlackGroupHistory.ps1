function Get-SlackGroupHistory {
    <#
    .SYNOPSIS
        Get history from a Slack group

    .DESCRIPTION
        Get history from a Slack group (this is more or less an alias for Get-SlackHistory).

    .PARAMETER Token
        Specify a token for authorization.

        See 'Authentication' section here for more information: https://api.slack.com/web
        Test tokens are a simple way to use this

    .PARAMETER Id
        One or more group IDs to extract history from.

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
        [string[]]$GroupID,

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
        if ($PSBoundParameters.ContainsKey('GroupID')) {
            $PSBoundParameters['ChannelID'] = $PSBoundParameters['GroupID']
            $PSBoundParameters.Remove('GroupID')
        }
    }
    end {
        Get-SlackHistory @PSBoundParameters
    }
}