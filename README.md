# UnofficialCrusaderPatch3
Development for the new UCP DLL Injection approach.

## Quick start
1. Go to Actions and download the latest build (Release or DevRelease)
2. Unzip to the game folder
3. Run install.bat
4. Run the game

In case there is a complaint about missing dlls at startup, make sure you have Visual Studio C++ runtime installed: 

https://aka.ms/vs/17/release/vc_redist.x86.exe

## Working on the DLL: Setting up the repo locally and building the project
1. Create a access token with the permission read:packages via your GitHub settings if you do not have one. You need it at step 4.
1. Install Visual Studios 2019 or newer
1. Install the nuget command line programm, if it didn't come with your VisualStudios Installation. You can do so, by downloading v3.3 or higher from https://www.nuget.org/downloads and adding the nuget.exe to your PATH
1. Start the VS2019 developer console.
1. Clone the repo, and change directory into the repo directory.
  ```powershell
  git clone --recurse-submodules -j8 https://github.com/UnofficialCrusaderPatch/UnofficialCrusaderPatch3
  cd UnofficialCrusaderPatch3
  ```
6. Start a powershell session in the dev console
  ```powershell
  powershell.exe
  ```
7. Then, skip to step 11 if you want to create the installation package. Else, add gynt's NuGet package repo to the known sources for NuGet. If you do not like storing the access token in plain text, omit the Username and Password parameters, and use them when asked at step 5.
  ```powershell
  nuget sources add -Name "gynt-packages" -Source "https://nuget.pkg.github.com/gynt/index.json" -StorePasswordInClearText -Username git -Password "%YOUR_ACCESS_TOKEN%"
  ```
8. Install dependencies
  ```powershell
  nuget restore
  ```
9. Set the BUILD_CONFIGURATION environment variable to "Release" if you want a Release build.
  ```powershell
  $env:BUILD_CONFIGURATION="Release"
  ```
10. Build the dll
  ```cmd
  msbuild /p:Configuration=$env:BUILD_CONFIGURATION`
  ```
## Creating the UCP3 installation package:
11. Execute build.ps1
```cmd
. .\build.ps1 -build "Release" -token YOUR_READ_PACKAGES_GITHUB_TOKEN
```
or run the scripts from `.github/workflows/msbuild.yml` manually

All files will be prepared in `$env:BUILD_CONFIGURATION\ucp-package` (e.g., Release\ucp-package). The files from this folder can be directly copied to the game directory.
To install the system, run `install.bat` to backup the game's `binkw32.dll` (to `binkw32_real.dll`) and overwrite `binkw32.dll` with `binkw32_ucp.dll`.

## Working on the lua part:
[Download](https://github.com/UnofficialCrusaderPatch/UnofficialCrusaderPatch3/actions) and install a non-Secure build. Core functionality is found in the `ucp/code` directory. Restart the game every time you modified the .lua files.

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


