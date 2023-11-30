# UnofficialCrusaderPatch3
Development for the new UCP runtime patching approach.

Issues that involve feature requests will be resolved according to feasibility and amount of votes: `is:issue is:open priority sort:reactions-+1-desc`

## Quick start
1. Go to Actions and download the latest build (Release or DevRelease)
2. Unzip to the game folder
3. Run install.bat
4. Run the game

In case there is a complaint about missing dlls at startup, make sure you have Visual Studio C++ runtime installed: 

https://aka.ms/vs/17/release/vc_redist.x86.exe

## Working on the DLL: Setting up the repo locally and building the project
1. Create a access token with the permission read:packages via your GitHub settings if you do not have one. You need it at step 7.
2. Install Visual Studios 2022 or newer
3. Install the nuget command line programm, if it didn't come with your VisualStudios Installation. You can do so, by downloading v3.3 or higher from https://www.nuget.org/downloads and adding the nuget.exe to your PATH
4. Start the VS2022 developer console.
5. Clone the repo, and change directory into the repo directory.
  ```powershell
  git clone --recurse-submodules -j8 https://github.com/UnofficialCrusaderPatch/UnofficialCrusaderPatch3
  cd UnofficialCrusaderPatch3
  ```
6. Start a powershell session in the dev console (Preferably [powershell 7](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.3) or higher)
  ```powershell
  pwsh.exe
  ```
7. Then, run the build script. You only need to add the NugetToken the first time you run this build script (succesfully). The token is used to add gynt's repo as a valid source for NuGet packages.
  ```powershell
  .\scripts\build.ps1 -Build "Release" -NugetToken "%YOUR_ACCESS_TOKEN%"
  ```
  
  You can also add the nuget source manually:
  ```powershell
  nuget sources add -Name "gynt-packages" -Source "https://nuget.pkg.github.com/gynt/index.json" -StorePasswordInClearText -Username git -Password "%YOUR_ACCESS_TOKEN%"
  ```
  You need to do this only once. If you do not like storing the access token in plain text, omit the Username and Password parameters, and use them when asked.

8. All files will be prepared in `Release\ucp-package` (%BUILD_CONFIGURATION%\ucp-package), and the repo directory will contain a zip file.
To install ucp, do this in the game folder:
- Unpack the zip in the game folder.
- Rename `binkw32.dll` to `binkw32_real.dll`
- Rename `binkw32_ucp.dll` to `binkw32.dll`, overwriting `binkw32.dll` 

## Working on the lua part:
[Download](https://github.com/UnofficialCrusaderPatch/UnofficialCrusaderPatch3/actions) and install a Dev build. Core functionality is found in the `ucp/code` directory. Restart the game every time you modified the .lua files.

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


