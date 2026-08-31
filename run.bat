@echo off
setlocal
set "LOVE_DIR=%LOCALAPPDATA%\Programs\LOVE\love-11.5-win64"
set "LOVE_EXE=%LOVE_DIR%\love.exe"

if exist "%LOVE_EXE%" (
    "%LOVE_EXE%" "%~dp0"
    exit /b %ERRORLEVEL%
)

where love >nul 2>&1
if %ERRORLEVEL%==0 (
    love "%~dp0"
    exit /b %ERRORLEVEL%
)

echo LÖVE2D not found.
echo Install: https://love2d.org/
echo Or run: doc\install-love.md
exit /b 1
