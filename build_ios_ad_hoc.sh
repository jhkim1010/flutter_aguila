#!/bin/bash

# iOS Ad Hoc 배포용 IPA 빌드 스크립트
# 이 스크립트는 Ad Hoc 배포용 IPA를 생성합니다.
# 설치하려는 iPhone의 UDID가 Apple Developer에 등록되어 있어야 합니다.

set -e

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  iOS Ad Hoc IPA 빌드 스크립트${NC}"
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
echo "   1. 설치하려는 iPhone의 UDID가 Apple Developer에 등록되어 있어야 합니다."
echo "   2. Xcode에서 Development Team이 설정되어 있어야 합니다."
echo "   3. Ad Hoc 프로비저닝 프로파일이 생성되어 있어야 합니다."
echo ""
echo -e "${BLUE}계속하려면 Enter를 누르세요...${NC}"
read

# Xcode에서 Archive 생성
echo ""
echo -e "${GREEN}🔨 Xcode에서 Archive 생성 중...${NC}"
echo -e "${YELLOW}   Xcode가 열리면 Product > Archive를 실행하세요.${NC}"
echo ""

# Xcode 열기
open ios/Runner.xcworkspace

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  다음 단계:${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "1. Xcode에서:"
echo "   - 상단 메뉴: Product > Archive"
echo "   - Archive 완료 대기"
echo ""
echo "2. Organizer 창에서:"
echo "   - 'Distribute App' 버튼 클릭"
echo "   - 'Ad Hoc' 선택 ⚠️ 중요!"
echo "   - 'Next' 클릭"
echo "   - 'Automatically manage signing' 선택"
echo "   - 'Next' 클릭"
echo "   - 'Export' 클릭"
echo "   - 저장 위치 선택 (예: Desktop)"
echo ""
echo "3. 생성된 IPA 파일을 iPhone에 설치:"
echo "   - Finder에서 iPhone 연결"
echo "   - IPA 파일을 드래그 앤 드롭"
echo "   - 또는 AirDrop으로 전송"
echo ""
echo -e "${GREEN}또는 자동으로 IPA를 생성하려면 export_ipa.sh를 실행하세요:${NC}"
echo "   ./export_ipa.sh"
echo ""
