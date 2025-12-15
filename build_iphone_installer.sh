#!/bin/bash

# Flutter 앱 iPhone용 설치 파일(IPA) 생성 스크립트
# "Be COOL" 앱 iPhone용 IPA 파일 생성 및 Dropbox 자동 저장

set -e  # 에러 발생 시 중단

echo "🚀 Flutter iPhone 설치 파일 빌드 시작..."
echo "📱 앱 이름: Be COOL"
echo "🍎 플랫폼: iPhone/iOS"
echo "📦 출력 형식: IPA (Ad-Hoc)"
echo ""

# UTF-8 인코딩 설정
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Flutter 프로젝트 디렉토리로 이동
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# iOS에서만 실행 가능한지 확인
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ iOS 빌드는 macOS에서만 가능합니다."
    exit 1
fi

# 앱 정보
APP_NAME="Be COOL"
VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | sed 's/+.*//')
BUILD_NUMBER=$(grep '^version:' pubspec.yaml | sed 's/.*+//')
IPA_NAME="Be_COOL_iPhone_v${VERSION}_${BUILD_NUMBER}.ipa"

# Flutter 의존성 확인 및 설치
echo "📦 의존성 확인 중..."
flutter pub get

# iOS Pods 설치
echo "🍎 iOS Pods 설치 중..."
cd ios
if [ -f "Podfile" ]; then
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    pod install || echo "⚠️  Pod install 실패했지만 계속 진행합니다 (이미 설치되어 있을 수 있음)"
fi
cd ..

# 빌드 전 정리 (자동 스킵 - 필요시 수동으로 flutter clean 실행)
# echo "🧹 이전 빌드 정리 중..."
# flutter clean

# Release IPA 빌드 (Ad-Hoc)
echo "🔨 Release IPA 빌드 중 (Ad-Hoc)..."
echo "⚠️  코드 서명이 필요합니다."
echo ""

# IPA 빌드 시도
if flutter build ipa --release --export-method ad-hoc 2>&1 | tee /tmp/flutter_ios_build.log; then
    echo ""
    echo "✅ IPA 빌드 성공!"
else
    echo ""
    echo "⚠️  flutter build ipa 실패, 대체 방법 시도 중..."
    
    # 대체 방법: flutter build ios 후 수동 IPA 생성
    echo "🔨 flutter build ios 실행 중..."
    flutter build ios --release --no-codesign
    
    echo ""
    echo "⚠️  수동 IPA 생성을 위해 Xcode Archive가 필요합니다."
    echo "   다음 단계를 수행하세요:"
    echo ""
    echo "   1. Xcode에서 프로젝트 열기:"
    echo "      open ios/Runner.xcworkspace"
    echo ""
    echo "   2. Xcode 상단 메뉴: Product > Archive"
    echo ""
    echo "   3. Archive 완료 후 export_ipa.sh 실행:"
    echo "      ./export_ipa.sh ad-hoc"
    echo ""
    exit 1
fi

# 빌드 결과 확인
IPA_FILE=$(find build/ios/ipa -name "*.ipa" 2>/dev/null | head -1)

if [ -z "$IPA_FILE" ] || [ ! -f "$IPA_FILE" ]; then
    # 다른 위치 확인
    IPA_FILE=$(find build/ios -name "*.ipa" -type f 2>/dev/null | head -1)
fi

if [ -n "$IPA_FILE" ] && [ -f "$IPA_FILE" ]; then
    echo ""
    echo "✅ IPA 파일 발견!"
    echo "   위치: $IPA_FILE"
    echo ""
    
    # Dropbox 폴더로 자동 복사
    echo "☁️  Dropbox로 자동 복사 중..."
    DROPBOX_DIR="/Users/marcoskim/Dropbox/ACE_3_uversion"
    mkdir -p "$DROPBOX_DIR"
    
    TARGET_IPA="$DROPBOX_DIR/$IPA_NAME"
    cp "$IPA_FILE" "$TARGET_IPA"
    
    IPA_SIZE=$(du -h "$TARGET_IPA" | cut -f1)
    echo "✅ IPA 파일이 Dropbox로 복사되었습니다!"
    echo ""
    echo "📦 설치 파일 정보:"
    echo "   파일명: $IPA_NAME"
    echo "   위치: $TARGET_IPA"
    echo "   크기: $IPA_SIZE"
    echo ""
    echo "💡 다른 iPhone에 설치하는 방법:"
    echo ""
    echo "방법 1: Finder를 통한 설치 (권장)"
    echo "   1. USB 케이블로 iPhone을 Mac에 연결"
    echo "   2. Finder에서 iPhone 선택"
    echo "   3. IPA 파일을 Finder 창으로 드래그 앤 드롭"
    echo "   4. iPhone에서: 설정 > 일반 > VPN 및 기기 관리"
    echo "      > 개발자 앱에서 '신뢰' 선택"
    echo ""
    echo "방법 2: AirDrop을 통한 전송"
    echo "   1. Mac과 iPhone에서 AirDrop 활성화"
    echo "   2. IPA 파일을 AirDrop으로 전송"
    echo "   3. iPhone에서 파일을 받고 설치"
    echo "   4. 설정 > 일반 > VPN 및 기기 관리에서 신뢰"
    echo ""
    echo "방법 3: 이메일/클라우드 저장소 사용"
    echo "   1. IPA 파일을 이메일이나 클라우드에 업로드"
    echo "   2. iPhone에서 다운로드"
    echo "   3. 파일 앱에서 IPA 파일 열기"
    echo "   4. 설치 후 설정 > 일반 > VPN 및 기기 관리에서 신뢰"
    echo ""
    echo "⚠️  중요 사항:"
    echo "   - 설치하려는 iPhone의 UDID가 Apple Developer에 등록되어 있어야 합니다"
    echo "   - Ad-Hoc 프로비저닝 프로파일이 필요합니다"
    echo "   - Apple Developer 계정이 필요합니다 (팀 ID: W93P494PLH)"
    echo ""
    echo "📱 iPhone UDID 확인 방법:"
    echo "   - iPhone: 설정 > 일반 > 정보 > UDID 복사"
    echo "   - 또는 iTunes/Finder에서 연결된 iPhone의 UDID 확인"
    echo ""
    
    # Finder에서 IPA 파일 열기 (선택사항)
    read -p "📂 Finder에서 IPA 파일을 열까요? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open -R "$TARGET_IPA"
    fi
else
    echo ""
    echo "❌ IPA 파일을 찾을 수 없습니다!"
    echo ""
    echo "📋 문제 해결 방법:"
    echo "   1. Xcode에서 프로젝트 열기:"
    echo "      open ios/Runner.xcworkspace"
    echo ""
    echo "   2. Runner 프로젝트 선택 > Runner 타겟 선택"
    echo ""
    echo "   3. Signing & Capabilities 탭에서:"
    echo "      - Development Team 선택"
    echo "      - 'Automatically manage signing' 체크"
    echo "      - Bundle Identifier 확인"
    echo ""
    echo "   4. Xcode에서 직접 Archive 생성:"
    echo "      - Product > Archive"
    echo "      - Archive 완료 후 'Distribute App' 선택"
    echo "      - 'Ad Hoc' 선택"
    echo "      - Export하여 IPA 파일 생성"
    echo ""
    echo "빌드 로그: /tmp/flutter_ios_build.log"
    exit 1
fi

echo ""
echo "🎉 빌드 완료!"

