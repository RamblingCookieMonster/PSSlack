# Parse auth.test
Function Parse-SlackAuth {
    [CmdletBinding()]
    param( $InputObject )

    foreach($Auth in $InputObject)
    {
        [PSCustomObject] @{
            PSTypeName = 'PSSlack.AuthInfo'

            IsAuthenticated = [bool] $Auth.ok
            Error = if ($Auth.Error) { $Auth.Error } else { }

            Url = $Auth.url

            UserID = $Auth.user_id
            User = $Auth.user

            TeamID = $Auth.team_id
            Team = $Auth.team

            Raw = $Auth
        }
    }
}