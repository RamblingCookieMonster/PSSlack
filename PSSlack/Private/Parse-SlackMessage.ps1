# Parse output from search.messages
Function Parse-SlackMessage {
    [cmdletbinding()]
    param( $InputObject )

    function Extract-Previous {
        param($Message)
        "@{0}: {1}" -f $Message.Username, $Message.Text
    }

    foreach($Message in $InputObject.messages.matches)
    {
        Add-ObjectDetail -TypeName PSSlack.SearchResult -InputObject $([pscustomobject]@{
            Username = $Message.username
            Channel = $Message.channel.name
            Text = $Message.text
            Attachments = $Message.Attachments
            Timestamp = ConvertFrom-UnixTime $Message.ts
            Permalink = $Message.permalink
            Previous = Extract-Previous $Message.Previous
            Previous_2 = Extract-Previous $Message.Previous_2
            Next = Extract-Previous $Message.Next
            Next_2 = Extract-Previous $Message.Next_2
        })
    }


}