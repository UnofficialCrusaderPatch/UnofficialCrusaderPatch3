
@ECHO OFF
if exist binkw32_real.dll (
	rem original dll exists
	goto DOCOPY
) else (
	rem original dll doesn't exist
	goto FAILEND
)

:DOCOPY
echo Overwriting binkw32.dll with binkw32_real.dll
copy binkw32_real.dll binkw32.dll /y
goto END

:FAILEND
echo Operation failed.

:END