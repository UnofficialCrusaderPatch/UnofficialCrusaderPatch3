# UnofficialCrusaderPatch3
Development for the new UCP DLL Injection approach.

## Setting up the repo locally and building the project
0. Make sure you have nuget installed.
0. Create a access token with just read:packages rights via your GitHub settings if you do not have one. You need it at step 4.
1. Clone the repo.
2. Start the VS2019 dev console, and change directory into the repo directory.
3. Start a powershell session in the dev console: `powershell.exe`
4. Run `nuget sources add -Name "gynt-packages" -Source "https://nuget.pkg.github.com/gynt/index.json" -StorePasswordInClearText -Username git -Password %YOUR_ACCESS_TOKEN%`
   Alternatively, if you do not like storing the access token in plain text, omit the Username and Password parameters.
5. Run `nuget restore`. Lua and RPS should get installed.
6. Set the BUILD_CONFIGURATION environment variable to "Release" if you want a Release build: `$env:BUILD_CONFIGURATION="Release"`
7. Run `msbuild /p:Configuration=$env:BUILD_CONFIGURATION`.
8. Run the powershell script that can be found in the Github Actions workflow file. Step "Prepare UCP3 package" (https://github.com/UnofficialCrusaderPatch/UnofficialCrusaderPatch3/blob/main/.github/workflows/msbuild.yml#L47)
9. All files will be prepared in `$env:BUILD_CONFIGURATION\ucp-package` (e.g., Release\ucp-package). 
10. Running the game: The files from this folder can be directly copied to the game directory.
11. Running the game: Copy the games original to `binkw32_real.dll` and rename `binkw32_ucp.dll` to `binkw32.dll`. (install.bat does this for you)

## Running the game
Copying the files to the game directory will work. Run `install.bat` to backup the game's binkw32.dll and overwrite `binkw32.dll` with `binkw32_ucp.dll`.

### More customized method
Create a file in your game folder called `launcher.bat` with the following contents:
```cmd
@echo off
SET UCP_DIR=C:\..\..\..\
SET UCP_CONFIG=ucp-config.yml
"Stronghold Crusader.exe"
exit
```
You can customize UCP_DIR to point to your git version tracked `content\ucp` folder.
To start the game with these preferences, run launcher.bat (you can setup dxwnd to use launcher.bat too).

## Recommended tools
IntelliJ IDEA (any will do) with the EmmyLUA plugin.
Create a new project (any interpreter will do, e.g. PyCharm) in any directory on your pc.
Add `content\ucp` as a content root.
