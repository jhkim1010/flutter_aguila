# Windows 실행 파일 빌드 스크립트
# PowerShell에서 실행: .\build_windows.ps1

Write-Host "🪟 Windows 실행파일 빌드 시작..." -ForegroundColor Cyan

# 1. 빌드 날짜 주입
Write-Host ""
Write-Host "📅 빌드 날짜 주입 중..." -ForegroundColor Yellow
& ".\scripts\inject_build_date.ps1"
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 빌드 날짜 주입 실패" -ForegroundColor Red
    exit 1
}

# 2. Flutter 빌드
Write-Host ""
Write-Host "🚀 Flutter 빌드 중..." -ForegroundColor Yellow
flutter build windows --release --no-pub

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Windows 빌드 실패" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Windows 빌드 완료!" -ForegroundColor Green
Write-Host "📦 실행 파일 위치: build\windows\runner\Release\Be_Cool.exe" -ForegroundColor Cyan

