function Get-PSSlackConfigPath
{
    [CmdletBinding()]
    param()

    end
    {
        if (Test-IsWindows)
        {
            Join-Path -Path $env:TEMP -ChildPath "$env:USERNAME-$env:COMPUTERNAME-PSSlack.xml"
        }
        else
        {
            Join-Path -Path $env:HOME -ChildPath '.psslack' # Leading . and no file extension to be Unixy.
        }
    }
}