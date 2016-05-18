function New-SlackField
{
    <#
    .SYNOPSIS
        Creates an array of Slack message attachment fields from an arbitrary PowerShell object

    .DESCRIPTION
        Creates an array of Slack message attachment fields from an arbitrary PowerShell object

        By default, retrieves all properties. You can use parameters to restrict this.

    .PARAMETER InputObject
        A plain-text summary of the attachment. This text will be used in clients that don't show formatted text (eg. IRC, mobile notifications) and should not contain any markup.

    .PARAMETER Short
        Whether to try to fit the field into a table, rather than a list

    .PARAMETER IncludeProperty
        If specified, include only these properties from the InputObject's properties
    
    .PARAMETER ExcludeProperty
        If specified, exclude these properties from the InputObject's properties

    .PARAMETER MemberType
        If specified, restrict the properties we discover from InputObject to these member types.

        Defaults to NoteProperty, Property, ScriptProperty 

    .EXAMPLE
        [pscustomobject]@{
            One = 1
            Two = 2
            Five = 5
        } | New-SlackField

        # Simple illustration: pipe anything that produces an object into New-SlackField.

    .EXAMPLE
        $Fields = [pscustomobject]@{
            AlertName = 'The System Is Down'
            Severity = 11
            ImpactedDepartment = 'All'
            URL = 'https://www.youtube.com/watch?v=TmpRs7xN06Q'
        } | New-SlackField -Short

        New-SlackMessageAttachment -Color $([System.Drawing.Color]::Orange) `
                                   -Fields $Fields `
                                   -Fallback 'Your client is bad' |
            New-SlackMessage -Channel '@wframe' `
                             -IconEmoji :bomb: `
                             -AsUser `
                             -Username 'SCOM Bot' |
            Send-SlackMessage -Token $Token

        # Build an imaginary SCOM alert, send it through New-SlackField, short mode
        # Send a Slack message with that field in an attachment

    .LINK
        https://github.com/RamblingCookieMonster/PSSlack

    .LINK
        https://api.slack.com/docs/attachments

    .LINK
        https://api.slack.com/methods/chat.postMessage
    #>
    [CmdletBinding(DefaultParameterSetName='InputObject')]
    Param
    (
        [Parameter(Mandatory = $true,
                   ParameterSetName = 'InputObject',
                   ValueFromPipeline = $True)]
        [Object[]]
        $InputObject,

        [switch]$Short,

        [string[]]$IncludeProperty,

        [string[]]$ExcludeProperty,

        [string[]]$MemberType
    )

    Process
    {
        foreach($Object in $InputObject)
        {
            $Params = @{}
            if($ExcludeProperty)
            {
                $Params.add('ExcludeProperty', $ExcludeProperty)
            }
            if($MemberType)
            {
                $Params.add('MemberType', $MemberType)
            }
            $Properties = Get-PropertyOrder @params -InputObject $Object

            if($IncludeProperty)
            {
                $Properties = $Properties | Where {$IncludeProperty -contains $_}
            }

            foreach($Property in $Properties)
            {
                $Field = @{
                    title = $Property
                    value = $Object.$Property
                }
                if($Short)
                {
                    $Field.add('short',$true)
                }
                Add-ObjectDetail -InputObject $Field -TypeName 'PSSlack.Field'
            }
        }
    }
}