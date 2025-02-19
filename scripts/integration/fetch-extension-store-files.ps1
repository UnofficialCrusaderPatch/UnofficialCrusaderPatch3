$REPO = "unofficialcrusaderpatch/unofficialcrusaderpatch3"

$tagsJson = gh release list --repo $REPO --json tagName --jq 'map(.tagName) |  map(select(. != "latest"))'
$tags = ConvertFrom-Json $tagsJson

$collection = [System.Collections.ArrayList]@()

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
  $collection.AddRange($extensions)
}


