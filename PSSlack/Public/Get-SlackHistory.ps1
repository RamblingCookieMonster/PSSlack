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
        Number of messages to return.  Defaults to 100.  Max 1000

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
        [switch]$Raw

    )
    begin
    {
        function Get-UnixTime {
            param($Date)
            $unixEpochStart = new-object DateTime 1970,1,1,0,0,0,([DateTimeKind]::Utc)
            [int]($Date.ToUniversalTime() - $unixEpochStart).TotalSeconds
        }

        Write-Verbose "$($PSBoundParameters | Out-String)"

        $body = @{ channel = $null }
        if($PSBoundParameters.ContainsKey('Before'))
        {
            $BeforeTS = Get-UnixTime -Date $Before
            $body.add('oldest', $BeforeTS)
        }
        if($PSBoundParameters.ContainsKey('After'))
        {
            $AfterTS = Get-UnixTime -Date $After
            $body.add('latest', $AfterTS)
        }
        if($Inclusive)
        {
            $body.add('inclusive', 1)
        }
        $params = @{
            Token = $Token
            Method = 'channels.history'
            Body = $body
        }

    }
    process
    {
        foreach($ID in $ChannelID)
        {
            $Params.body.channel = $ID
            $response = Send-SlackApi @params
            if ($response.ok)
            {
                if($Raw)
                {
                    $link = "$($Script:PSSlack.ArchiveUri)/$($response.channel)/p$($response.ts -replace '\.')"
                    $response | Add-Member -MemberType NoteProperty -Name link -Value $link
                    $response
                }
                else
                {
                    Parse-SlackMessage -InputObject $Response
                }
            }
            else 
            {
                $response
            }
        }
    }
}