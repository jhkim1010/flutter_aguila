@echo off
chcp 65001 >nul
REM Windows build batch file
REM Double-click or run from command prompt: build_windows.bat

echo Windows build starting...

REM Run PowerShell script
powershell.exe -ExecutionPolicy Bypass -File ".\scripts\inject_build_date.ps1"
if %ERRORLEVEL% NEQ 0 (
    echo Build date injection failed
    pause
    exit /b 1
)

REM Flutter build
echo.
echo Building Flutter app...
flutter build windows --release --no-pub

if %ERRORLEVEL% NEQ 0 (
    echo Windows build failed
    pause
    exit /b 1
)

echo.
echo Windows build completed!
echo Executable location: build\windows\runner\Release\Be_Cool.exe
pause

