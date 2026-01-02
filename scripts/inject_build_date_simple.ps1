# Build date injection script (Simple version without Korean characters)
# Set UTF-8 encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Get project root directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath
Set-Location $projectRoot

# Get current date
$buildDate = Get-Date -Format "yyyy-MM-dd"
$buildDateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Write-Host "Injecting build date: $buildDateTime" -ForegroundColor Cyan

# Create generated directory
$generatedDir = "lib\generated"
if (-not (Test-Path $generatedDir)) {
    New-Item -ItemType Directory -Path $generatedDir -Force | Out-Null
}

# Create build_info.dart file
$buildInfoFile = Join-Path $generatedDir "build_info.dart"

$buildInfoContent = @"
// This file is auto-generated. Do not edit manually.
// Generated automatically. Do not edit manually.

/// App build information
class BuildInfo {
  /// Build date (YYYY-MM-DD format)
  static const String buildDate = '$buildDate';
  
  /// Build date and time (YYYY-MM-DD HH:MM:SS format)
  static const String buildDateTime = '$buildDateTime';
  
  /// Returns build date as DateTime object
  static DateTime get buildDateAsDateTime {
    return DateTime.parse(buildDate);
  }
}
"@

# Use UTF-8 encoding without BOM
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$fullPath = Join-Path (Get-Location) $buildInfoFile
[System.IO.File]::WriteAllText($fullPath, $buildInfoContent, $utf8NoBom)

Write-Host "Build info file created: $buildInfoFile" -ForegroundColor Green
Write-Host "Build date: $buildDateTime" -ForegroundColor Cyan

