#!/bin/bash

# Flutter 앱 iOS 빌드 스크립트
# "Be COOL" 앱 iPad용 설치 파일(IPA) 생성

echo "🚀 Flutter iOS 앱 빌드 시작..."
echo "📱 앱 이름: Be COOL"
echo "🍎 플랫폼: iPad/iOS"

# UTF-8 인코딩 설정
export LANG=en_US.UTF-8

# Flutter 프로젝트 디렉토리로 이동
cd "$(dirname "$0")"

# Flutter 의존성 확인 및 설치
echo "📦 의존성 확인 중..."
flutter pub get

# iOS Pods 설치
echo "🍎 iOS Pods 설치 중..."
cd ios
export LANG=en_US.UTF-8
pod install
cd ..

# Release IPA 빌드
echo "🔨 Release IPA 빌드 중..."
echo "⚠️  코드 서명이 필요합니다. Xcode에서 Development Team을 설정해주세요."
echo ""

# IPA 빌드 시도
flutter build ipa --release 2>&1 | tee /tmp/flutter_ios_build.log

# 빌드 결과 확인
IPA_FILE=$(find build/ios/ipa -name "*.ipa" 2>/dev/null | head -1)

if [ -n "$IPA_FILE" ] && [ -f "$IPA_FILE" ]; then
    echo ""
    echo "✅ IPA 빌드 성공!"
    echo ""
    
    # Dropbox 폴더 생성 (없는 경우)
    DROPBOX_DIR="/Users/marcoskim/Dropbox/ACE_3_uversion"
    mkdir -p "$DROPBOX_DIR"
    
    # Be_Cool.ipa로 이름 변경하여 Dropbox로 복사
    TARGET_FILE="$DROPBOX_DIR/Be_Cool.ipa"
    cp "$IPA_FILE" "$TARGET_FILE"
    
    echo "📦 설치 파일 위치:"
    echo "   원본: $IPA_FILE"
    echo "   복사: $TARGET_FILE"
    echo ""
    echo "📊 파일 정보:"
    ls -lh "$TARGET_FILE"
    echo ""
    echo "✅ Be_Cool.ipa 파일이 Dropbox로 복사되었습니다!"
    echo ""
    echo "💡 iPad에 설치하는 방법:"
    echo "   1. iTunes 또는 Finder를 통해 iPad에 연결"
    echo "   2. Be_Cool.ipa 파일을 iPad로 드래그 앤 드롭"
    echo "   3. 또는 Xcode > Window > Devices and Simulators에서 설치"
else
    echo ""
    echo "❌ IPA 빌드 실패!"
    echo ""
    echo "📋 문제 해결 방법:"
    echo "   1. Xcode에서 프로젝트 열기:"
    echo "      open ios/Runner.xcworkspace"
    echo ""
    echo "   2. Runner 프로젝트 선택 > Runner 타겟 선택"
    echo ""
    echo "   3. Signing & Capabilities 탭에서:"
    echo "      - Development Team 선택 (W93P494PLH)"
    echo "      - 'Automatically manage signing' 체크"
    echo "      - Bundle Identifier 확인 (com.coolsistema.becoolaguila)"
    echo ""
    echo "   4. Xcode에서 직접 Archive 생성:"
    echo "      - Product > Archive"
    echo "      - Archive 완료 후 'Distribute App' 선택"
    echo "      - 'Ad Hoc' 또는 'Development' 선택"
    echo "      - Export하여 IPA 파일 생성"
    echo ""
    echo "빌드 로그: /tmp/flutter_ios_build.log"
    exit 1
fi

