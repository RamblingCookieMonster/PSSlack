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
            Permalink = $Message.permalink
            previous = Extract-Previous $Message.Previous
            previous_2 = Extract-Previous $Message.Previous_2
            next = Extract-Previous $Message.Next
            next_2 = Extract-Previous $Message.Next_2
        })
    }


}