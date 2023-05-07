Param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [string]$UCPPath,
    [Parameter(Mandatory=$false, ValueFromPipeline=$false)]
    [switch]$RemoveZippedFolders,
    [Parameter(Mandatory=$true, ValueFromPipeline=$false)]
    [string]$Certificate
)

if ((Test-Path -Path "$Certificate") -ne $true ) {
  throw "Missing certificate to sign zip files with: $($Certificate)"
}

$codeDirectory = Get-Item -Path "$($UCPPath)\code"

Write-Output "Zipping code: file: $($UCPPath)code.zip folder: $($codeDirectory)\*"
7z a -tzip -m0=Copy "$($codeDirectory.Parent)\$($codeDirectory.Name).zip" "$($codeDirectory.FullName)\*"	

if ($RemoveZippedFolders) {
  Remove-Item -Recurse -Force -Path "$($UCPPath)code\"	
}

throw "Quit"

Write-Output "Zipping plugins"

$pluginDirectories = Get-ChildItem -Path "$($UCPPath)\plugins" -Directory

foreach ($pluginDirectory in $pluginDirectories) {
	
	$name = $pluginDirectory.Name
	
	7z a -tzip -m0=Copy "$($pluginDirectory.Parent)\$($name).zip" "$($pluginDirectory.FullName)\*"	

  if ($RemoveZippedFolders) {
    Remove-Item -Recurse -Force -Path "$($pluginDirectory.FullName)"
  }
  
}

Write-Output "Zipping modules"

$moduleDirectories = Get-ChildItem -Path "$($UCPPath)\modules" -Directory

foreach ($moduleDirectory in $moduleDirectories) {
	
	$name = $moduleDirectory.Name
	
	7z a -tzip -m0=Copy "$($moduleDirectory.Parent)\$($name).zip" "$($moduleDirectory.FullName)\*"	

  if ($RemoveZippedFolders) {
    Remove-Item -Recurse -Force -Path "$($moduleDirectory.FullName)"
  }
  
}



$extensions = [System.Collections.ArrayList]@()

Write-Output "Hashing modules"

$moduleZips = Get-ChildItem -Path "$($UCPPath)\modules\*.zip" -File

foreach ($moduleZip in $moduleZips) {
	
	$hash = (Get-FileHash -Algorithm SHA256 -Path $moduleZip | Select-Object -ExpandProperty Hash).ToLower()
	
	$extensions.Add(
	  [ordered]@{
		  name = $moduleZip.BaseName;
		  hash = $hash;
	  }
	)
	
}

Write-Output "Hashing code zip"

$extensions.Add(
	[ordered]@{
		  name = "code";
		  hash = (Get-FileHash -Algorithm SHA256 -Path "$($UCPPath)\code.zip" | Select-Object -ExpandProperty Hash).ToLower();
	 })

Write-Output "Writing extension store file"
# Install-Module -Name powershell-yaml
Import-Module powershell-yaml

$extensionStore = [ordered]@{
	'ucp-build' = "3.0.0";
	extensions = $extensions;
}

$result = ConvertTo-Yaml $extensionStore

Set-Content -Path "$($UCPPath)\extension-store.yml" -Value $result


Write-Output "Signing extension store file"
# ucp3-module-signing-key.pem 
(openssl dgst -sign "$Certificate" -keyform PEM -sha256 -out "$($UCPPath)\extension-store.yml.sig" -hex -r "$($UCPPath)\extension-store.yml")
