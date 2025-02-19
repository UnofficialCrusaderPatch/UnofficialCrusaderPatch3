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

# If the module uses C++ we have to build it first
$hasSLN = Get-ChildItem -Recurse -Path ($module.FullName + "\*.sln")

Push-Location $hasSLN.Directory.FullName
# This is kept in to keep compatibility with VS2019 style of nuget referencing
nuget restore -Source "$UCP3_NUPKGDIRECTORY"

msbuild /m /t:restore /p:RestoreAdditionalProjectSources="$UCP3_NUPKGDIRECTORY" /Verbosity:$Verbosity

msbuild /m /p:Configuration=$BUILD_CONFIGURATION /Verbosity:$Verbosity /property:Platform=x86
Pop-Location