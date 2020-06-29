param($Task = 'Default')

# Grab nuget bits, install modules, set build variables, start build.
Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null
Install-Module Pester -RequiredVersion 4.10.1 -Force -AllowClobber -SkipPublisherCheck -Scope CurrentUser
Install-Module Psake, PSDeploy, BuildHelpers -force
Import-Module Psake, BuildHelpers

Set-BuildEnvironment

Invoke-psake .\psake.ps1 -taskList $Task -nologo
exit ( [int]( -not $psake.build_success ) )