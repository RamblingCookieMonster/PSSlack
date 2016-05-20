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
        
        #[validatescript({Test-Path -PathType Leaf -Path $_})]
        #[parameter(ParameterSetName = 'File',
        #           Mandatory = $True)]
        #[string]$Path,
        
        [string[]]$Channel,
        [string]$FileName,
        [String]$Title,
        [String]$Comment
    )
    process
    {

        $body = @{}

        switch ($psboundparameters.keys) {
            'Content'     {$body.content     = $content}
            'Channel'     {$body.channels = $Channel -join ", " }
            'FileName'    {$body.filename = $FileName}
            'Title'       {$body.Title = $Title}
            'Comment'     {$body.comment = $Comment}
        }

        Write-Verbose "Send-SlackApi -Body $($body | Format-List | Out-String)"
        $response = Send-SlackApi -Method files.upload -Body $body -Token $Token
        $response
    }
}