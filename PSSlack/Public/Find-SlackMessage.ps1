function Find-SlackMessage {
  param (
      [string]$Query,
      $Token,
      [validateset('asc','desc')]
      $SortDirection = 'desc',
      [validateset('score','timestamp')]
      $SortBy = 'score'
  )
  end
  {
    $body = @{
        query = $Query
        sort_dir = $SortDirection
        sort = $SortBy
    }
    $params = @{
        Body = $Body
        method = 'search.messages'
    }
    if($PSBoundParameters.ContainsKey('Token'))
    {
        $Params.Add('Token',$token)
    }

    $response = Send-SlackApi @params
    
    if ($response.ok)
    {
      $link = "$($Script:PSSlack.ArchiveUri)/$($response.channel)/" +
        "p$($response.ts -replace '\.')"
      $response | 
        add-member -membertype NoteProperty -Name link -Value $link
    }

    $response
  }
}