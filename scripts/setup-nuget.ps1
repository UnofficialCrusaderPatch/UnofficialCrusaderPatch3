param (
  [string]$NugetToken = "missing"
)


if ($null -eq (nuget sources list | Select-String "gynt-packages")) {
  if ($NugetToken -eq "missing") {
    throw "Missing nuget token to setup gynt-packages nuget repo"
  }
  # Set up the right nuget packages
  nuget sources add -Name "gynt-packages" -Source "https://nuget.pkg.github.com/gynt/index.json" -StorePasswordInClearText -Username git -Password "$NugetToken"
}