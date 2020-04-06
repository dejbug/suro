@ECHO OFF

IF "%1" == "" (
	SET PROJECT_DIR=%~dp0
) ELSE (
	SET PROJECT_DIR=%~f1\
)

IF "%2" == "" (
	SET HOT_DIR=%~dp0
) ELSE (
	SET HOT_DIR=%~f2\
)

SET SURO_C=%PROJECT_DIR%suro-c.exe
SET SURO_W=%PROJECT_DIR%suro-w.exe

FOR %%i IN (%HOT_DIR%*.path) DO (
	IF NOT EXIST %SURO_W% (
		ECHO ! "%SURO_W%" not found. Needed for "%%~dpni.exe".
	) ELSE (
		ECHO * Copying "%SURO_W%" to "%%~dpni.exe".
		ECHO COPY /B /V "%SURO_W%" "%%~dpni.exe" 1>NUL 2>NUL || ( ECHO ! FAILED. && GOTO :EOF )
	)
)

FOR %%i IN (%HOT_DIR%*.bat) DO (
	IF "%%~ni" == "%~n0" (
		ECHO * Skipped "%%~dpni.exe".
	) ELSE (
		IF NOT "%%~fi" == "%~f0" (
			IF NOT EXIST %SURO_C% (
				ECHO ! "%SURO_C%" not found. Needed for "%%~dpni.exe".
			) ELSE (
				ECHO * Copying "%SURO_C%" to "%%~dpni.exe".
				ECHO COPY /B /V "%SURO_C%" "%%~dpni.exe" 1>NUL 2>NUL || ( ECHO ! FAILED. && GOTO :EOF )
			)
		)
	)
)
