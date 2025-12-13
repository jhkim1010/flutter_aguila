#!/bin/bash

# Ad Hoc 배포용 IPA 자동 빌드 스크립트
# 이 스크립트는 Flutter 빌드부터 IPA 생성까지 자동으로 수행합니다.

set -e

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Ad Hoc IPA 자동 빌드 스크립트${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Flutter 프로젝트 디렉토리로 이동
cd "$(dirname "$0")"

# Flutter 의존성 확인
echo -e "${YELLOW}📦 Flutter 의존성 확인 중...${NC}"
flutter pub get

# iOS Pods 설치
echo -e "${YELLOW}🍎 iOS Pods 설치 중...${NC}"
cd ios
pod install
cd ..

# Xcode 프로젝트 확인
if [ ! -d "ios/Runner.xcworkspace" ]; then
    echo -e "${RED}❌ ios/Runner.xcworkspace를 찾을 수 없습니다.${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}⚠️  중요 사항:${NC}"
echo "   Ad Hoc 배포를 위해서는:"
echo "   1. 설치하려는 iPhone의 UDID가 Apple Developer에 등록되어 있어야 합니다."
echo "   2. Xcode에서 Development Team이 설정되어 있어야 합니다."
echo "   3. Xcode에서 'Automatically manage signing'이 활성화되어 있어야 합니다."
echo ""

# Xcode에서 Archive 생성
echo -e "${GREEN}🔨 Xcode에서 Archive 생성 중...${NC}"
echo -e "${YELLOW}   Xcode가 열리면 다음 단계를 수행하세요:${NC}"
echo ""
echo "   1. Xcode 상단 메뉴: Product > Archive"
echo "   2. Archive 완료 대기 (몇 분 소요)"
echo "   3. Archive 완료 후 이 스크립트로 돌아와서 Enter를 누르세요"
echo ""

# Xcode 열기
open ios/Runner.xcworkspace

echo ""
echo -e "${BLUE}Archive가 완료되면 Enter를 누르세요...${NC}"
read

# Archive 파일 확인
ARCHIVE_DIR="$HOME/Library/Developer/Xcode/Archives"
LATEST_ARCHIVE=$(find "$ARCHIVE_DIR" -name "*.xcarchive" -type d -maxdepth 2 | sort -r | head -1)

if [ -z "$LATEST_ARCHIVE" ]; then
    echo -e "${RED}❌ Archive 파일을 찾을 수 없습니다.${NC}"
    echo "Xcode에서 Product > Archive를 실행했는지 확인하세요."
    exit 1
fi

echo -e "${GREEN}✓ Archive 파일 발견:${NC}"
echo "  $LATEST_ARCHIVE"
echo ""

# Ad Hoc IPA 생성
echo -e "${GREEN}📦 Ad Hoc IPA 생성 중...${NC}"
./export_ipa.sh ad-hoc

echo ""
echo -e "${GREEN}✅ 완료!${NC}"
echo ""
echo -e "${BLUE}다음 단계:${NC}"
echo "  1. 생성된 IPA 파일 위치 확인 (Dropbox 또는 Desktop)"
echo "  2. iPhone에 설치:"
echo "     - Finder에서 iPhone 연결"
echo "     - IPA 파일을 드래그 앤 드롭"
echo "     - 또는 AirDrop으로 전송"
echo ""
echo -e "${YELLOW}⚠️  설치가 안 되면:${NC}"
echo "  - iPhone의 UDID가 Apple Developer에 등록되어 있는지 확인"
echo "  - 설정 > 일반 > VPN 및 기기 관리에서 개발자 인증서 신뢰"
echo ""
