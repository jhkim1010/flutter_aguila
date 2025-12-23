#!/bin/bash

# 키스토어의 SHA1 지문 확인 스크립트

echo "=========================================="
echo "키스토어 SHA1 지문 확인"
echo "=========================================="
echo ""

KEYSTORE_FILE="$1"

if [ -z "$KEYSTORE_FILE" ]; then
    echo "사용법: $0 <키스토어_파일_경로>"
    echo ""
    echo "예시:"
    echo "  $0 ~/android-keys/upload-keystore.jks"
    echo "  $0 ~/android-keys/upload-keystore.jks.backup"
    exit 1
fi

if [ ! -f "$KEYSTORE_FILE" ]; then
    echo "❌ 파일을 찾을 수 없습니다: $KEYSTORE_FILE"
    exit 1
fi

echo "키스토어 파일: $KEYSTORE_FILE"
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
    echo "✓ Android Studio의 Java 사용: $JAVA_HOME"
else
    # 시스템 keytool 사용 시도
    KEYTOOL_PATH="keytool"
    echo "⚠️  Android Studio Java를 찾을 수 없습니다. 시스템 keytool을 사용합니다."
fi

echo ""

# key.properties에서 비밀번호 읽기 시도
STORE_PASSWORD=""
if [ -f "android/key.properties" ]; then
    STORE_PASSWORD=$(grep "^storePassword=" android/key.properties | cut -d'=' -f2)
fi

if [ -z "$STORE_PASSWORD" ]; then
    echo "비밀번호를 입력하세요 (입력 내용은 표시되지 않습니다):"
    read -s STORE_PASSWORD
    echo ""
fi

echo "SHA1 지문 확인 중..."
echo ""

# SHA1 지문 확인
SHA1_OUTPUT=$("$KEYTOOL_PATH" -list -v -keystore "$KEYSTORE_FILE" -alias upload -storepass "$STORE_PASSWORD" 2>&1)

if echo "$SHA1_OUTPUT" | grep -q "SHA1:"; then
    echo "✅ 키스토어 SHA1 지문:"
    echo "$SHA1_OUTPUT" | grep -A 1 "SHA1:"
    echo ""
    
    # SHA1 추출
    ACTUAL_SHA1=$(echo "$SHA1_OUTPUT" | grep "SHA1:" | head -1 | sed 's/.*SHA1: //' | tr -d ' ')
    REQUIRED_SHA1="61:3A:B7:25:7B:3C:ED:4B:8A:69:C0:7C:61:21:F8:31:4F:11:5B:70"
    REQUIRED_SHA1_CLEAN=$(echo "$REQUIRED_SHA1" | tr -d ' ')
    
    echo "=========================================="
    echo "비교 결과:"
    echo "=========================================="
    echo "필요한 SHA1: $REQUIRED_SHA1"
    echo "현재 SHA1:   $ACTUAL_SHA1"
    echo ""
    
    if [ "$ACTUAL_SHA1" = "$REQUIRED_SHA1_CLEAN" ]; then
        echo "✅ ✅ ✅ 일치합니다! 이 키를 사용하면 됩니다!"
    else
        echo "❌ 일치하지 않습니다."
    fi
else
    echo "❌ SHA1 지문을 확인할 수 없습니다."
    echo ""
    echo "오류 메시지:"
    echo "$SHA1_OUTPUT" | tail -5
    echo ""
    echo "필요한 SHA1: 61:3A:B7:25:7B:3C:ED:4B:8A:69:C0:7C:61:21:F8:31:4F:11:5B:70"
fi

echo "=========================================="

