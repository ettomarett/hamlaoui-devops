@echo off
echo ============================================================
echo  🚀 E-Commerce Microservices Frontend Server
echo ============================================================
echo.
echo Starting frontend server...
echo.
echo Browser will open automatically at: http://localhost:8000
echo.
echo Press Ctrl+C to stop the server
echo ============================================================
echo.

REM Start Python server
python server.py 8000

REM If Python 3 is not available as 'python', try 'python3'
if %ERRORLEVEL% neq 0 (
    echo Trying python3...
    python3 server.py 8000
)

REM If both fail, show error message
if %ERRORLEVEL% neq 0 (
    echo.
    echo ❌ Error: Python not found!
    echo.
    echo Please ensure Python is installed and added to PATH.
    echo Download Python from: https://python.org
    echo.
    pause
) 