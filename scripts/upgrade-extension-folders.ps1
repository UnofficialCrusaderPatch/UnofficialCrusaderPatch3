
$ErrorActionPreference = "Stop"

& "$($PSScriptRoot)\import-yaml"

$moduleDirs = Get-ChildItem -Path "content/ucp/modules" -Directory
$pluginDirs = Get-ChildItem -Path "content/ucp/plugins" -Directory


$extensionDirs = $moduleDirs + $pluginDirs

foreach($extensionDir in $extensionDirs) {
    $isGit = Test-Path -Path "$($extensionDir.FullName)\.git"

    if (Test-Path -Path "$($extensionDir.FullName)\definition.yml") {

        $defRaw = Get-Content -Raw -Path "$($extensionDir.FullName)\definition.yml"

        $def = ConvertFrom-Yaml $defRaw

        $version = $def.version

        if ($extensionDir.FullName.EndsWith($version) -ne $true) {
            $relativePath = $extensionDir.FullName.Substring($pwd.Path.Length + 1)
            $noVersion = $relativePath.SubString(0, $relativePath.LastIndexOf('-'))
            $newRelativePath = $noVersion + '-' + $version

            if ( $true -eq $isGit ) {
              Invoke-Expression "git mv $($relativePath) $($newRelativePath)"
            } else {
              Move-Item -Path "$relativePath" -Destination "$newRelativePath"
            }
        
        }

    }



    
}
