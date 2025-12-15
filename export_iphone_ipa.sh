#!/bin/bash

# Archive에서 IPA 파일을 자동으로 Export하는 스크립트
# Xcode Organizer를 사용하여 IPA 생성

set -e

echo "📱 iPhone용 IPA Export 시작..."
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Archive 파일 확인
ARCHIVE_PATH="build/ios/archive/Runner.xcarchive"

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "❌ Archive 파일을 찾을 수 없습니다: $ARCHIVE_PATH"
    echo ""
    echo "먼저 Archive를 생성하세요:"
    echo "  ./build_iphone_installer.sh"
    exit 1
fi

echo "✅ Archive 파일 발견: $ARCHIVE_PATH"
echo ""

# Export Options Plist 생성
EXPORT_OPTIONS_PLIST="/tmp/ExportOptions_iphone.plist"
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
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.coolsistema.becoolaguila</key>
        <string></string>
    </dict>
</dict>
</plist>
EOF

echo "📦 Export Options 생성 완료"
echo ""

# 출력 디렉토리
OUTPUT_DIR="build/ios/ipa_export"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# IPA Export 시도
echo "🔨 IPA Export 중..."
echo "   Archive: $ARCHIVE_PATH"
echo "   출력: $OUTPUT_DIR"
echo ""

if xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
    -exportPath "$OUTPUT_DIR" \
    -allowProvisioningUpdates 2>&1 | tee /tmp/xcode_export.log; then
    
    # 생성된 IPA 파일 찾기
    IPA_FILE=$(find "$OUTPUT_DIR" -name "*.ipa" -type f | head -1)
    
    if [ -n "$IPA_FILE" ] && [ -f "$IPA_FILE" ]; then
        echo ""
        echo "✅ IPA 파일 생성 성공!"
        echo ""
        
        # 파일명 변경
        VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | sed 's/+.*//')
        BUILD_NUMBER=$(grep '^version:' pubspec.yaml | sed 's/.*+//')
        IPA_NAME="Be_COOL_iPhone_v${VERSION}_${BUILD_NUMBER}.ipa"
        
        # Dropbox로 복사
        DROPBOX_DIR="/Users/marcoskim/Dropbox/ACE_3_uversion"
        mkdir -p "$DROPBOX_DIR"
        
        TARGET_IPA="$DROPBOX_DIR/$IPA_NAME"
        cp "$IPA_FILE" "$TARGET_IPA"
        
        IPA_SIZE=$(du -h "$TARGET_IPA" | cut -f1)
        
        echo "📦 설치 파일 정보:"
        echo "   파일명: $IPA_NAME"
        echo "   위치: $TARGET_IPA"
        echo "   크기: $IPA_SIZE"
        echo ""
        echo "💡 다른 iPhone에 설치하는 방법:"
        echo "   1. Finder에서 iPhone 연결"
        echo "   2. IPA 파일을 iPhone으로 드래그 앤 드롭"
        echo "   3. iPhone에서: 설정 > 일반 > VPN 및 기기 관리 > 개발자 앱 신뢰"
        echo ""
        
        # Finder에서 열기
        open -R "$TARGET_IPA"
    else
        echo ""
        echo "⚠️  IPA 파일을 찾을 수 없습니다."
        echo "   Xcode Organizer를 사용하여 수동으로 Export하세요:"
        echo "   open build/ios/archive/Runner.xcarchive"
    fi
else
    echo ""
    echo "⚠️  자동 Export 실패"
    echo ""
    echo "📋 Xcode Organizer를 사용하여 수동으로 Export하세요:"
    echo ""
    echo "   1. Xcode Organizer 열기:"
    echo "      open build/ios/archive/Runner.xcarchive"
    echo ""
    echo "   2. 또는 Xcode에서:"
    echo "      Window > Organizer > Archives 탭"
    echo ""
    echo "   3. Archive 선택 > 'Distribute App' 클릭"
    echo ""
    echo "   4. 'Ad Hoc' 선택 > Next"
    echo ""
    echo "   5. Export 위치 선택 > Export"
    echo ""
    echo "빌드 로그: /tmp/xcode_export.log"
fi

# 임시 파일 정리
rm -f "$EXPORT_OPTIONS_PLIST"

echo ""
echo "🎉 완료!"

