Function Get-PSSlackConfig {
    <#
    .SYNOPSIS
        Get PSSlack module configuration.

    .DESCRIPTION
        Get PSSlack module configuration

    .PARAMETER Source
        Get the config data from either...

            PSSlack:     the live module variable used for command defaults
            PSSlack.xml: the serialized PSSlack.xml that loads when importing the module

        Defaults to PSSlack

    .PARAMETER Path
        If specified, read config from this XML file.

        Defaults to PSSlack.xml in the module root

    .FUNCTIONALITY
        Slack
    #>
    [cmdletbinding(DefaultParameterSetName = 'source')]
    param(
        [parameter(ParameterSetName='source')]
        [ValidateSet("PSSlack","PSSlack.xml")]
        $Source = "PSSlack",

        [parameter(ParameterSetName='path')]
        [parameter(ParameterSetName='source')]
        $Path = "$ModuleRoot\$env:USERNAME-$env:COMPUTERNAME-PSSlack.xml"
    )

    if($PSCmdlet.ParameterSetName -eq 'source' -and $Source -eq "PSSlack" -and -not $PSBoundParameters.ContainsKey('Path'))
    {
        $Script:PSSlack
    }
    else
    {
        function Decrypt {
            param($String)
            if($String -is [System.Security.SecureString])
            {
                [System.Runtime.InteropServices.marshal]::PtrToStringAuto(
                    [System.Runtime.InteropServices.marshal]::SecureStringToBSTR(
                        $string))
            }
        }
        Import-Clixml -Path $Path |
            Select-Object -Property ArchiveUri,
                                    @{l='Uri';e={Decrypt $_.Uri}},
                                    @{l='Token';e={Decrypt $_.Token}},
                                    Proxy
    }

}