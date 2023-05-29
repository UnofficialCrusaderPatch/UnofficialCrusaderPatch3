param (
	[Parameter(Mandatory=$false)][string]$Path = "."
)

$ErrorActionPreference = "Stop"

$DIRS_TO_REMOVE = "Debug","Release","DebugSecure","ReleaseSecure","obj", "packages"

$TARGET_DIRS_PROJ = Get-ChildItem -Path "$Path" -Recurse -Filter "*.vcxproj" | Select-Object -ExpandProperty Directory
$TARGET_DIRS_SLN = Get-ChildItem -Path "$Path" -Recurse -Filter "*.sln" | Select-Object -ExpandProperty Directory
$TARGET_DIRS = $TARGET_DIRS_PROJ + $TARGET_DIRS_SLN

$TARGET_DIRS | Get-ChildItem -Directory | Where-Object {
        $DIRS_TO_REMOVE.Contains($_.Name)
    } | ForEach-Object {
        Write-Output "Removing directory: $_"
        Remove-Item -Recurse -Path $_
    }
