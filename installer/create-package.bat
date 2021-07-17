msbuild UCP3.sln -property:Configuration=Release

rmdir /S /Q ucp-package
mkdir ucp-package

copy Release\dll.dll ucp-package\binkw32_ucp.dll
copy Release\RPS.dll ucp-package\RPS.dll
copy Release\lua.dll ucp-package\lua.dll

copy installer\rename-dlls.bat ucp-package\install-ucp.bat

xcopy lua\ucp ucp-package\ucp /y /e /i

