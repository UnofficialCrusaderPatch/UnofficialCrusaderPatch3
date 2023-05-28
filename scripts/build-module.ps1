
param (
    [Parameter(Mandatory=$true)][string]$Path,
    [Parameter(Mandatory=$true)][string]$Destination,
	[Parameter(Mandatory=$true)][string]$BUILD_CONFIGURATION
)

$ErrorActionPreference = "Stop"

# Creates a System.IO.FileSystemInfo
$module = Get-Item -Path $Path

Write-Output "Building module: $($module.Name)"


  
  
& "$($PSScriptRoot)\compile-module.ps1" -Path $($module) -BUILD_CONFIGURATION $($BUILD_CONFIGURATION)
& "$($PSScriptRoot)\package-module.ps1" -Path $($module) -Destination "$Destination" -BUILD_CONFIGURATION $($BUILD_CONFIGURATION)