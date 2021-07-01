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

    .PARAMETER ForceVerbose
        If specified, don't explicitly remove verbose output from Invoke-RestMethod

        *** WARNING ***
        This will expose your token in verbose output

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

        [switch]$ForceVerbose = $Script:PSSlack.ForceVerbose
    )
    $Params = @{
        Uri = "https://slack.com/api/$Method"
        ErrorAction = 'Stop'
        Header = @{ Authorization = "Bearer $Token" }
    }
    if($Proxy) {
        $Params['Proxy'] = $Proxy
    }
    if(-not $ForceVerbose) {
        $Params.Add('Verbose', $False)
    }
    if($ForceVerbose) {
        $Params.Add('Verbose', $true)
    }

    try {
        $Response = $null
        $Response = Invoke-RestMethod @Params -Body $Body
    }
    catch {
        # (HTTP 429 is "Too Many Requests")
        if ($_.Exception.Response.StatusCode -eq 429) {

            # Get the time before we can try again.
            if( $_.Exception.Response.Headers -and $_.Exception.Response.Headers.Contains('Retry-After') ) {
                $RetryPeriod = $_.Exception.Response.Headers.GetValues('Retry-After')
                if($RetryPeriod -is [string[]]) {
                    $RetryPeriod = [int]$RetryPeriod[0]
                }
            }
            else {
                $RetryPeriod = 2
            }
            Write-Verbose "Sleeping [$RetryPeriod] seconds due to Slack 429 response"
            Start-Sleep -Seconds $RetryPeriod
            Send-SlackApi @PSBoundParameters

        }
        elseif ($_.ErrorDetails.Message -ne $null) {
            # Convert the error-message to an object. (Invoke-RestMethod will not return data by-default if a 4xx/5xx status code is generated.)
            $_.ErrorDetails.Message | ConvertFrom-Json | Parse-SlackError -Exception $_.Exception -ErrorAction Stop

        }
        else {
            Write-Error -Exception $_.Exception -Message "Slack API call failed: $_"
        }
    }

    # Check to see if we have confirmation that our API call failed.
    # (Responses with exception-generating status codes are handled in the "catch" block above - this one is for errors that don't generate exceptions)
    if ($Response -ne $null -and $Response.ok -eq $False) {
        $Response | Parse-SlackError
    }
    elseif($Response) {
        Write-Output $Response
    }
    else {
        Write-Verbose "Something went wrong.  `$Response is `$null"
    }
}
