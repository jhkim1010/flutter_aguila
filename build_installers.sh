#!/bin/bash

# Flutter 앱 macOS 및 Android용 설치 파일 생성 스크립트
# "Be COOL" 앱 설치 파일 생성 (다른 기기에서 사용 가능)

set -e  # 에러 발생 시 중단

echo "🚀 Flutter 설치 파일 빌드 시작..."
echo "📱 앱 이름: Be COOL"
echo ""

# UTF-8 인코딩 설정
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Flutter 프로젝트 디렉토리로 이동
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# 앱 정보
APP_NAME="Be COOL"
# pubspec.yaml 은 CRLF 파일이라 tr -d '\r' 없이는 값 끝에 캐리지 리턴이 붙는다.
# 그대로 파일명에 쓰면 'Be_COOL_..._1\r.dmg' 처럼 접근 불가능한 이름이 만들어진다.
VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | sed 's/+.*//' | tr -d '\r')
BUILD_NUMBER=$(grep '^version:' pubspec.yaml | sed 's/.*+//' | tr -d '\r')

# 출력 디렉토리 설정
OUTPUT_DIR="$SCRIPT_DIR/build/installers"
mkdir -p "$OUTPUT_DIR"

# Dropbox 디렉토리 설정
DROPBOX_DIR="/Users/marcoskim/Dropbox/ACE_3_uversion"
mkdir -p "$DROPBOX_DIR"

# 플랫폼 선택
echo "📦 빌드할 플랫폼을 선택하세요:"
echo "   1) macOS (DMG)"
echo "   2) Android (APK)"
echo "   3) 둘 다"
echo ""
read -p "선택 (1/2/3): " PLATFORM_CHOICE

BUILD_MACOS=false
BUILD_ANDROID=false

case $PLATFORM_CHOICE in
    1)
        BUILD_MACOS=true
        ;;
    2)
        BUILD_ANDROID=true
        ;;
    3)
        BUILD_MACOS=true
        BUILD_ANDROID=true
        ;;
    *)
        echo "❌ 잘못된 선택입니다."
        exit 1
        ;;
esac

# Flutter 의존성 확인 및 설치
echo ""
echo "📦 의존성 확인 중..."
flutter pub get

# ============================================
# macOS DMG 빌드
# ============================================
if [ "$BUILD_MACOS" = true ]; then
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo "❌ macOS 빌드는 macOS에서만 가능합니다."
        BUILD_MACOS=false
    else
        echo ""
        echo "🍎 macOS DMG 빌드 시작..."
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        APP_BUNDLE_NAME="${APP_NAME}.app"
        DMG_NAME="${APP_NAME// /_}_macOS_v${VERSION}_${BUILD_NUMBER}.dmg"
        DMG_PATH="$OUTPUT_DIR/$DMG_NAME"
        
        # macOS Pods 설치
        echo "🍎 macOS Pods 설치 중..."
        cd macos
        if [ -f "Podfile" ]; then
            pod install || echo "⚠️  Pod install 실패했지만 계속 진행합니다"
        fi
        cd ..
        
        # Release macOS 빌드
        echo "🔨 Release macOS 빌드 중..."
        flutter build macos --release
        
        # 빌드 결과 확인
        APP_BUNDLE="build/macos/Build/Products/Release/${APP_BUNDLE_NAME}"
        if [ ! -d "$APP_BUNDLE" ]; then
            APP_BUNDLE="build/macos/Build/Products/Release/Be_Cool.app"
            if [ ! -d "$APP_BUNDLE" ]; then
                APP_BUNDLE="build/macos/Build/Products/Release/Runner.app"
                if [ ! -d "$APP_BUNDLE" ]; then
                    echo "❌ 앱 번들을 찾을 수 없습니다!"
                    ls -la "build/macos/Build/Products/Release/" || true
                    BUILD_MACOS=false
                fi
            fi
        fi
        
        if [ "$BUILD_MACOS" = true ]; then
            echo "✅ 앱 번들 빌드 성공!"
            echo "   위치: $APP_BUNDLE"
            
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
            
            COPIED_APP="$DMG_CONTENTS_DIR/${APP_BUNDLE_NAME}"
            
            # 코드 서명 확인
            SIGNED=false
            DEVELOPER_ID=$(security find-identity -v -p codesigning 2>/dev/null | grep "Developer ID Application" | head -1 | sed 's/.*"\(.*\)".*/\1/')
            
            if codesign -dv --verbose=4 "$COPIED_APP" 2>&1 | grep -q "valid on disk"; then
                echo "   ✅ 앱이 코드 서명되어 있습니다."
                SIGNED=true
            elif [ -n "$DEVELOPER_ID" ]; then
                echo "   🔐 개발자 인증서로 재서명 시도 중..."
                if codesign --force --deep --sign "$DEVELOPER_ID" "$COPIED_APP" 2>&1 | grep -v "replacing existing signature"; then
                    echo "   ✅ 재서명 완료"
                    SIGNED=true
                fi
            fi
            
            # Applications 폴더로의 심볼릭 링크 생성
            ln -s /Applications "$DMG_CONTENTS_DIR/Applications"
            
            # DMG 파일 생성
            echo "   DMG 파일 생성 중..."
            if [ -f "$DMG_PATH" ]; then
                rm -f "$DMG_PATH"
            fi
            
            hdiutil create -volname "$APP_NAME" \
                -srcfolder "$DMG_CONTENTS_DIR" \
                -ov \
                -format UDZO \
                "$DMG_PATH"
            
            # 임시 디렉토리 정리
            rm -rf "$DMG_TEMP_DIR"
            
            if [ -f "$DMG_PATH" ]; then
                DMG_SIZE=$(du -h "$DMG_PATH" | cut -f1)
                echo ""
                echo "✅ macOS DMG 파일 생성 성공!"
                echo "   파일명: $DMG_NAME"
                echo "   위치: $DMG_PATH"
                echo "   크기: $DMG_SIZE"
                
                # Dropbox로 복사
                echo "☁️  Dropbox로 복사 중..."
                cp "$DMG_PATH" "$DROPBOX_DIR/$DMG_NAME"
                echo "   ✅ Dropbox 위치: $DROPBOX_DIR/$DMG_NAME"
            else
                echo "❌ DMG 파일 생성 실패!"
                BUILD_MACOS=false
            fi
        fi
    fi
fi

# ============================================
# Android APK 빌드
# ============================================
if [ "$BUILD_ANDROID" = true ]; then
    echo ""
    echo "🤖 Android APK 빌드 시작..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    APK_NAME="${APP_NAME// /_}_Android_v${VERSION}_${BUILD_NUMBER}.apk"
    APK_PATH="$OUTPUT_DIR/$APK_NAME"
    
    # Release APK 빌드
    echo "🔨 Release APK 빌드 중..."
    flutter build apk --release
    
    # 빌드 결과 확인
    APK_FILE="build/app/outputs/flutter-apk/app-release.apk"
    
    if [ -f "$APK_FILE" ]; then
        echo "✅ APK 빌드 성공!"
        echo "   위치: $APK_FILE"
        
        # 출력 디렉토리로 복사
        cp "$APK_FILE" "$APK_PATH"
        
        APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
        echo ""
        echo "✅ Android APK 파일 생성 성공!"
        echo "   파일명: $APK_NAME"
        echo "   위치: $APK_PATH"
        echo "   크기: $APK_SIZE"
        
        # Dropbox로 복사
        echo "☁️  Dropbox로 복사 중..."
        cp "$APK_PATH" "$DROPBOX_DIR/$APK_NAME"
        echo "   ✅ Dropbox 위치: $DROPBOX_DIR/$APK_NAME"
    else
        echo "❌ APK 파일을 찾을 수 없습니다!"
        BUILD_ANDROID=false
    fi
fi

# ============================================
# 결과 요약
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 빌드 완료!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$BUILD_MACOS" = true ]; then
    echo "🍎 macOS 설치 파일:"
    echo "   로컬: $OUTPUT_DIR/$DMG_NAME"
    echo "   Dropbox: $DROPBOX_DIR/$DMG_NAME"
    echo ""
    echo "   설치 방법:"
    echo "   1. DMG 파일을 더블클릭하여 열기"
    echo "   2. 앱을 Applications 폴더로 드래그"
    echo "   3. 다른 Mac에서 실행 시:"
    echo "      - '손상된 앱' 경고가 나타나면 우클릭 > '열기' 선택"
    echo "      - 또는 터미널에서: xattr -cr \"/Applications/${APP_BUNDLE_NAME}\""
    echo ""
fi

if [ "$BUILD_ANDROID" = true ]; then
    echo "🤖 Android 설치 파일:"
    echo "   로컬: $OUTPUT_DIR/$APK_NAME"
    echo "   Dropbox: $DROPBOX_DIR/$APK_NAME"
    echo ""
    echo "   설치 방법:"
    echo "   1. APK 파일을 Android 기기로 전송 (이메일, USB, 클라우드 등)"
    echo "   2. Android 기기에서: 설정 > 보안 > 알 수 없는 소스 허용"
    echo "   3. APK 파일을 열어 설치"
    echo "   4. 설치 후 앱 실행"
    echo ""
fi

echo "📂 모든 설치 파일 위치:"
echo "   로컬: $OUTPUT_DIR"
echo "   Dropbox: $DROPBOX_DIR"
echo ""

# Finder에서 출력 디렉토리 열기
if [[ "$OSTYPE" == "darwin"* ]]; then
    read -p "📂 Finder에서 설치 파일을 열까요? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open "$OUTPUT_DIR"
    fi
fi

echo ""
echo "✨ 완료!"
