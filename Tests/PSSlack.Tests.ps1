$PSVersion = $PSVersionTable.PSVersion.Major
$ModuleName = $ENV:BHProjectName
$ModulePath = Join-Path $ENV:BHProjectPath $ModuleName

# Verbose output for non-master builds on appveyor
# Handy for troubleshooting.
# Splat @Verbose against commands as needed (here or in pester tests)
    $Verbose = @{}
    if($ENV:BHBranchName -notlike "master" -or $env:BHCommitMessage -match "!verbose")
    {
        $Verbose.add("Verbose",$True)
    }

Import-Module $ModulePath -Force

$TestUri = 'TestUri'
$TestToken = 'TestToken'
$TestArchive = 'TestArchive'
$TestProxy = 'TestProxy'
$TestContentType = 'TestContentType'

$AlternativePath = 'TestDrive:\ThisSlackXml.xml'

Describe "PSSlack Module PS$PSVersion" {
    Context 'Strict mode' {

        Set-StrictMode -Version latest

        It 'Should load' {
            $Module = Get-Module $ModuleName
            $Module.Name | Should Be $ModuleName
            $Commands = $Module.ExportedCommands.Keys
            $Commands -contains 'Find-SlackMessage' | Should Be $True
            $Commands -contains 'Get-PSSlackConfig' | Should Be $True
            $Commands -contains 'Set-PSSlackConfig' | Should Be $True
            $Commands -contains 'New-SlackMessage' | Should Be $True
            $Commands -contains 'New-SlackMessageAttachment' | Should Be $True
            $Commands -contains 'Send-SlackMessage' | Should Be $True
        }

        It 'Should have empty values in PSSlack.xml' {
            $Config = Import-Clixml "$env:TEMP\$env:USERNAME-$env:COMPUTERNAME-PSSlack.xml"
            $Props = $Config.PSObject.Properties.Name
            #Loop is faster but less clear in failed tests.
            $Props -contains 'Uri' | Should Be $True
            $Props -contains 'Token' | Should Be $True
            $Props -contains 'ArchiveUri' | Should Be $True
            $Props -contains 'Proxy' | Should Be $True
            $Props -contains 'ContentType' | Should Be $True

            $Config.Uri | Should BeNullOrEmpty
            $Config.Token | Should BeNullOrEmpty
            $Config.ArchiveUri | Should BeNullOrEmpty
            $Config.Proxy | Should BeNullOrEmpty
            $Config.ContentType | Should BeNullOrEmpty
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
                Proxy = $TestProxy
                ContentType = $TestContentType
            }
            Set-PSSlackConfig @params
            $Config = Import-Clixml "$env:TEMP\$env:USERNAME-$env:COMPUTERNAME-PSSlack.xml"

            $Config.Uri | Should BeOfType System.Security.SecureString
            $Config.Token | Should BeOfType System.Security.SecureString
            $Config.ArchiveUri | Should Be 'TestArchive'
            $Config.Proxy | Should Be 'TestProxy'
            $Config.ContentType | Should Be 'TestContentType'
        }

        It 'Should set a user-specified file' {
            $Params = @{
                Uri= $TestUri
                Token = $TestToken
                ArchiveUri = "$TestArchive`x"
                Proxy = "$TestProxy`x"
                Path = $AlternativePath
                ContentType = $TestContentType
            }
            Set-PSSlackConfig @params
            $Config = Import-Clixml $AlternativePath

            $Config.Uri | Should BeOfType System.Security.SecureString
            $Config.Token | Should BeOfType System.Security.SecureString
            $Config.ArchiveUri | Should Be 'TestArchivex'
            $Config.Proxy | Should Be 'TestProxyx'
            $Config.ContentType | Should Be 'TestContentType'
        }
    }
}

Describe "Get-PSSlackConfig PS$PSVersion" {
    Context 'Strict mode' {

        Set-StrictMode -Version latest

        It 'Should read PSSlack.xml' {
            $Config = Get-PSSlackConfig -Source PSSlack.xml

            $Config.Uri | Should Be 'TestUri'
            $Config.Token | Should Be 'TestToken'
            $Config.ArchiveUri | Should Be 'TestArchive'
            $Config.Proxy | Should Be 'TestProxy'
            $Config.ContentType | Should Be 'TestContentType'
        }

        It 'Should read PSSlack variable' {
            $Config = Get-PSSlackConfig -Source PSSlack

            $Config.Uri | Should Be 'TestUri'
            $Config.Token | Should Be 'TestToken'
            $Config.ArchiveUri | Should Be 'TestArchivex' #From running alternate path test before...
            $Config.Proxy | Should Be 'TestProxyx' #From running alternate path test before...
            $Config.ContentType | Should Be 'TestContentType'
    }

        It 'Should read a user-specified file' {
            # We've tested set... use it here.
            $Params = @{
                Uri= $TestUri
                Token = $TestToken
                ArchiveUri = "$TestArchive`x"
                Proxy = "$TestProxy`x"
                Path = $AlternativePath
                ContentType = $TestContentType
            }
            Set-PSSlackConfig @params

            $Config = Get-PSSlackConfig -Path $AlternativePath

            $Config.Uri | Should Be 'TestUri'
            $Config.Token | Should Be 'TestToken'
            $Config.ArchiveUri | Should Be 'TestArchivex'
            $Config.Proxy | Should Be 'TestProxyx'
            $Config.ContentType | Should Be 'TestContentType'
        }
    }
}

# Tests have passed, rely on set-psslackconfig...
Set-PSSlackConfig -Uri $null -Token $null -ArchiveUri $null -Proxy $null


Describe "Send-SlackMessage PS$PSVersion" {
    InModuleScope $ModuleName {

        Mock -ModuleName PSSlack -CommandName Send-SlackApi {
            [pscustomobject]@{
                PSB = $PSBoundParameters
                Arg = $Args
            }
        }
        Mock -ModuleName PSSlack -CommandName Invoke-RestMethod  {
            [pscustomobject]@{
                PSB = $PSBoundParameters
                Arg = $Args
            }
        }

        It 'Should call Send-SlackApi for token auth' {
            $x = Send-SlackMessage -Token Token -Text 'Hi'
            Assert-MockCalled -ModuleName PSSlack -CommandName Send-SlackApi -Scope Describe
        }

        It 'Should call Invoke-RESTMethod for Uri auth' {
            $x = Send-SlackMessage -Uri Uri -Text 'Hi'
            Assert-MockCalled -ModuleName PSSlack -CommandName Invoke-RestMethod -Scope Describe
        }

        It 'Should not pass parameters if not specified' {
            $x = Send-SlackMessage -Token Token -Text 'Hi'
            # 7 we see here, 1 for body value, 2 are from ForceVerbose resulting in Verbose $False...
            $x.arg.count | Should Be 10 
            $x.arg -contains '-Body:' | Should Be $True
            $x.arg -contains '-Method:' | Should Be $True
            $x.arg -contains '-Token:' | Should Be $True
            $x.arg -contains '-ContentType:' | Should Be $True
            $x.arg -contains 'TestContentType' | Should Be $True
            $x.arg -contains 'Token' | Should Be $True
            $x.arg -contains 'chat.postMessage' | Should Be $True
        }
    }
}

Describe "Test-SlackApi" {
    Context "Strict Mode" {
        Set-StrictMode -Version latest
        It "Should receive API response" {
            $x = Test-SlackApi
            $x | Should Be $true
        }
        It "Should fail with invalid API keys" {
            {Test-SlackApi -Token "PSSlack_InvalidAPIToken"} | Should -Throw
        }
    }

}

Remove-Item $env:TEMP\$env:USERNAME-$env:COMPUTERNAME-PSSlack.xml -force -Confirm:$False

Describe 'New-SlackMessageAttachment' {
    It 'Should be a hashtable when not on pipeline' {
        $message = New-SlackMessageAttachment -Text "Test" -Fallback "test"
        $message | Should -BeOfType Hashtable
    }

    It 'Should Be an Array with Three Members, when Piped Three Times' {
        $message = New-SlackMessageAttachment -text "test1" -Fallback 'Test1' |
          New-SlackMessageAttachment -text "test2" -Fallback "test2" |
          New-SlackMessageAttachment -text "test3" -FallBack "test3"
        $message.Count | Should -BeExactly 3
    }
    It 'Should Be an Array with Five Members, when Piped Five Times' {
        $message = New-SlackMessageAttachment -text "test1" -Fallback 'Test1' |
          New-SlackMessageAttachment -text "test2" -Fallback "test2" |
          New-SlackMessageAttachment -text "test3" -FallBack "test3" |
          New-SlackMessageAttachment -text "test4" -Fallback "test4" |
          New-SlackMessageAttachment -text "test5" -Fallback "test5" 
        $message.Count | Should -BeExactly 5
    }
}