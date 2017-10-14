# Parse users
Function Parse-SlackTeam {
    [CmdletBinding()]
    param( $InputObject )

    foreach($Team in $InputObject)
    {
        [PSCustomObject] @{
            PSTypeName = 'PSSlack.Team'
            ID = $Team.id
            Name = $Team.name
            Domain = $Team.domain
            EmailDomain = ($Team.email_domain -split ',')
            Icon = [Ordered] @{
                Image34 = $Team.icon.image_34
                Image44 = $Team.icon.image_44
                Image68 = $Team.icon.image_68
                Image88 = $Team.icon.image_88
                Image102 = $Team.icon.image_102
                Image132 = $Team.icon.image_132
                Image230 = $Team.icon.image_230
                ImageDefault = $Team.icon.image_default
            }
            Raw = $Team
        }
    }
}