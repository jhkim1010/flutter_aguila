#!/bin/bash

# Flutter 앱 macOS 설치 파일(DMG) 생성 스크립트
# "Be COOL" 앱 macOS DMG 파일 생성

set -e  # 에러 발생 시 중단

echo "🚀 Flutter macOS 설치 파일 빌드 시작..."
echo "📱 앱 이름: Be COOL"
echo "💻 플랫폼: macOS"
echo "📦 출력 형식: DMG"
echo ""

# Flutter 프로젝트 디렉토리로 이동
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# macOS에서만 실행 가능한지 확인
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ macOS 빌드는 macOS에서만 가능합니다."
    exit 1
fi

# 앱 정보
APP_NAME="Be COOL"
APP_BUNDLE_NAME="${APP_NAME}.app"
VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | sed 's/+.*//')
BUILD_NUMBER=$(grep '^version:' pubspec.yaml | sed 's/.*+//')
DMG_NAME="${APP_NAME// /_}_macOS_v${VERSION}_${BUILD_NUMBER}.dmg"
DMG_PATH="$SCRIPT_DIR/build/macos/$DMG_NAME"

# Flutter 의존성 확인 및 설치
echo "📦 의존성 확인 중..."
flutter pub get

# macOS Pods 설치
echo "🍎 macOS Pods 설치 중..."
cd macos
if [ -f "Podfile" ]; then
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    pod install || echo "⚠️  Pod install 실패했지만 계속 진행합니다 (이미 설치되어 있을 수 있음)"
fi
cd ..

# 빌드 전 정리 (선택사항)
# 자동 모드: 환경 변수 CLEAN_BUILD가 설정되어 있으면 정리, 아니면 건너뜀
if [[ "${CLEAN_BUILD:-n}" =~ ^[Yy]$ ]]; then
    echo "🧹 이전 빌드 정리 중..."
    flutter clean
else
    echo "🧹 이전 빌드 정리 건너뜀..."
fi

# Release macOS 빌드
echo "🔨 Release macOS 빌드 중..."
flutter build macos --release

# 빌드 결과 확인
APP_BUNDLE="build/macos/Build/Products/Release/${APP_BUNDLE_NAME}"
if [ ! -d "$APP_BUNDLE" ]; then
    # 다른 가능한 앱 이름들 확인
    APP_BUNDLE="build/macos/Build/Products/Release/Be_Cool.app"
    if [ ! -d "$APP_BUNDLE" ]; then
        APP_BUNDLE="build/macos/Build/Products/Release/Runner.app"
        if [ ! -d "$APP_BUNDLE" ]; then
            echo "❌ 앱 번들을 찾을 수 없습니다!"
            echo "   찾은 위치: build/macos/Build/Products/Release/"
            ls -la "build/macos/Build/Products/Release/" || true
            exit 1
        fi
    fi
fi

echo ""
echo "✅ 앱 번들 빌드 성공!"
echo "   위치: $APP_BUNDLE"
echo ""

# DMG 생성 디렉토리 준비
DMG_TEMP_DIR="build/macos/DMG_TEMP"
DMG_CONTENTS_DIR="$DMG_TEMP_DIR/${APP_NAME}"

echo "📦 DMG 파일 생성 중..."

# 이전 DMG 디렉토리 정리
rm -rf "$DMG_TEMP_DIR"
mkdir -p "$DMG_CONTENTS_DIR"

# 앱 번들을 DMG 디렉토리로 복사
echo "   앱 번들 복사 중..."
cp -R "$APP_BUNDLE" "$DMG_CONTENTS_DIR/"

# 복사된 앱 번들 경로
COPIED_APP="$DMG_CONTENTS_DIR/${APP_BUNDLE_NAME}"

# 코드 서명 확인 및 재서명 시도
echo "   코드 서명 확인 중..."
SIGNED=false

# 개발자 인증서 찾기
DEVELOPER_ID=$(security find-identity -v -p codesigning 2>/dev/null | grep "Developer ID Application" | head -1 | sed 's/.*"\(.*\)".*/\1/')

if codesign -dv --verbose=4 "$COPIED_APP" 2>&1 | grep -q "valid on disk"; then
    echo "   ✅ 앱이 코드 서명되어 있습니다."
    SIGNED=true
elif [ -n "$DEVELOPER_ID" ]; then
    echo "   🔐 개발자 인증서로 재서명 시도 중..."
    echo "   인증서: $DEVELOPER_ID"
    if codesign --force --deep --sign "$DEVELOPER_ID" "$COPIED_APP" 2>&1 | grep -v "replacing existing signature"; then
        echo "   ✅ 재서명 완료"
        SIGNED=true
    else
        echo "   ⚠️  재서명 실패"
    fi
else
    echo "   ⚠️  Developer ID 인증서를 찾을 수 없습니다."
    echo "   앱 실행을 위한 헬퍼 스크립트를 생성합니다..."
fi

# 앱 실행 헬퍼 스크립트 생성 (코드 서명이 없는 경우)
if [ "$SIGNED" = false ]; then
    HELPER_SCRIPT="$DMG_CONTENTS_DIR/앱_실행하기.command"
    cat > "$HELPER_SCRIPT" <<'HELPER_EOF'
#!/bin/bash
# Be COOL 앱 실행 헬퍼 스크립트
# Gatekeeper 문제를 해결하여 앱을 실행합니다

APP_NAME="Be_Cool.app"
APP_PATH="/Applications/$APP_NAME"

echo "🚀 Be COOL 앱 실행 준비 중..."
echo ""

# Applications 폴더에 앱이 있는지 확인
if [ ! -d "$APP_PATH" ]; then
    echo "❌ 앱을 찾을 수 없습니다: $APP_PATH"
    echo ""
    echo "먼저 앱을 Applications 폴더로 드래그하세요."
    echo ""
    read -p "계속하려면 Enter를 누르세요..."
    exit 1
fi

echo "🔓 Gatekeeper 속성 제거 중..."
xattr -cr "$APP_PATH"

echo "✅ 준비 완료!"
echo ""
echo "앱을 실행합니다..."
echo ""

open "$APP_PATH"

sleep 2
echo ""
echo "✅ 앱이 실행되었습니다!"
echo ""
echo "💡 다음부터는 Applications 폴더에서 직접 실행할 수 있습니다."
echo ""
read -p "계속하려면 Enter를 누르세요..."
HELPER_EOF
    chmod +x "$HELPER_SCRIPT"
    echo "   ✅ 헬퍼 스크립트 생성 완료: $HELPER_SCRIPT"
fi

# Applications 폴더로의 심볼릭 링크 생성
ln -s /Applications "$DMG_CONTENTS_DIR/Applications"

# DMG 파일 생성
echo "   DMG 파일 생성 중..."
DMG_DIR="build/macos"
mkdir -p "$DMG_DIR"

# 기존 DMG 파일 삭제
if [ -f "$DMG_PATH" ]; then
    rm -f "$DMG_PATH"
fi

# hdiutil을 사용하여 DMG 생성
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_CONTENTS_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

# 임시 디렉토리 정리
rm -rf "$DMG_TEMP_DIR"

# DMG 파일 정보 출력
if [ -f "$DMG_PATH" ]; then
    DMG_SIZE=$(du -h "$DMG_PATH" | cut -f1)
    echo ""
    echo "✅ DMG 파일 생성 성공!"
    echo ""
    echo "📦 설치 파일 정보:"
    echo "   파일명: $DMG_NAME"
    echo "   위치: $DMG_PATH"
    echo "   크기: $DMG_SIZE"
    echo ""
    echo "💡 설치 방법:"
    echo "   1. DMG 파일을 더블클릭하여 열기"
    echo "   2. 앱을 Applications 폴더로 드래그"
    echo ""
    if [ "$SIGNED" = false ]; then
        echo "⚠️  다른 Mac에서 실행 시:"
        echo "   '손상된 앱' 또는 '확인할 수 없는 개발자' 경고가 나타날 수 있습니다."
        echo ""
        echo "   해결 방법 (선택 1 - 권장):"
        echo "   1. DMG에서 '앱_실행하기.command' 파일을 더블클릭"
        echo "   2. 또는 앱을 우클릭 > '열기' 선택 (첫 실행 시)"
        echo ""
        echo "   해결 방법 (선택 2 - 터미널 사용):"
        echo "   터미널에서 다음 명령어 실행:"
        echo "   xattr -cr \"/Applications/${APP_BUNDLE_NAME}\""
        echo ""
    else
        echo "✅ 앱이 코드 서명되어 있어 다른 Mac에서도 실행 가능합니다."
        echo ""
    fi
    
    # Dropbox로 자동 복사
    echo "☁️  Dropbox로 자동 복사 중..."
    DROPBOX_DIR="/Users/marcoskim/Dropbox/ACE_3_uversion"
    mkdir -p "$DROPBOX_DIR"
    
    TARGET_DMG="$DROPBOX_DIR/$DMG_NAME"
    cp "$DMG_PATH" "$TARGET_DMG"
    echo "✅ DMG 파일이 Dropbox로 복사되었습니다!"
    echo "   위치: $TARGET_DMG"
    echo ""
    
    # Finder에서 DMG 파일 열기 (선택사항)
    # 자동 모드: 환경 변수 OPEN_FINDER가 설정되어 있으면 열기
    if [[ "${OPEN_FINDER:-n}" =~ ^[Yy]$ ]]; then
        open -R "$DMG_PATH"
    fi
else
    echo "❌ DMG 파일 생성 실패!"
    exit 1
fi

echo ""
echo "🎉 빌드 완료!"

