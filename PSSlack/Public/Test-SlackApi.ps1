<#
.SYNOPSIS
    Tests connectivity to the Slack API.
.DESCRIPTION
    This cmdlet calls the Slack API.test method to ensure PSSlack is able to connect to (and invoke) API methods.
.EXAMPLE
    # Test connectivity without a token
    PS C:\> Test-SlackApi
    
    # Test connectivity using a specified token
    PS C:\> Test-SlackApi -Token "xoxp-111-222-333-456789abcdef"
.INPUTS
    A Slack API token to use, if desired.
.OUTPUTS
    A Boolean value indicating whether the call passed/failed, or the response object from Slack's API.
.PARAMETER Token
    The API token to use when communicating with the Slack API.
.PARAMETER Raw
    Return the raw response object from the Slack API, versus parsing it and returning a boolean.
.NOTES
    Test-SlackApi will not, by default, use the preconfigured Slack API token (as the api.test method does not require authorization).
.FUNCTIONALITY
    Slack
.LINK
    https://api.slack.com/methods/api.test
#>
function Test-SlackApi {
    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [String]$Token,

        [Switch]$Raw
    )
    
    process {
        Write-Verbose "Testing Slack API."
        $RequestID = New-Guid # Generate a unique value for us to use when checking requests coming back from Slack's API
        Write-Debug "Unique ID: $RequestID"

        $Params = @{
            Body = @{
                PSSlackRequestID = $RequestID
            }
            Method = "api.test"
        }
        If ($Token) {
            Write-Verbose "Adding token to request."
            $Params.Token = $Token
        }
        Write-Verbose "Calling Slack API..."
        $Response = Send-SlackApi @Params -ErrorAction Stop

        If ($Raw) {
            Return $Response
        } Elseif ($Response.ok) {
            Write-Verbose "Received response from Slack api.test call."
            If ($Response.args.PSSlackRequestID -eq $RequestID) {
                Write-Verbose "Unique ID matches."
                Return $true
            } else {
                Write-Error "Slack API call succeeded, but responded with incorrect value."
            }
        } else {
            Return $False
        }
    }
}