param (
  [Parameter(Mandatory=$true)][string]$Path,
	[Parameter(Mandatory=$true)][string]$BUILD_CONFIGURATION,
  [Parameter(Mandatory=$true)][string]$UCP3_NUPKGDIRECTORY,
	[Parameter(Mandatory=$false)][string]$Verbosity = "quiet"  # msbuild verbosity level
)

# Creates a System.IO.FileSystemInfo
$module = Get-Item -Path $Path

Push-Location $module

& ".\build.ps1" -BuildType $BUILD_CONFIGURATION -UCP3Path $UCP3_NUPKGDIRECTORY

Pop-Location