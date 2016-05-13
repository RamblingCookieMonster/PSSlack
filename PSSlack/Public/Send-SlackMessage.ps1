function Send-SlackMessage {
    [cmdletbinding(DefaultParameterSetName = 'Param')]
    param (
        [string]$Token = $Script:PSSlack.Token,
        [string]$Uri,
        [parameter(ParameterSetName = 'SlackMessage')]
        $SlackMessage,
        $Channel,
        [parameter(ParameterSetName = 'Param')]
        $Text,
        [parameter(ParameterSetName = 'Param')]
        $Username, 
        [parameter(ParameterSetName = 'Param')]
        $IconUrl, 
        [parameter(ParameterSetName = 'Param')]
        [switch]$AsUser,
        [parameter(ParameterSetName = 'Param')]
        [switch]$LinkNames,
        [parameter(ParameterSetName = 'Param')]
        [validateset('full','none')]
        [string]$Parse = 'none',
        [parameter(ParameterSetName = 'Param')]
        [validateset($True, $False)]
        [bool]$UnfurlLinks,
        [parameter(ParameterSetName = 'Param')]
        [validateset($True, $False)]
        [bool]$UnfurlMedia,
        [object[]]$Attachments
    )
    end {

        $body = @{
            channel = $channel
        }

        if($PSCmdlet.ParameterSetName -eq 'Param')
        {
            switch ($psboundparameters.keys) {
                'text'        {$body.text     = $text}
                'username'    {$body.username = $username}
                'as_user'     {$body.asuser = $AsUser}
                'iconurl'     {$body.icon_url = $iconurl}
                'link_names'  {$body.link_names = 1}
                'parse'       {$body.parse = $Parse}
                'UnfurlLinks' {$body.unfurl_links = $UnfurlLinks}
                'UnfurlMedia' {$body.unfurl_media = $UnfurlMedia}
                'attachments' {$body.attachments = $Attachments}
            }
        }
        else
        {
            $body = $SlackMessage
        }

        if($Token -or ($Script:PSSlack.Token -and -not $Uri))
        {

            if($body.attachments)
            {
                $body.attachments = ConvertTo-Json -InputObject @($body.attachments) -Depth 4 -Compress
            }
            
            Write-Verbose "Send-SlackApi -Body $($Body | Format-List | Out-String)"
            $response = Send-SlackApi -Method chat.postMessage -Body $body -Token $Token
    
            if ($response.ok)
            {
                $link = "$($Script:PSSlack.ArchiveUri)/$($response.channel)/p$($response.ts -replace '\.')"
                $response | Add-Member -MemberType NoteProperty -Name link -Value $link
            }
    
            $response
        }
        Elseif($Uri -or $Script:PSSlack.Uri)
        {
            $json = ConvertTo-Json -Depth 4 -Compress -InputObject $body
            Invoke-RestMethod -Method Post -Body $json -Uri $Uri
        }
        else
        {
            Throw 'No Uri or Token specified.  Specify a Uri or Token in the parameters or via Set-PSSlackConfig'
        }
    }
}