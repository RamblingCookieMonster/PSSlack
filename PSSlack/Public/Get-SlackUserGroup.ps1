function Get-SlackUserGroup {
    <#
    .SYNOPSIS
        Get Slack user groups
    .DESCRIPTION
        Get Slack user groups
    .PARAMETER Token
        Token to use for the Slack API
        Default value is the value set by Set-PSSlackConfig
    .PARAMETER IncludeUsers
        If specified, include users

        If you update the user map ahead of time, we parse user IDs to user names:
            Get-SlackUserMap -Update ahead of team
    .PARAMETER IncludeDisabled
        If specified, include disabled users
    .Parameter Raw
        Return raw output.  If specified, Name parameter is ignored
    .EXAMPLE
        Get-SlackUserGroup
        # Get slack user group info
    .EXAMPLE
        $null = Get-SlackUserMap -Update
        Get-SlackUserGroup -IncludeUsers

        # Get user id to name map, pull user groups and their members
    .FUNCTIONALITY
        Slack
    #>
    [cmdletbinding()]
    param (
        [string]$Token = $Script:PSSlack.Token,
        [switch]$IncludeUsers,
        [switch]$IncludeDisabled,
        [switch]$Raw
    )
    begin
    {
        Write-Verbose "$($PSBoundParameters | Out-String)"
        $body = @{}
        if($IncludeUsers) {
            $body.add('include_users',$true)
        }
        if($IncludeDisabled) {
            $body.add('include_disabled',$true)
        }

        $params = @{
            Token = $Token
            Method = 'usergroups.list'
        }
        if($body.keys.count -gt 0) {
            $params.add('body',$body)
        }

        $RawGroups = Send-SlackApi @params
        if($Raw) {
            $RawGroups
        }
        else {
            Parse-SlackUserGroup -InputObject $RawGroups.usergroups
        }
    }
}
