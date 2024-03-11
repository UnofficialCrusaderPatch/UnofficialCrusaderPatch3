param (
  [Parameter(Mandatory=$true)][string]$Path,
  [Parameter(Mandatory=$true)][string]$Destination,
  [Parameter(Mandatory=$false)][switch]$RemoveZippedFolders = $true,
  [Parameter(Mandatory=$false)][switch]$Zip = $false
)

$ErrorActionPreference = "Stop"

# Creates a System.IO.FileSystemInfo
$plugin = Get-Item -Path $Path


Write-Output "Packaging plugin: $($plugin.Name)"


# Create the plugin directory in the ucp-package\ucp\plugins folder
New-Item -Path "$Destination" -Name $plugin.Name -ItemType "directory"
$pluginDir = Get-Item -Path "$Destination\$($plugin.Name)"

Copy-Item "$($plugin.FullName)\*" -Destination "$pluginDir" -Recurse

if ($Zip -eq $true) {
  $name = $pluginDir.Name
	
  7z a -tzip -m0=Copy "$($pluginDir.Parent)\$($name).zip" "$($pluginDir.FullName)\*"	

  if ($RemoveZippedFolders) {
    Remove-Item -Recurse -Force -Path "$($pluginDir.FullName)"
  }
}

