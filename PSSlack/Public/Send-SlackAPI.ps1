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
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Method,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Body = @{ },

        [Parameter()]
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

        [Parameter()]
        [string]$Proxy = $Script:PSSlack.Proxy,

        [Parameter()]
        [switch]$ForceVerbose = $Script:PSSlack.ForceVerbose,

        # If specified, enables cursor-based pagination of results. See https://api.slack.com/docs/pagination
        # for the list of Slack REST API methods that support cursor-based pagination.
        [Parameter(ParameterSetName="Pagination")]
        [switch]
        $EnablePagination,

        # Specifies the page size when using cursor-based pagination. Slack recommends a range of 100-200.
        # The default is 200.  Note: Slack limits the max to 1000 on certain APIs. That limit may vary over
        # time and over different APIs.
        [Parameter(ParameterSetName="Pagination")]
        [ValidateRange(1,1000)]
        [int]
        $PageSize = 200,

        # MaxNumberPages can be used to limit the number of pages returned from Slack. The default value is
        # 0 which represents no limit i.e. all results are returned.
        [Parameter(ParameterSetName="Pagination")]
        [ValidateRange(0, [int]::MaxValue)]
        [int]
        $MaxNumberPages = 0
    )

    $Params = @{
        Uri = "https://slack.com/api/$Method"
        ErrorAction = 'Stop'
    }
    if ($Proxy) {
        $Params['Proxy'] = $Proxy
    }
    if (-not $ForceVerbose) {
        $Params.Add('Verbose', $false)
    }
    if ($ForceVerbose) {
        $Params.Add('Verbose', $true)
    }

    if ($EnablePagination) {
        $Params['Uri'] += "?limit=$PageSize"
    }

    $Body.token = $Token
    $pageCount = 0
    $hasMoreData = $true
    $paginationUriBase = $Params.Uri

    do {
        try {
            $Response = $null
            $Response = Invoke-RestMethod @Params -Body $Body
        }
        catch {
            # (HTTP 429 is "Too Many Requests")
            if ($_.Exception.Response.StatusCode -eq 429) {

                # Get the time before we can try again.
                if ($_.Exception.Response.Headers -and $_.Exception.Response.Headers.Contains('Retry-After') ) {
                    $RetryPeriod = $_.Exception.Response.Headers.GetValues('Retry-After')
                    if ($RetryPeriod -is [string[]]) {
                        $RetryPeriod = [int]$RetryPeriod[0]
                    }
                }
                else {
                    $RetryPeriod = 2
                }

                Write-Verbose "Sleeping [$RetryPeriod] seconds due to Slack 429 response"
                Start-Sleep -Seconds $RetryPeriod
                continue
            }
            elseif ($null -ne $_.ErrorDetails.Message) {
                # Convert the error-message to an object. (Invoke-RestMethod will not return data by-default if a 4xx/5xx status code is generated.)
                $_.ErrorDetails.Message | ConvertFrom-Json | Parse-SlackError -Exception $_.Exception -ErrorAction Stop
            }
            else {
                Write-Error -Exception $_.Exception -Message "Slack API call failed: $_"
            }
        }

        # Check to see if we have confirmation that our API call failed.
        # (Responses with exception-generating status codes are handled in the "catch" block above - this one is for errors that don't generate exceptions)
        if ($null -ne $Response -and $Response.ok -eq $false) {
            $Response | Parse-SlackError
            break
        }
        elseif ($Response) {
            Write-Output $Response
            if ($EnablePagination) {
                $pageCount++

                $nextCursor = $Response.response_metadata.next_cursor
                if ($nextCursor) {
                    $encodedNextCursor = $nextCursor -replace '=$','%3D'
                    $Params['Uri'] = "${paginationUriBase}&cursor=$encodedNextCursor"
                }
                else {
                    $hasMoreData = $false
                }
            }
        }
        else {
            Write-Verbose "Something went wrong.  `$Response is `$null"
            break
        }
    } while ($EnablePagination -and $hasMoreData -and (($MaxNumberPages -eq 0) -or ($pageCount -lt $MaxNumberPages)))
}
