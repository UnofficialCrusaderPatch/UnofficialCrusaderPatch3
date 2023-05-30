
param (
    [Parameter(Mandatory=$true)][string]$Path,
	[Parameter(Mandatory=$true)][string]$BUILD_CONFIGURATION,
	[Parameter(Mandatory=$false)][string]$Verbosity = "quiet"  # msbuild verbosity level
)

$ErrorActionPreference = "Stop"

Write-Output "Compiling ucp.dll"

# Build UCP3
pushd $Path
msbuild /t:restore /Verbosity:$Verbosity
msbuild /m /Verbosity:$Verbosity /p:Configuration=$BUILD_CONFIGURATION . 
popd