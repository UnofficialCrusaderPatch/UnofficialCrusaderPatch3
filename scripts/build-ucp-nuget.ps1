param (
  [Parameter(Mandatory=$true)][string]$Path = "."
)

Write-Output "Compiling ucp dll"

& "$($PSScriptRoot)\compile-ucp-dll.ps1" -Path $Path -BUILD_CONFIGURATION "Debug"
& "$($PSScriptRoot)\compile-ucp-dll.ps1" -Path $Path -BUILD_CONFIGURATION "DebugSecure"
& "$($PSScriptRoot)\compile-ucp-dll.ps1" -Path $Path -BUILD_CONFIGURATION "Release"
& "$($PSScriptRoot)\compile-ucp-dll.ps1" -Path $Path -BUILD_CONFIGURATION "ReleaseSecure"

Write-Output "Compiling ucp dll complete"

### Make the nuget package

Write-Output "Creating nuget package"
msbuild /t:pack .\dll\dll.vcxproj /Verbosity:quiet
Write-Output "Creating nuget package complete"
