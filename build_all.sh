#!/bin/bash

# Flutter 앱 전체 플랫폼 빌드 스크립트
# "Be COOL" 앱 설치 파일 생성

echo "🚀 Flutter 앱 전체 빌드 시작..."
echo "📱 앱 이름: Be COOL"
echo ""

# Flutter 프로젝트 디렉토리로 이동
cd "$(dirname "$0")"

# Flutter 의존성 확인 및 설치
echo "📦 의존성 확인 중..."
flutter pub get

# 빌드 전 정리
echo "🧹 이전 빌드 정리 중..."
flutter clean

# Android APK 빌드
echo ""
echo "🤖 Android APK 빌드 중..."
flutter build apk --release

if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    echo "✅ Android 빌드 성공!"
    
    # Dropbox 폴더 생성 (없는 경우)
    DROPBOX_DIR="/Users/marcoskim/Dropbox/ACE_3_uversion"
    mkdir -p "$DROPBOX_DIR"
    
    # Be_Cool.apk로 이름 변경하여 Dropbox로 복사
    TARGET_FILE="$DROPBOX_DIR/Be_Cool.apk"
    cp "build/app/outputs/flutter-apk/app-release.apk" "$TARGET_FILE"
    
    echo "   원본 위치: $(pwd)/build/app/outputs/flutter-apk/app-release.apk"
    echo "   복사 위치: $TARGET_FILE"
    ls -lh "$TARGET_FILE"
    echo "   ✅ Be_Cool.apk 파일이 Dropbox로 복사되었습니다!"
else
    echo "❌ Android 빌드 실패!"
fi

# iOS 빌드 (macOS에서만 가능)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo ""
    echo "🍎 iOS 빌드 중..."
    cd ios
    pod install
    cd ..
    flutter build ios --release
    
    if [ -d "build/ios/iphoneos/Runner.app" ]; then
        echo "✅ iOS 빌드 성공!"
        echo "   위치: $(pwd)/build/ios/iphoneos/Runner.app"
    else
        echo "❌ iOS 빌드 실패!"
    fi
else
    echo ""
    echo "⚠️  iOS 빌드는 macOS에서만 가능합니다."
fi

# macOS 빌드 (macOS에서만 가능)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo ""
    echo "💻 macOS 빌드 중..."
    flutter build macos --release
    
    if [ -d "build/macos/Build/Products/Release/Be COOL.app" ] || [ -d "build/macos/Build/Products/Release/Runner.app" ]; then
        echo "✅ macOS 빌드 성공!"
        echo "   위치: $(pwd)/build/macos/Build/Products/Release/"
    else
        echo "❌ macOS 빌드 실패!"
    fi
else
    echo ""
    echo "⚠️  macOS 빌드는 macOS에서만 가능합니다."
fi

echo ""
echo "🎉 빌드 완료!"

