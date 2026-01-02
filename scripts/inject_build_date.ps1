# Build date injection script for Windows
# This script injects build date into platform-specific configuration files

# Set UTF-8 encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# 프로젝트 루트 디렉토리로 이동
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath
Set-Location $projectRoot

# 현재 날짜를 YYYY-MM-DD 형식으로 생성
$buildDate = Get-Date -Format "yyyy-MM-dd"
$buildDateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Write-Host "📅 빌드 날짜 주입 중: $buildDateTime" -ForegroundColor Cyan

# ============================================
# 1. Android 설정
# ============================================
Write-Host "📱 Android 설정 업데이트 중..." -ForegroundColor Yellow

$androidValuesDir = "android\app\src\main\res\values"
if (-not (Test-Path $androidValuesDir)) {
    New-Item -ItemType Directory -Path $androidValuesDir -Force | Out-Null
}

$androidStringsFile = Join-Path $androidValuesDir "strings.xml"

if (Test-Path $androidStringsFile) {
    # 기존 파일이 있으면 빌드 날짜만 업데이트
    $content = Get-Content $androidStringsFile -Raw
    if ($content -match 'build_date') {
        $content = $content -replace '<string name="build_date">.*?</string>', "<string name=`"build_date`">$buildDate</string>"
        Set-Content -Path $androidStringsFile -Value $content -NoNewline
    } else {
        # build_date가 없으면 추가
        $content = $content -replace '</resources>', "    <string name=`"build_date`">$buildDate</string>`n</resources>"
        Set-Content -Path $androidStringsFile -Value $content -NoNewline
    }
} else {
    # 파일이 없으면 새로 생성
    $content = @"
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Be COOL</string>
    <string name="build_date">$buildDate</string>
</resources>
"@
    Set-Content -Path $androidStringsFile -Value $content
}

Write-Host "✅ Android 설정 완료" -ForegroundColor Green

# ============================================
# 2. iOS 설정
# ============================================
Write-Host "🍎 iOS 설정 업데이트 중..." -ForegroundColor Yellow

$iosInfoPlist = "ios\Runner\Info.plist"

if (Test-Path $iosInfoPlist) {
    # CFBundleBuildDate 키가 있는지 확인
    $content = Get-Content $iosInfoPlist -Raw
    if ($content -match 'CFBundleBuildDate') {
        # 기존 값 업데이트
        $content = $content -replace '(?s)(<key>CFBundleBuildDate</key>\s*<string>).*?(</string>)', "`$1$buildDateTime`$2"
        Set-Content -Path $iosInfoPlist -Value $content -NoNewline
    } else {
        # CFBundleBuildDate 키가 없으면 추가 (CFBundleVersion 다음에)
        $content = $content -replace '(?s)(<key>CFBundleVersion</key>\s*<string>.*?</string>)', "`$1`n`t<key>CFBundleBuildDate</key>`n`t<string>$buildDateTime</string>"
        Set-Content -Path $iosInfoPlist -Value $content -NoNewline
    }
    Write-Host "✅ iOS 설정 완료" -ForegroundColor Green
} else {
    Write-Host "⚠️ iOS Info.plist 파일을 찾을 수 없습니다: $iosInfoPlist" -ForegroundColor Yellow
}

# ============================================
# 3. macOS 설정
# ============================================
Write-Host "💻 macOS 설정 업데이트 중..." -ForegroundColor Yellow

$macosInfoPlist = "macos\Runner\Info.plist"

if (Test-Path $macosInfoPlist) {
    # CFBundleBuildDate 키가 있는지 확인
    $content = Get-Content $macosInfoPlist -Raw
    if ($content -match 'CFBundleBuildDate') {
        # 기존 값 업데이트
        $content = $content -replace '(?s)(<key>CFBundleBuildDate</key>\s*<string>).*?(</string>)', "`$1$buildDateTime`$2"
        Set-Content -Path $macosInfoPlist -Value $content -NoNewline
    } else {
        # CFBundleBuildDate 키가 없으면 추가
        $content = $content -replace '(?s)(<key>CFBundleVersion</key>\s*<string>.*?</string>)', "`$1`n`t<key>CFBundleBuildDate</key>`n`t<string>$buildDateTime</string>"
        Set-Content -Path $macosInfoPlist -Value $content -NoNewline
    }
    Write-Host "✅ macOS 설정 완료" -ForegroundColor Green
} else {
    Write-Host "⚠️ macOS Info.plist 파일을 찾을 수 없습니다: $macosInfoPlist" -ForegroundColor Yellow
}

# ============================================
# 4. Flutter 코드에서 읽을 수 있는 파일 생성
# ============================================
Write-Host "📝 Flutter 빌드 정보 파일 생성 중..." -ForegroundColor Yellow

$generatedDir = "lib\generated"
if (-not (Test-Path $generatedDir)) {
    New-Item -ItemType Directory -Path $generatedDir -Force | Out-Null
}

$buildInfoFile = Join-Path $generatedDir "build_info.dart"

$buildInfoContent = @"
// 이 파일은 자동으로 생성됩니다. 수동으로 편집하지 마세요.
// Generated automatically. Do not edit manually.

/// 앱의 빌드 정보
class BuildInfo {
  /// 빌드 날짜 (YYYY-MM-DD 형식)
  static const String buildDate = '$buildDate';
  
  /// 빌드 날짜 및 시간 (YYYY-MM-DD HH:MM:SS 형식)
  static const String buildDateTime = '$buildDateTime';
  
  /// 빌드 날짜를 DateTime 객체로 반환
  static DateTime get buildDateAsDateTime {
    return DateTime.parse(buildDate);
  }
}
"@

Set-Content -Path $buildInfoFile -Value $buildInfoContent

Write-Host "✅ Flutter 빌드 정보 파일 생성 완료: $buildInfoFile" -ForegroundColor Green

# ============================================
# 5. Windows 설정 (선택사항)
# ============================================
Write-Host "🪟 Windows 설정 업데이트 중..." -ForegroundColor Yellow

$windowsMainCpp = "windows\runner\main.cpp"

if (Test-Path $windowsMainCpp) {
    Write-Host "✅ Windows는 Flutter BuildInfo를 사용합니다" -ForegroundColor Green
} else {
    Write-Host "⚠️ Windows main.cpp 파일을 찾을 수 없습니다" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✅ 모든 플랫폼의 빌드 날짜 주입이 완료되었습니다!" -ForegroundColor Green
Write-Host "📅 빌드 날짜: $buildDateTime" -ForegroundColor Cyan

