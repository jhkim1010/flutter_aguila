#!/bin/bash

# Flutter 앱 macOS 및 Android 설치 파일 빌드 스크립트
# "Be COOL" 앱 설치 파일 생성 (다른 기기에서 사용 가능)

set -e  # 에러 발생 시 중단

echo "🚀 Flutter 설치 파일 빌드 시작..."
echo "📱 앱 이름: Be COOL"
echo "💻 플랫폼: macOS + Android"
echo ""

# Flutter 프로젝트 디렉토리로 이동
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# 출력 디렉토리 설정
OUTPUT_DIR="$SCRIPT_DIR/build/installers"
DROPBOX_DIR="/Users/marcoskim/Dropbox/ACE_3_uversion"
mkdir -p "$OUTPUT_DIR"
mkdir -p "$DROPBOX_DIR"

# 버전 정보 가져오기
VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | sed 's/+.*//')
BUILD_NUMBER=$(grep '^version:' pubspec.yaml | sed 's/.*+//')

echo "📦 버전: $VERSION (빌드: $BUILD_NUMBER)"
echo ""

# Flutter 의존성 확인 및 설치
echo "📦 의존성 확인 중..."
flutter pub get

# 빌드 결과 저장
BUILD_SUCCESS=true

# ============================================
# macOS 빌드
# ============================================
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo ""
    echo "============================================"
    echo "🍎 macOS 빌드 시작"
    echo "============================================"
    echo ""
    
    # macOS Pods 설치
    echo "🍎 macOS Pods 설치 중..."
    cd macos
    if [ -f "Podfile" ]; then
        export LANG=en_US.UTF-8
        export LC_ALL=en_US.UTF-8
        pod install || echo "⚠️  Pod install 실패했지만 계속 진행합니다"
    fi
    cd ..
    
    # Release macOS 빌드
    echo "🔨 Release macOS 빌드 중..."
    flutter build macos --release
    
    # 앱 번들 찾기
    APP_BUNDLE="build/macos/Build/Products/Release/Be COOL.app"
    if [ ! -d "$APP_BUNDLE" ]; then
        APP_BUNDLE="build/macos/Build/Products/Release/Be_Cool.app"
        if [ ! -d "$APP_BUNDLE" ]; then
            APP_BUNDLE="build/macos/Build/Products/Release/Runner.app"
        fi
    fi
    
    if [ -d "$APP_BUNDLE" ]; then
        echo "✅ macOS 앱 번들 빌드 성공!"
        
        # DMG 생성
        echo "📦 DMG 파일 생성 중..."
        APP_NAME="Be COOL"
        DMG_NAME="${APP_NAME// /_}_macOS_v${VERSION}_${BUILD_NUMBER}.dmg"
        DMG_PATH="$OUTPUT_DIR/$DMG_NAME"
        
        # DMG 임시 디렉토리 준비
        DMG_TEMP_DIR="build/macos/DMG_TEMP"
        DMG_CONTENTS_DIR="$DMG_TEMP_DIR/${APP_NAME}"
        rm -rf "$DMG_TEMP_DIR"
        mkdir -p "$DMG_CONTENTS_DIR"
        
        # 앱 번들 복사
        cp -R "$APP_BUNDLE" "$DMG_CONTENTS_DIR/"
        
        # Applications 폴더로의 심볼릭 링크 생성
        ln -s /Applications "$DMG_CONTENTS_DIR/Applications"
        
        # DMG 파일 생성
        hdiutil create -volname "$APP_NAME" \
            -srcfolder "$DMG_CONTENTS_DIR" \
            -ov \
            -format UDZO \
            "$DMG_PATH" 2>/dev/null || true
        
        # 임시 디렉토리 정리
        rm -rf "$DMG_TEMP_DIR"
        
        if [ -f "$DMG_PATH" ]; then
            DMG_SIZE=$(du -h "$DMG_PATH" | cut -f1)
            echo "✅ macOS DMG 파일 생성 성공!"
            echo "   파일: $DMG_NAME"
            echo "   크기: $DMG_SIZE"
            echo "   위치: $DMG_PATH"
            
            # Dropbox로 복사
            cp "$DMG_PATH" "$DROPBOX_DIR/$DMG_NAME"
            echo "✅ Dropbox로 복사 완료: $DROPBOX_DIR/$DMG_NAME"
        else
            echo "⚠️  DMG 생성 실패, 앱 번들만 복사합니다"
            APP_COPY_NAME="${APP_NAME// /_}_macOS_v${VERSION}_${BUILD_NUMBER}.app"
            cp -R "$APP_BUNDLE" "$OUTPUT_DIR/$APP_COPY_NAME"
            cp -R "$APP_BUNDLE" "$DROPBOX_DIR/$APP_COPY_NAME"
            echo "✅ 앱 번들 복사 완료"
        fi
    else
        echo "❌ macOS 빌드 실패!"
        BUILD_SUCCESS=false
    fi
else
    echo "⚠️  macOS 빌드는 macOS에서만 가능합니다. 건너뜁니다."
fi

# ============================================
# Android APK 빌드
# ============================================
echo ""
echo "============================================"
echo "🤖 Android APK 빌드 시작"
echo "============================================"
echo ""

# Release APK 빌드
echo "🔨 Release APK 빌드 중..."
flutter build apk --release

# APK 파일 확인 및 복사
APK_SOURCE="build/app/outputs/flutter-apk/app-release.apk"
if [ -f "$APK_SOURCE" ]; then
    APK_NAME="Be_Cool_Android_v${VERSION}_${BUILD_NUMBER}.apk"
    APK_PATH="$OUTPUT_DIR/$APK_NAME"
    
    cp "$APK_SOURCE" "$APK_PATH"
    
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    echo "✅ Android APK 빌드 성공!"
    echo "   파일: $APK_NAME"
    echo "   크기: $APK_SIZE"
    echo "   위치: $APK_PATH"
    
    # Dropbox로 복사
    cp "$APK_PATH" "$DROPBOX_DIR/$APK_NAME"
    echo "✅ Dropbox로 복사 완료: $DROPBOX_DIR/$APK_NAME"
else
    echo "❌ Android APK 빌드 실패!"
    BUILD_SUCCESS=false
fi

# ============================================
# 빌드 결과 요약
# ============================================
echo ""
echo "============================================"
echo "📊 빌드 결과 요약"
echo "============================================"
echo ""

if [ "$BUILD_SUCCESS" = true ]; then
    echo "✅ 모든 빌드 완료!"
    echo ""
    echo "📦 설치 파일 위치:"
    echo "   로컬: $OUTPUT_DIR"
    echo "   Dropbox: $DROPBOX_DIR"
    echo ""
    echo "📱 설치 방법:"
    echo ""
    
    if [[ "$OSTYPE" == "darwin"* ]] && [ -f "$OUTPUT_DIR"/*.dmg ] 2>/dev/null; then
        echo "🍎 macOS:"
        echo "   1. DMG 파일을 더블클릭하여 열기"
        echo "   2. 앱을 Applications 폴더로 드래그"
        echo "   3. 첫 실행 시: 앱을 우클릭 > '열기' 선택"
        echo ""
    fi
    
    if [ -f "$OUTPUT_DIR"/*.apk ] 2>/dev/null; then
        echo "🤖 Android:"
        echo "   1. APK 파일을 Android 기기로 전송"
        echo "   2. 기기에서 '알 수 없는 출처' 설치 허용"
        echo "   3. APK 파일을 탭하여 설치"
        echo ""
    fi
    
    # Finder에서 출력 폴더 열기
    read -p "📂 Finder에서 출력 폴더를 열까요? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open "$OUTPUT_DIR"
    fi
else
    echo "❌ 일부 빌드가 실패했습니다."
    exit 1
fi

echo ""
echo "🎉 완료!"
