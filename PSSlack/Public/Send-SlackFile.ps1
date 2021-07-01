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

    .PARAMETER Thread
        Optional thread where file is sent. Needs to be the parent thread id which is either the ts or thread_ts.

        Can find a ts by querying https://api.slack.com/methods/conversations.history

    .PARAMETER FileName
        Required filename for this file.  Used to determine syntax highlighting and other functionality.

    .PARAMETER Title
        Optional title of the file

    .PARAMETER Comment
        Optional initial comment for the file

    .PARAMETER ForceVerbose
        If specified, don't explicitly remove verbose output from Invoke-RestMethod

        *** WARNING ***
        This will expose your token in verbose output

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
        [string]$Thread,
        [string]$FileName,
        [String]$Title,
        [String]$Comment,

        [switch]$ForceVerbose = $Script:PSSlack.ForceVerbose
    )
    process
    {
        if ($Content) {
            $body = @{}
            switch ($psboundparameters.keys) {
            'Content'     {$body.content     = $content}
            'Channel'     {$body.channels = $Channel -join ", " }
            'Thread'      {$body.thread_ts = $Thread}
            'FileName'    {$body.filename = $FileName}
            'Title'       {$body.Title = $Title}
            'Comment'     {$body.initial_comment = $Comment}
            'FileType'    {$body.filetype = $FileType}
            }
            Write-Verbose "Send-SlackApi -Body $($body | Format-List | Out-String)"
            $Params = @{
                Method = 'files.upload'
                Body = $Body
                Token = $Token
                ForceVerbose = $ForceVerbose
            }
            $response = Send-SlackApi @Params
        } else {

            $fileName = (Split-Path -Path $Path -Leaf)
            $uri = 'https://slack.com/api/files.upload'

            if ($IsCoreCLR) {
                # PowerShell Core implementation

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
                    'Thread' {
                        # Add Thread
                        $threadHeader = [System.Net.Http.Headers.ContentDispositionHeaderValue]::new('form-data')
                        $threadHeader.Name = 'thread_ts'
                        $threadContent = [System.Net.Http.StringContent]::new($Thread)
                        $threadContent.Headers.ContentDisposition = $threadHeader
                        $multipartContent.Add($threadContent)
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
                finally {
                    $fileStream.Close()
                }
            }
            else {
                # Legacy Windows PowerShell implementation

                $LF = "`r`n"
                $readFile = [System.IO.File]::ReadAllBytes($Path)
                $enc = [System.Text.Encoding]::GetEncoding("iso-8859-1")
                $fileEnc = $enc.GetString($readFile)
                $boundary = [System.Guid]::NewGuid().ToString()

                $bodyLines =
                    "--$boundary$LF" +
                    "Content-Disposition: form-data; name=`"file`"; filename=`"$fileName`"$LF" +
                    "Content-Type: 'multipart/form-data'$LF$LF" +
                    "$fileEnc$LF" +
                    "--$boundary$LF" +
                    "Content-Disposition: form-data; name=`"token`"$LF" +
                    "Content-Type: 'multipart/form-data'$LF$LF" +
                    "$token$LF"


                switch ($psboundparameters.keys) {
                'Channel'     {$bodyLines +=
                                ("--$boundary$LF" +
                                "Content-Disposition: form-data; name=`"channels`"$LF" +
                                "Content-Type: multipart/form-data$LF$LF" +
                                ($Channel -join ", ") + $LF)}
                'Thread'     {$bodyLines +=
                                ("--$boundary$LF" +
                                "Content-Disposition: form-data; name=`"thread_ts`"$LF" +
                                "Content-Type: multipart/form-data$LF$LF" +
                                "$Thread$LF")}
                'FileName'    {$bodyLines +=
                                ("--$boundary$LF" +
                                "Content-Disposition: form-data; name=`"filename`"$LF" +
                                "Content-Type: multipart/form-data$LF$LF" +
                                "$FileName$LF")}
                'Title'       {$bodyLines +=
                                ("--$boundary$LF" +
                                "Content-Disposition: form-data; name=`"title`"$LF" +
                                "Content-Type: multipart/form-data$LF$LF" +
                                "$Title$LF")}
                'Comment'     {$bodyLines +=
                                ("--$boundary$LF" +
                                "Content-Disposition: form-data; name=`"initial_comment`"$LF" +
                                "Content-Type: multipart/form-data$LF$LF" +
                                "$Comment$LF")}
                }
                $bodyLines += "--$boundary--$LF"
                try {
                    $Params = @{
                        Uri = $uri
                        Method = 'Post'
                        ContentType = "multipart/form-data; boundary=`"$boundary`""
                        Body = $bodyLines
                    }
                    if(-not $ForceVerbose) {
                        $Params.Add('Verbose', $False)
                    }
                    if($ForceVerbose) {
                        $Params.Add('Verbose', $true)
                    }
                    $response = Invoke-RestMethod @Params
                }
                catch [System.Net.WebException] {
                    Write-Error( "Rest call failed for $uri`: $_" )
                    throw $_
                }
            }
        }
        $response
    }
}