#!/bin/bash

# IPA Export Script
# 이 스크립트는 Archive 파일에서 IPA를 생성합니다.

set -e

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== IPA Export Script ===${NC}"

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

# Export Options Plist 생성
EXPORT_OPTIONS_PLIST="/tmp/ExportOptions.plist"
cat > "$EXPORT_OPTIONS_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>W93P494PLH</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>compileBitcode</key>
    <false/>
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
    echo ""
    echo "이제 이 IPA 파일을 iPad에 설치할 수 있습니다."
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
