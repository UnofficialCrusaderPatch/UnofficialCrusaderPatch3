
& "$($PSScriptRoot)\compile-ucp-dll.ps1" -Path "." -BUILD_CONFIGURATION "Debug"
& "$($PSScriptRoot)\compile-ucp-dll.ps1" -Path "." -BUILD_CONFIGURATION "DebugSecure"
& "$($PSScriptRoot)\compile-ucp-dll.ps1" -Path "." -BUILD_CONFIGURATION "Release"
& "$($PSScriptRoot)\compile-ucp-dll.ps1" -Path "." -BUILD_CONFIGURATION "ReleaseSecure"

### Make the nuget package

msbuild /t:pack dll /Verbosity:quiet