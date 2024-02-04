Param(
  [Parameter(Mandatory = $true, ValueFromPipeline = $true)][string]$UCPPath,
  [Parameter(Mandatory = $true, ValueFromPipeline = $false)][string]$Certificate
)


$ErrorActionPreference = "Stop"


Write-Output "Signing extension store"


if ((Test-Path -Path "$Certificate") -ne $true ) {
  throw "Missing certificate to sign zip files with: $($Certificate)"
}


Write-Output "Signing extension store file"
# ucp3-module-signing-key.pem 
& "$($PSScriptRoot)\sign-file.ps1" -Path "$($UCPPath)\extension-store.yml" -Destination "$($UCPPath)\extension-store.yml.sig" -Certificate "$Certificate"