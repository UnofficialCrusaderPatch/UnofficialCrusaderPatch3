
@ECHO OFF
if exist binkw32_real.dll (
    rem original dll exists
	goto DOCOPY
) else (
    rem original dll doesn't exist
	if exist binkw32.dll (
		echo Backing up game file "binkw32.dll"
		copy binkw32.dll binkw32_real.dll
		goto DOCOPY
	) else (
		echo binkw32.dll does not exist. Are we in the right folder?
		goto FAILEND
	)
)

:DOCOPY
echo Overwriting binkw32.dll with ucp dll
copy binkw32_ucp.dll binkw32.dll /y
goto END

:FAILEND
echo Operation failed.

:END