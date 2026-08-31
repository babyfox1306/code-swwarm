@echo off
REM CODE SWARM — launch Python worker (called from LÖVE)
REM Usage: launch-worker.bat PYTHON_EXE WORKER_PY IPC_DIR
if "%~3"=="" exit /b 1
start "" /B "%~1" "%~2" "%~3"
exit /b 0
