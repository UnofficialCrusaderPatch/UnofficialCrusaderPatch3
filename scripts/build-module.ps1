
param (
  [Parameter(Mandatory=$true)][string]$Path,
  [Parameter(Mandatory=$true)][string]$Destination,
	[Parameter(Mandatory=$true)][string]$BUILD_CONFIGURATION,
  [Parameter(Mandatory=$false)][string]$UCPNuPkgPath = ".",
  [Parameter(Mandatory=$false)][boolean]$RemoveZippedFolders = $true,
  [Parameter(Mandatory=$false)][string]$ExtensionStorePath = ""
)

$ErrorActionPreference = "Stop"

# Creates a System.IO.FileSystemInfo
$module = Get-Item -Path $Path
$moduleName = $module.Name

Write-Output "Building module: $($module.Name)"

$SIMPLE_CONFIG_MAPPING = @{
  "DebugSecure" = "Debug";
  "ReleaseSecure" = "Release";
  "Debug" = "Debug";
  "Release" = "Release";
}

$simpleBuildConfiguration=$SIMPLE_CONFIG_MAPPING[$BUILD_CONFIGURATION]

if ("" -ne $UCPNuPkgPath) {
  & "$($PSScriptRoot)\build-module-compile-code.ps1" -Path $($module) -BUILD_CONFIGURATION $simpleBuildConfiguration -UCP3_NUPKGDIRECTORY "$UCPNuPkgPath"
} else {
  Write-Output "Skipping compilation as no -UCPNuPkgPath was specified"
}

& "$($PSScriptRoot)\build-module-package-files.ps1" -Path $($module) -Destination "$Destination" -BUILD_CONFIGURATION $($BUILD_CONFIGURATION)


if ( $ExtensionStorePath -ne "" ) {

  & "$($PSScriptRoot)\append-to-extension-store.ps1" -Path "$Destination\$moduleName.zip" -ExtensionStorePath $ExtensionStorePath
}
