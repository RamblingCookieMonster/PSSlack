function Test-IsWindows
{
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    end
    {
        !(Test-Path -Path Variable:\IsWindows) -or $IsWindows
    }
}
