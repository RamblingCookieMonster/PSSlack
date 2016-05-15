#From http://powershell.com/cs/blogs/tips/archive/2012/03/09/converting-unix-time.aspx - Thanks!
function ConvertFrom-UnixTime {
    param(
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true)]
        [Int32]
        $UnixTime
    )
    begin {
        $startdate = Get-Date –Date '01/01/1970' 
    }
    process {
        $timespan = New-Timespan -Seconds $UnixTime
        $startdate + $timespan
    }
}