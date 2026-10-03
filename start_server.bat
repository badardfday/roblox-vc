@echo off
setlocal
cd /d "%~dp0"

where py >nul 2>nul
if not errorlevel 1 (
	py -3 start_server.py
) else (
	python start_server.py
)

if errorlevel 1 (
	echo.
	echo The server exited with an error. Review the messages above.
	pause
)

endlocal
