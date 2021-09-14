# UnofficialCrusaderPatch3
Development for the new UCP DLL Injection approach.

## Working on the DLL: Setting up the repo locally and building the project
0. Make sure you have the nuget command line program installed. Also, create a access token with just read:packages rights via your GitHub settings if you do not have one. You need it at step 4.
1. Start the VS2019 developer console.
2. Clone the repo, and change directory into the repo directory.
```powershell
git clone https://github.com/UnofficialCrusaderPatch/UnofficialCrusaderPatch3
cd UnofficialCrusaderPatch3
```
3. Start a powershell session in the dev console`
```powershell
powershell.exe
```
4. Add gynt's NuGet package repo to the known sources for NuGet. If you do not like storing the access token in plain text, omit the Username and Password parameters, and use them when asked at step 5.
```powershell
nuget sources add -Name "gynt-packages" -Source "https://nuget.pkg.github.com/gynt/index.json" -StorePasswordInClearText -Username git -Password "%YOUR_ACCESS_TOKEN%"
```
5. Install dependencies
```powershell
nuget restore
```
6. Set the BUILD_CONFIGURATION environment variable to "Release" if you want a Release build.
```powershell
$env:BUILD_CONFIGURATION="Release"
```
7. Build the dll
```cmd
msbuild /p:Configuration=$env:BUILD_CONFIGURATION`
```
## Creating the UCP3 package:
Execute powershell scripts found [here](https://github.com/UnofficialCrusaderPatch/UnofficialCrusaderPatch3/blob/main/.github/workflows/msbuild.yml) (copy paste) into your powershell session. 

All files will be prepared in `$env:BUILD_CONFIGURATION\ucp-package` (e.g., Release\ucp-package). The files from this folder can be directly copied to the game directory.
To install the system, run `install.bat` to backup the game's `binkw32.dll` (to `binkw32_real.dll`) and overwrite `binkw32.dll` with `binkw32_ucp.dll`.

## Working on the lua part:
Install a non-Secure build and modify the .lua files. Core functionality is found in the `ucp/code` directory. 

### Recommended tools
IntelliJ IDEA (any will do) with the EmmyLUA plugin.
Create a new project (any interpreter will do, e.g. PyCharm) in any directory on your pc.
Add `content\ucp` as a content root.

## Running the game
When everything is installed, start `Stronghold Crusader.exe`

### More customized method
It may be nice to make the game load the lua files from a different folder than the `ucp/` folder in the game folder.
For example, it is nicer to make it load the .lua files from GitHub. To achieve this, create a file in your game folder called `launcher.bat` with the following contents:
```cmd
@echo off
SET UCP_DIR=C:\..\..\..\github\UCP3
"Stronghold Crusader.exe"
exit
```
You can customize `UCP_DIR` to point to your git version tracked `content\ucp` folder.
To start the game with these preferences, run launcher.bat (you can setup dxwnd to use launcher.bat).


