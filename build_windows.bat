@echo off
REM Windows 실행 파일 빌드 배치 파일
REM 더블클릭하거나 명령 프롬프트에서 실행: build_windows.bat

echo 🪟 Windows 실행파일 빌드 시작...

REM PowerShell 스크립트 실행
powershell.exe -ExecutionPolicy Bypass -File ".\scripts\inject_build_date.ps1"
if %ERRORLEVEL% NEQ 0 (
    echo ❌ 빌드 날짜 주입 실패
    pause
    exit /b 1
)

REM Flutter 빌드
echo.
echo 🚀 Flutter 빌드 중...
flutter build windows --release --no-pub

if %ERRORLEVEL% NEQ 0 (
    echo ❌ Windows 빌드 실패
    pause
    exit /b 1
)

echo.
echo ✅ Windows 빌드 완료!
echo 📦 실행 파일 위치: build\windows\runner\Release\Be_Cool.exe
pause

