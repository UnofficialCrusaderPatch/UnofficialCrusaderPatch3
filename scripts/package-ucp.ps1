   
param (
    [Parameter(Mandatory=$true)][string]$Path,
    [Parameter(Mandatory=$true)][string]$BUILD_CONFIGURATION,
    [Parameter(Mandatory=$false)][string]$SigningCertificatePath = ""
)

$ErrorActionPreference = "Stop"

$SIMPLE_CONFIG_MAPPING = @{
    "DebugSecure" = "Debug";
    "ReleaseSecure" = "Release";
    "Debug" = "Debug";
    "Release" = "Release";
}

Write-Output "Packaging ucp"

## Set up directories
if(Test-Path -Path "$($Path)\$BUILD_CONFIGURATION\ucp-package") {
  Remove-Item -Recurse -Force -Path "$($Path)\$BUILD_CONFIGURATION\ucp-package"
}
mkdir "$($Path)\$BUILD_CONFIGURATION\ucp-package"
mkdir "$($Path)\$BUILD_CONFIGURATION\ucp-package\ucp"   


## Copy all content/ucp files to ucp-package/ucp, except the modules folder
$mainfiles = Get-ChildItem "$($Path)\content\ucp" | Where({$_.Name -ne "modules"})  | foreach{$_.FullName}
Copy-Item $mainfiles -Destination "$($Path)\$BUILD_CONFIGURATION\ucp-package\ucp" -Recurse


## Copy all the module information using the xml specifications of each module.
$modules = Get-ChildItem -Directory content\ucp\modules
foreach($module in $modules) {
    & "$($PSScriptRoot)\package-module.ps1" -Path $($module) -Destination "$($Path)\$BUILD_CONFIGURATION\ucp-package\ucp\modules\" -BUILD_CONFIGURATION $($BUILD_CONFIGURATION)
}


## Copy over fasm dll
Copy-Item "$($Path)\dll\vendor\fasm\extensions\fasm.dll" -Destination "$($Path)\$BUILD_CONFIGURATION\ucp-package\ucp\code\vendor\fasm\fasm.dll"
Copy-Item "$($Path)\dll\vendor\fasm\LICENSE.txt" -Destination "$($Path)\$BUILD_CONFIGURATION\ucp-package\ucp\code\vendor\fasm\LICENSE.txt"


### Zip and sign if necessary
if( $SigningCertificatePath -ne "") {
    
    & "$($PSScriptRoot)\signer.ps1" -UCPPath "$($Path)\$BUILD_CONFIGURATION\ucp-package\ucp\" -RemoveZippedFolders -Certificate $SigningCertificatePath
}


## Copy the dll files
$dllfiles = Get-ChildItem "$($Path)\$BUILD_CONFIGURATION\*.dll"
Copy-Item $dllfiles -Destination "$($Path)\$BUILD_CONFIGURATION\ucp-package\" -Recurse

# binkw32.dll is in the Release or Debug folder.
$binkw32dir = $SIMPLE_CONFIG_MAPPING[$BUILD_CONFIGURATION]    
Copy-Item "$($Path)\$binkw32dir\binkw32.dll" -Destination "$($Path)\$BUILD_CONFIGURATION\ucp-package\" -Recurse

# Rename it to have the _ucp underscore
Rename-Item -Path "$($Path)\$BUILD_CONFIGURATION\ucp-package\binkw32.dll" -NewName "binkw32_ucp.dll"


## Copy the bat file that renames binkw32_ucp.dll to binkw32.dll and backs up binkw32.dll to binkw32_real.dll (if necessary)
Copy-Item "$($Path)\installer\rename-dlls.bat" "$($Path)\$BUILD_CONFIGURATION\ucp-package\ucp\install.bat"

# Needed for the gameseeds feature of ucp legacy
mkdir "$($Path)\$BUILD_CONFIGURATION\ucp-package\gameseeds"


$ENDUSER_CONFIG_MAPPING = @{
    "DebugSecure" = "Debug";
    "ReleaseSecure" = "";
    "Debug" = "DebugDeveloper";
    "Release" = "Developer";
}


$f = Get-Content -Path "$($Path)\version.yml" -Raw
$vyml = ConvertFrom-Yaml $f

$date = $(git log -1 --format=%cd --date=iso-strict)

# Create the ucp-version.yml
#Import-Module powershell-yaml
$versionInfo = [ordered]@{
    major = $vyml.major;
    minor = $vyml.minor;
    patch = $vyml.patch;
    sha = "$GITHUB_SHA";
    build = $ENDUSER_CONFIG_MAPPING["$BUILD_CONFIGURATION"];
    date = "$date";
}
$y = ConvertTo-Yaml $versionInfo
Set-Content -Path "$($Path)\$BUILD_CONFIGURATION\ucp-package\ucp\ucp-version.yml" -Value $y



### Create the zip file

# Create a file name
$name = "$GITHUB_SHA".SubString(0, 10)
$type = "$BUILD_CONFIGURATION" #.SubString(0, 1)
if($BUILD_CONFIGURATION -eq "Debug") 
{
  $type = "DevDebug"
}
if($BUILD_CONFIGURATION -eq "DebugSecure") 
{
  $type = "Debug"
}
if($BUILD_CONFIGURATION -eq "Release") 
{
  $type = "DevRelease"
}
if($BUILD_CONFIGURATION -eq "ReleaseSecure") 
{
  $type = "Release"
}
$NAME = "UCP3-snapshot-$type-$name"

# Write a zip file in the main folder 
7z a -tzip -m0=Copy "$($Path)\$($NAME).zip" "$($Path)\$BUILD_CONFIGURATION/ucp-package/*"
