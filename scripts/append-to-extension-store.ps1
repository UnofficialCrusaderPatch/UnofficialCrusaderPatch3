
param (
  [Parameter(Mandatory=$true)][string]$Path,
  [Parameter(Mandatory=$true)][string]$ExtensionStorePath
)

$ErrorActionPreference = "Stop"

Write-Output "Adding zip file to extension-store.yml"

$zip = Get-Item -Path "$Path"

Write-Output "$zip"

Import-Module powershell-yaml

if ( $false -eq (Test-Path -Path "$ExtensionStorePath") ) {
  $arr = [System.Collections.ArrayList]@();
  $known = Get-Content ".\scripts\data\known_hashes.yml" | ConvertFrom-Yaml
  $arr.AddRange($known)
  
  $extensionStore = [ordered]@{}
  $extensionStore.extensions = $arr
} else {
  $extensionStore = Get-Content -Path "$ExtensionStorePath" | ConvertFrom-Yaml
}

$hash = (Get-FileHash -Algorithm SHA256 -Path $zip | Select-Object -ExpandProperty Hash).ToLower()

$extensionStore.extensions.Add(
  [ordered]@{
    name = $zip.BaseName;
    hash = $hash;
  }
)

ConvertTo-Yaml $extensionStore | Set-Content -Path $ExtensionStorePath