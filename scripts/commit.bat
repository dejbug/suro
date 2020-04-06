@ECHO OFF

IF "%1" == "" (
	SET ROOT=%~dp0
) ELSE (
	SET ROOT=%~f1\
)

SET SURO_C=%ROOT%suro-c.exe
SET SURO_W=%ROOT%suro-w.exe

FOR %%i IN (%~dp0*.path) DO (
	IF NOT EXIST %SURO_W% (
		ECHO ! "%SURO_W%" not found. Needed for "%%~dpni.exe".
	) ELSE (
		ECHO * Copying "%SURO_W%" to "%%~dpni.exe".
		COPY /B /V "%SURO_W%" "%%~dpni.exe" 1>NUL 2>NUL || ( ECHO ! FAILED. && GOTO :EOF )
	)
)

FOR %%i IN (%~dp0*.bat) DO (
	IF NOT "%%~fi" == "%~f0" (
		IF NOT EXIST %SURO_C% (
			ECHO ! "%SURO_C%" not found. Needed for "%%~dpni.exe".
		) ELSE (
			ECHO * Copying "%SURO_C%" to "%%~dpni.exe".
			COPY /B /V "%SURO_C%" "%%~dpni.exe" 1>NUL 2>NUL || ( ECHO ! FAILED. && GOTO :EOF )
		)
	)
)
