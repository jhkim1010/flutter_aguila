# Windows build script
# Run in PowerShell: .\build_windows.ps1

# Set UTF-8 encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "Windows build starting..." -ForegroundColor Cyan

# 0. Check installer.iss file before build
Write-Host ""
Write-Host "Checking installer.iss file..." -ForegroundColor Yellow
$installerIssPath = Join-Path (Get-Location) "installer.iss"
if (Test-Path $installerIssPath) {
    $content = Get-Content $installerIssPath -Raw
    $lines = Get-Content $installerIssPath
    Write-Host "   installer.iss file found: $installerIssPath" -ForegroundColor Green
    
    # Check if MyAppVersion is defined
    $hasMyAppVersion = $content -match '#define\s+MyAppVersion'
    if (-not $hasMyAppVersion) {
        Write-Host "   ERROR: MyAppVersion not found in installer.iss!" -ForegroundColor Red
        Write-Host "   Checking line 5..." -ForegroundColor Yellow
        if ($lines.Count -ge 5) {
            Write-Host "   Line 5: $($lines[4])" -ForegroundColor Cyan
        }
        Write-Host ""
        Write-Host "   Please check installer.iss file manually:" -ForegroundColor Yellow
        Write-Host "   1. Open installer.iss in Notepad" -ForegroundColor Yellow
        Write-Host "   2. Check line 5: should be '#define MyAppVersion ""1.0.0""'" -ForegroundColor Yellow
        Write-Host "   3. Save as ANSI encoding" -ForegroundColor Yellow
        Write-Host ""
        exit 1
    } else {
        Write-Host "   MyAppVersion definition found" -ForegroundColor Green
        if ($lines.Count -ge 5) {
            Write-Host "   Line 5: $($lines[4])" -ForegroundColor Cyan
        }
    }
} else {
    Write-Host "   WARNING: installer.iss file not found!" -ForegroundColor Yellow
    Write-Host "   Creating default installer.iss..." -ForegroundColor Yellow
    # Create default installer.iss if it doesn't exist
}

# 1. Inject build date
Write-Host ""
Write-Host "Injecting build date..." -ForegroundColor Yellow
# Try simple version first, fallback to full version
$buildDateInjected = $false
if (Test-Path ".\scripts\inject_build_date_simple.ps1") {
    try {
        & ".\scripts\inject_build_date_simple.ps1"
        if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq $null) {
            $buildDateInjected = $true
            Write-Host "Build date injection completed successfully." -ForegroundColor Green
        } else {
            Write-Host "ERROR: Build date injection failed (exit code: $LASTEXITCODE)" -ForegroundColor Red
            Write-Host "Please check the script manually:" -ForegroundColor Yellow
            Write-Host "  .\scripts\inject_build_date_simple.ps1" -ForegroundColor Yellow
            exit 1
        }
    } catch {
        Write-Host "ERROR: Build date injection script failed: $_" -ForegroundColor Red
        exit 1
    }
} elseif (Test-Path ".\scripts\inject_build_date.ps1") {
    try {
        & ".\scripts\inject_build_date.ps1"
        if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq $null) {
            $buildDateInjected = $true
            Write-Host "Build date injection completed successfully." -ForegroundColor Green
        } else {
            Write-Host "ERROR: Build date injection failed (exit code: $LASTEXITCODE)" -ForegroundColor Red
            Write-Host "Please check the script manually:" -ForegroundColor Yellow
            Write-Host "  .\scripts\inject_build_date.ps1" -ForegroundColor Yellow
            exit 1
        }
    } catch {
        Write-Host "ERROR: Build date injection script failed: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "WARNING: Build date injection script not found!" -ForegroundColor Yellow
    Write-Host "Skipping build date injection. Build will continue with old date." -ForegroundColor Yellow
    Write-Host ""
}

# 2. Flutter build
Write-Host ""
Write-Host "Building Flutter app..." -ForegroundColor Yellow

# Try to find Flutter
$flutterPath = $null

# First, check if flutter is in PATH
$flutterCheck = Get-Command flutter -ErrorAction SilentlyContinue
if ($flutterCheck) {
    $flutterPath = "flutter"
    Write-Host "Found Flutter in PATH" -ForegroundColor Green
} else {
    # Try common installation locations
    $possiblePaths = @(
        "$env:LOCALAPPDATA\flutter\bin\flutter.bat",
        "$env:ProgramFiles\flutter\bin\flutter.bat",
        "$env:ProgramFiles(x86)\flutter\bin\flutter.bat",
        "$env:USERPROFILE\flutter\bin\flutter.bat",
        "$env:USERPROFILE\AppData\Local\flutter\bin\flutter.bat",
        "C:\flutter\bin\flutter.bat",
        "C:\src\flutter\bin\flutter.bat"
    )

    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $flutterPath = $path
            Write-Host "Found Flutter at: $path" -ForegroundColor Green
            break
        }
    }
    
    # Check FLUTTER_ROOT environment variable
    if ($null -eq $flutterPath -and $env:FLUTTER_ROOT) {
        $flutterRootPath = Join-Path $env:FLUTTER_ROOT "bin\flutter.bat"
        if (Test-Path $flutterRootPath) {
            $flutterPath = $flutterRootPath
            Write-Host "Found Flutter via FLUTTER_ROOT: $flutterPath" -ForegroundColor Green
        }
    }
}

if ($null -eq $flutterPath) {
    Write-Host ""
    Write-Host "Flutter not found in common locations." -ForegroundColor Red
    Write-Host ""
    Write-Host "Please do one of the following:" -ForegroundColor Yellow
    Write-Host "1. Add Flutter to your PATH environment variable" -ForegroundColor Yellow
    Write-Host "2. Set FLUTTER_ROOT environment variable to your Flutter installation directory" -ForegroundColor Yellow
    Write-Host "3. Run 'flutter build windows --release --no-pub' manually from command prompt" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To add Flutter to PATH:" -ForegroundColor Cyan
    Write-Host "  - Find your Flutter installation (usually C:\src\flutter or C:\flutter)" -ForegroundColor Cyan
    Write-Host "  - Add the 'bin' folder to your PATH (e.g., C:\src\flutter\bin)" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

# Run Flutter build
Write-Host "Running: $flutterPath build windows --release --no-pub" -ForegroundColor Cyan
& $flutterPath build windows --release --no-pub

if ($LASTEXITCODE -ne 0) {
    Write-Host "Windows build failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Windows build completed!" -ForegroundColor Green
Write-Host "Executable location: build\windows\runner\Release\Be_Cool.exe" -ForegroundColor Cyan

