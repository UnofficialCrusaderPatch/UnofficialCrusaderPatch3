$ErrorActionPreference = "Stop"

$ep = Get-ExecutionPolicy -Scope CurrentUser
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# Install yaml library
if(!(Get-Module -ListAvailable -Name powershell-yaml)) {
  Install-Module powershell-yaml -Scope CurrentUser -Force  
}

Import-Module powershell-yaml

Set-ExecutionPolicy "$ep" -Scope CurrentUser