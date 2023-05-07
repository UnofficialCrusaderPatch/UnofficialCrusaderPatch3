Param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [string]$Path,
    [Parameter(Mandatory=$false, ValueFromPipeline=$false)]
    [switch]$RemoveZippedFolders,
    [Parameter(Mandatory=$true, ValueFromPipeline=$false)]
    [string]$Certificate
)

if ((Test-Path -Path "$Certificate") -ne $true ) {
  throw "Missing certificate to sign zip files with: $($Certificate)"
}

$pluginDirectories = Get-ChildItem -Path "$($Path)\plugins" -Directory

foreach ($pluginDirectory in $pluginDirectories) {
	
	$name = $pluginDirectory.Name
	
	7z a -tzip -m0=Copy "$($pluginDirectory.Parent)\$($name).zip" "$($pluginDirectory.FullName)\*"	

  if ($RemoveZippedFolders) {
    Remove-Item -Recurse -Force -Path "$($pluginDirectory.FullName)"
  }
  
}

$moduleDirectories = Get-ChildItem -Path "$($Path)\modules" -Directory

foreach ($moduleDirectory in $moduleDirectories) {
	
	$name = $moduleDirectory.Name
	
	7z a -tzip -m0=Copy "$($moduleDirectory.Parent)\$($name).zip" "$($moduleDirectory.FullName)\*"	

  if ($RemoveZippedFolders) {
    Remove-Item -Recurse -Force -Path "$($moduleDirectory.FullName)"
  }
  
}

$moduleZips = Get-ChildItem -Path "$($Path)\modules\*.zip" -File

$extensions = [System.Collections.ArrayList]@()

foreach ($moduleZip in $moduleZips) {
	
	$hash = (Get-FileHash -Algorithm SHA256 -Path $moduleZip | Select-Object -ExpandProperty Hash).ToLower()
	
	$extensions.Add(
	  [ordered]@{
		  name = $moduleZip.BaseName;
		  hash = $hash;
	  }
	)
	
}

7z a -tzip -m0=Copy "$($Path)\code.zip" "$($Path)\code\*"	

if ($RemoveZippedFolders) {
  Remove-Item -Recurse -Force -Path "$($Path)\code"	
}

$hash = (Get-FileHash -Algorithm SHA256 -Path "$($Path)\code.zip" | Select-Object -ExpandProperty Hash).ToLower()

$extensions.Add(
	[ordered]@{
		  name = "code";
		  hash = $hash;
	 })

# Install-Module -Name powershell-yaml
Import-Module powershell-yaml

$extensionStore = [ordered]@{
	'ucp-build' = "3.0.0";
	extensions = $extensions;
}

$result = ConvertTo-Yaml $extensionStore

Set-Content -Path "$($Path)\extension-store.yml" -Value $result

# ucp3-module-signing-key.pem 
(openssl dgst -sign "$Certificate" -keyform PEM -sha256 -out "$($Path)\extension-store.yml.sig" -hex -r "$($Path)\extension-store.yml")
