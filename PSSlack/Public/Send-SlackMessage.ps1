function Send-SlackMessage {
  param (
      $text,
      $channel,
      $username, 
      $iconurl, 
      [switch]$AsUser
  )
  end {
    $body = @{
      
      channel = $channel
    }

    switch ($psboundparameters.keys) {
      'text'     {$body.text     = $text}
      'username' {$body.username = $username}
      'as_user'  {$body.AsUser = $AsUser}
      'iconurl'  {$body.icon_url = $iconurl}
    }

    $response = Send-SlackApi -method chat.postMessage -body $body
    
    if ($response.ok) {
      $link = "https://chefio.slack.com/archives/$($response.channel)/" +
        "p$($response.ts -replace '\.')"
      $response | 
        add-member -membertype NoteProperty -Name link -Value $link
    }

    $response
  }
}