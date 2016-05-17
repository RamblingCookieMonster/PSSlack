# More to do. Ugly example. I don't like depending on AppVeyor specific env vars...

Properties {
    [string]$ProjectRoot = $PSScriptRoot #$ENV:APPVEYOR_BUILD_FOLDER # Change based on build solution
    $Timestamp = Get-date -uformat "%Y%m%d-%H%M%S"
    $PSVersion = $PSVersionTable.PSVersion.Major
    $TestFile = "TestResults_PS$PSVersion`_$TimeStamp.xml"

    $Address = "https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)"

    $Verbose = @{}
    if($env:APPVEYOR_REPO_BRANCH -and $env:APPVEYOR_REPO_BRANCH -notlike "master")
    {
        $Verbose.add("Verbose",$True)
    }
}

Task Default -Depends Deploy

Task Init {
    Set-Location $ProjectRoot
}

Task Clean {
    Remove-Item "$PSScriptRoot\Destination\" -ErrorAction SilentlyContinue -Force -Recurse
}

Task Test -Depends Clean {
    $TestResults = Invoke-Pester @verbose -Path $ProjectRoot\Tests -PassThru -OutputFormat NUnitXml -OutputFile "$ProjectRoot\$TestFile"

    if($TestResults.FailedCount -gt 0)
    {
        Write-Error "Failed '$($TestResults.FailedCount)' tests, build failed"
    }

    #Run a test with the current version of PowerShell, upload results    
    "`n`tSTATUS: Testing with PowerShell $PSVersion"

    If($env:APPVEYOR_JOB_ID)
    {
        (New-Object 'System.Net.WebClient').UploadFile( $Address, "$ProjectRoot\$TestFile" )
        Remove-Item "$ProjectRoot\$TestFile" -Force -ErrorAction SilentlyContinue
    }

    Remove-Item "$ProjectRoot\$TestFile" -Force -ErrorAction SilentlyContinue

    if($TestResults.FailedCount -gt 0)
    {
        Write-Error "Failed '$($TestResults.FailedCount)' tests, build failed"
    }
}

Task Deploy -Depends Test {
    "Deploying"
}