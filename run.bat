@echo off
setlocal
cd /d "%~dp0"

set "LOVE_DIR=%LOCALAPPDATA%\Programs\LOVE\love-11.5-win64"
set "LOVE_EXE=%LOVE_DIR%\love.exe"
set "BUNDLED_PY=%~dp0vendor\python\python.exe"

if exist "%BUNDLED_PY%" (
    set "CODESWARM_PYTHON=%BUNDLED_PY%"
) else if exist "%LOCALAPPDATA%\Programs\Python\Python311\python.exe" (
    set "CODESWARM_PYTHON=%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
) else if exist "%LOCALAPPDATA%\Programs\Python\Python310\python.exe" (
    set "CODESWARM_PYTHON=%LOCALAPPDATA%\Programs\Python\Python310\python.exe"
)

if not defined CODESWARM_PYTHON (
    echo NOTE: Bundled Python not found at vendor\python\python.exe
    echo Run: powershell -ExecutionPolicy Bypass -File scripts\fetch-python.ps1
    echo Or install Python 3.10+ and add to PATH.
)

if exist "%LOVE_EXE%" (
    "%LOVE_EXE%" .
    exit /b %ERRORLEVEL%
)

where love >nul 2>&1
if %ERRORLEVEL%==0 (
    love .
    exit /b %ERRORLEVEL%
)

echo LÖVE2D not found.
echo Install: https://love2d.org/
exit /b 1
