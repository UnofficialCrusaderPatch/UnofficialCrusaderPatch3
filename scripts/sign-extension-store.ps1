Param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$UCPPath,
    [Parameter(Mandatory=$true, ValueFromPipeline=$false)][string]$Certificate
)


$ErrorActionPreference = "Stop"


Write-Output "Signing extensions. Generating extension store"


if ((Test-Path -Path "$Certificate") -ne $true ) {
  throw "Missing certificate to sign zip files with: $($Certificate)"
}


Write-Output "Signing extension store file"
# ucp3-module-signing-key.pem 
(openssl dgst -sign "$Certificate" -keyform PEM -sha256 -out "$($UCPPath)\extension-store.yml.sig" -hex -r "$($UCPPath)\extension-store.yml")
