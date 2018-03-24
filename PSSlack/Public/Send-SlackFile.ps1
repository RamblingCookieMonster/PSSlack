function Send-SlackFile {
    <#
    .SYNOPSIS
        Send a Slack file

    .DESCRIPTION
        Send a Slack file

    .PARAMETER Token
        Token to use for the Slack API

        Default value is the value set by Set-PSSlackConfig

    .PARAMETER Content
        Content of the file to send.  Text is editable after sending.

    .Parameter FileType
        If specified, override the FileType determined by the filename.

        List of types: https://api.slack.com/types/file#file_types

    .PARAMETER Channel
        Optional channel, private group, or IM channel to send file to. Can be an encoded ID, or a name.

    .PARAMETER FileName
        Required filename for this file.  Used to determine syntax highlighting and other functionality.

    .PARAMETER Title
        Optional title of the file

    .PARAMETER Comment
        Optional initial comment for the file

    .EXAMPLE
        Send-SlackFile -Token $Token `
                       -Channel general `
                       -Content 'get-help about_* | get-random' `
                       -FileType perl `
                       -filename example.ps1

        # Send a slack file that turns into a snippet.
        # Use perl, because PowerShell syntax highlighting is sad

    .EXAMPLE
        Send-SlackFile -Channel '@wframe' `
                       -path C:\homer.gif `
                       -title homer

        # Send a gif to @wframe using a previously-stored token (Set-PSSlackConfig)

    .FUNCTIONALITY
        Slack
    #>

    [cmdletbinding(DefaultParameterSetName = 'Content')]
    param (
        [string]$Token = $Script:PSSlack.Token,

        [parameter(ParameterSetName = 'Content',
                   Mandatory = $True)]
        [string]$Content,

        [validatescript({Test-Path -PathType Leaf -Path $_})]
        [parameter(ParameterSetName = 'File',
                   Mandatory = $True)]
        [string]$Path,

        [parameter(ParameterSetName = 'Content')]
        [string]$FileType,

        [string[]]$Channel,
        [string]$FileName,
        [String]$Title,
        [String]$Comment
    )
    process
    {
        if ($Content) {
            $body = @{}
            switch ($psboundparameters.keys) {
            'Content'     {$body.content     = $content}
            'Channel'     {$body.channels = $Channel -join ", " }
            'FileName'    {$body.filename = $FileName}
            'Title'       {$body.Title = $Title}
            'Comment'     {$body.initial_comment = $Comment}
            'FileType'    {$body.filetype = $FileType}
            }
            Write-Verbose "Send-SlackApi -Body $($body | Format-List | Out-String)"
            $response = Send-SlackApi -Method files.upload -Body $body -Token $Token
        } else {
            $fileName = (Split-Path -Path $Path -Leaf)
            $uri = 'https://slack.com/api/files.upload'

            $multipartContent = [System.Net.Http.MultipartFormDataContent]::new()

            # Add file contents
            $fileHeader = [System.Net.Http.Headers.ContentDispositionHeaderValue]::new('form-data')
            $fileHeader.Name = 'file'
            $fileHeader.FileName = $FileName
            $fileStream = [System.IO.FileStream]::new($Path, [System.IO.FileMode]::Open)
            $fileContent = [System.Net.Http.StreamContent]::new($fileStream)
            $fileContent.Headers.ContentDisposition = $fileHeader
            $fileContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse('multipart/form-data')
            $multipartContent.Add($fileContent)

            # Add token
            $tokenHeader = [System.Net.Http.Headers.ContentDispositionHeaderValue]::new('form-data')
            $tokenHeader.Name = 'token'
            $tokenContent = [System.Net.Http.StringContent]::new($token)
            $tokenContent.Headers.ContentDisposition = $tokenHeader
            $multipartContent.Add($tokenContent)

            switch ($psboundparameters.keys) {
                'Channel' {
                    # Add channel
                    $channelHeader = [System.Net.Http.Headers.ContentDispositionHeaderValue]::new('form-data')
                    $channelHeader.Name = 'channels'
                    $channelContent = [System.Net.Http.StringContent]::new(($Channel -join ', '))
                    $channelContent.Headers.ContentDisposition = $channelHeader
                    $multipartContent.Add($channelContent)
                }
                'FileName' {
                    # Add file name
                    $filenameHeader = [System.Net.Http.Headers.ContentDispositionHeaderValue]::new('form-data')
                    $filenameHeader.Name = 'filename'
                    $filenameContent = [System.Net.Http.StringContent]::new($FileName)
                    $filenameContent.Headers.ContentDisposition = $filenameHeader
                    $multipartContent.Add($filenameContent)
                }
                'Title' {
                    # Add title
                    $titleHeader = [System.Net.Http.Headers.ContentDispositionHeaderValue]::new('form-data')
                    $titleHeader.Name = 'title'
                    $titleContent = [System.Net.Http.StringContent]::new($Title)
                    $titleContent.Headers.ContentDisposition = $titleHeader
                    $multipartContent.Add($titleContent)
                }
                'Comment' {
                    # Add comment
                    $commentHeader = [System.Net.Http.Headers.ContentDispositionHeaderValue]::new('form-data')
                    $commentHeader.Name = 'initial_comment'
                    $commentContent = [System.Net.Http.StringContent]::new($Comment)
                    $commentContent.Headers.ContentDisposition = $commentHeader
                    $multipartContent.Add($commentContent)
                }
            }

            try {
                $response = Invoke-RestMethod -Uri $uri -Method Post -Body $multipartContent
            }
            catch [System.Net.WebException] {
                Write-Error( "Rest call failed for $uri`: $_" )
                throw $_
            }
        }
        $response
    }
}