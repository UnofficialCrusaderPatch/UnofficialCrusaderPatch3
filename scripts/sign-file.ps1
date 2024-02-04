Param(
  [Parameter(Mandatory = $true, ValueFromPipeline = $true)][string]$Path,
  [Parameter(Mandatory = $false, ValueFromPipeline = $false)][string]$Destination = "",
  [Parameter(Mandatory = $true, ValueFromPipeline = $false)][string]$Certificate
)

$ErrorActionPreference = "Stop"

if ((Test-Path -Path "$Certificate") -ne $true ) {
  throw "Missing certificate to sign: $($Certificate)"
}

if ($Destination -eq "") {
  $Destination = "$($Path).sig"
}

(openssl dgst -sign "$Certificate" -keyform PEM -sha256 -out "$Destination" -hex -r "$Path")
