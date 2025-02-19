param (
  [Parameter(Mandatory=$true)][string]$Path,
	[Parameter(Mandatory=$true)][string]$BUILD_CONFIGURATION,
  [Parameter(Mandatory=$true)][string]$UCP3_NUPKGDIRECTORY,
	[Parameter(Mandatory=$false)][string]$Verbosity = "quiet"  # msbuild verbosity level
)

$mesonMapping = @{
  "DebugSecure" = "debug";
  "ReleaseSecure" = "release";
  "Debug" = "debug";
  "Release" = "release";
}

# Creates a System.IO.FileSystemInfo
$module = Get-Item -Path $Path

# Find meson.build file (no recursion)
$mesonBuildFile = Get-ChildItem -Path ($module.FullName + "\meson.build")

Push-Location $mesonBuildFile.Parent

# Setup the build directory
meson setup build --buildtype $mesonMapping[$BUILD_CONFIGURATION]
ninja -C build

Pop-Location