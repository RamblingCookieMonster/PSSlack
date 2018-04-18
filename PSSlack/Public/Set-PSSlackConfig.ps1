function Set-PSSlackConfig {
    <#
    .SYNOPSIS
        Set PSSlack module configuration.

    .DESCRIPTION
        Set PSSlack module configuration, and $PSSlack module variable.

        This data is used as the default Token and Uri for most commands.

        If a command takes either a token or a uri, tokens take precedence.

        WARNING: Use this to store the token or uri on a filesystem at your own risk
                 Only supported on Windows systems, via the DPAPI

    .PARAMETER Token
        Specify a Token to use

        Only serialized to disk on Windows, via DPAPI

    .PARAMETER Uri
        Specify a Uri to use

        Only serialized to disk on Windows, via DPAPI

    .PARAMETER ArchiveUri
        Archive URI. Generally, https://<TEAMNAME>.slack.com/archives/

        Used to generate a link to a specific archive URI, where appropriate

    .PARAMETER Proxy
        Proxy to use with Invoke-RESTMethod

    .PARAMETER MapUser
        Whether to generate a map of Slack user ID to name on module load, for use in Slack File commands

    .PARAMETER Path
        If specified, save config file to this file path.  Defaults to PSSlack.xml in the user temp folder on Windows, or .psslack in the user's home directory on Linux/macOS.

    .FUNCTIONALITY
        Slack
    #>
    [cmdletbinding()]
    param(
        [string]$Uri,
        [string]$Token,
        [string]$ArchiveUri,
        [string]$Proxy,
        [bool]$MapUser,
        [string]$Path = $script:_PSSlackXmlpath
    )

    Switch ($PSBoundParameters.Keys)
    {
        'Uri'        { $Script:PSSlack.Uri = $Uri }
        'Token'      { $Script:PSSlack.Token = $Token }
        'ArchiveUri' { $Script:PSSlack.ArchiveUri = $ArchiveUri }
        'Proxy'      { $Script:PSSlack.Proxy = $Proxy }
        'MapUser'    { $Script:PSSlack.MapUser = $MapUser }
    }

    Function Encrypt {
        param([string]$string)
        if($String -notlike '' -and (Test-IsWindows))
        {
            ConvertTo-SecureString -String $string -AsPlainText -Force
        }
    }

    #Write the global variable and the xml
    $Script:PSSlack |
        Select-Object -Property ArchiveUri,
                                @{l='Uri';e={Encrypt $_.Uri}},
                                @{l='Token';e={Encrypt $_.Token}},
                                Proxy,
                                MapUser |
        Export-Clixml -Path $Path -force

}
