# Parse users
Function Parse-SlackUser {
    [cmdletbinding()]
    param( $InputObject )

    foreach($User in $InputObject)
    {
        [pscustomobject]@{
            PSTypeName = 'PSSlack.User'
            ID = $User.id
            Name = $User.name
            DisplayName = $User.Profile.Display_Name
            RealName = $User.Profile.Real_Name
            FirstName = $User.Profile.First_Name
            Last_Name = $User.Profile.Last_Name
            Email = $User.Profile.email
            Phone = $User.Profile.Phone
            Skype = $User.Profile.Skype
            IsBot = $User.Is_Bot
            IsAdmin = $User.Is_Admin
            IsOwner = $User.Is_Owner
            IsPrimaryOwner = $User.Is_Primary_Owner
            IsRestricted = $User.Is_Restricted
            IsUltraRestricted = $User.Is_Ultra_Restricted
            StatusText = $User.Profile.Status_Text
            StatusEmoji = $User.Profile.Status_Emoji
            TimeZoneLabel = $User.tz_label
            TimeZone = $User.tz
            Presence = $User.Presence
            BillingActive = $User.BillingActive
            Updated = ConvertFrom-UnixTime $User.updated
            Deleted = $User.Deleted
            Raw = $User
        }
    }
}