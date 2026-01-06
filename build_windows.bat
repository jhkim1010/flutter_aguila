@echo off
chcp 65001 >nul
REM Windows build batch file
REM Double-click or run from command prompt: build_windows.bat

echo Windows build starting...

REM Run PowerShell script for build date injection
echo Injecting build date...
if exist ".\scripts\inject_build_date_simple.ps1" (
    powershell.exe -ExecutionPolicy Bypass -File ".\scripts\inject_build_date_simple.ps1"
    if %ERRORLEVEL% NEQ 0 (
        echo ERROR: Build date injection failed!
        echo Please check PowerShell execution policy or run manually:
        echo   powershell.exe -ExecutionPolicy Bypass -File ".\scripts\inject_build_date_simple.ps1"
        pause
        exit /b 1
    )
    echo Build date injection completed successfully.
) else if exist ".\scripts\inject_build_date.ps1" (
    powershell.exe -ExecutionPolicy Bypass -File ".\scripts\inject_build_date.ps1"
    if %ERRORLEVEL% NEQ 0 (
        echo ERROR: Build date injection failed!
        echo Please check PowerShell execution policy or run manually:
        echo   powershell.exe -ExecutionPolicy Bypass -File ".\scripts\inject_build_date.ps1"
        pause
        exit /b 1
    )
    echo Build date injection completed successfully.
) else (
    echo WARNING: Build date injection script not found!
    echo Skipping build date injection. Build will continue with old date.
    echo.
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

