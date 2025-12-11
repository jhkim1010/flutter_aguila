#!/bin/bash

# Flutter 앱 모든 플랫폼 빌드 스크립트
# "Be COOL" 앱 - Android, iOS (iPhone/iPad), macOS 설치 파일 생성

set -e  # 에러 발생 시 중단 (하지만 각 빌드는 독립적으로 처리)

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 변수 설정
APP_NAME="Be COOL"
DROPBOX_DIR="/Users/marcoskim/Dropbox/ACE_3_uversion"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Dropbox 디렉토리 생성
mkdir -p "$DROPBOX_DIR"

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}🚀 Flutter 앱 전체 플랫폼 빌드 시작${NC}"
echo -e "${BLUE}📱 앱 이름: $APP_NAME${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# 프로젝트 디렉토리로 이동
cd "$PROJECT_DIR"

# UTF-8 인코딩 설정
export LANG=en_US.UTF-8

# 빌드 결과 추적
BUILD_RESULTS=()

# ============================================================================
# 1. Android APK 빌드
# ============================================================================
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}📱 1/4 Android APK 빌드 시작...${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if flutter build apk --release 2>&1 | tee /tmp/flutter_android_build.log; then
    APK_FILE="build/app/outputs/flutter-apk/app-release.apk"
    if [ -f "$APK_FILE" ]; then
        TARGET_APK="$DROPBOX_DIR/Be_Cool.apk"
        cp "$APK_FILE" "$TARGET_APK"
        APK_SIZE=$(ls -lh "$TARGET_APK" | awk '{print $5}')
        echo ""
        echo -e "${GREEN}✅ Android APK 빌드 성공!${NC}"
        echo -e "   위치: $TARGET_APK"
        echo -e "   크기: $APK_SIZE"
        BUILD_RESULTS+=("✅ Android APK: 성공")
    else
        echo -e "${RED}❌ Android APK 파일을 찾을 수 없습니다.${NC}"
        BUILD_RESULTS+=("❌ Android APK: 실패")
    fi
else
    echo -e "${RED}❌ Android APK 빌드 실패${NC}"
    BUILD_RESULTS+=("❌ Android APK: 실패")
fi

# ============================================================================
# 2. iOS IPA 빌드 (iPhone/iPad 공통)
# ============================================================================
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}🍎 2/4 iOS IPA 빌드 시작 (iPhone/iPad 공통)...${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# iOS Pods 설치
if [ -d "ios" ]; then
    echo "📦 iOS Pods 설치 중..."
    cd ios
    pod install 2>&1 | grep -v "CocoaPods did not set the base configuration" || true
    cd ..
fi

# IPA 빌드 시도
if flutter build ipa --release 2>&1 | tee /tmp/flutter_ios_build.log; then
    # Archive가 생성되었는지 확인
    ARCHIVE_DIR="$HOME/Library/Developer/Xcode/Archives"
    LATEST_ARCHIVE=$(find "$ARCHIVE_DIR" -name "*.xcarchive" -type d -maxdepth 2 -newer "$PROJECT_DIR/build/ios/archive/Runner.xcarchive" 2>/dev/null | sort -r | head -1)
    
    if [ -z "$LATEST_ARCHIVE" ]; then
        LATEST_ARCHIVE=$(find "$ARCHIVE_DIR" -name "*.xcarchive" -type d -maxdepth 2 | sort -r | head -1)
    fi
    
    if [ -n "$LATEST_ARCHIVE" ] && [ -d "$LATEST_ARCHIVE" ]; then
        echo ""
        echo "📦 Archive에서 IPA 생성 중..."
        
        # Export Options Plist 생성
        EXPORT_OPTIONS_PLIST="/tmp/ExportOptions_$$.plist"
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
        
        # 임시 디렉토리에 IPA 생성
        TEMP_DIR="/tmp/ipa_export_$$"
        mkdir -p "$TEMP_DIR"
        
        if xcodebuild -exportArchive \
            -archivePath "$LATEST_ARCHIVE" \
            -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
            -exportPath "$TEMP_DIR" \
            -allowProvisioningUpdates 2>&1 | grep -v "Command line name" || true; then
            
            EXPORTED_IPA=$(find "$TEMP_DIR" -name "*.ipa" -type f | head -1)
            
            if [ -n "$EXPORTED_IPA" ] && [ -f "$EXPORTED_IPA" ]; then
                # iPhone용과 iPad용으로 복사 (실제로는 같은 파일)
                TARGET_IPA_IPHONE="$DROPBOX_DIR/Be_Cool_iPhone.ipa"
                TARGET_IPA_IPAD="$DROPBOX_DIR/Be_Cool_iPad.ipa"
                
                cp "$EXPORTED_IPA" "$TARGET_IPA_IPHONE"
                cp "$EXPORTED_IPA" "$TARGET_IPA_IPAD"
                
                IPA_SIZE=$(ls -lh "$TARGET_IPA_IPHONE" | awk '{print $5}')
                echo ""
                echo -e "${GREEN}✅ iOS IPA 빌드 성공!${NC}"
                echo -e "   iPhone용: $TARGET_IPA_IPHONE"
                echo -e "   iPad용: $TARGET_IPA_IPAD"
                echo -e "   크기: $IPA_SIZE"
                BUILD_RESULTS+=("✅ iOS IPA (iPhone/iPad): 성공")
                
                # 임시 파일 정리
                rm -rf "$TEMP_DIR"
                rm -f "$EXPORT_OPTIONS_PLIST"
            else
                echo -e "${RED}❌ IPA 파일 생성 실패${NC}"
                BUILD_RESULTS+=("❌ iOS IPA: 실패 (IPA 생성 실패)")
                rm -rf "$TEMP_DIR"
                rm -f "$EXPORT_OPTIONS_PLIST"
            fi
        else
            echo -e "${RED}❌ Archive Export 실패${NC}"
            BUILD_RESULTS+=("❌ iOS IPA: 실패 (Export 실패)")
            rm -rf "$TEMP_DIR"
            rm -f "$EXPORT_OPTIONS_PLIST"
        fi
    else
        echo -e "${RED}❌ Archive 파일을 찾을 수 없습니다.${NC}"
        BUILD_RESULTS+=("❌ iOS IPA: 실패 (Archive 없음)")
    fi
else
    echo -e "${RED}❌ iOS Archive 빌드 실패${NC}"
    BUILD_RESULTS+=("❌ iOS IPA: 실패 (빌드 실패)")
fi

# ============================================================================
# 3. macOS .app 빌드
# ============================================================================
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}💻 3/4 macOS .app 빌드 시작...${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# macOS에서만 실행 가능
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS Pods 설치
    if [ -d "macos" ]; then
        echo "📦 macOS Pods 설치 중..."
        cd macos
        pod install 2>&1 | grep -v "CocoaPods did not set the base configuration" || true
        cd ..
    fi
    
    if flutter build macos --release 2>&1 | tee /tmp/flutter_macos_build.log; then
        # 빌드 완료 후 잠시 대기 (파일 시스템 동기화)
        sleep 2
        
        # 프로젝트 디렉토리로 이동 (확실하게)
        cd "$PROJECT_DIR"
        
        # 여러 가능한 파일명 확인 (절대 경로 사용)
        APP_BUNDLE=""
        if [ -d "$PROJECT_DIR/build/macos/Build/Products/Release/Be_Cool.app" ]; then
            APP_BUNDLE="$PROJECT_DIR/build/macos/Build/Products/Release/Be_Cool.app"
        elif [ -d "$PROJECT_DIR/build/macos/Build/Products/Release/Be COOL.app" ]; then
            APP_BUNDLE="$PROJECT_DIR/build/macos/Build/Products/Release/Be COOL.app"
        elif [ -d "$PROJECT_DIR/build/macos/Build/Products/Release/Runner.app" ]; then
            APP_BUNDLE="$PROJECT_DIR/build/macos/Build/Products/Release/Runner.app"
        fi
        
        if [ -n "$APP_BUNDLE" ] && [ -d "$APP_BUNDLE" ]; then
            TARGET_APP="$DROPBOX_DIR/Be_COOL_macOS.app"
            if [ -d "$TARGET_APP" ]; then
                rm -rf "$TARGET_APP"
            fi
            cp -R "$APP_BUNDLE" "$TARGET_APP"
            
            APP_SIZE=$(du -sh "$TARGET_APP" | awk '{print $1}')
            echo ""
            echo -e "${GREEN}✅ macOS .app 빌드 성공!${NC}"
            echo -e "   원본: $APP_BUNDLE"
            echo -e "   위치: $TARGET_APP"
            echo -e "   크기: $APP_SIZE"
            BUILD_RESULTS+=("✅ macOS .app: 성공")
        else
            echo -e "${RED}❌ macOS .app 파일을 찾을 수 없습니다.${NC}"
            echo -e "   프로젝트 디렉토리: $PROJECT_DIR"
            echo -e "   확인한 경로:"
            echo -e "   - $PROJECT_DIR/build/macos/Build/Products/Release/Be_Cool.app"
            echo -e "   - $PROJECT_DIR/build/macos/Build/Products/Release/Be COOL.app"
            echo -e "   - $PROJECT_DIR/build/macos/Build/Products/Release/Runner.app"
            echo ""
            echo -e "   실제 파일 목록:"
            ls -la "$PROJECT_DIR/build/macos/Build/Products/Release/"*.app 2>/dev/null || echo "   (파일 없음)"
            BUILD_RESULTS+=("❌ macOS .app: 실패")
        fi
    else
        echo -e "${RED}❌ macOS 빌드 실패${NC}"
        BUILD_RESULTS+=("❌ macOS .app: 실패")
    fi
else
    echo -e "${YELLOW}⚠️  macOS 빌드는 macOS에서만 가능합니다.${NC}"
    BUILD_RESULTS+=("⚠️  macOS .app: 건너뜀 (비-macOS 환경)")
fi

# ============================================================================
# 빌드 결과 요약
# ============================================================================
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}📊 빌드 결과 요약${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

for result in "${BUILD_RESULTS[@]}"; do
    echo -e "   $result"
done

echo ""
echo -e "${BLUE}📦 생성된 파일 위치:${NC}"
echo -e "   $DROPBOX_DIR"
echo ""

# 생성된 파일 목록 표시
echo -e "${BLUE}📋 생성된 파일 목록:${NC}"
ls -lh "$DROPBOX_DIR"/Be_Cool* 2>/dev/null | awk '{print "   " $9 " (" $5 ")"}' || echo "   파일을 찾을 수 없습니다."

echo ""
echo -e "${GREEN}✅ 빌드 프로세스 완료!${NC}"
echo ""
