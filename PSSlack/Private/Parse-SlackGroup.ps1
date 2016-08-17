Function Parse-SlackGroup {
    [cmdletbinding()]
    param( $InputObject )

    foreach($Group in $InputObject)
    {
        $TopicSet = $null
        $PurposeSet = $null
        if($Group.Purpose.last_set)
        {
            $PurposeSet = ConvertFrom-UnixTime $Group.Purpose.last_set
        }
        if($Group.topic.last_set)
        {
            $TopicSet = ConvertFrom-UnixTime $Group.topic.last_set
        }
        [pscustomobject]@{
            PSTypeName = 'PSSlack.Group'
            ID = $Group.id
            Name = $Group.name
            Created = ConvertFrom-UnixTime $Group.created
            Creator = $Group.creator
            IsArchived = $Group.is_archived
            Members = $Group.members
            Topic = $Group.Topic.value
            TopicSet = $TopicSet
            Purpose = $Group.Purpose.value
            PurposeSet = $PurposeSet
            MemberCount = ($Group.members).Count
            Raw = $Group
        }
    }
}