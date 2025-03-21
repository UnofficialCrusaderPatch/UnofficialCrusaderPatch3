
$REPO = "unofficialcrusaderpatch/unofficialcrusaderpatch3"

$tagsJson = gh release list --repo $REPO --json tagName --jq 'map(.tagName) |  map(select(. != "latest"))'
$tags = ConvertFrom-Json $tagsJson # make sure they are latest to earliest version

$collection = [System.Collections.ArrayList]@()

$known = Get-Content ".\scripts\data\known_hashes.yml" -ErrorAction Ignore | ConvertFrom-Yaml
$map = [System.Collections.Hashtable]::new()

$known | ForEach-Object {
  if ($null -eq $map[$_.name]) {
    $map[$_.name] = $_.hash
  }
}

$tags | ForEach-Object {

  $tag = $_
  $zipAsset = gh release view $tag --repo $REPO --json assets --jq '.assets' | ConvertFrom-Json | Where-Object {
    $_.name -match "UCP3-[0-9]+[.][0-9]+[.][0-9]+-[a-f0-9]+.zip"
  }
  
  $assetName = $zipAsset.name
  
  Invoke-WebRequest $zipAsset.url -OutFile $assetName
  
  Remove-Item -Recurse -Force -Path "temp" -ErrorAction SilentlyContinue
  Expand-Archive -Path $assetName -DestinationPath "temp"
  
  $storePath = Get-ChildItem -Recurse -Path "temp\**\extension-store.yml"
  $store = $storePath | Get-Content | ConvertFrom-Yaml
  $extensions = $store.extensions | Where-Object { "code" -ne $_.name}

  $uniqueExtensions = $extensions | Where-Object {$null -eq $map[$_.name]}
  Write-Output "Adding unique extensions: $($uniqueExtensions.Count)"
  $uniqueExtensions | Select-Object -ExpandProperty name | Join-String -Separator ", " | Write-Output

  if ($null -ne $uniqueExtensions) {
    $collection.AddRange($uniqueExtensions)
  }
  
  $uniqueExtensions | ForEach-Object {
    if ($null -eq $map[$_.name]) {
      $map[$_.name] = $_.hash
    }
  }
}


$collection | Where-Object {$_.hash.Length -eq 64} | Sort-Object -Property name | ConvertTo-Yaml | Out-File ".\scripts\data\known_hashes.yml"