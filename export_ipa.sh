#!/bin/bash

# IPA Export Script
# 이 스크립트는 Archive 파일에서 IPA를 생성합니다.
# 사용법: ./export_ipa.sh [ad-hoc|development|app-store]

set -e

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 배포 방법 선택 (기본값: ad-hoc)
METHOD="${1:-ad-hoc}"

# 유효한 방법 확인
if [[ ! "$METHOD" =~ ^(ad-hoc|development|app-store)$ ]]; then
    echo -e "${RED}❌ 잘못된 배포 방법: $METHOD${NC}"
    echo "사용법: ./export_ipa.sh [ad-hoc|development|app-store]"
    echo "  ad-hoc: 특정 기기에만 설치 가능 (기기 UDID 등록 필요)"
    echo "  development: 개발용 (연결된 기기에만)"
    echo "  app-store: App Store Connect 업로드용"
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  IPA Export Script${NC}"
echo -e "${BLUE}  배포 방법: $METHOD${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 최신 Archive 파일 찾기
ARCHIVE_DIR="$HOME/Library/Developer/Xcode/Archives"
LATEST_ARCHIVE=$(find "$ARCHIVE_DIR" -name "*.xcarchive" -type d -maxdepth 2 | sort -r | head -1)

if [ -z "$LATEST_ARCHIVE" ]; then
    echo -e "${RED}❌ Archive 파일을 찾을 수 없습니다.${NC}"
    echo "먼저 Xcode에서 Product > Archive를 실행하세요."
    exit 1
fi

echo -e "${GREEN}✓ Archive 파일 발견:${NC}"
echo "  $LATEST_ARCHIVE"
echo ""

# Ad Hoc 배포 시 경고
if [ "$METHOD" = "ad-hoc" ]; then
    echo -e "${YELLOW}⚠️  Ad Hoc 배포 주의사항:${NC}"
    echo "   - 설치하려는 iPhone의 UDID가 Apple Developer에 등록되어 있어야 합니다."
    echo "   - Ad Hoc 프로비저닝 프로파일이 생성되어 있어야 합니다."
    echo ""
fi

# Export Options Plist 생성
EXPORT_OPTIONS_PLIST="/tmp/ExportOptions.plist"
cat > "$EXPORT_OPTIONS_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>$METHOD</string>
    <key>teamID</key>
    <string>W93P494PLH</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>compileBitcode</key>
    <false/>
EOF

# Ad Hoc의 경우 추가 옵션
if [ "$METHOD" = "ad-hoc" ]; then
    cat >> "$EXPORT_OPTIONS_PLIST" <<EOF
    <key>provisioningProfiles</key>
    <dict>
        <key>com.coolsistema.becoolaguila</key>
        <string></string>
    </dict>
EOF
fi

cat >> "$EXPORT_OPTIONS_PLIST" <<EOF
</dict>
</plist>
EOF

echo -e "${GREEN}✓ Export Options Plist 생성 완료${NC}"

# 출력 디렉토리 설정 (Dropbox - Android APK와 같은 폴더)
DROPBOX_DIR="$HOME/Dropbox/ACE_3_uversion"
mkdir -p "$DROPBOX_DIR"

if [ ! -d "$DROPBOX_DIR" ]; then
    echo -e "${YELLOW}⚠️  Dropbox 폴더를 찾을 수 없습니다. Desktop에 생성합니다.${NC}"
    OUTPUT_DIR="$HOME/Desktop"
else
    OUTPUT_DIR="$DROPBOX_DIR"
fi

IPA_NAME="Be_Cool.ipa"

echo ""
echo -e "${YELLOW}IPA를 생성합니다...${NC}"
echo "  Archive: $LATEST_ARCHIVE"
echo "  출력: $OUTPUT_DIR/$IPA_NAME"
echo ""

# 임시 디렉토리에 먼저 생성
TEMP_DIR="/tmp/ipa_export_$$"
mkdir -p "$TEMP_DIR"

# IPA 생성
xcodebuild -exportArchive \
    -archivePath "$LATEST_ARCHIVE" \
    -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
    -exportPath "$TEMP_DIR" \
    -allowProvisioningUpdates

# 생성된 IPA 파일 찾기
EXPORTED_IPA=$(find "$TEMP_DIR" -name "*.ipa" -type f | head -1)

if [ -n "$EXPORTED_IPA" ]; then
    # Dropbox로 이동
    mv "$EXPORTED_IPA" "$OUTPUT_DIR/$IPA_NAME"
    
    echo ""
    echo -e "${GREEN}✅ IPA 파일 생성 완료!${NC}"
    echo "  위치: $OUTPUT_DIR/$IPA_NAME"
    echo "  배포 방법: $METHOD"
    echo ""
    
    if [ "$METHOD" = "ad-hoc" ]; then
        echo -e "${BLUE}iPhone에 설치하는 방법:${NC}"
        echo "  1. Finder에서 iPhone 연결"
        echo "  2. IPA 파일을 드래그 앤 드롭"
        echo "  3. 또는 AirDrop으로 전송 후 설치"
        echo ""
        echo -e "${YELLOW}⚠️  설치가 안 되면:${NC}"
        echo "  - iPhone의 UDID가 Apple Developer에 등록되어 있는지 확인"
        echo "  - Ad Hoc 프로비저닝 프로파일이 생성되어 있는지 확인"
        echo "  - 설정 > 일반 > VPN 및 기기 관리에서 개발자 인증서 신뢰"
    elif [ "$METHOD" = "development" ]; then
        echo -e "${BLUE}개발 기기에 설치하는 방법:${NC}"
        echo "  1. iPhone을 Mac에 USB로 연결"
        echo "  2. Xcode > Window > Devices and Simulators"
        echo "  3. IPA 파일 드래그 앤 드롭"
    elif [ "$METHOD" = "app-store" ]; then
        echo -e "${BLUE}App Store Connect에 업로드:${NC}"
        echo "  - 이 IPA는 App Store Connect에 업로드하거나 TestFlight에 사용됩니다"
        echo "  - 직접 설치할 수 없습니다"
    fi
    echo ""
else
    echo -e "${RED}❌ IPA 파일 생성 실패${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# 임시 디렉토리 정리
rm -rf "$TEMP_DIR"

# 임시 파일 정리
rm -f "$EXPORT_OPTIONS_PLIST"
