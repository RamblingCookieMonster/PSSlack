#Borrowed from https://github.com/jgigler/Powershell.Slack - thanks!
function New-SlackMessageAttachment
{
<#
.SYNOPSIS
    Creates a rich notification (Attachment) to be posted in a slack channel.

.DESCRIPTION
    Used to create Atachment message payloads for Slack. Attachemnts are a way of crafting richly-formatted messages in Slack. They can be as simple as a single plain text message, to as complex as a multi-line message with pictures, links and tables. 

.PARAMETER Fallback
    A plain-text summary of the attachment. This text will be used in clients that don't show formatted text (eg. IRC, mobile notifications) and should not contain any markup.

.PARAMETER Severity
    This value is used to color the border along the left side of the message attachment. This parameter cannot be used in conjunction with the "Color" parameter. Only good,bad and warning are accepted by this parameter.

.PARAMETER Colour
    This value is used to color the border along the left side of the message attachment. Use Hex Web Colors to define the color. This parameter cannot be used in conjuction with the Severity Parameter.

.PARAMETER Pretext
    This is optional text that appears above the message attachment block.

.PARAMETER AuthorName
    Small text used to display the author's name.

.PARAMETER AuthorLink
    A valid URL that will hyperlink the AuthorName text mentioned above. Will only work if AuthorName is present.

.PARAMETER AuthorIcon
    A valid URL that displays a small 16x16px image to the left of the AuthorName text. Will only work if AuthorName is present.

.PARAMETER Title
    The title is displayed as larger, bold text near the top of the message attachment.

.PARAMETER TitleLink
    If the title link is specified then it turns the Title into a hyperlink that the user can click. 

.PARAMETER Text
    This is the main text in a message attachment, and can contain standard message markup. Not to be confused with Pretext which would appear above this.

.PARAMETER ImageURL
    A valid URL to an image file that will be displayed inside a message attachment.

.PARAMETER ThumbURL
    A valid URL to an image file that will be displayed as a thumbnail on the right side of a message attachment.

.PARAMETER Fields
    Fields are defined as an array, and hashtables contained within it will be displayed in a table inside the message attachment.
    Each hashtable inside the array must contain a "title" parameter and a "value" parameter. Optionally it may also contain "Short" which is a boolean parameter.

.EXAMPLE
   New-SlackRichNotification -Fallback "Your app sucks it should process attachments" -Title "Service Error" -Value "Service down for server contoso1" -Severity danger -channel "Operations" -UserName "Slack Powershell Bot"
   
   This command would generate the following output in Powershell:
-------------------------------------------------------------------------------

Name                           Value                                                                                                                                                                                  
----                           -----                                                                                                                                                                                  
username                       Slack Powershell Bot                                                                                                                                                                   
channel                        Operations                                                                                                                                                                             
icon_url                                                                                                                                                                                                              
attachments                    {System.Collections.Hashtable}

.EXAMPLE
(New-SlackRichNotification -Fallback "Your app sucks it should process attachments" -Title "Service Error" -Value "Service down for server contoso1" -Severity danger -channel "random" -UserName "Slack Powershell Bot").attachments

This command allows us to see inside the attachments Hashtable. It's output looks like the following:
-------------------------------------------------------------------------------

Name                           Value                                                                                                                                                                                  
----                           -----                                                                                                                                                                                  
color                          danger                                                                                                                                                                                 
fallback                       Your app sucks it should process attachments                                                                                                                                           
fields                         {System.Collections.Hashtable}


.EXAMPLE
$MyFields = @(
    @{
        title = 'Assigned To'
        value = 'John Doe'
        short = 'true'
    }
    @{
        title = 'Priority'
        value = 'Super Critical!'
        short = 'true'
    }
)

$notification = New-SlackRichNotification -Fallback "A plaintext message" -Title "Description" -Text "Some text that will appear above the Fields" -Fields $MyFields
Send-SlackNotification -Url "https://yourname.slack.com/path/to/hookintegrations" -Notification $notification

----------------------------------------------------------------------
In this example, $MyFields is defined as an Array. Inside that array are two separate hashtables with the two parameters that are required for a field. 
Since the "short" boolean parameter has been speified these two fields will be displayed next to each other in Slack. 


.LINK
https://github.com/jgigler/Powershell.Slack

.LINK
https://api.slack.com/docs/attachments

.LINK
https://api.slack.com/methods/chat.postMessage
#>

    [CmdletBinding(DefaultParameterSetName='Severity')]
    [OutputType([System.Collections.Hashtable])]
    Param
    (
        [Parameter(Mandatory=$true,
                   Position=0)]
        [String]$Fallback,
        
        [Parameter(Mandatory=$false,
                   ParameterSetName='Severity')]
        [ValidateSet("good",
                     "warning", 
                     "danger")]
        [String]$Severity,
        
        [Parameter(Mandatory=$false,
                   ParameterSetName='Color')]
        [Alias("Colour")]
        $Color,

        [String]$AuthorName,
        [String]$Pretext,
        [String]$AuthorLink,
        [String]$AuthorIcon,
        [String]$Title,
        [String]$TitleLink,
        [Parameter(Position=1)]
        [String]$Text,
        [String]$ImageURL,
        [String]$ThumbURL,
        [validatescript({
            foreach($key in $_.keys){
                if('title', 'short', 'value' -notcontains $key)
                {
                    throw "$Key is invalid, must be 'title', 'value', or 'short'"
                }
            }
            $true
        })]
        [System.Collections.Hashtable[]]$Fields,
        [validateset('text','pretext','fields')]
        [string[]]$MarkDownFields # https://get.slack.help/hc/en-us/articles/202288908-How-can-I-add-formatting-to-my-messages-
    )

    Process
    {
        #consolidate the colour and severity parameters for the API.
        switch($PSCmdlet.ParameterSetName)
        {
            'Severity' {
                $Color = $Severity
            }
            'Color' {
                if($Color -is [System.Drawing.Color])
                {
                    [string]$Color = Color-ToNumber $Color
                }
            }
        }

        $Attachment = @{}
        switch($PSBoundParameters.Keys)
        {
            'fallback' {$Attachment.fallback = $Fallback}
            'color' {$Attachment.color = $Color}
            'pretext'{$Attachment.pretext = $Pretext}
            'AuthorName'{$Attachment.author_name = $AuthorName}
            'AuthorLink' {$Attachment.author_link = $AuthorLink}
            'AuthorIcon' { $Attachment.author_icon = $AuthorIcon}
            'Title' { $Attachment.title = $Title}
            'TitleLink' { $Attachment.title_link = $TitleLink }
            'Text' {$Attachment.text = $Text}
            'fields' { $Attachment.fields = $Fields } #Fields are defined by the user as an Array of HashTables.
            'ImageUrl' {$Attachment.image_url = $ImageURL}
            'ThumbUrl' {$Attachment.thumb_url = $ThumbURL}
            'MarkDownFields' {$Attachment.mrkdwn_in = @($MarkDownFields)}
        }
        $Attachment
    }
}