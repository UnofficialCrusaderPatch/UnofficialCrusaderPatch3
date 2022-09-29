param (
	[string]$build = "Release",
	[string]$token = ""
	#[Parameter(Mandatory=$true)][string]$username,
	#[string]$password = $( Read-Host "Input password, please" )
)
 
# Install yaml library
Install-Module powershell-yaml -Scope CurrentUser # -Force
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
Import-Module powershell-yaml

$msbuild_raw = Get-Content -Path ".github\workflows\msbuild.yml" -Raw
$msbuild = ConvertFrom-Yaml $msbuild_raw

foreach($ev in $msbuild.env.GetEnumerator()) {
	[System.Environment]::SetEnvironmentVariable($ev.Name, $ev.Value)
}

$env:BUILD_CONFIGURATION = $build
$env:DIR = "$env:BUILD_CONFIGURATION\ucp-package\"
$env:GITHUB_ENV = "GITHUB_ENV"
$env:GITHUB_SHA = git rev-parse HEAD

rm -R .\$env:BUILD_CONFIGURATION\ucp-package\

foreach($step in $msbuild.jobs.build.steps) {
	if ($step.ContainsKey("run")) {
		$step["run"] | Invoke-Expression
	}
}

