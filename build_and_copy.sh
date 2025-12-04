#!/bin/bash

# 빌드 및 복사 스크립트
# 사용법: ./build_and_copy.sh [platform]
# platform: android, ios, macos, windows, web

OUTPUT_DIR="/Users/marcoskim/Dropbox/ACE_3_uversion/Be_Cool (Aguila 2a)"
APP_NAME="Be_Cool"

# 출력 디렉토리 생성
mkdir -p "$OUTPUT_DIR"

# 플랫폼별 빌드 및 복사 함수
build_android() {
    echo "📱 Android APK 빌드 중..."
    flutter build apk --release
    
    if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
        cp "build/app/outputs/flutter-apk/app-release.apk" "$OUTPUT_DIR/${APP_NAME}-android.apk"
        echo "✅ Android APK 복사 완료: $OUTPUT_DIR/${APP_NAME}-android.apk"
    else
        echo "❌ Android APK 빌드 실패"
    fi
}

build_ios() {
    echo "🍎 iOS IPA 빌드 중..."
    flutter build ipa --release
    
    if [ -d "build/ios/ipa" ]; then
        IPA_FILE=$(find build/ios/ipa -name "*.ipa" | head -1)
        if [ -n "$IPA_FILE" ]; then
            cp "$IPA_FILE" "$OUTPUT_DIR/${APP_NAME}-ios.ipa"
            echo "✅ iOS IPA 복사 완료: $OUTPUT_DIR/${APP_NAME}-ios.ipa"
        else
            echo "❌ iOS IPA 파일을 찾을 수 없습니다"
        fi
    else
        echo "❌ iOS IPA 빌드 실패"
    fi
}

build_macos() {
    echo "💻 macOS 앱 빌드 중..."
    flutter build macos --release
    
    # 빌드된 앱 경로 확인 (PRODUCT_NAME이 Be_Cool로 변경되었으므로 Be_Cool.app로 빌드됨)
    if [ -d "build/macos/Build/Products/Release/Be_Cool.app" ]; then
        # 임시 디렉토리에서 압축 파일 생성 (깔끔한 구조를 위해)
        TEMP_DIR=$(mktemp -d)
        cp -R "build/macos/Build/Products/Release/Be_Cool.app" "$TEMP_DIR/"
        
        # 압축 파일 생성 (기존 파일 덮어쓰기 옵션 포함)
        cd "$TEMP_DIR"
        zip -r "${APP_NAME}-macos.zip" "Be_Cool.app" -x "*.DS_Store"
        cd - > /dev/null
        
        # 출력 디렉토리로 복사 (기존 파일 덮어쓰기)
        cp -f "$TEMP_DIR/${APP_NAME}-macos.zip" "$OUTPUT_DIR/"
        
        # 임시 디렉토리 정리
        rm -rf "$TEMP_DIR"
        
        echo "✅ macOS 앱 복사 완료: $OUTPUT_DIR/${APP_NAME}-macos.zip"
        echo "   압축 해제 시 Be_Cool.app 파일 1개만 생성됩니다."
    elif [ -d "build/macos/Build/Products/Release/flutter_app.app" ]; then
        # 이전 빌드가 남아있는 경우 이름 변경 후 압축
        TEMP_DIR=$(mktemp -d)
        cp -R "build/macos/Build/Products/Release/flutter_app.app" "$TEMP_DIR/Be_Cool.app"
        
        # 압축 파일 생성
        cd "$TEMP_DIR"
        zip -r "${APP_NAME}-macos.zip" "Be_Cool.app" -x "*.DS_Store"
        cd - > /dev/null
        
        # 출력 디렉토리로 복사 (기존 파일 덮어쓰기)
        cp -f "$TEMP_DIR/${APP_NAME}-macos.zip" "$OUTPUT_DIR/"
        
        # 임시 디렉토리 정리
        rm -rf "$TEMP_DIR"
        
        echo "✅ macOS 앱 복사 완료: $OUTPUT_DIR/${APP_NAME}-macos.zip"
        echo "   압축 해제 시 Be_Cool.app 파일 1개만 생성됩니다."
    else
        echo "❌ macOS 앱 빌드 실패"
    fi
}

build_windows() {
    echo "🪟 Windows 실행파일 빌드 중..."
    flutter build windows --release
    
    if [ -d "build/windows/runner/Release" ]; then
        # Windows 실행파일과 필요한 DLL 파일들을 zip으로 압축
        cd build/windows/runner/Release
        zip -r "${APP_NAME}-windows.zip" .
        cd - > /dev/null
        cp "build/windows/runner/Release/${APP_NAME}-windows.zip" "$OUTPUT_DIR/"
        echo "✅ Windows 실행파일 복사 완료: $OUTPUT_DIR/${APP_NAME}-windows.zip"
    else
        echo "❌ Windows 빌드 실패"
    fi
}

build_web() {
    echo "🌐 Web 빌드 중..."
    flutter build web --release
    
    if [ -d "build/web" ]; then
        cd build
        zip -r "${APP_NAME}-web.zip" web
        cd - > /dev/null
        cp "build/${APP_NAME}-web.zip" "$OUTPUT_DIR/"
        echo "✅ Web 빌드 복사 완료: $OUTPUT_DIR/${APP_NAME}-web.zip"
    else
        echo "❌ Web 빌드 실패"
    fi
}

# 메인 로직
PLATFORM=${1:-all}

case $PLATFORM in
    android)
        build_android
        ;;
    ios)
        build_ios
        ;;
    macos)
        build_macos
        ;;
    windows)
        build_windows
        ;;
    web)
        build_web
        ;;
    all)
        echo "🚀 모든 플랫폼 빌드 시작..."
        build_android
        build_macos
        build_windows
        # iOS는 macOS에서만 빌드 가능
        if [[ "$OSTYPE" == "darwin"* ]]; then
            build_ios
        fi
        build_web
        echo "✅ 모든 빌드 완료!"
        ;;
    *)
        echo "사용법: $0 [android|ios|macos|windows|web|all]"
        exit 1
        ;;
esac

echo ""
echo "📦 출력 디렉토리: $OUTPUT_DIR"
if [ -d "$OUTPUT_DIR" ]; then
    ls -lh "$OUTPUT_DIR" | grep "$APP_NAME" || echo "파일이 없습니다."
fi

