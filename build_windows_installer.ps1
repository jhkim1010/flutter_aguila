# Flutter Windows Installer Build Script
# "Flutter Aguila" App Windows Installer Creation

# UTF-8 encoding settings
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null

Write-Host "🚀 Starting Flutter Windows installer build..." -ForegroundColor Cyan
Write-Host "📱 App Name: Flutter Aguila" -ForegroundColor Cyan
Write-Host "💻 Platform: Windows" -ForegroundColor Cyan
Write-Host ""

# Change to Flutter project directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# Get version information
$VersionLine = Select-String -Path "pubspec.yaml" -Pattern "^version:" | Select-Object -First 1
if ($VersionLine) {
    $VersionMatch = $VersionLine.Line -match "version:\s*([\d.]+)\+(\d+)"
    if ($VersionMatch) {
        $Version = $matches[1]
        $BuildNumber = $matches[2]
    } else {
        $Version = "1.0.0"
        $BuildNumber = "1"
    }
} else {
    $Version = "1.0.0"
    $BuildNumber = "1"
}

Write-Host "📦 Version: $Version (Build: $BuildNumber)" -ForegroundColor Yellow
Write-Host ""

# Set output directories
$OutputDir = Join-Path $ScriptDir "build\installers"
$InstallerDir = Join-Path $ScriptDir "installer"
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
New-Item -ItemType Directory -Force -Path $InstallerDir | Out-Null

# Find Flutter path
$FlutterPath = $null
$FlutterPaths = @(
    "$env:USERPROFILE\flutter\bin\flutter.bat",
    "C:\flutter\bin\flutter.bat",
    "C:\src\flutter\bin\flutter.bat",
    "$env:LOCALAPPDATA\flutter\bin\flutter.bat"
)

foreach ($Path in $FlutterPaths) {
    if (Test-Path $Path) {
        $FlutterPath = $Path
        break
    }
}

# Set Flutter command
if ($FlutterPath) {
    $FlutterCmd = $FlutterPath
    Write-Host "✅ Flutter path found: $FlutterPath" -ForegroundColor Green
} else {
    # Try to find flutter in PATH
    $FlutterCmd = "flutter"
}

# Check for existing build files
$BuildDir = "build\windows\x64\runner\Release"
$HasExistingBuild = Test-Path $BuildDir

if ($HasExistingBuild) {
    Write-Host "✅ Existing build files found: $BuildDir" -ForegroundColor Green
    $UseExistingBuild = Read-Host "Use existing build files? (y/n)"
    
    if ($UseExistingBuild -ne "y" -and $UseExistingBuild -ne "Y") {
        $HasExistingBuild = $false
    }
}

# Flutter build (if needed)
if (-not $HasExistingBuild) {
    if (-not $FlutterPath) {
        Write-Host ""
        Write-Host "⚠️  Flutter not found!" -ForegroundColor Yellow
        Write-Host "   Please install Flutter or add it to PATH." -ForegroundColor Yellow
        Write-Host "   Or select 'y' if you have existing build files." -ForegroundColor Yellow
        exit 1
    }
    
    # Check and install Flutter dependencies
    Write-Host "📦 Checking dependencies..." -ForegroundColor Yellow
    & $FlutterCmd pub get
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Flutter pub get failed!" -ForegroundColor Red
        exit 1
    }
    
    # Clean previous build (optional)
    $CleanBuild = Read-Host "🧹 Clean previous build? (y/n)"
    if ($CleanBuild -eq "y" -or $CleanBuild -eq "Y") {
        Write-Host "🧹 Cleaning previous build..." -ForegroundColor Yellow
        & $FlutterCmd clean
    }
    
    # Release Windows build
    Write-Host ""
    Write-Host "🔨 Building Release Windows..." -ForegroundColor Yellow
    & $FlutterCmd build windows --release
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Windows build failed!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "📦 Using existing build files..." -ForegroundColor Yellow
}

# Check build results
$BuildDir = "build\windows\x64\runner\Release"
$ExeFile = Join-Path $BuildDir "flutter_app.exe"

# Check executable file name (Be_Cool.exe or flutter_app.exe)
if (Test-Path (Join-Path $BuildDir "Be_Cool.exe")) {
    $ExeFile = Join-Path $BuildDir "Be_Cool.exe"
    $ExeName = "Be_Cool.exe"
} elseif (Test-Path (Join-Path $BuildDir "flutter_app.exe")) {
    $ExeFile = Join-Path $BuildDir "flutter_app.exe"
    $ExeName = "flutter_app.exe"
} else {
    Write-Host "❌ Executable file not found!" -ForegroundColor Red
    Write-Host "   Check location: $BuildDir" -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path $ExeFile)) {
    Write-Host "❌ Executable file not found: $ExeFile" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Windows build successful!" -ForegroundColor Green
Write-Host "   Executable: $ExeFile" -ForegroundColor Gray

# Create installer with Inno Setup
Write-Host ""
Write-Host "📦 Creating installer with Inno Setup..." -ForegroundColor Yellow

# Check Inno Setup compiler path
$InnoSetupPaths = @(
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "${env:ProgramFiles}\Inno Setup 6\ISCC.exe",
    "${env:ProgramFiles(x86)}\Inno Setup 5\ISCC.exe",
    "${env:ProgramFiles}\Inno Setup 5\ISCC.exe"
)

$InnoSetupCompiler = $null
foreach ($Path in $InnoSetupPaths) {
    if (Test-Path $Path) {
        $InnoSetupCompiler = $Path
        break
    }
}

if (-not $InnoSetupCompiler) {
    Write-Host ""
    Write-Host "⚠️  Inno Setup not found!" -ForegroundColor Yellow
    Write-Host "   Please install Inno Setup or manually compile the installer.iss file." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   Download: https://jrsoftware.org/isinfo.php" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📦 Built files location:" -ForegroundColor Yellow
    Write-Host "   $BuildDir" -ForegroundColor Gray
    
    # Open folder
    $OpenFolder = Read-Host "📂 Open build folder? (y/n)"
    if ($OpenFolder -eq "y" -or $OpenFolder -eq "Y") {
        Start-Process explorer.exe -ArgumentList $BuildDir
    }
    
    exit 0
}

# Update installer.iss file (version information)
$IssFile = Join-Path $ScriptDir "installer.iss"
if (Test-Path $IssFile) {
    Write-Host "   installer.iss file verified" -ForegroundColor Gray
    
    # Read file content
    $IssContent = Get-Content $IssFile -Raw
    
    # Check if MyAppVersion is properly defined
    $hasMyAppVersion = $IssContent -match '#define\s+MyAppVersion\s+"[^"]*"'
    
    if (-not $hasMyAppVersion) {
        Write-Host "   ⚠️  Warning: MyAppVersion not found or malformed. Fixing..." -ForegroundColor Yellow
        
        # Try to fix common malformed patterns
        # Pattern 1: $11.0.0" -> #define MyAppVersion "11.0.0"
        $IssContent = $IssContent -replace '\$\d+\.\d+\.\d+"', "#define MyAppVersion `"$Version`""
        
        # Pattern 2: Missing #define MyAppVersion line (add after MyAppName)
        if ($IssContent -notmatch '#define\s+MyAppVersion') {
            $IssContent = $IssContent -replace '(#define MyAppName "[^"]*")', "`$1`r`n#define MyAppVersion `"$Version`""
        }
        
        # Pattern 3: If still not found, try to find version number and fix
        if ($IssContent -notmatch '#define\s+MyAppVersion') {
            # Extract version from malformed line like $11.0.0"
            $versionMatch = $IssContent -match '\$(\d+\.\d+\.\d+)"'
            if ($versionMatch) {
                $extractedVersion = $matches[1]
                $IssContent = $IssContent -replace '\$\d+\.\d+\.\d+"', "#define MyAppVersion `"$extractedVersion`""
            } else {
                # If no version found, use the version from pubspec.yaml
                $IssContent = $IssContent -replace '(#define MyAppName "[^"]*")', "`$1`r`n#define MyAppVersion `"$Version`""
            }
        }
        
        Write-Host "   ✅ Fixed MyAppVersion definition" -ForegroundColor Green
    } else {
        # Update version information if properly defined
        $IssContent = $IssContent -replace '(#define MyAppVersion ")[^"]*(")', "`$1$Version`$2"
    }
    
    Set-Content -Path $IssFile -Value $IssContent -NoNewline -Encoding UTF8
}

# Run Inno Setup compilation
Write-Host "   Running Inno Setup compiler..." -ForegroundColor Gray
& $InnoSetupCompiler $IssFile

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Installer created successfully!" -ForegroundColor Green
    
    # Find created installer file
    $InstallerFiles = Get-ChildItem -Path $InstallerDir -Filter "*.exe" | Where-Object { $_.Name -like "*Setup*" }
    
    if ($InstallerFiles) {
        $InstallerFile = $InstallerFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        $InstallerSize = [math]::Round($InstallerFile.Length / 1MB, 2)
        
        Write-Host ""
        Write-Host "📦 Installer file information:" -ForegroundColor Cyan
        Write-Host "   Filename: $($InstallerFile.Name)" -ForegroundColor Gray
        Write-Host "   Location: $($InstallerFile.FullName)" -ForegroundColor Gray
        Write-Host "   Size: $InstallerSize MB" -ForegroundColor Gray
        
        # Copy to output directory
        $TargetFile = Join-Path $OutputDir $InstallerFile.Name
        Copy-Item $InstallerFile.FullName $TargetFile -Force
        Write-Host ""
        Write-Host "✅ Copied to output directory: $TargetFile" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Installer file not found. Please check the installer folder." -ForegroundColor Yellow
        Write-Host "   Location: $InstallerDir" -ForegroundColor Gray
    }
} else {
    Write-Host ""
    Write-Host "❌ Inno Setup compilation failed!" -ForegroundColor Red
    Write-Host "   Please check the installer.iss file." -ForegroundColor Yellow
    exit 1
}

# Summary
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🎉 Build completed!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "📦 Installer file location:" -ForegroundColor Yellow
Write-Host "   Local: $OutputDir" -ForegroundColor Gray
if ($InstallerFiles) {
    Write-Host "   Installer: $($InstallerFile.Name)" -ForegroundColor Gray
}
Write-Host ""
Write-Host "📱 Installation instructions:" -ForegroundColor Yellow
Write-Host "   1. Double-click the installer file (.exe) to run" -ForegroundColor Gray
Write-Host "   2. Follow the installation wizard" -ForegroundColor Gray
Write-Host "   3. Run the app from desktop or Start menu after installation" -ForegroundColor Gray
Write-Host ""

# Open folder
$OpenFolder = Read-Host "📂 Open output folder? (y/n)"
if ($OpenFolder -eq "y" -or $OpenFolder -eq "Y") {
    Start-Process explorer.exe -ArgumentList $OutputDir
}

Write-Host ""
Write-Host "✨ Done!" -ForegroundColor Green

