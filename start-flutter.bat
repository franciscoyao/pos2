@echo off
echo ========================================
echo   Starting POS Flutter App
echo ========================================
echo.
echo Choose your platform:
echo 1. Windows Desktop
echo 2. Web Browser (Chrome)
echo.
set /p choice="Enter choice (1 or 2): "

if "%choice%"=="1" (
    echo Starting Windows app...
    flutter run -d windows
) else if "%choice%"=="2" (
    echo Starting Web app...
    flutter run -d chrome
) else (
    echo Invalid choice!
    pause
)
