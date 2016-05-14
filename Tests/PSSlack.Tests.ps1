$Verbose = @{}
if($env:APPVEYOR_REPO_BRANCH -and $env:APPVEYOR_REPO_BRANCH -notlike "master")
{
    $Verbose.add("Verbose",$True)
}

$PSVersion = $PSVersionTable.PSVersion.Major
$ModuleName = 'PSSlack'

Import-Module $PSScriptRoot\..\$ModuleName -Force

Describe "PSSlack PS$PSVersion" {
    Context 'Strict mode' {

        Set-StrictMode -Version latest

        It 'Should load' {
            $Module = Get-Module $ModuleName
            $Module.Name | Should be $ModuleName
            $Commands = $Module.ExportedCommands.Keys
            $Commands -contains 'Find-SlackMessage' | Should Be $True
            $Commands -contains 'Get-PSSlackConfig' | Should Be $True
            $Commands -contains 'Set-PSSlackConfig' | Should Be $True
            $Commands -contains 'New-SlackMessage' | Should Be $True
            $Commands -contains 'New-SlackMessageAttachment' | Should Be $True
            $Commands -contains 'Send-SlackMessage' | Should Be $True
        }
    }

}

