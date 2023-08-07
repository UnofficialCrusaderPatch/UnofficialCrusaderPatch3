
$ErrorActionPreference = "Stop"

& "$($PSScriptRoot)\import-yaml"

$moduleDirs = Get-ChildItem -Path "content/ucp/modules" -Directory
$pluginDirs = Get-ChildItem -Path "content/ucp/plugins" -Directory


$extensionDirs = $moduleDirs + $pluginDirs

$gitExtensionDirs = $extensionDirs | Where-Object {Test-Path -Path "$($_.FullName)\.git"}

foreach($gitExtensionDir in $gitExtensionDirs) {
    $defRaw = Get-Content -Raw -Path "$($gitExtensionDir.FullName)\definition.yml"

    $def = ConvertFrom-Yaml $defRaw

    $version = $def.version

    if ($gitExtensionDir.FullName.EndsWith($version) -ne $true) {
        $relativePath = $gitExtensionDir.FullName.Substring($pwd.Path.Length + 1)
        $noVersion = $relativePath.SubString(0, $relativePath.LastIndexOf('-'))
        $newRelativePath = $noVersion + '-' + $version

        Invoke-Expression "git mv $($relativePath) $($newRelativePath)"
    }

    
}