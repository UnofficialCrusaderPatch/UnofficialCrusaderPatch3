# UnofficialCrusaderPatch3
Development for the new UCP DLL Injection approach.

## Setting up the repo locally and building the project
1. Clone the repo
2. Start the VS2019 dev console, and change directory into the repo directory.
3. Create a access token with just read:packages rights via your GitHub settings if you do not have one.
4. Start a powershell session: `powershell.exe`
5. Run `nuget sources add -Name "gynt-packages" -Source "https://nuget.pkg.github.com/gynt/index.json" -StorePasswordInClearText -Username git -Password %YOUR_ACCESS_TOKEN%`
   Alternatively, if you do not like storing the access token in plain text, omit the Username and Password parameters.
6. Run `nuget restore`. Lua and RPS should get installed.
7. Run `msbuild /p:Configuration=Release` (if you want a Release build).
8. Set the BUILD_CONFIGURATION environment variable: `$env:BUILD_CONFIGURATION="Release"`
9. Run the powershell script that can be found in the Github Actions workflow file. Step "Prepare UCP3 package" (https://github.com/UnofficialCrusaderPatch/UnofficialCrusaderPatch3/blob/main/.github/workflows/msbuild.yml#L41)
10. All files will be prepared in Release\ucp-package. The files from this folder can be directly copied to the game directory.

## Running the game
Copying the files to the game directory will work.

### More customized method
Create a file in your game folder called `launcher.bat` with the following contents:
```cmd
@echo off
SET UCP_DIR=C:\..\..\..\
SET UCP_CONFIG=ucp-config.yml
"Stronghold Crusader.exe"
exit
```
You can customize UCP_DIR to point to your Release\ucp-package folder.
To start the game with these preferences, run launcher.bat (you can setup dxwnd to use launcher.bat too).

## Recommended tools
IntelliJ IDEA (any will do) with the EmmyLUA plugin.
