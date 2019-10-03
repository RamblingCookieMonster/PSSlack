function Send-SlackChannelInvite {
    <#
    .SYNOPSIS
        Send a Slack channel invite

    .DESCRIPTION
        Send a Slack channel invite

    .PARAMETER Token
        Token to use for the Slack API

        Default value is the value set by Set-PSSlackConfig

    .PARAMETER Channel
        Channel, private group, or IM channel to send file to. Can be an encoded ID, or a name.

    .PARAMETER User
        Optional initial comment for the file

    .PARAMETER ForceVerbose
        If specified, don't explicitly remove verbose output from Invoke-RestMethod

        *** WARNING ***
        This will expose your token in verbose output

    .EXAMPLE
        Send-SlackChannelInvite -Token $Token `
                       -Channel test_channel `
                       -User test_user

    .FUNCTIONALITY
        Slack
    #>

    param (
        [string]$Token = $Script:PSSlack.Token,
        [string]$Channel,
        [string]$User,
        [switch]$ForceVerbose = $Script:PSSlack.ForceVerbose
    )
    process
    {
        $body = @{}
        switch ($psboundparameters.keys) {
            'Channel'     { $body.channel = $Channel }
            'User'        { $body.user = $User }
        }
        Write-Verbose "Send-SlackApi -Body $($body | Format-List | Out-String)"
        $Params = @{
            Method = 'channels.invite'
            Body = $Body
            Token = $Token
            ForceVerbose = $ForceVerbose
        }
        $response = Send-SlackApi @Params
        
        $response
    }
}