function Send-SlackFile {
    <#
    .SYNOPSIS
        Send a Slack file

    .DESCRIPTION
        Send a Slack file

        We currently only support the 'Content' option for uploads. PRs for 'File' welcome :)
        https://api.slack.com/methods/files.upload

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
            'Comment'     {$body.comment = $Comment}
            'FileType'    {$body.filetype = $FileType}
            }
            Write-Verbose "Send-SlackApi -Body $($body | Format-List | Out-String)"
            $response = Send-SlackApi -Method files.upload -Body $body -Token $Token
        } else {

            $LF = "`r`n"
            $uri = "https://slack.com/api/files.upload"
            $fileName = (Split-Path -Path $Path -Leaf)
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
                            "Content-Disposition: form-data; name=`"comment`"$LF" +
                            "Content-Type: multipart/form-data$LF$LF" +
                            "$Title$LF")}
            }
            $bodyLines += "--$boundary--$LF"
            
            try {
                # Submit form-data with Invoke-RestMethod-Cmdlet
                $response = Invoke-RestMethod -Uri $uri -Method Post -ContentType "multipart/form-data; boundary=`"$boundary`"" -Body $bodyLines
            }
            # In case of emergency...
            catch [System.Net.WebException] {
                Write-Error( "Rest call failed for $uri`: $_" )
                throw $_
            }
        }
        $response
    }
}