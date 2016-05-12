[![Build status](https://ci.appveyor.com/api/projects/status/xyl9iyopvbucvpbi/branch/master?svg=true)](https://ci.appveyor.com/project/RamblingCookieMonster/psstackexchange/branch/master)

PSSlack
=============

This is not fully featured or tested, but pull requests would be welcome!

#Instructions

```powershell
# One time setup
    # Download the repository
    # Unblock the zip
    # Extract the PSStackExchange folder to a module path (e.g. $env:USERPROFILE\Documents\WindowsPowerShell\Modules\)

    #Simple alternative, if you have PowerShell 5, or the PowerShellGet module:
        Install-Module PSStackExchange

# Import the module.
    Import-Module PSStackExchange    #Alternatively, Import-Module \\Path\To\PSStackExchange

# Get commands in the module
    Get-Command -Module PSStackExchange

# Get help
    Get-Help Get-SEObject -Full
    Get-Help about_PSStackExchange
```

#Examples

### Find Stack Exchange Sites and Urls

```PowerShell
# Find Stack Exchange sites and urls
    Get-SEObject -Object Sites |
        Sort -Property api_site_parameter |
        Select -Property api_site_parameter, site_url
```

![Get Sites](/Media/Get-SEObject.png)

### Search Stack Exchange Questions

```PowerShell
# Search questions on stack overflow, tagged PowerShell, with System.DBNull in the title
    Search-SEQuestion -Title System.DBNull -Tag PowerShell -Site StackOverflow

# Search questions on ServerFault
#     Posted by User with ID 105072
#     With PowerShell in the Title
#     Without the tag windows-server-2008-r2
    Search-SEQuestion -User 105072 `
                      -Site ServerFault `
                      -ExcludeTag 'windows-server-2008-r2' `
                      -Title PowerShell
```

![Search Questions](/Media/Search-SEQuestion.png)


