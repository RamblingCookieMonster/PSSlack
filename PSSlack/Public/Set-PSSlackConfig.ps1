function Set-PSSlackConfig {
    <#
    .SYNOPSIS
        Set PSSlack module configuration.

    .DESCRIPTION
        Set PSSlack module configuration, and $PSSlack module variable.

        This data is used as the default Token and Uri for most commands.

        If a command takes either a token or a uri, tokens take precedence.

        WARNING: Use this to store the token or uri on a filesystem at your own risk.
                 We use the DPAPI to store this.

    .PARAMETER Token
        Specify a Token to use

        Encrypted with the DPAPI

    .PARAMETER Uri
        Specify a Uri to use

        Encrypted with the DPAPI

    .PARAMETER ArchiveUri
        Archive URI. Generally, https://<TEAMNAME>.slack.com/archives/

        Used to generate a link to a specific archive URI, where appropriate

    .PARAMETER Proxy
        Proxy to use with Invoke-RESTMethod

    .PARAMETER Path
        If specified, save config file to this file path.  Defaults to PSSlack.xml in the module root.

    .FUNCTIONALITY
        Slack
    #>
    [cmdletbinding()]
    param(
        [string]$Uri,
        [string]$Token,
        [string]$ArchiveUri,
        [string]$Proxy,
        [string]$Path = "$ModuleRoot\$env:USERNAME-$env:COMPUTERNAME-PSSlack.xml"
    )

    Switch ($PSBoundParameters.Keys)
    {
        'Uri'        { $Script:PSSlack.Uri = $Uri }
        'Token'      { $Script:PSSlack.Token = $Token }
        'ArchiveUri' { $Script:PSSlack.ArchiveUri = $ArchiveUri }
        'Proxy'      { $Script:PSSlack.Proxy = $Proxy }
    }

    Function Encrypt {
        param([string]$string)
        if($String -notlike '')
        {
            ConvertTo-SecureString -String $string -AsPlainText -Force
        }
    }

    #Write the global variable and the xml
    $Script:PSSlack |
        Select-Object -Property ArchiveUri,
                                @{l='Uri';e={Encrypt $_.Uri}},
                                @{l='Token';e={Encrypt $_.Token}},
                                Proxy |
        Export-Clixml -Path $Path -force

}
