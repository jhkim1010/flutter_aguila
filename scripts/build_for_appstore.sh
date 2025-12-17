#!/bin/bash

# 앱 스토어 제출을 위한 빌드 스크립트

set -e

echo "🚀 앱 스토어 제출을 위한 빌드 시작..."

# Flutter 빌드
echo "📱 Flutter iOS Release 빌드 중..."
flutter build ipa --release

echo "✅ 빌드 완료!"
echo ""
echo "다음 단계:"
echo "1. Xcode에서 ios/Runner.xcworkspace 열기"
echo "2. Product > Archive 선택"
echo "3. Organizer에서 Distribute App 선택"
echo "4. App Store Connect에 업로드"

