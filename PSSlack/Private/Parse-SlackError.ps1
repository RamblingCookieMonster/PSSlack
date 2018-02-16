function Parse-SlackError {
    [CmdletBinding()]
    param (
        # The response object from Slack's API.
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Object]$ResponseObject,

        # The exception from Invoke-RestMethod, if available.
        [Exception]$Exception
    )

    Begin {
        $SlackErrorData = @{
            # Messages are adapted from Slack API documentation
            invalid_arg_name = @{
                Message = "The method was passed an argument whose name falls outside the bounds of accepted or expected values. This includes very long names and names with non-alphanumeric characters other than _." 
                RecommendedAction = "Verify API call is well-formed."
            }

            invalid_array_arg = @{
                Message = "The method was passed a PHP-style array argument (e.g. with a name like foo[7]). These are never valid with the Slack API."
                RecommendedAction = "Rename or remove the argument"
            }

            invalid_charset = @{
                Message = "The method was called via a POST request, but the charset specified in the Content-Type header was invalid. Valid charset names are: utf-8 iso-8859-1."
            }

            invalid_form_data = @{
                Message = "The method was called via a POST request with Content-Type application/x-www-form-urlencoded or multipart/form-data, but the form data was either missing or syntactically invalid."
            }

            invalid_post_type = @{
                Message = "The method was called via a POST request, but the specified Content-Type was invalid. Valid types are: application/x-www-form-urlencoded multipart/form-data text/plain."
            }

            missing_post_type = @{
                Message = "The method was called via a POST request and included a data payload, but the request did not include a Content-Type header."
            }

            team_added_to_org = @{
                Message = "The workspace associated with your request is currently undergoing migration to an Enterprise Organization. Web API and other platform operations will be intermittently unavailable until the transition is complete."
                RecommendedAction = "Wait until migration is complete, then try the request again."
            }

            request_timeout = @{
                Message = "The method was called via a POST request, but the POST data was either missing or truncated."
            }

            fatal_error = @{
                Message = "The server could not complete your operation(s) without encountering a catastrophic error. Some aspect of the operation may have succeeded before the error was raised."
            }

            not_authed = @{
                Message = "No authentication token provided."
                RecommendedAction = "Specify an authentication token via the -Token or -URI parameters, then try again."
            }

            invalid_auth = @{
                Message = "Some aspect of authentication cannot be validated. Either the provided token is invalid or the request originates from an IP address disallowed from making the request."
            }

            account_inactive = @{
                Message = "Authentication token is for a deleted user or workspace."
            }

            no_permission = {
                Message = "The workspace token used in this request does not have the permissions necessary to complete the request."

            }
        }
    }
    
    process {
        If ($ResponseObject.ok) {
            # We weren't actually given an error in this case
            Write-Debug "Parse-SlackError: Received non-error response, skipping."
            return 
        }

        $ErrorParams = $SlackErrorData[$ResponseObject.error]
        If ($Exception) {
            $ErrorParams.Exception = $Exception
        }

        Write-Error -ErrorId $ResponseObject.error @ErrorParams
    }
    
    end {
    }
}