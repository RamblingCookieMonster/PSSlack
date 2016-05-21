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

    .FUNCTIONALITY
        Slack
    #>
    [cmdletbinding()]
    param(
        [ValidateSet("PSSlack","PSSlack.xml")]
        $Source = "PSSlack"
    )
    
    if($Source -eq "PSSlack")
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
        Import-Clixml -Path "$ModuleRoot\PSSlack.xml" |
            Select -Property ArchiveUri,
                         @{l='Uri';e={Decrypt $_.Uri}},
                         @{l='Token';e={Decrypt $_.Token}}
    }

}