# Windows build script
# Run in PowerShell: .\build_windows.ps1

# Set UTF-8 encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "Windows build starting..." -ForegroundColor Cyan

# 1. Inject build date
Write-Host ""
Write-Host "Injecting build date..." -ForegroundColor Yellow
# Try simple version first, fallback to full version
if (Test-Path ".\scripts\inject_build_date_simple.ps1") {
    & ".\scripts\inject_build_date_simple.ps1"
} else {
    & ".\scripts\inject_build_date.ps1"
}
if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
    Write-Host "Build date injection failed" -ForegroundColor Red
    exit 1
}

# 2. Flutter build
Write-Host ""
Write-Host "Building Flutter app..." -ForegroundColor Yellow

# Try to find Flutter in common locations
$flutterPath = $null
$possiblePaths = @(
    "$env:LOCALAPPDATA\flutter\bin\flutter.bat",
    "$env:ProgramFiles\flutter\bin\flutter.bat",
    "$env:USERPROFILE\flutter\bin\flutter.bat"
)

foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $flutterPath = $path
        break
    }
}

# Check if flutter is in PATH
if ($null -eq $flutterPath) {
    $flutterCheck = Get-Command flutter -ErrorAction SilentlyContinue
    if ($flutterCheck) {
        $flutterPath = "flutter"
    }
}

if ($null -eq $flutterPath) {
    Write-Host "Flutter not found. Please add Flutter to your PATH or set FLUTTER_ROOT environment variable." -ForegroundColor Red
    Write-Host "You can also run: flutter build windows --release --no-pub manually" -ForegroundColor Yellow
    exit 1
}

& $flutterPath build windows --release --no-pub

if ($LASTEXITCODE -ne 0) {
    Write-Host "Windows build failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Windows build completed!" -ForegroundColor Green
Write-Host "Executable location: build\windows\runner\Release\Be_Cool.exe" -ForegroundColor Cyan

