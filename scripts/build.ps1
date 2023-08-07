param (
	[string]$Build = "Release",
	[string]$NugetToken = "missing",
	[Parameter(Mandatory=$false)][string]$SigningCertificatePath = ""
)

$ErrorActionPreference = "Stop"

& "$($PSScriptRoot)\import-yaml"


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

& "$($PSScriptRoot)\build-nuget.ps1"

# Prepare for future installation of the nuget package by modules by adding a source pointing to the nuget package

## Two options here. Old thing was
#if ((nuget sources list | Select-String "ucp3-dll") -eq $null) {
#    nuget sources add -Name "ucp3-dll" -Source "$($pwd)\dll\"
#}

# But that pollutes the user pc (adding gynt-packages is already pollution)
# Alternative is to use /p:RestoreAdditionalProjectSources=Path to .nupkg directory in all restore commands
$NUPKG_DIRECTORY = Get-Item -Path "dll\*.nupkg" | Select-Object -ExpandProperty Directory

Write-Output "NUPKG_DIRECTORY: $NUPKG_DIRECTORY"

if ($NUPKG_DIRECTORY -eq $null) {
    dir dll
    throw "NUPKG_DIRECTORY is not valid. Was the nupkg built?"
}

# Remove old versions of nuget ucp
Get-ChildItem -Path "$env:UserProfile\.nuget\packages" -Directory -Filter "UnofficialCrusaderPatch*" | Remove-Item -Recurse


### Compile modules

# First make sure each extension has the right version in the directory
& "$($PSScriptRoot)\upgrade-git-module-folders.ps1"

# Build each module if required

# List of modules
$modules = Get-ChildItem -Directory content\ucp\modules
foreach($module in $modules) {  
    & "$($PSScriptRoot)\compile-module.ps1" -Path $($module) -BUILD_CONFIGURATION $($BUILD_CONFIGURATION) -UCP3_NUPKGDIRECTORY "$NUPKG_DIRECTORY"
}

### Packaging UCP
& "$($PSScriptRoot)\package-ucp.ps1" -Path "." -BUILD_CONFIGURATION $BUILD_CONFIGURATION -SigningCertificatePath $SigningCertificatePath




