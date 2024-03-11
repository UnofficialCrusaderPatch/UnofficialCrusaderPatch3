param (
    [Parameter(Mandatory=$true)][string]$Path,
    [Parameter(Mandatory=$true)][string]$Destination,
    [Parameter(Mandatory=$false)][switch]$RemoveZippedFolders = $true
)

$mainfiles = Get-ChildItem "$($Path)\content\ucp" | Where({$_.Name -ne "modules"})  | Where({$_.Name -ne "plugins"}) | foreach{$_.FullName}
Copy-Item $mainfiles -Destination "$($Destination)" -Recurse

## Copy over fasm dll
# $($Path)\$BUILD_CONFIGURATION\ucp-package\ucp
Copy-Item "$($Path)\dll\vendor\fasm\extensions\fasm.dll" -Destination "$Destination\code\vendor\fasm\fasm.dll"
Copy-Item "$($Path)\dll\vendor\fasm\LICENSE.txt" -Destination "$Destination\code\vendor\fasm\LICENSE.txt"


$codeDirectory = Get-Item -Path "$($Destination)\code"

# Write-Output "Zipping code: file: $($Destination)\code.zip folder: $($codeDirectory)\*"
Write-Output "Zipping code: file: $($codeDirectory.Parent.FullName)\$($codeDirectory.Name).zip folder: $($codeDirectory)\*"
7z a -tzip -m0=Copy "$($codeDirectory.Parent.FullName)\$($codeDirectory.Name).zip" "$($codeDirectory.FullName)\*"	

if ($RemoveZippedFolders) {
  Remove-Item -Recurse -Force -Path $codeDirectory
}
