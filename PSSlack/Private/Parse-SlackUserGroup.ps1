Function Parse-SlackUserGroup {
    [cmdletbinding()]
    param( $InputObject )

    foreach($Group in $InputObject)
    {
        $Users = $null
        if($Group.users.count -gt 0) {
            $Users = Get-SlackUserFromID -Id $Group.users
            $UserCount = $Users.count
        }
        else {
            $UserCount = $null
        }
        [pscustomobject]@{
            PSTypeName = 'PSSlack.UserGroup'
            ID = $Group.id
            Name = $Group.name
            Handle = $Group.handle
            Description = $Group.description
            Created = ConvertFrom-UnixTime $Group.'date_create'
            Updated = ConvertFrom-UnixTime $Group.'date_update'
            CreatedBy = Get-SlackUserFromID -Id $Group.'created_by'
            UpdatedBy = Get-SlackUserFromID -Id $Group.'updated_by'
            Users = $Users
            UserCount = $UserCount
            Raw = $Group
        }
    }
}