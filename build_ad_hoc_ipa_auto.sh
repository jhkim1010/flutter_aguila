#!/bin/bash

# Ad Hoc 배포용 IPA 완전 자동 빌드 스크립트
# 이 스크립트는 Flutter 빌드부터 IPA 생성까지 완전 자동으로 수행합니다.

set -e

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Ad Hoc IPA 완전 자동 빌드${NC}"
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
echo "   2. Xcode에서 Development Team (W93P494PLH)이 설정되어 있어야 합니다."
echo "   3. Xcode에서 'Automatically manage signing'이 활성화되어 있어야 합니다."
echo ""

# Flutter iOS 빌드 (Release)
echo -e "${GREEN}🔨 Flutter iOS 빌드 중 (Release)...${NC}"
flutter build ios --release --no-codesign

# Archive 생성
echo ""
echo -e "${GREEN}📦 Xcode Archive 생성 중...${NC}"
echo "   이 작업은 몇 분이 소요될 수 있습니다..."
echo ""

# Archive 생성
xcodebuild archive \
    -workspace ios/Runner.xcworkspace \
    -scheme Runner \
    -configuration Release \
    -archivePath build/ios/archive/Runner.xcarchive \
    -allowProvisioningUpdates \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO 2>&1 | tee /tmp/xcode_archive.log

# Archive 파일 확인
ARCHIVE_PATH="build/ios/archive/Runner.xcarchive"

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo ""
    echo -e "${RED}❌ Archive 생성 실패${NC}"
    echo ""
    echo -e "${YELLOW}대안: Xcode에서 수동으로 Archive 생성${NC}"
    echo "   1. Xcode 열기: open ios/Runner.xcworkspace"
    echo "   2. Product > Archive 실행"
    echo "   3. Archive 완료 후 export_ipa.sh ad-hoc 실행"
    echo ""
    echo "빌드 로그: /tmp/xcode_archive.log"
    exit 1
fi

echo -e "${GREEN}✓ Archive 생성 완료${NC}"
echo "  위치: $ARCHIVE_PATH"
echo ""

# Ad Hoc IPA 생성
echo -e "${GREEN}📦 Ad Hoc IPA 생성 중...${NC}"

# Export Options Plist 생성
EXPORT_OPTIONS_PLIST="/tmp/ExportOptions_AdHoc.plist"
cat > "$EXPORT_OPTIONS_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>ad-hoc</string>
    <key>teamID</key>
    <string>W93P494PLH</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
EOF

# 출력 디렉토리 설정
DROPBOX_DIR="$HOME/Dropbox/ACE_3_uversion"
mkdir -p "$DROPBOX_DIR"

if [ ! -d "$DROPBOX_DIR" ]; then
    OUTPUT_DIR="$HOME/Desktop"
else
    OUTPUT_DIR="$DROPBOX_DIR"
fi

IPA_NAME="Be_Cool_AdHoc.ipa"

# 임시 디렉토리
TEMP_DIR="/tmp/ipa_export_$$"
mkdir -p "$TEMP_DIR"

# IPA 생성
echo "   Archive에서 IPA 추출 중..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
    -exportPath "$TEMP_DIR" \
    -allowProvisioningUpdates 2>&1 | tee /tmp/xcode_export.log

# 생성된 IPA 파일 찾기
EXPORTED_IPA=$(find "$TEMP_DIR" -name "*.ipa" -type f | head -1)

if [ -n "$EXPORTED_IPA" ]; then
    # 출력 디렉토리로 이동
    mv "$EXPORTED_IPA" "$OUTPUT_DIR/$IPA_NAME"
    
    echo ""
    echo -e "${GREEN}✅ Ad Hoc IPA 파일 생성 완료!${NC}"
    echo ""
    echo -e "${BLUE}파일 정보:${NC}"
    echo "  위치: $OUTPUT_DIR/$IPA_NAME"
    echo "  크기: $(ls -lh "$OUTPUT_DIR/$IPA_NAME" | awk '{print $5}')"
    echo ""
    echo -e "${BLUE}iPhone에 설치하는 방법:${NC}"
    echo "  1. Finder에서 iPhone 연결"
    echo "  2. IPA 파일을 드래그 앤 드롭"
    echo "  3. 또는 AirDrop으로 전송 후 설치"
    echo ""
    echo -e "${YELLOW}⚠️  설치가 안 되면:${NC}"
    echo "  - iPhone의 UDID가 Apple Developer에 등록되어 있는지 확인"
    echo "  - Ad Hoc 프로비저닝 프로파일이 생성되어 있는지 확인"
    echo "  - 설정 > 일반 > VPN 및 기기 관리에서 개발자 인증서 신뢰"
    echo ""
else
    echo ""
    echo -e "${RED}❌ IPA 파일 생성 실패${NC}"
    echo ""
    echo -e "${YELLOW}대안: Xcode에서 수동으로 Export${NC}"
    echo "   1. Xcode 열기: open ios/Runner.xcworkspace"
    echo "   2. Product > Archive 실행"
    echo "   3. Organizer에서 'Distribute App' 클릭"
    echo "   4. 'Ad Hoc' 선택 후 Export"
    echo ""
    echo "Export 로그: /tmp/xcode_export.log"
    rm -rf "$TEMP_DIR"
    rm -f "$EXPORT_OPTIONS_PLIST"
    exit 1
fi

# 임시 디렉토리 정리
rm -rf "$TEMP_DIR"
rm -f "$EXPORT_OPTIONS_PLIST"

echo -e "${GREEN}✅ 완료!${NC}"
