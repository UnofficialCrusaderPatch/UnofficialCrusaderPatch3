   
param (
    [Parameter(Mandatory=$true)][string]$Path,
	[Parameter(Mandatory=$true)][string]$Destination,
    [Parameter(Mandatory=$true)][string]$BUILD_CONFIGURATION
)

$ErrorActionPreference = "Stop"

# Creates a System.IO.FileSystemInfo
$module = Get-Item -Path $Path

Write-Output "Packaging module: $($module.Name)"

$SIMPLE_CONFIG_MAPPING = @{
    "DebugSecure" = "Debug";
    "ReleaseSecure" = "Release";
    "Debug" = "Debug";
    "Release" = "Release";
}

$simpleBuildConfiguration=$SIMPLE_CONFIG_MAPPING[$BUILD_CONFIGURATION]

# Create the module directory in the ucp-package\ucp\modules folder
  New-Item -Path "$Destination" -Name $module.Name -ItemType "directory"
  $moduleDir = "$Destination" + $module.Name + "\"

  # If the module specifies a custom list of files to include, read that
  $hasFilesList = Test-Path -Path ($module.FullName + "\files.xml")

  # Copy the specified files, or *.lua and definition.yml if no module.files file was found.
  if($hasFilesList) {
    $defaultFilesNode = Select-Xml -XPath "/module/files[not(@build)]" -Path ($module.FullName + "\files.xml")
    $buildFilesNode = Select-Xml -XPath "/module/files[@build='$simpleBuildConfiguration']" -Path ($module.FullName + "\files.xml")
    
    $node = $null
    if($buildFilesNode) {
      $node = $buildFilesNode
    } elseif ($defaultFilesNode) {
      $node = $defaultFilesNode
    } else {
      Throw "Invalid files.xml in module: " + $moduleDir
    }
    
    $moduleFiles = $node.Node.file
    foreach($moduleFile in $moduleFiles) {
      # To allow specification of $(Configuration) in "src" in module.files, we substitute it with the right value here
      $srcFile = $moduleFile.src.Replace("`$(Configuration)", "$simpleBuildConfiguration")
      
      $t = $null
      if($moduleFile.target -eq $null) {
        $t = "."
      } else {
        $t = $moduleFile.target
      }
      
      # create dest if not exist
      $destinationFolder = $moduleDir + "\" + $t + "\"
      if (!(Test-Path -path $destinationFolder)) {
        New-Item $destinationFolder -Type Directory
      }
      
      # Copy the file, can include wildcards
      Copy-Item ($module.FullName + "\" + $srcFile) -Destination $destinationFolder -Recurse
    }
  } else {

    $filesYmlPath = ($module.FullName + "\files.yml")
    $hasFilesList = Test-Path -Path $filesYmlPath

    if ($hasFilesList) {
      $filesYml = Get-Content -Path $filesYmlPath | ConvertFrom-Yaml

      if (($filesYml.meta -ne $null) -and ($filesYml.meta.version -ne $null) -and ($filesYml.meta.version -ne "1.0.0")) {
        throw "Unsupported files.yml version"
      }

      $bcKey = "files-$simpleBuildConfiguration"

      $files = $null

      if ($filesYml[$bcKey]) {
        $files = $filesYml[$bcKey]        
      } elseif ($filesYml.files) {
        $files = $filesYml.files
      } 


      if ($files) {
        $files | ForEach-Object {

          # To allow specification of $(Configuration) in "src" in module.files, we substitute it with the right value here
          if ($src -eq $null) {
            throw ".src attribute cannot be empty"
          }

          $srcFile = $_.src.Replace("`$(Configuration)", "$simpleBuildConfiguration")

          $t = "."
          if($_.target -ne $null) {
            $t = $_.target
          }
          
          # create dest if not exist
          $destinationFolder = $moduleDir + "\" + $t + "\"
          if (!(Test-Path -path $destinationFolder)) {
            New-Item $destinationFolder -Type Directory
          }
          
          # Copy the file, can include wildcards
          Copy-Item ($module.FullName + "\" + $srcFile) -Destination $destinationFolder -Recurse
        }
      }

    } else {

      # TODO: avoid this wildcard. Include .lua .yml and ... only?
      Copy-Item ($module.FullName + "\*") -Destination $moduleDir -Recurse
    }

  }