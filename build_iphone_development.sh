#!/bin/bash

# Development 배포용 IPA 생성 스크립트
# Apple Developer Program 없이 Mac에 연결된 iPhone에 설치 가능

set -e

echo "📱 iPhone Development 배포용 IPA 생성..."
echo "⚠️  이 방법은 Mac에 연결된 iPhone에만 설치 가능합니다"
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Archive 파일 확인
ARCHIVE_PATH="build/ios/archive/Runner.xcarchive"

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "❌ Archive 파일을 찾을 수 없습니다."
    echo "먼저 Archive를 생성하세요:"
    echo "  ./build_iphone_installer.sh"
    exit 1
fi

echo "✅ Archive 파일 발견: $ARCHIVE_PATH"
echo ""

# Export Options Plist 생성 (Development)
EXPORT_OPTIONS_PLIST="/tmp/ExportOptions_development.plist"
cat > "$EXPORT_OPTIONS_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>compileBitcode</key>
    <false/>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <false/>
</dict>
</plist>
EOF

echo "📦 Export Options 생성 완료 (Development)"
echo ""

# 출력 디렉토리
OUTPUT_DIR="build/ios/ipa_development"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# IPA Export 시도
echo "🔨 Development IPA Export 중..."
echo ""

if xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
    -exportPath "$OUTPUT_DIR" \
    -allowProvisioningUpdates 2>&1 | tee /tmp/xcode_export_dev.log; then
    
    # 생성된 IPA 파일 찾기
    IPA_FILE=$(find "$OUTPUT_DIR" -name "*.ipa" -type f | head -1)
    
    if [ -n "$IPA_FILE" ] && [ -f "$IPA_FILE" ]; then
        echo ""
        echo "✅ Development IPA 파일 생성 성공!"
        echo ""
        
        # 파일명 변경
        VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | sed 's/+.*//')
        BUILD_NUMBER=$(grep '^version:' pubspec.yaml | sed 's/.*+//')
        IPA_NAME="Be_COOL_iPhone_Development_v${VERSION}_${BUILD_NUMBER}.ipa"
        
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
        echo "⚠️  중요: Development 배포는 Mac에 연결된 iPhone에만 설치 가능합니다"
        echo ""
        echo "💡 설치 방법:"
        echo "   1. iPhone을 Mac에 USB로 연결"
        echo "   2. Finder에서 iPhone 선택"
        echo "   3. IPA 파일을 Finder 창으로 드래그 앤 드롭"
        echo "   4. iPhone에서: 설정 > 일반 > VPN 및 기기 관리 > 개발자 앱 신뢰"
        echo ""
        echo "⚠️  참고:"
        echo "   - 이 IPA는 7일 후 만료됩니다"
        echo "   - 다른 iPhone에 설치하려면 Apple Developer Program 가입 필요 ($99/년)"
        echo ""
        
        # Finder에서 열기
        open -R "$TARGET_IPA"
    else
        echo ""
        echo "⚠️  IPA 파일을 찾을 수 없습니다."
    fi
else
    echo ""
    echo "❌ Development IPA Export 실패"
    echo ""
    echo "Xcode Organizer를 사용하여 수동으로 Export하세요:"
    echo "   1. Xcode Organizer 열기: open build/ios/archive/Runner.xcarchive"
    echo "   2. 'Distribute App' 클릭"
    echo "   3. 'Debugging' 선택"
    echo "   4. 'Development' 선택"
    echo ""
    echo "빌드 로그: /tmp/xcode_export_dev.log"
fi

# 임시 파일 정리
rm -f "$EXPORT_OPTIONS_PLIST"

echo ""
echo "🎉 완료!"

