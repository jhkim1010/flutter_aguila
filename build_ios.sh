#!/bin/bash

# Flutter 앱 iOS 빌드 스크립트
# "Be COOL" 앱 설치 파일 생성

echo "🚀 Flutter iOS 앱 빌드 시작..."
echo "📱 앱 이름: Be COOL"

# Flutter 프로젝트 디렉토리로 이동
cd "$(dirname "$0")"

# Flutter 의존성 확인 및 설치
echo "📦 의존성 확인 중..."
flutter pub get

# iOS Pods 설치
echo "🍎 iOS Pods 설치 중..."
cd ios
pod install
cd ..

# 빌드 전 정리
echo "🧹 이전 빌드 정리 중..."
flutter clean

# Release iOS 빌드
echo "🔨 Release iOS 빌드 중..."
flutter build ios --release

# 빌드 결과 확인
if [ -d "build/ios/iphoneos/Runner.app" ]; then
    echo "✅ 빌드 성공!"
    echo "📦 앱 번들 위치:"
    echo "   $(pwd)/build/ios/iphoneos/Runner.app"
    echo ""
    echo "💡 IPA 파일을 생성하려면 Xcode를 사용하거나 다음 명령어를 실행하세요:"
    echo "   flutter build ipa"
else
    echo "❌ 빌드 실패!"
    exit 1
fi

