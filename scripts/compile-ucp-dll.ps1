
param (
    [Parameter(Mandatory=$true)][string]$Path,
	[Parameter(Mandatory=$true)][string]$BUILD_CONFIGURATION
)

$ErrorActionPreference = "Stop"

Write-Output "Compiling ucp.dll"

# Build UCP3
pushd $Path
msbuild /t:restore
msbuild /m /p:Configuration=$BUILD_CONFIGURATION .
popd