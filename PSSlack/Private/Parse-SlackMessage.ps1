# Parse output from search.messages
Function Parse-SlackMessage {
    [cmdletbinding()]
    param(
        $InputObject,
        [switch]$Match
    )

    function Extract-Previous {
        param($Message)
        if($Message.username -or $Message.Text)
        {
            "@{0}: {1}" -f $Message.Username, $Message.Text
        }
        else
        {
            $null
        }
    }

    if($Match)
    {
        $Messages = $InputObject.messages.matches
        $pstypename = 'PSSlack.SearchResult'

        foreach($Message in $Messages)
        {
            [pscustomobject]@{
                PSTypeName = $pstypename
                Username = $Message.username
                Channel = $Message.channel.name
                Text = $Message.text
                Attachments = $Message.Attachments
                Reactions = $Message.Reactions
                File = $Message.File
                Type = $Message.Type
                SubType = $Message.subtype
                Timestamp = ConvertFrom-UnixTime $Message.ts
                Permalink = $Message.permalink
                Previous = Extract-Previous $Message.Previous
                Previous_2 = Extract-Previous $Message.Previous_2
                Next = Extract-Previous $Message.Next
                Next_2 = Extract-Previous $Message.Next_2
            }
        }
    }
    else
    {
        $Messages = $InputObject.messages
        $pstypename = 'PSSlack.History'

        foreach($Message in $Messages)
        {
            [pscustomobject]@{
                PSTypeName = $pstypename
                Username = $Message.username
                Text = $Message.text
                Attachments = $Message.Attachments
                Reactions = $Message.Reactions
                File = $Message.File
                Type = $Message.Type
                SubType = $Message.subtype
                Timestamp = ConvertFrom-UnixTime $Message.ts
            }
        }
    }
}