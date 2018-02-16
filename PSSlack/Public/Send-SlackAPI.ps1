function Send-SlackApi
{
    <#
    .SYNOPSIS
        Send a message to the Slack API endpoint

    .DESCRIPTION
        Send a message to the Slack API endpoint

        This function is used by other PSSlack functions.
        It's a simple wrapper you could use for calls to the Slack API

    .PARAMETER Method
        Slack API method to call.

        Reference: https://api.slack.com/methods

    .PARAMETER Body
        Hash table of arguments to send to the Slack API.

    .PARAMETER Token
        Slack token to use

    .PARAMETER Proxy
        Proxy server to use

    .PARAMETER RateLimit
        Indicates the API method is rate-limit and should use automatic back-off/retry upon receipt of a HTTP 429 (Too Many Requests) response from the server.

    .FUNCTIONALITY
        Slack
    #>
    [OutputType([String])]
    [cmdletbinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Method,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Body = @{ },

        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            if (-not $_ -and -not $Script:PSSlack.Token)
            {
                throw 'Please supply a Slack Api Token with Set-SlackApiToken.'
            }
            else
            {
                $true
            }
        })]
        [string]$Token = $Script:PSSlack.Token,

        [string]$Proxy = $Script:PSSlack.Proxy,

        [Switch]$RateLimit
    )

    # Create a "leaky bucket" for a given API token, indicating a counter of requests "in" the bucket and drip rate (per-second) that requests exit the bucket.
    # This is used to follow along with Slack's API rate-limiting algorithm.
    If ($Script:APIRateBuckets[$Token] -eq $Null) {
        $Script:APIRateBuckets[$Token] = @{
            Counter = 0
            MaxCount = 25
            LeakRateMsec = 1000
            LastDrip = [DateTime]::Now
        }
    }


    $Params = @{
        Uri = "https://slack.com/api/$Method"
    }
    if($Proxy)
    {
        $Params['Proxy'] = $Proxy
    }
    $Body.token = $Token

    # Update the bucket for this API key to "drain" it as necessary - even if we're not using a RLed API call in this instance.
    $Bucket = $Script:APIRateBuckets[$Token]

    # If we should "drip" (non-zero counter, at least 1 drip period has elapsed)
    If ($Bucket.Counter -gt 0 -and ([DateTime]::Now - $Bucket.LastDrip).TotalMilliseconds -gt $Bucket.LeakRateMsec) {
        # Figure out how many drips should have occurred.
        $NumDrips = [Math]::Floor(([DateTime]::Now - $Bucket.LastDrip).TotalMilliseconds / $Bucket.LeakRateMsec)

        # Decrement the counter by the number of drips (if the counter is nonzero afterwards), or set the counter to zero.
        $Bucket.Counter -= [Math]::Min($NumDrips, $Bucket.Counter)

        # Update the last drip timestamp to indicate we just dripped.
        $Bucket.LastDrip = [DateTime]::Now
    }

    try {

        # If we want to invoke a rate-limited API method and the bucket is full...
        If ($RateLimit -and ($Bucket.Counter -eq $Bucket.MaxCount)) {
                
            # Determine when the next drip will occur.
            $NextDrip = $Bucket.LastDrip.AddMilliseconds($Bucket.LeakRateMsec)
            Write-Warning "Rate-limit bucket full, waiting..."
            
            # Sleep until then.
            Start-Sleep -Milliseconds ($NextDrip - [DateTime]::Now).TotalMilliseconds
            
            # Drip accordingly.
            $Bucket.Counter--
            $Bucket.LastDrip = [DateTime]::Now

        }

        $Response = Invoke-RestMethod @Params -body $Body

        # If we've successfully invoked a rate-limited API method...
        If ($RateLimit -and $Response.ok) {

            # Increase the counter for our bucket.
            $Bucket.Counter++    
        }

    }
    catch [System.Net.WebException] {
        # If we're configured to do rate-limiting...
        # (HTTP 429 is "Too Many Requests")
        If ($_.Exception.Response.StatusCode -eq 429 -and $RateLimit) {

            # Get the time before we can try again.
            $RetryPeriod = $_.Exception.Response.Headers["Retry-After"]

            # Set our bucket to be full.
            $Bucket.Counter = $Bucket.MaxCount
            
            # Figure out when the last drip "should" have occurred, based on how many seconds we have until the next drip.
            $Bucket.LastDrip = [DateTime]::Now.AddSeconds($RetryPeriod).AddMilliseconds($Bucket.LeakRateMsec * -1)

            # Warn the user.
            Write-Warning "Slack API rate-limit exceeded - blocking for $RetryPeriod second(s)."
            
            # (We don't actually have to sleep here, but rather recurse - the next call will handle sleeping.)
            Send-SlackApi @PSBoundParameters
            
        } Else {

            # Convert the error-message to an object. (Invoke-RestMethod will not return data by-default if a 4xx/5xx status code is generated.)
            $_.ErrorDetails.Message | ConvertFrom-Json | Parse-SlackError -Exception $_.Exception -ErrorAction Stop
            
        }
    }

    # Check to see if we have confirmation that our API call failed.
    # (Responses with exception-generating status codes are handled in the "catch" block above - this one is for errors that don't generate exceptions)
    If ($Response -ne $null -and $Response.ok -eq $False) {
        $Response | Parse-SlackError
    }

    
}
