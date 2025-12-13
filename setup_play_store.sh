#!/bin/bash

# Google Play Store 배포를 위한 서명 키 설정 스크립트

set -e

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Google Play Store 배포 설정${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 키 저장소 디렉토리 생성
KEY_DIR="$HOME/android-keys"
mkdir -p "$KEY_DIR"

KEY_FILE="$KEY_DIR/upload-keystore.jks"

# 키 파일이 이미 존재하는지 확인
if [ -f "$KEY_FILE" ]; then
    echo -e "${YELLOW}⚠️  키 파일이 이미 존재합니다: $KEY_FILE${NC}"
    echo ""
    read -p "기존 키 파일을 덮어쓰시겠습니까? (y/N): " overwrite
    if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
        echo "취소되었습니다."
        exit 0
    fi
fi

echo -e "${GREEN}1단계: 서명 키 생성${NC}"
echo ""

# Java 경로 찾기 (Android Studio의 Java 우선 사용)
JAVA_HOME_PATH=""
KEYTOOL_PATH=""

# Android Studio의 Java 확인
if [ -d "/Applications/Android Studio.app/Contents/jbr/Contents/Home" ]; then
    JAVA_HOME_PATH="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
    KEYTOOL_PATH="$JAVA_HOME_PATH/bin/keytool"
elif [ -d "$HOME/Library/Android/sdk/jbr" ]; then
    JAVA_HOME_PATH="$HOME/Library/Android/sdk/jbr"
    KEYTOOL_PATH="$JAVA_HOME_PATH/bin/keytool"
fi

# Java 경로 설정
if [ -n "$JAVA_HOME_PATH" ] && [ -f "$KEYTOOL_PATH" ]; then
    export JAVA_HOME="$JAVA_HOME_PATH"
    export PATH="$JAVA_HOME/bin:$PATH"
    echo -e "${BLUE}✓ Android Studio의 Java 사용: $JAVA_HOME${NC}"
else
    # 시스템 keytool 사용 시도
    KEYTOOL_PATH="keytool"
    echo -e "${YELLOW}⚠️  Android Studio Java를 찾을 수 없습니다. 시스템 keytool을 사용합니다.${NC}"
fi

echo ""
echo "키 생성에 필요한 정보를 입력하세요:"
echo ""

# 키 생성
"$KEYTOOL_PATH" -genkey -v \
    -keystore "$KEY_FILE" \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -alias upload

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ 키 생성 완료!${NC}"
    echo "   위치: $KEY_FILE"
    echo ""
    
    # key.properties 파일 생성
    echo -e "${GREEN}2단계: key.properties 파일 생성${NC}"
    echo ""
    
    read -sp "키스토어 비밀번호 입력: " store_password
    echo ""
    read -sp "키 비밀번호 입력 (같으면 Enter): " key_password
    echo ""
    
    if [ -z "$key_password" ]; then
        key_password="$store_password"
    fi
    
    KEY_PROPERTIES="android/key.properties"
    
    cat > "$KEY_PROPERTIES" <<EOF
storePassword=$store_password
keyPassword=$key_password
keyAlias=upload
storeFile=$KEY_FILE
EOF
    
    echo ""
    echo -e "${GREEN}✅ key.properties 파일 생성 완료!${NC}"
    echo "   위치: $KEY_PROPERTIES"
    echo ""
    
    # .gitignore 확인
    if ! grep -q "key.properties" android/.gitignore 2>/dev/null; then
        echo "" >> android/.gitignore
        echo "# Google Play Store 서명 키" >> android/.gitignore
        echo "key.properties" >> android/.gitignore
        echo "*.jks" >> android/.gitignore
        echo "*.keystore" >> android/.gitignore
        echo -e "${GREEN}✅ .gitignore 업데이트 완료${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  다음 단계${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "1. android/app/build.gradle.kts 파일 수정 필요"
    echo "   (자동 수정 스크립트 실행: ./update_build_gradle.sh)"
    echo ""
    echo "2. Application ID 확인"
    echo "   현재: com.example.flutter_app"
    echo "   권장: com.coolsistema.becoolaguila"
    echo ""
    echo "3. AAB 빌드:"
    echo "   flutter build appbundle --release"
    echo ""
    echo "4. Google Play Console에 업로드"
    echo ""
    
else
    echo ""
    echo -e "${RED}❌ 키 생성 실패${NC}"
    exit 1
fi
