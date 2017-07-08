[![Build status](https://ci.appveyor.com/api/projects/status/kuxiy9m0g19g04o0?svg=true)](https://ci.appveyor.com/project/RamblingCookieMonster/psslack)

PSSlack
=============

This is a quick and dirty module to interact with the Slack API.

This is a work in progress; it's not fully featured or tested, and there may be breaking changes.  Silly blog post pending.

Pull requests and other contributions would be welcome!

# Instructions

```powershell
# One time setup
    # Download the repository
    # Unblock the zip
    # Extract the PSSlack folder to a module path (e.g. $env:USERPROFILE\Documents\WindowsPowerShell\Modules\)
# Or, with PowerShell 5 or later or PowerShellGet:
    Install-Module PSSlack

# Import the module.
    Import-Module PSSlack    #Alternatively, Import-Module \\Path\To\PSSlack

# Get commands in the module
    Get-Command -Module PSSlack

# Get help
    Get-Help Send-SlackMessage -Full
    Get-Help about_PSSlack
```

### Prerequisites

* PowerShell 3 or later
* A valid token or incoming webhook uri from Slack.
  * [Grab a test token](https://api.slack.com/docs/oauth-test-tokens)
  * [Register a Slack app, grab a token](https://api.slack.com/docs/oauth) - we'll try wrapping this in the module later
  * [Add an incoming webhook to your team, grab the Uri](https://my.slack.com/services/new/incoming-webhook/)

# Examples

### Send a Simple Slack Message

```powershell
# This example shows a crudely crafted message without any attachments,
# using parameters from Send-SlackMessage to construct the message.

#Previously set up Uri from https://<YOUR TEAM>.slack.com/apps/A0F7XDUAZ
$Uri = "Some incoming webhook uri from Slack"

Send-SlackMessage -Uri $Uri `
                  -Channel '@wframe' `
                  -Parse full `
                  -Text 'Hello @wframe, join me in #devnull!'

# Send a message to @wframe (not a channel), parsing the text to linkify usernames and channels
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;![Simple Send-SlackMessage](/Media/SimpleMessage.png)

### Search for a Slack Message

```powershell
# Search for a message containing PowerShell, sorting results by timestamp

Find-SlackMessage -Token $Token `
                  -Query 'PowerShell' `
                  -SortBy timestamp
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;![Find Message](/Media/FindMessage.png)

```powershell
# Search for a message containing PowerShell
# Results are sorted by best match by default
# Notice the extra properties and previous/next messages

Find-SlackMessage -Token $Token `
                  -Query 'PowerShell' |
    Select-Object -Property *
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;![Find Message Select All](/Media/FindMessageSelect.png)

You could use this simply to search Slack from the CLI, or in an automated solution that might avoid posting if certain content is already found in Slack.

### Send a Richer Slack Message

```powershell
# This is a simple example illustrating some common options
# when constructing a message attachment
# giving you a richer message

$Token = 'A token. maybe from https://api.slack.com/docs/oauth-test-tokens'

New-SlackMessageAttachment -Color $([System.Drawing.Color]::red) `
                           -Title 'The System Is Down' `
                           -TitleLink https://www.youtube.com/watch?v=TmpRs7xN06Q `
                           -Text 'Please Do The Needful' `
                           -Pretext 'Everything is broken' `
                           -AuthorName 'SCOM Bot' `
                           -AuthorIcon 'http://ramblingcookiemonster.github.io/images/tools/wrench.png' `
                           -Fallback 'Your client is bad' |
    New-SlackMessage -Channel '@wframe' `
                     -IconEmoji :bomb: |
    Send-SlackMessage -Token $Token
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;![Rich messages](/Media/RichMessage.png)

Notice that the title is clickable.  You might link to...

* The alert in question
* A logging solution query
* A dashboard
* Some other contextual link
* Strongbad

### Send Multiple Slack Attachments

```powershell
# This example demonstrates that you can chain new attachments
# together to form a multi-attachment message

$Token = 'A token. maybe from https://api.slack.com/docs/oauth-test-tokens'

New-SlackMessageAttachment -Color $_PSSlackColorMap.red `
                           -Title 'The System Is Down' `
                           -TitleLink https://www.youtube.com/watch?v=TmpRs7xN06Q `
                           -Text 'Everybody panic!' `
                           -Pretext 'Everything is broken' `
                           -Fallback 'Your client is bad' |
    New-SlackMessageAttachment -Color $([System.Drawing.Color]::Orange) `
                               -Title 'The Other System Is Down' `
                               -TitleLink https://www.youtube.com/watch?v=TmpRs7xN06Q `
                               -Text 'Please Do The Needful' `
                               -Fallback 'Your client is bad' |
    New-SlackMessage -Channel '@wframe' `
                     -IconEmoji :bomb: `
                     -AsUser `
                     -Username 'SCOM Bot' |
    Send-SlackMessage -Token $Token
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;![Multiple Attachments](/Media/MultiAttachments.png)

Notice that we can chain multiple New-SlackMessageAttachments together.

### Send a Table of Key Value Pairs

```powershell
# This example illustrates a pattern where you might
# want to send output from a script; you might
# include errors, successful items, or other output

# Pretend we're in a script, and caught an exception of some sort
$Fail = [pscustomobject]@{
    samaccountname = 'bob'
    operation = 'Remove privileges'
    status = "An error message"
    timestamp = (Get-Date).ToString()
}

# Create an array from the properties in our fail object
$Fields = @()
foreach($Prop in $Fail.psobject.Properties.Name)
{
    $Fields += @{
        title = $Prop
        value = $Fail.$Prop
        short = $true
    }
}

$Token = 'A token. maybe from https://api.slack.com/docs/oauth-test-tokens'

# Construct and send the message!
New-SlackMessageAttachment -Color $([System.Drawing.Color]::Orange) `
                           -Title 'Failed to process account' `
                           -Fields $Fields `
                           -Fallback 'Your client is bad' |
    New-SlackMessage -Channel 'devnull' |
    Send-SlackMessage -Uri $uri

# We build up a pretend error object, and send each property to a 'Fields' array
# Creates an attachment with the fields from our error
# Creates a message fromthat attachment and sents it with a uri
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;![Fields](/Media/Fields.png)

### Store and Retrieve Configs

To save time and typing, you can save a token or uri to a config file (protected via DPAPI) and a module variable.

This is used as the default for commands, and is reloaded if you open a new PowerShell session.

```powershell
# Save a Uri and Token.
# If both are specified, token takes precedence.
Set-PSSlackConfig -Uri 'SomeSlackUri' -Token 'SomeSlackToken'

# Read the current cofig
Get-PSSlackConfig
```

# Notes

Currently evaluating .NET Core / Cross-platform functionality.  The following will not work initially:

* Serialization of URIs and tokens via Set-PSSlackConfig.  Use explicit parameters.
* [System.Drawing.Color]::SomeColor shortcut.  Use the provided $_PSSlackColorMap hash to simplify this.  E.g. $_PSSlackColorMap.red

There are a good number of Slack functions out there, including jgigler's [PowerShell.Slack](https://github.com/jgigler/Powershell.Slack) and Steven Murawski's [Slack](https://github.com/smurawski/Slack).  We borrowed some ideas and code from these - thank you!

If you want to go beyond interacting with the Slack API, you might consider [using a bot](http://ramblingcookiemonster.github.io/PoshBot/#references)
