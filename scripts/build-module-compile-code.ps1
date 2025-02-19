
param (
  [Parameter(Mandatory=$true)][string]$Path,
	[Parameter(Mandatory=$true)][string]$BUILD_CONFIGURATION,
  [Parameter(Mandatory=$true)][string]$UCP3_NUPKGDIRECTORY,
	[Parameter(Mandatory=$false)][string]$Verbosity = "quiet"  # msbuild verbosity level
)

$ErrorActionPreference = "Stop"

# Creates a System.IO.FileSystemInfo
$module = Get-Item -Path $Path

Write-Output "Compiling module: $($module.Name)"

$SIMPLE_CONFIG_MAPPING = @{
    "DebugSecure" = "Debug";
    "ReleaseSecure" = "Release";
    "Debug" = "Debug";
    "Release" = "Release";
}

# Modules that should be compiled do not inherit the Secure build configurations for now
$simpleBuildConfiguration=$SIMPLE_CONFIG_MAPPING[$BUILD_CONFIGURATION]

# If the module uses C++ we have to build it first
$hasSLN = Get-ChildItem -Recurse -Path ($module.FullName + "\*.sln") -ErrorAction SilentlyContinue

# Find meson.build file (no recursion)
$hasMeson = Get-ChildItem -Path ($module.FullName + "\meson.build") -ErrorAction SilentlyContinue

# Find build.ps1 for custom build implementations
$hasBuild = Get-ChildItem -Path ($module.FullName + "\build.ps1") -ErrorAction SilentlyContinue

# Build the module
if ($hasBuild) {
  & "$($PSScriptRoot)\compilation\compile-custom.ps1" -Path $Path -BUILD_CONFIGURATION $simpleBuildConfiguration -UCP3_NUPKGDIRECTORY $UCP3_NUPKGDIRECTORY -Verbosity $Verbosity
}
elseif ($hasMeson) {
  & "$($PSScriptRoot)\compilation\compile-meson.ps1" -Path $Path -BUILD_CONFIGURATION $simpleBuildConfiguration -UCP3_NUPKGDIRECTORY $UCP3_NUPKGDIRECTORY -Verbosity $Verbosity
}
elseif($hasSLN) {
  & "$($PSScriptRoot)\compilation\compile-sln.ps1" -Path $Path -BUILD_CONFIGURATION $simpleBuildConfiguration -UCP3_NUPKGDIRECTORY $UCP3_NUPKGDIRECTORY -Verbosity $Verbosity
}
