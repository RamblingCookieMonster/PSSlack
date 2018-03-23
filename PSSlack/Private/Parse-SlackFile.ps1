# Parse output from search.messages
Function Parse-SlackFile {
    [cmdletbinding()]
    param(
        $InputObject,
        [switch]$Match
    )
    $Files = $InputObject.files
    $pstypename = 'PSSlack.File'
    foreach($File in $Files)
    {
        $UserName = $null
        $Map = @{}
        foreach($Key in $Script:_PSSlackUserMap.Keys) {
            $Map.add($Script:_PSSlackUserMap[$Key], $Key)
        }
        if($Map.ContainsKey($File.user))
        {
            $UserName = $Map[$File.user]
        }
        if($Script:_PSSlackUserMap.Keys.Count -like 0) {
            Write-Verbose "No Slack User Map found.  Please run Get-SlackUserMap -Update"
        }
        [pscustomobject]@{
            PSTypeName = $pstypename
            ID = $File.id
            Name = $File.name
            Created = ConvertFrom-UnixTime $File.created
            Title = $File.title
            MimeType = $File.mimetype
            FileType = $File.filetype
            Type = $File.pretty_type
            UserName = $UserName
            UserID = $File.user
            Size = $File.size
            IsPublic = $File.is_public
            PermalinkPublic = $File.permalink_public
            Permalink = $File.permalink
            UrlPrivateDownload = $File.url_private_download
            Lines = $File.lines
            Channels = $File.channels
            Groups = $File.groups
            Ims = $File.ims
            Raw = $File
        }
    }
}