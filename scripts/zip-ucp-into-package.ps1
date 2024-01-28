   
param (
  [Parameter(Mandatory=$true)][string]$Path,
  [Parameter(Mandatory=$true)][string]$BUILD_CONFIGURATION,
  [Parameter(Mandatory=$false)][string]$Destination = "."
)

$Path = Get-Item -Path $Path

pushd "$Path"
$GITHUB_SHA = (git rev-parse HEAD)
popd

# Create a file name
$name = "$GITHUB_SHA".SubString(0, 10)
$type = "$BUILD_CONFIGURATION" #.SubString(0, 1)
if($BUILD_CONFIGURATION -eq "Debug") 
{
  $type = "DevDebug"
  $NAME = "UCP3-snapshot-$name-DevDebug"
}
if($BUILD_CONFIGURATION -eq "DebugSecure") 
{
  $type = "Debug"
  $NAME = "UCP3-snapshot-$name-Debug"
}
if($BUILD_CONFIGURATION -eq "Release") 
{
  $type = "DevRelease"
  $NAME = "UCP3-snapshot-$name-Developer"
}
if($BUILD_CONFIGURATION -eq "ReleaseSecure") 
{
  $type = "Release"
  $NAME = "UCP3-snapshot-$name"
}

# Write a zip file in the main folder 
7z a -tzip -m0=Copy "$($Destination)\$($NAME).zip" "$($Path)\$BUILD_CONFIGURATION/ucp-package/*"