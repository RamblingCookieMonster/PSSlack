@{

# Script module or binary module file associated with this manifest.
RootModule = 'PSSlack.psm1'

# Version number of this module.
ModuleVersion = '1.0.0'

# ID used to uniquely identify this module
GUID = 'fb0a1f73-e16c-4829-b2a7-4fc8d7bed545'

# Author of this module
Author = 'Warren Frame'

# Copyright statement for this module
Copyright = '(c) 2018 Warren F. All rights reserved.'

# Description of the functionality provided by this module
Description = 'PowerShell module for the Slack API'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '3.0'

# Format files (.ps1xml) to be loaded when importing this module
FormatsToProcess = 'PSSlack.Format.ps1xml'

# Functions to export from this module
FunctionsToExport = '*'

# Cmdlets to export from this module
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '_PSSlackColorMap'

# Aliases to export from this module
AliasesToExport = '*'

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
         Tags = @('Slack', 'Chat', 'Message', 'Messaging', 'ChatOps')

        # A URL to the license for this module.
         LicenseUri = 'https://github.com/RamblingCookieMonster/PSSlack/blob/master/LICENSE'

        # A URL to the main website for this project.
         ProjectUri = 'https://github.com/RamblingCookieMonster/PSSlack/'

        # ReleaseNotes of this module
        ReleaseNotes = 'Switched from channels.list to conversations.list, thanks to @DWOF!'

    } # End of PSData hashtable

} # End of PrivateData hashtable
}





