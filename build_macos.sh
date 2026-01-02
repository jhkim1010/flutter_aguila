#!/bin/bash

# Flutter 앱 macOS 실행 파일 빌드 스크립트
# "Be COOL" 앱 macOS 실행 파일 생성

echo "🚀 Flutter macOS 앱 빌드 시작..."
echo "📱 앱 이름: Be COOL"
echo "💻 플랫폼: macOS"
echo ""

# Flutter 프로젝트 디렉토리로 이동
cd "$(dirname "$0")"

# macOS에서만 실행 가능한지 확인
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ macOS 빌드는 macOS에서만 가능합니다."
    exit 1
fi

# 빌드 날짜 주입
echo "📅 빌드 날짜 주입 중..."
bash scripts/inject_build_date.sh

# Flutter 의존성 확인 및 설치
echo "📦 의존성 확인 중..."
flutter pub get

# macOS Pods 설치
echo "🍎 macOS Pods 설치 중..."
cd macos
pod install
cd ..

# 빌드 전 정리
echo "🧹 이전 빌드 정리 중..."
flutter clean

# Release macOS 빌드
echo "🔨 Release macOS 빌드 중..."
flutter build macos --release

# 빌드 결과 확인
APP_BUNDLE="build/macos/Build/Products/Release/Be COOL.app"
if [ ! -d "$APP_BUNDLE" ]; then
    APP_BUNDLE="build/macos/Build/Products/Release/Runner.app"
fi

if [ -d "$APP_BUNDLE" ]; then
    echo ""
    echo "✅ 빌드 성공!"
    echo ""
    echo "📦 실행 파일 위치:"
    echo "   $(pwd)/$APP_BUNDLE"
    echo ""
    echo "📊 파일 정보:"
    ls -lh "$APP_BUNDLE"
    echo ""
    echo "💡 실행 방법:"
    echo "   1. Finder에서 앱을 더블클릭하여 실행"
    echo "   2. 또는 터미널에서 다음 명령어로 실행:"
    echo "      open \"$(pwd)/$APP_BUNDLE\""
    echo ""
    
    # Dropbox 폴더로 복사 (선택사항)
    read -p "Dropbox로 복사하시겠습니까? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        DROPBOX_DIR="/Users/marcoskim/Dropbox/ACE_3_uversion"
        mkdir -p "$DROPBOX_DIR"
        
        TARGET_DIR="$DROPBOX_DIR/Be_COOL_macOS.app"
        if [ -d "$TARGET_DIR" ]; then
            rm -rf "$TARGET_DIR"
        fi
        
        cp -R "$APP_BUNDLE" "$TARGET_DIR"
        echo "✅ Be_COOL_macOS.app이 Dropbox로 복사되었습니다!"
        echo "   위치: $TARGET_DIR"
    fi
else
    echo "❌ 빌드 실패!"
    exit 1
fi

