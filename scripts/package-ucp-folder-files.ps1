
param (
    [Parameter(Mandatory=$true)][string]$Path,
    [Parameter(Mandatory=$true)][string]$BUILD_CONFIGURATION
)

$ErrorActionPreference = "Stop"

$SIMPLE_CONFIG_MAPPING = @{
    "DebugSecure" = "Debug";
    "ReleaseSecure" = "Release";
    "Debug" = "Debug";
    "Release" = "Release";
}


## Copy the dll files
$dllfiles = Get-ChildItem "$($Path)\$BUILD_CONFIGURATION\*.dll"
Copy-Item $dllfiles -Destination "$($Path)\$BUILD_CONFIGURATION\ucp-package\" -Recurse

# binkw32.dll is in the Release or Debug folder.
$binkw32dir = $SIMPLE_CONFIG_MAPPING[$BUILD_CONFIGURATION]    
Copy-Item "$($Path)\$binkw32dir\binkw32.dll" -Destination "$($Path)\$BUILD_CONFIGURATION\ucp-package\" -Recurse

# Rename it to have the _ucp underscore
Rename-Item -Path "$($Path)\$BUILD_CONFIGURATION\ucp-package\binkw32.dll" -NewName "binkw32_ucp.dll" -Force


## Copy the bat file that renames binkw32_ucp.dll to binkw32.dll and backs up binkw32.dll to binkw32_real.dll (if necessary)
Copy-Item "$($Path)\installer\rename-dlls.bat" "$($Path)\$BUILD_CONFIGURATION\ucp-package\ucp\install.bat"



$ENDUSER_CONFIG_MAPPING = @{
    "DebugSecure" = "Debug";
    "ReleaseSecure" = "";
    "Debug" = "DebugDeveloper";
    "Release" = "Developer";
}


$f = Get-Content -Path "$($Path)\version.yml" -Raw
$vyml = ConvertFrom-Yaml $f

$date = $(git log -1 --format=%cd --date=iso-strict)

$GITHUB_SHA = (git rev-parse HEAD)

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
