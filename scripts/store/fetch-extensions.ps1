
function Get-UCP-Extensions {
  param (
    [Parameter(Mandatory = $true)][System.Collections.ArrayList]$IncludeList,
    [Parameter(Mandatory = $true)][string]$Destination
    
  )

  $ErrorActionPreference = 'Stop'

  $DoneList = [System.Collections.ArrayList]::new()

  $REPO = "UnofficialCrusaderPatch/UCP3-extensions-store"
  $UCP3_REPO = "UnofficialCrusaderPatch/UnofficialCrusaderPatch3"
  $STORE_FILE_NAME = "store.yml"
  $releaseTags = gh --repo $REPO release list --json tagName | ConvertFrom-Json | ForEach-Object { $_.tagName }

  # Descending order
  $sortedReleaseVersionsArray = @($releaseTags | Where-Object { $_.StartsWith("v") } | ForEach-Object { [semver]($_.Substring(1)) } | Sort-Object -Descending)

  $tags = $sortedReleaseVersionsArray | ForEach-Object {"$($_.Major).$($_.Minor).$($_.Patch)"}

  foreach ($tag in $tags) {
    Write-Debug "tag: $tag"

    $storeFile = gh release view "v$tag" --repo $REPO --json assets --jq '.assets' | ConvertFrom-Json | Where-Object {
      $_.name -eq $STORE_FILE_NAME
    }
  
    $storeFileResponse = Invoke-WebRequest $storeFile.url
    $storeFileContents = [System.Text.Encoding]::GetEncoding("UTF-8").GetString($storeFileResponse.Content) | ConvertFrom-Yaml
  
    foreach($ext in $storeFileContents.extensions.list) {
      $url = $ext.contents.package.url
      $sig = $ext.contents.package.signature
      $name = $ext.definition.name
      $version = $ext.definition.version
      $type = $ext.definition.type
      $id = "$name-$version"

      if ($IncludeList.Contains($id) -and ($false -eq $DoneList.Contains($id))) {
        Write-Debug "extension: $id"
        New-Item "$($Destination)\$($type)s" -ItemType Directory -ErrorAction Ignore
        $zipPath = "$($Destination)\$($type)s\$id.zip"
        $folderPath = "$($Destination)\$($type)s\$id"

        if ((("plugin" -eq $type) -and ($false -eq (Test-Path -Path $folderPath))) -or (("module" -eq $type) -and ($false -eq (Test-Path -Path $zipPath)))) {
          Invoke-WebRequest $url -OutFile $zipPath
      
          if ("plugin" -eq $type) {
            Expand-Archive -Path $zipPath -DestinationPath $folderPath
            Remove-Item -Path $zipPath
          } else {
            Set-Content -Value $sig -Path "$($Destination)\$($type)s\$id.zip.sig"
          }
  
          $DoneList.Add($id)
        }


      } else {
        Write-Debug "ignoring: $id"
      }

    }
  
  }

}

function Find-Extension-Identifiers {
  param (
    [Parameter(Mandatory = $false)][string]$Folder = ".\content\ucp\"
  )

  $PathPlugins = "$Folder\plugins\"
  $PathModules = "$Folder\modules\"

  $pluginNames = Get-ChildItem $PathPlugins -Directory | Select-Object -ExpandProperty Name
  $moduleNames = Get-ChildItem $PathModules -Directory | Select-Object -ExpandProperty Name

  return $moduleNames + $pluginNames
}