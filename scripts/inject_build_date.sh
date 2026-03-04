#!/bin/bash

# 빌드 날짜를 각 플랫폼의 설정 파일에 자동으로 주입하는 스크립트
# 빌드 시점에 실행되어 컴파일 날짜를 기록합니다.

set -e

# 프로젝트 루트 디렉토리로 이동
cd "$(dirname "$0")/.."

# 현재 날짜를 YYYY-MM-DD 형식으로 생성
BUILD_DATE=$(date +"%Y-%m-%d")
BUILD_DATETIME=$(date +"%Y-%m-%d %H:%M:%S")

echo "📅 빌드 날짜 주입 중: $BUILD_DATETIME"

# ============================================
# 1. Android 설정
# ============================================
echo "📱 Android 설정 업데이트 중..."

# strings.xml 파일 생성 또는 업데이트
ANDROID_VALUES_DIR="android/app/src/main/res/values"
mkdir -p "$ANDROID_VALUES_DIR"

ANDROID_STRINGS_FILE="$ANDROID_VALUES_DIR/strings.xml"

if [ -f "$ANDROID_STRINGS_FILE" ]; then
    # 기존 파일이 있으면 빌드 날짜만 업데이트
    if grep -q "build_date" "$ANDROID_STRINGS_FILE"; then
        # macOS와 Linux 모두에서 동작하도록 sed 사용
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s|<string name=\"build_date\">.*</string>|<string name=\"build_date\">$BUILD_DATE</string>|g" "$ANDROID_STRINGS_FILE"
        else
            # Linux
            sed -i "s|<string name=\"build_date\">.*</string>|<string name=\"build_date\">$BUILD_DATE</string>|g" "$ANDROID_STRINGS_FILE"
        fi
    else
        # build_date가 없으면 추가
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|</resources>|    <string name=\"build_date\">$BUILD_DATE</string>\n</resources>|" "$ANDROID_STRINGS_FILE"
        else
            sed -i "s|</resources>|    <string name=\"build_date\">$BUILD_DATE</string>\n</resources>|" "$ANDROID_STRINGS_FILE"
        fi
    fi
else
    # 파일이 없으면 새로 생성
    cat > "$ANDROID_STRINGS_FILE" << EOF
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Be COOL</string>
    <string name="build_date">$BUILD_DATE</string>
</resources>
EOF
fi

# AndroidManifest.xml의 label에 날짜 추가 (선택사항)
# android:label="Be COOL ($BUILD_DATE)" 형식으로 변경 가능하지만,
# strings.xml을 사용하는 것이 더 깔끔함

echo "✅ Android 설정 완료"

# ============================================
# 2. iOS 설정
# ============================================
echo "🍎 iOS 설정 업데이트 중..."

IOS_INFO_PLIST="ios/Runner/Info.plist"

if [ -f "$IOS_INFO_PLIST" ]; then
    # CFBundleBuildDate 키가 있는지 확인
    if grep -q "CFBundleBuildDate" "$IOS_INFO_PLIST"; then
        # 기존 값 업데이트
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS에서는 plutil 사용 가능
            if command -v plutil &> /dev/null; then
                plutil -replace CFBundleBuildDate -string "$BUILD_DATETIME" "$IOS_INFO_PLIST"
            else
                # plutil이 없으면 sed 사용
                sed -i '' "s|<string>.*</string>.*CFBundleBuildDate|<string>$BUILD_DATETIME</string>\n\t<key>CFBundleBuildDate</key>|" "$IOS_INFO_PLIST"
                # 더 정확한 방법: 키-값 쌍 찾아서 교체
                sed -i '' "/<key>CFBundleBuildDate<\/key>/,+1s|<string>.*</string>|<string>$BUILD_DATETIME</string>|" "$IOS_INFO_PLIST"
            fi
        else
            # Linux에서는 sed만 사용
            sed -i "/<key>CFBundleBuildDate<\/key>/,+1s|<string>.*</string>|<string>$BUILD_DATETIME</string>|" "$IOS_INFO_PLIST"
        fi
    else
        # CFBundleBuildDate 키가 없으면 추가 (CFBundleVersion 다음에)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            if command -v plutil &> /dev/null; then
                plutil -insert CFBundleBuildDate -string "$BUILD_DATETIME" "$IOS_INFO_PLIST"
            else
                # sed로 CFBundleVersion 다음에 추가
                sed -i '' "/<key>CFBundleVersion<\/key>/,+1a\\
	<key>CFBundleBuildDate</key>\\
	<string>$BUILD_DATETIME</string>
" "$IOS_INFO_PLIST"
            fi
        else
            sed -i "/<key>CFBundleVersion<\/key>/,+1a\	<key>CFBundleBuildDate</key>\n	<string>$BUILD_DATETIME</string>" "$IOS_INFO_PLIST"
        fi
    fi
    echo "✅ iOS 설정 완료"
else
    echo "⚠️ iOS Info.plist 파일을 찾을 수 없습니다: $IOS_INFO_PLIST"
fi

# ============================================
# 3. macOS 설정
# ============================================
echo "💻 macOS 설정 업데이트 중..."

MACOS_INFO_PLIST="macos/Runner/Info.plist"

if [ -f "$MACOS_INFO_PLIST" ]; then
    # CFBundleBuildDate 키가 있는지 확인
    if grep -q "CFBundleBuildDate" "$MACOS_INFO_PLIST"; then
        # 기존 값 업데이트
        if [[ "$OSTYPE" == "darwin"* ]]; then
            if command -v plutil &> /dev/null; then
                plutil -replace CFBundleBuildDate -string "$BUILD_DATETIME" "$MACOS_INFO_PLIST"
            else
                sed -i '' "/<key>CFBundleBuildDate<\/key>/,+1s|<string>.*</string>|<string>$BUILD_DATETIME</string>|" "$MACOS_INFO_PLIST"
            fi
        else
            sed -i "/<key>CFBundleBuildDate<\/key>/,+1s|<string>.*</string>|<string>$BUILD_DATETIME</string>|" "$MACOS_INFO_PLIST"
        fi
    else
        # CFBundleBuildDate 키가 없으면 추가
        if [[ "$OSTYPE" == "darwin"* ]]; then
            if command -v plutil &> /dev/null; then
                plutil -insert CFBundleBuildDate -string "$BUILD_DATETIME" "$MACOS_INFO_PLIST"
            else
                sed -i '' "/<key>CFBundleVersion<\/key>/,+1a\\
	<key>CFBundleBuildDate</key>\\
	<string>$BUILD_DATETIME</string>
" "$MACOS_INFO_PLIST"
            fi
        else
            sed -i "/<key>CFBundleVersion<\/key>/,+1a\	<key>CFBundleBuildDate</key>\n	<string>$BUILD_DATETIME</string>" "$MACOS_INFO_PLIST"
        fi
    fi
    echo "✅ macOS 설정 완료"
else
    echo "⚠️ macOS Info.plist 파일을 찾을 수 없습니다: $MACOS_INFO_PLIST"
fi

# ============================================
# 4. Flutter 코드에서 읽을 수 있는 파일 생성
# ============================================
echo "📝 Flutter 빌드 정보 파일 생성 중..."

GENERATED_DIR="lib/generated"
mkdir -p "$GENERATED_DIR"

BUILD_INFO_FILE="$GENERATED_DIR/build_info.dart"

cat > "$BUILD_INFO_FILE" << EOF
// 이 파일은 자동으로 생성됩니다. 수동으로 편집하지 마세요.
// Generated automatically. Do not edit manually.

/// 앱의 빌드 정보
class BuildInfo {
  /// 빌드 날짜 (YYYY-MM-DD 형식)
  static const String buildDate = '$BUILD_DATE';
  
  /// 빌드 날짜 및 시간 (YYYY-MM-DD HH:MM:SS 형식)
  static const String buildDateTime = '$BUILD_DATETIME';
  
  /// 빌드 날짜를 DateTime 객체로 반환
  static DateTime get buildDateAsDateTime {
    return DateTime.parse(buildDate);
  }
}
EOF

echo "✅ Flutter 빌드 정보 파일 생성 완료: $BUILD_INFO_FILE"

# ============================================
# 5. Windows 설정 (선택사항)
# ============================================
echo "🪟 Windows 설정 업데이트 중..."

WINDOWS_MAIN_CPP="windows/runner/main.cpp"

if [ -f "$WINDOWS_MAIN_CPP" ]; then
    # Windows의 경우 윈도우 타이틀에 날짜를 추가할 수 있지만,
    # 현재는 main.cpp에서 하드코딩되어 있으므로 주석으로만 표시
    # 실제로는 Flutter 코드에서 BuildInfo를 사용하는 것이 더 나음
    echo "✅ Windows는 Flutter BuildInfo를 사용합니다"
else
    echo "⚠️ Windows main.cpp 파일을 찾을 수 없습니다"
fi

echo ""
echo "✅ 모든 플랫폼의 빌드 날짜 주입이 완료되었습니다!"
echo "📅 빌드 날짜: $BUILD_DATETIME"

