$Verbose = @{}
if($env:APPVEYOR_REPO_BRANCH -and $env:APPVEYOR_REPO_BRANCH -notlike "master")
{
    $Verbose.add("Verbose",$True)
}

$PSVersion = $PSVersionTable.PSVersion.Major
$ModuleName = 'PSSlack'
$ModulePath = (Get-Item "$PSScriptRoot\..\$ModuleName").FullName

$TestUri = 'TestUri'
$TestToken = 'TestToken'
$TestArchive = 'TestArchive'

Import-Module $ModulePath -Force

Describe "PSSlack Module PS$PSVersion" {
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

        It 'Should not have empty values in PSSlack.xml' {
            $Config = Import-Clixml $ModulePath\PSSlack.xml
            $Props = $Config.PSObject.Properties.Name
            #Loop is faster but less clear in failed tests.
            $Props -contains 'Uri' | Should be $True
            $Props -contains 'Token' | Should be $True
            $Props -contains 'ArchiveUri' | Should be $True
            $Config.Uri | Should BeNullOrEmpty
            $Config.Token | Should BeNullOrEmpty
            $Config.ArchiveUri | Should BeNullOrEmpty
        }
    }
}

Describe "Set-PSSlackConfig PS$PSVersion" {
    Context 'Strict mode' {

        Set-StrictMode -Version latest

        It 'Should set PSSlack.xml' {
            $Params = @{
                Uri= $TestUri
                Token = $TestToken
                ArchiveUri = $TestArchive 
            }
            Set-PSSlackConfig @params
            $Config = Import-Clixml $ModulePath\PSSlack.xml

            $Config.Uri | Should be 'TestUri'
            $Config.Token | Should be 'TestToken'
            $Config.ArchiveUri | Should be 'TestArchive'
        }
    }
}

Describe "Get-PSSlackConfig PS$PSVersion" {
    Context 'Strict mode' {

        Set-StrictMode -Version latest

        It 'Should read PSSlack.xml' {
            $Config = Get-PSSlackConfig -Source PSSlack.xml

            $Config.Uri | Should be 'TestUri'
            $Config.Token | Should be 'TestToken'
            $Config.ArchiveUri | Should be 'TestArchive'
        }
        
        It 'Should read PSSlack variable' {
            [pscustomobject]@{
                Uri= $TestUri
                Token = $TestToken
                ArchiveUri = $TestArchive 
            } | Export-Clixml -Path $ModulePath\PSSlack.xml -Force -Confirm:$False

            $Config = Get-PSSlackConfig -Source PSSlack

            $Config.Uri | Should be 'TestUri'
            $Config.Token | Should be 'TestToken'
            $Config.ArchiveUri | Should be 'TestArchive'

        }
    }
}