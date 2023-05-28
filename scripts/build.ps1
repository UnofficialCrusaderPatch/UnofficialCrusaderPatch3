param (
	[string]$Build = "Release",
	[string]$NugetToken = "missing",
	[Parameter(Mandatory=$false)][string]$SigningCertificatePath = ""
)

$ErrorActionPreference = "Stop"

function Require-Script {
    param (
        $ScriptName
    )

    & "$($PSScriptRoot)\$($ScriptName).ps1"
}

Require-Script "import-yaml"


$BUILD_CONFIGURATION = $Build
$BUILD_DIR = "$BUILD_CONFIGURATION\ucp-package\"
$GITHUB_ENV = "GITHUB_ENV"
$GITHUB_SHA = git rev-parse HEAD

$SIMPLE_CONFIG_MAPPING = @{
    "DebugSecure" = "Debug";
    "ReleaseSecure" = "Release";
    "Debug" = "Debug";
    "Release" = "Release";
}

if ($BUILD_CONFIGURATION -eq "ReleaseSecure") {
    if ($SigningCertificatePath -eq "") {
        throw "Missing path to certificate to sign extensions with: $($SigningCertificatePath)"
    }
}


### Prepare directory structure

if(!(Test-Path -Path "$BUILD_CONFIGURATION")) {
  mkdir "$BUILD_CONFIGURATION"  
}



### Add gynt's repo as a source of nuget packages
if ((nuget sources list | Select-String "gynt-packages") -eq $null) {
    if ($NugetToken -eq "missing") {
      throw "Missing nuget token to setup gynt-packages nuget repo"
    }
    # Set up the right nuget packages
    nuget sources add -Name "gynt-packages" -Source "https://nuget.pkg.github.com/gynt/index.json" -StorePasswordInClearText -Username git -Password "$NugetToken"
}



### Compile UCP dll. Build all configurations to make a nuget package

& "$($PSScriptRoot)\compile-ucp-dll.ps1" -Path "." -BUILD_CONFIGURATION "Debug"
& "$($PSScriptRoot)\compile-ucp-dll.ps1" -Path "." -BUILD_CONFIGURATION "DebugSecure"
& "$($PSScriptRoot)\compile-ucp-dll.ps1" -Path "." -BUILD_CONFIGURATION "Release"
& "$($PSScriptRoot)\compile-ucp-dll.ps1" -Path "." -BUILD_CONFIGURATION "ReleaseSecure"

### Make the nuget package

msbuild /t:pack dll
# Prepare for future installation of the nuget package by modules by adding a source pointing to the nuget package

if ((nuget sources list | Select-String "ucp3-dll") -eq $null) {
    nuget sources add -Name "ucp3-dll" -Source "$($pwd)\dll\"
}

# Remove old versions of nuget ucp
Get-ChildItem -Path "$env:UserProfile\.nuget\packages" -Directory -Filter "UnofficialCrusaderPatch*" | Remove-Item -Recurse


### Compile modules

# Build each module if required

# List of modules
$modules = Get-ChildItem -Directory content\ucp\modules
foreach($module in $modules) {  
    & "$($PSScriptRoot)\compile-module.ps1" -Path $($module) -BUILD_CONFIGURATION $($BUILD_CONFIGURATION)
}

### Packaging UCP
& "$($PSScriptRoot)\package-ucp.ps1" -Path "." -BUILD_CONFIGURATION $BUILD_CONFIGURATION -SigningCertificatePath $SigningCertificatePath




