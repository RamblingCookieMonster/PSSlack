function Remove-SlackFile {
    <#
    .SYNOPSIS
        Remove Slack files
    .DESCRIPTION
        Remove Slack files
    .PARAMETER Token
        Token to use for the Slack API

        Default value is the value set by Set-PSSlackConfig
    .PARAMETER ID
        Remove file with this ID
    .PARAMETER Force
        If specified, override all prompts and delete file
    .PARAMETER Raw
        Return raw output
    .EXAMPLE
        Remove-SlackFile -id F18UVDLR3 -Force
        # Remove a specific file without prompts
    .EXAMPLE
        Get-SlackFile -Before (Get-Date).AddYears(-1) | Remove-SlackFile -id F18UVDLR3
        # Remove files created over a year ago
    .FUNCTIONALITY
        Slack
    #>
    [cmdletbinding(SupportsShouldProcess=$true, ConfirmImpact="High")]
    param (
        [parameter( ValueFromPipelineByPropertyName = $True)]
        [string]$Id,
        [string]$Token = $Script:PSSlack.Token,
        [switch]$Force,
        [switch]$Raw
    )
    begin
    {
        Write-Verbose "$($PSBoundParameters | Out-String)"
        $RejectAll = $false
        $ConfirmAll = $false
    }
    process
    {
        foreach($FileID in $Id)
        {
            $body = @{
                file = $FileID
            }
            $params = @{
                Token = $Token
                Method = 'files.delete'
                Body = $body
            }
            if( ($Force -and -not $WhatIfPreference) -or $PSCmdlet.ShouldProcess( "Removed the file [$FileID]",
                                        "Remove the file [$FileID]?",
                                        "Removing Files" )) {
                if( ($Force -and -not $WhatIfPreference) -or $PSCmdlet.ShouldContinue("Are you REALLY sure you want to remove [$FileID]?",
                                                       "Removing [$FileID]",
                                                       [ref]$ConfirmAll,
                                                       [ref]$RejectAll)) {
                    $Response = Send-SlackApi @params
                    if($Raw)
                    {
                        return $Response
                    }
                    if($Response.ok)
                    {
                        [pscustomobject]@{
                            Id = $FileID
                            ok = $true
                            Raw = $Response
                        }
                    }
                    else
                    {
                        [pscustomobject]@{
                            Id = $FileID
                            ok = $false
                            Error = $Response.error
                            Raw = $Response
                        }                        
                    }
                }
            }
        }
    }
}