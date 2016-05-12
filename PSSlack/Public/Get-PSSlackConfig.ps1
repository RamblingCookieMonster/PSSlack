Function Get-PSSlackConfig {
    <#
    .SYNOPSIS
        Get PSSlack module configuration.

    .DESCRIPTION
        Get PSSlack module configuration

    .FUNCTIONALITY
        Slack
    #>
    [cmdletbinding()]
    param(
        [ValidateSet("PSSlack","PSSlack.xml")]$Source = "PSSlack"
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