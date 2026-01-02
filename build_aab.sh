#!/bin/bash

# Google Play Store용 AAB (Android App Bundle) 빌드 스크립트

set -e

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  AAB 빌드 스크립트${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Flutter 프로젝트 디렉토리로 이동
cd "$(dirname "$0")"

# key.properties 파일 확인
if [ ! -f "android/key.properties" ]; then
    echo -e "${RED}❌ key.properties 파일을 찾을 수 없습니다.${NC}"
    echo ""
    echo "먼저 서명 키를 설정하세요:"
    echo "  ./setup_play_store.sh"
    exit 1
fi

# 빌드 날짜 주입
echo -e "${YELLOW}📅 빌드 날짜 주입 중...${NC}"
bash scripts/inject_build_date.sh

# Flutter 의존성 확인
echo -e "${YELLOW}📦 Flutter 의존성 확인 중...${NC}"
flutter pub get

# Release AAB 빌드
echo ""
echo -e "${GREEN}🔨 Release AAB 빌드 중...${NC}"
flutter build appbundle --release

# 빌드 결과 확인 (beCool.aab로 이름 변경됨)
AAB_FILE="build/app/outputs/bundle/release/beCool.aab"
ORIGINAL_AAB="build/app/outputs/bundle/release/app-release.aab"

# beCool.aab가 없으면 원본 파일 확인
if [ ! -f "$AAB_FILE" ] && [ -f "$ORIGINAL_AAB" ]; then
    echo -e "${YELLOW}⚠️  파일 이름 변경 중...${NC}"
    mv "$ORIGINAL_AAB" "$AAB_FILE"
fi

if [ -f "$AAB_FILE" ]; then
    echo ""
    echo -e "${GREEN}✅ AAB 빌드 성공!${NC}"
    echo ""
    echo "📦 파일 정보:"
    echo "   위치: $(pwd)/$AAB_FILE"
    echo "   크기: $(ls -lh "$AAB_FILE" | awk '{print $5}')"
    echo ""
    echo "📋 다음 단계:"
    echo "   1. Google Play Console 접속"
    echo "   2. 앱 선택 또는 새 앱 생성"
    echo "   3. 프로덕션 > 새 버전 만들기"
    echo "   4. AAB 파일 업로드: beCool.aab"
    echo ""
else
    echo ""
    echo -e "${RED}❌ AAB 빌드 실패${NC}"
    echo "   예상 위치: $AAB_FILE"
    exit 1
fi
