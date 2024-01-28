param (
  [Parameter(Mandatory = $true)][string[]]$What,
  [Parameter(Mandatory = $false)][string]$Path = ".",
  [Parameter(Mandatory = $false)][string]$BuildType = "",
  [Parameter(Mandatory = $false)][string]$NugetToken = "missing",
  [Parameter(Mandatory = $false)][string]$Certificate = ""
)

$ErrorActionPreference = "Stop"

if ( $What.Contains("all") ) {
  # [string[]]$What = "setup","nuget","modules","plugins","ucp"

  & "$($PSScriptRoot)\build.ps1" -Path $Path -What "clean"
  & "$($PSScriptRoot)\build.ps1" -Path $Path -What "setup" -NugetToken $NugetToken
  & "$($PSScriptRoot)\build.ps1" -Path $Path -What "nuget"
  & "$($PSScriptRoot)\build.ps1" -Path $Path -What "modules" -BuildType $BuildType
  & "$($PSScriptRoot)\build.ps1" -Path $Path -What "plugins"
  & "$($PSScriptRoot)\build.ps1" -Path $Path -What "ucp" -BuildType $BuildType -Certificate $Certificate

  return
}

if ( $What.Contains("modules") ) {

  if ( $BuildType -eq "" ) {
    throw "-BuildType not specified"
  }


}

$Path = Get-Item -Path $Path

try {

  [string[]]$BUILD_CONFIGURATIONS = "Debug","DebugSecure","Release","ReleaseSecure"
  $BUILD_CONFIGURATION = $BuildType
  $BUILD_DIR = "$Path\$BUILD_CONFIGURATION\ucp-package\"
  $GITHUB_ENV = "GITHUB_ENV"


  $SIMPLE_CONFIG_MAPPING = @{
    "DebugSecure"   = "Debug";
    "ReleaseSecure" = "Release";
    "Debug"         = "Debug";
    "Release"       = "Release";
  }
  
  
  ### Prepare directory structure
  
    
  if ( $What.Contains("clean") ) {
    Write-Output "Cleaning"

    # Remove old versions of nuget ucp
    if ( Test-Path -Path "$env:UserProfile\.nuget\packages" ) {
      Get-ChildItem -Path "$env:UserProfile\.nuget\packages" -Directory -Filter "UnofficialCrusaderPatch*" | Remove-Item -Recurse
    }

    ## Set up directories
    foreach ($bc in $BUILD_CONFIGURATIONS) {
      if(Test-Path -Path "$($Path)\$bc\ucp-package") {
        Remove-Item -Recurse -Force -Path "$($Path)\$bc\ucp-package"
      }
    }

    Write-Output "Cleaning complete"

    return
  }
  
  if ( $What.Contains("setup") ) {

    Write-Output "Running setup"
  
    ### Add gynt's repo as a source of nuget packages
    & "$($PSScriptRoot)\setup-nuget.ps1" -NugetToken $NugetToken

    Write-Output "Running setup complete"
    return
  }

  if ( $What.Contains("nuget") ) {

    Write-Output "Building nuget"

    ### Compile UCP dll: Build all configurations to make a nuget package
    & "$($PSScriptRoot)\build-ucp-nuget.ps1" -Path $Path

        
    # Remove old versions of nuget ucp
    Get-ChildItem -Path "$env:UserProfile\.nuget\packages" -Directory -Filter "UnofficialCrusaderPatch*" | Remove-Item -Recurse
    
    # Prepare for future installation of the nuget package by modules by adding a source pointing to the nuget package
    
    ## Two options here. Old thing was
    #if ((nuget sources list | Select-String "ucp3-dll") -eq $null) {
    #    nuget sources add -Name "ucp3-dll" -Source "$($pwd)\dll\"
    #}
    
    # But that pollutes the user pc (adding gynt-packages is already pollution)
    # Alternative is to use /p:RestoreAdditionalProjectSources=Path to .nupkg directory in all restore commands
    $NUPKG_DIRECTORY = Get-Item -Path "$Path\dll\*.nupkg" | Select-Object -ExpandProperty Directory
    
    if ($NUPKG_DIRECTORY -eq $null) {
      throw "NUPKG_DIRECTORY is not valid. Was the nupkg built?"
    }

    Write-Output "NuPkg can be found in directory: $NUPKG_DIRECTORY"
    Write-Output "Building nuget complete"

    return
  }

  if ( $What.Contains("modules") -or $What.Contains("plugins") ) {
    ### Update extension folder names
    # First make sure each extension has the right version in the directory
    & "$($PSScriptRoot)\upgrade-extension-folders.ps1"
  }

  
  ### Packaging UCP


  if ( $What.Contains("ucp") -or $What.Contains("modules") -or $What.Contains("plugins") ) {

    #### Create Build Configuration directory if it does not exist
    if ($false -eq (Test-Path -Path "$Path\$BUILD_CONFIGURATION")) {
      New-Item -Path "$Path" -Name "$BUILD_CONFIGURATION" -ItemType "directory" | Out-Null
    }
    
    if ( $false -eq (Test-Path -Path "$($Path)\$BUILD_CONFIGURATION\ucp-package")) {
      New-Item -Path "$($Path)\$BUILD_CONFIGURATION" -Name "ucp-package" -ItemType 'directory' | Out-Null
      New-Item -Path "$($Path)\$BUILD_CONFIGURATION\ucp-package" -Name "ucp" -ItemType 'directory' | Out-Null
    }
  }

  if ( $What.Contains("modules") ) {

    Write-Output "Building modules"
        
    $nupkg_file = Get-Item -Path "$Path\dll\*.nupkg"
    $NUPKG_DIRECTORY =  $nupkg_file | Select-Object -ExpandProperty Directory

    Write-Output "Using ucp nupkg: $nupkg_file"

    if ($NUPKG_DIRECTORY -eq $null) {
      throw "NUPKG_DIRECTORY is not valid. Was the nupkg built?"
    }

    $ExtensionStorePath = "$($Path)\$BUILD_CONFIGURATION\ucp-package\ucp\extension-store.yml"

    ## Copy all the module information using the xml specifications of each module.
    $modules = Get-ChildItem -Directory "$Path\content\ucp\modules"
    foreach($module in $modules) {
        & "$($PSScriptRoot)\build-module.ps1" -Path $($module) -Destination "$($Path)\$BUILD_CONFIGURATION\ucp-package\ucp\modules\" -BUILD_CONFIGURATION $($BUILD_CONFIGURATION) -RemoveZippedFolders -UCPNuPkgPath $NUPKG_DIRECTORY -ExtensionStorePath $ExtensionStorePath
    }

    Write-Output "Building modules complete"

    return
  }

  if ( $What.Contains("plugins") ) {
    Write-Output "Building plugins"
    ## Copy all the module information using the xml specifications of each module.
    $plugins = Get-ChildItem -Directory "$Path\content\ucp\plugins"
    foreach($plugin in $plugins) {
        & "$($PSScriptRoot)\build-plugin.ps1" -Path $($plugin) -Destination "$($Path)\$BUILD_CONFIGURATION\ucp-package\ucp\plugins\" -RemoveZippedFolders
    }

    Write-Output "Building plugins complete"

    return
  }


  if ( $What.Contains("ucp") ) {
    Write-Output "Creating ucp package"

   
    if ($BuildType -eq "ReleaseSecure") {
      if ($Certificate -eq "") {
        throw "Missing -Certificate (path to extension signing certificate): $Certificate"
      }
    }

    ## Copy all content/ucp files to ucp-package/ucp, except the modules and plugins folder
    & "$($PSScriptRoot)\package-ucp-code.ps1" -Path $Path -Destination "$($Path)\$BUILD_CONFIGURATION\ucp-package\ucp" -RemoveZippedFolders

    $ExtensionStorePath = "$($Path)\$BUILD_CONFIGURATION\ucp-package\ucp\extension-store.yml"
    & "$($PSScriptRoot)\append-to-extension-store.ps1" -Path "$($Path)\$BUILD_CONFIGURATION\ucp-package\ucp\code.zip" -ExtensionStorePath $ExtensionStorePath

   

    if( $Certificate -ne "") {          
      & "$($PSScriptRoot)\sign-extension-store.ps1" -UCPPath "$($Path)\$BUILD_CONFIGURATION\ucp-package\ucp\" -Certificate $Certificate
    }

    ### Package ucp folder files
    & "$($PSScriptRoot)\package-ucp-folder-files.ps1" -Path $Path -BUILD_CONFIGURATION $BUILD_CONFIGURATION

    ### Create the zip file
    & "$($PSScriptRoot)\zip-ucp-into-package.ps1" -Path $Path -BUILD_CONFIGURATION $BUILD_CONFIGURATION -Destination $Path

    Write-Output "Creating ucp package complete"

    return
  }

} finally {
  
}


