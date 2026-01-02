# Windows build script with manual Flutter path input
# Use this if Flutter is not in your PATH

# Set UTF-8 encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "Windows build starting..." -ForegroundColor Cyan

# 1. Inject build date
Write-Host ""
Write-Host "Injecting build date..." -ForegroundColor Yellow
if (Test-Path ".\scripts\inject_build_date_simple.ps1") {
    & ".\scripts\inject_build_date_simple.ps1"
} else {
    & ".\scripts\inject_build_date.ps1"
}

# 2. Find Flutter
Write-Host ""
Write-Host "Looking for Flutter..." -ForegroundColor Yellow

$flutterPath = $null

# Check PATH first
$flutterCheck = Get-Command flutter -ErrorAction SilentlyContinue
if ($flutterCheck) {
    $flutterPath = "flutter"
    Write-Host "Found Flutter in PATH" -ForegroundColor Green
} else {
    # Try common locations
    $commonPaths = @(
        "$env:LOCALAPPDATA\flutter\bin\flutter.bat",
        "$env:ProgramFiles\flutter\bin\flutter.bat",
        "$env:ProgramFiles(x86)\flutter\bin\flutter.bat",
        "$env:USERPROFILE\flutter\bin\flutter.bat",
        "$env:USERPROFILE\AppData\Local\flutter\bin\flutter.bat",
        "C:\flutter\bin\flutter.bat",
        "C:\src\flutter\bin\flutter.bat"
    )

    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            $flutterPath = $path
            Write-Host "Found Flutter at: $path" -ForegroundColor Green
            break
        }
    }
    
    # Check FLUTTER_ROOT
    if ($null -eq $flutterPath -and $env:FLUTTER_ROOT) {
        $flutterRootPath = Join-Path $env:FLUTTER_ROOT "bin\flutter.bat"
        if (Test-Path $flutterRootPath) {
            $flutterPath = $flutterRootPath
            Write-Host "Found Flutter via FLUTTER_ROOT: $flutterPath" -ForegroundColor Green
        }
    }
}

# If still not found, ask user
if ($null -eq $flutterPath) {
    Write-Host ""
    Write-Host "Flutter not found automatically." -ForegroundColor Yellow
    Write-Host ""
    $userInput = Read-Host "Enter Flutter installation path (e.g., C:\src\flutter or press Enter to skip)"
    
    if ($userInput -and $userInput.Trim() -ne "") {
        $userPath = $userInput.Trim()
        # Remove trailing backslash if present
        if ($userPath.EndsWith("\")) {
            $userPath = $userPath.Substring(0, $userPath.Length - 1)
        }
        
        $flutterBat = Join-Path $userPath "bin\flutter.bat"
        if (Test-Path $flutterBat) {
            $flutterPath = $flutterBat
            Write-Host "Using Flutter at: $flutterPath" -ForegroundColor Green
        } else {
            Write-Host "Flutter.bat not found at: $flutterBat" -ForegroundColor Red
            Write-Host "Please check your Flutter installation path." -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host ""
        Write-Host "Please add Flutter to your PATH or run manually:" -ForegroundColor Yellow
        Write-Host "  flutter build windows --release --no-pub" -ForegroundColor Cyan
        exit 1
    }
}

# 3. Build Flutter app
Write-Host ""
Write-Host "Building Flutter app..." -ForegroundColor Yellow
Write-Host "Running: $flutterPath build windows --release --no-pub" -ForegroundColor Cyan

& $flutterPath build windows --release --no-pub

if ($LASTEXITCODE -ne 0) {
    Write-Host "Windows build failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Windows build completed!" -ForegroundColor Green
Write-Host "Executable location: build\windows\runner\Release\Be_Cool.exe" -ForegroundColor Cyan

