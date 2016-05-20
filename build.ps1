# Grab nuget bits, install modules, start build.
$null = Get-PackageProvider -Name NuGet -ForceBootstrap

Install-Module Psake, PSDeploy, Pester -force

Import-Module Psake
Invoke-psake .\psake.ps1