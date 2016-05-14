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
        Import-Clixml -Path "$PSScriptRoot\PSSlack.xml"
    }

}