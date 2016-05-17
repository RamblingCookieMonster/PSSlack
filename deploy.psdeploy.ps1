# Generic module deployment.  Assumes a folder structure of:
# - RepoFolder
#   - This PSDeploy file
#   - ModuleName
#     - ModuleName.psd1

# find a folder that has psd1 of same name...
$Script:ModuleToDeploy = Get-ChildItem $PSScriptRoot -Directory |
    Where-Object {
        Test-Path $(Join-Path $_.FullName "$($_.name).psd1";)
    } |
    Select -ExpandProperty Fullname

if($ModuleToDeploy -and $ModuleToDeploy.Count -eq 1)
{
    Deploy Module {
        By PSGalleryModule {
            FromSource $Script:ModuleToDeploy
            To Gallery
            WithOptions @{
                ApiKey = $ENV:NugetApiKey
            }
        }
    }
}