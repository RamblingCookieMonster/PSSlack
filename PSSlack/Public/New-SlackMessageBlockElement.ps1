#Borrowed from https://github.com/jgigler/Powershell.Slack - thanks @jgigler et al!
function New-SlackMessageBlockElement
{
    <#
    .SYNOPSIS
        Creates a rich notification (Block ELement) to use in a Slack Block.
        Block elements can be used inside of section, context, and actions layout Blocks. 
        
    .DESCRIPTION
        Creates a rich notification (Block ELement) to use in a Slack Block.

        Used to create Blocks message payloads for Slack.
        Blocks are a way of crafting richly-formatted messages in Slack, and can also be used
        to build interactions
    
    .PARAMETER Type
        The type of the Block element.

    .PARAMETER ExistingBlockElement
        One or more Block Element to add this Block Element to.

        Allows you to chain calls to this function:
            New-SlackMessageBlockElement ... | New-SlackMessageBlockElement ...

    .PARAMETER ActionId
        An identifier for this action.
        You can use this when you receive an interaction payload to identify the source of the action.
        Should be unique among all other action_ids used elsewhere by your app.
        Maximum length for this field is 255 characters

    .PARAMETER Text
        Defines the button's text
        This parameters exists when Type is 'button'

    .PARAMETER Url
        A URL to load in the user's browser when the button is clicked.
        Maximum length for this field is 3000 characters.
        If you're using url, you'll still receive an interaction payload and will need to send an acknowledgement response.
        This parameters exists when Type is 'button'

    .PARAMETER Value
        The value to send along with the interaction payload. Maximum length for this field is 2000 characters.
        This parameters exists when Type is 'button'

    .PARAMETER Style
        Decorates buttons with alternative visual color schemes. Use this option with restraint.
            'primary' gives buttons a green outline and text, ideal for affirmation or confirmation actions. primary should only be used for one button within a set.
            'danger' gives buttons a red outline and text, and should be used when the action is destructive. Use danger even more sparingly than primary.
        If you don't include this field, the default button style will be used
        This parameters exists when Type is 'button'

    .PARAMETER PlaceHolder
        Defines the placeholder text shown on the block element
        This parameters exists when Type is 'static_select', 'datepicker' or 'multi_static_select'

    .PARAMETER InitialDate
        The initial date that is selected when the element is loaded. This should be in the format YYYY-MM-DD.
        This parameters exists when Type is 'datepicker'

    .PARAMETER ImageUrl
        The URL of the image to be displayed.
        This parameters exists when Type is 'image'

    .PARAMETER AltText
        A plain-text summary of the image.
        This should not contain any markup.
        This parameters exists when Type is 'image'

    .PARAMETER Options
        An array of option objects. Maximum number of options is 100
        This parameters exists when Type is 'static_select', 'overflow' or 'multi_static_select'

    .PARAMETER InitialOptions
        An array of option objects that exactly match one or more of the options within options.
        This parameters exists when Type is 'multi_static_select'

    .PARAMETER MaxSelectedItems
        Specifies the maximum number of items that can be selected in the menu. Minimum number is 1
        This parameters exists when Type is 'multi_static_select'

    .PARAMETER InitialOption
        A single option that exactly matches one of the options within options
        This parameters exists when Type is 'static_select'
    
    .EXAMPLE
        # This is a simple example illustrating some common options
        # when constructing a message Block
        # giving you a richer message
        $Token = 'A token. maybe from https://api.slack.com/docs/oauth-test-tokens'

        $elements_of = New-SlackMessageBlockElement -Type overflow -ActionId "ofId" -Options @{ yes = "Oh Yeah" ; no = "Oh gosh no!" }

        $Block = New-SlackMessageBlock -BlockId "LoremIpsumBlockId" -Type section -Accessory $elements_of -Text "Hey, havin' fun ??" 
            New-SlackMessage -Channel '@wframe' `
                             -IconEmoji :bomb: `
                             -Blocks $Block |
            Send-SlackMessage -Token $Token

        # Create a message Block with a simple question :)
        # Attach this to a slack message sending to the devnull channel
        # Send the newly created message using a token

    .EXAMPLE
        # This example demonstrates that you can chain new Blocks & new BlocksElements
        # together to form a multi-attachment message
        $Token = 'A token. maybe from https://api.slack.com/docs/oauth-test-tokens'

        $elements_of = New-SlackMessageBlockElement -Type overflow -ActionId "ofId" -Options @{ yes = "Oh Yeah" ; no = "Oh gosh no!" }

        $elements_bt = New-SlackMessageBlockElement -Type button -ActionId "btnGit" -Text "Go to Github" -Style primary -Value "value_git" -Url "https://github.com/" | `
                        New-SlackMessageBlockElement -Type button -ActionId "btnGoogle" -Text "Prefer google" -Style danger -Value "value_google" -Url "https://www.google.fr"

        $Blocks = New-SlackMessageBlock -BlockId "HeaderBlockId" -Type header -Text "Here we got an header text" `
                | New-SlackMessageBlock -Type divider `
                | New-SlackMessageBlock -BlockId "OverFlowBlockId" -Type section -Accessory $elements_of -Text "Hey, havin' fun ??"`
                | New-SlackMessageBlock -Type divider `
                | New-SlackMessageBlock -BlockId "ActionsBlockId" -Type actions -Elements $elements_bt
            New-SlackMessage -Channel '@wframe' `
                             -IconEmoji :bomb: `
                             -Blocks $Blocks `
                             -Text "PreviewText" |
            Send-SlackMessage -Token $Token

        # Create a message Block with a simple question :)
        # Attach this to a slack message sending to the devnull channel
        # Send the newly created message using a token

        # Create an Blockelement, create another Blockelement, add these to a Block, create another Block, another Block
        # add these to a message,
        # and send with a token

    .LINK
        https://github.com/RamblingCookieMonster/PSSlack

    .LINK
        https://api.slack.com/reference/Block-kit/Block-elements

    .LINK
        https://api.slack.com/docs/interactive-message-field-guide

    .LINK
        https://api.slack.com/methods/chat.postMessage
    #>
    [CmdletBinding(DefaultParameterSetName='Button')]
    [OutputType([System.Collections.Hashtable])]
    Param
    (
        [Parameter(ValueFromPipeline = $True)]
        [PSTypeName('PSSlack.MessageBlockElement')]
        [object[]]
        $ExistingBlockElement,

        [ValidateSet('image','button','datepicker','multi_static_select','static_select','overflow')]
        [string]$Type
    )

    dynamicparam {

        $params = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        switch($Type) {
            "button"  {
                New-DynamicParam -Name ActionId -Type string -DPDictionary $params
                New-DynamicParam -Name Text -Type string -Mandatory -DPDictionary $params -Position 1
                New-DynamicParam -Name Url -Type string -Mandatory -DPDictionary $params -Position 2
                New-DynamicParam -Name Value -Type string -DPDictionary $params -Position 3
                New-DynamicParam -Name Style -Type string -DPDictionary $params -Position 4 -ValidateSet ("primary","danger","default")
            }

            "datepicker" {
                New-DynamicParam -Name ActionId -Type string -DPDictionary $params
                New-DynamicParam -Name PlaceHolder -Type string -DPDictionary $params -Position 1
                New-DynamicParam -Name InitialDate -Type string -DPDictionary $params -Position 2 -HelpMessage ""

            }

            "image"  {
                New-DynamicParam -Name ImageUrl -Type string -DPDictionary $params -Position 1
                New-DynamicParam -Name AltText -Type string -DPDictionary $params -Position 2
            }

            "multi_static_select"  {
                New-DynamicParam -Name ActionId -Type string -DPDictionary $params
                New-DynamicParam -Name PlaceHolder -Type string -Mandatory -DPDictionary $params -Position 1
                New-DynamicParam -Name Options -Type hashtable -Mandatory -DPDictionary $params -Position 2
                New-DynamicParam -Name InitialOptions -Type hashtable -DPDictionary $params -Position 3
                New-DynamicParam -Name MaxSelectedItems -Type int -DPDictionary $params -Position 4
            }

            "static_select"  {
                New-DynamicParam -Name ActionId -Type string -DPDictionary $params
                New-DynamicParam -Name PlaceHolder -Type string -Mandatory -DPDictionary $params -Position 1
                New-DynamicParam -Name Options -Type hashtable -Mandatory -DPDictionary $params -Position 2
                New-DynamicParam -Name InitialOption -Type hashtable -Mandatory -DPDictionary $params -Position 3
            }
            
            "overflow"  {
                New-DynamicParam -Name ActionId -Type string -DPDictionary $params
                New-DynamicParam -Name Options -Type hashtable -Mandatory -DPDictionary $params -Position 1
            }
        }
        return $params
    }

    Begin
    {
        $Element = @{}
        switch($PSBoundParameters.Keys)
        {
            'ActionId' {$Element.action_id = $PSBoundParameters["ActionId"] }
            'Type' {$Element.type = $Type}

            'Text' {$Element.text = @{ type = "plain_text" ; text = $PSBoundParameters["Text"] }}

            'Url' {$Element.url = $PSBoundParameters["Url"]}
            'Value' {$Element.value = $PSBoundParameters["Value"]}
            'Style' {$Element.style = $PSBoundParameters["Style"] }

            'PlaceHolder' { $Element.placeholder = @{ type = "plain_text" ; text = $PSBoundParameters["PlaceHolder"] } }
            'InitialDate' { $Element.initial_date = $PSBoundParameters["InitialDate"] }
            'ImageUrl' { $Element.image_url = $PSBoundParameters["ImageUrl"] }
            'AltText' { $Element.alt_text = $PSBoundParameters["AltText"] }
            'Options' {
                $Options = $PSBoundParameters["Options"]
                $formattedOptions = @()
                $Options.Keys | ForEach-Object{ $formattedOptions += @{ value = $_ ; text = @{ type = "plain_text" ; text = $Options[$_] } } }
                $Element.options = @($formattedOptions)
            }
            'InitialOptions' {
                $InitialOptions = $PSBoundParameters["InitialOptions"]
                $formattedInitialOptions = @()
                $InitialOptions.Keys | ForEach-Object{ $formattedInitialOptions += @{ value = $_ ; text = @{ type = "plain_text" ; text = $InitialOptions[$_] } } }
                $Element.initial_options = $formattedInitialOptions
            }
            'InitialOption' { 
                $InitialOption = $PSBoundParameters["InitialOptions"]
                if($InitialOption.Keys.Count -gt 1) {
                    Write-Verbose "Kind of wierd to have multiple initial options for a single_option element : only first value will be used"
                }
                if($InitialOption.Keys.Count -gt 0) {
                    $Element.initial_option = @{ value = $InitialOption.Keys[0] ; text = @{ type = "plain_text" ; text = $InitialOption[$InitialOption.Keys[0]] } }
                }
            }
            'MaxSelectedItems' { $Element.max_selected_items = $PSBoundParameters["MaxSelectedItems"] }
        }

        Add-ObjectDetail -InputObject $Element -TypeName 'PSSlack.MessageBlockElement' -Passthru $False
        $ReturnObject = @()
    }
    Process
    {
        foreach($a in $ExistingBlockElement)
        {
            $ReturnObject += $a
        }
        
        If($ExistingBlockElement)
        {
            Write-Verbose "Existing BlockElement : $($ExistingBlockElement | ConvertTo-Json -compress)"
        }
    }
    End {
        $ReturnObject += $Element
        $ReturnObject
    }
}