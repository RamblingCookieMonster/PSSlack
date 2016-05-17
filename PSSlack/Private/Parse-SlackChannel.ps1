# Parse channels
Function Parse-SlackChannel {
    [cmdletbinding()]
    param( $InputObject )

    foreach($Channel in $InputObject)
    {
        $TopicSet = $null
        $PurposeSet = $null
        if($Channel.Purpose.last_set)
        {
            $PurposeSet = ConvertFrom-UnixTime $Channel.Purpose.last_set
        }
        if($Channel.topic.last_set)
        {
            $TopicSet = ConvertFrom-UnixTime $Channel.topic.last_set
        }
        [pscustomobject]@{
            PSTypeName = 'PSSlack.Channel'
            ID = $Channel.id
            Name = $Channel.name
            Created = ConvertFrom-UnixTime $Channel.created
            Creator = $Channel.creator
            IsGeneral = $Channel.is_general
            IsArchived = $Channel.is_archived
            Members = $Channel.members
            Topic = $Channel.Topic.value
            TopicSet = $TopicSet
            Purpose = $Channel.Purpose.value
            PurposeSet = $PurposeSet
            MemberCount = $Channel.num_members
        }
    }
}