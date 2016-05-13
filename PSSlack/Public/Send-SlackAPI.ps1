function Send-SlackApi {
    param (
        $Method,
        $Body = @{},
        $Token = $Script:PSSlack.Token
    )

    if ([string]::isnullorempty($token)){
        throw "Please supply a Slack Api Token with Set-SlackApiToken."
    }

    $Body.token = $Token
    Invoke-RestMethod -Uri "https://slack.com/api/$method" -body $Body
}