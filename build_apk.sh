#!/bin/bash

# Flutter 앱 APK 빌드 스크립트
# "Be COOL" 앱 설치 파일 생성

echo "🚀 Flutter 앱 빌드 시작..."
echo "📱 앱 이름: Be COOL"

# Flutter 프로젝트 디렉토리로 이동
cd "$(dirname "$0")"

# 빌드 날짜 주입
echo "📅 빌드 날짜 주입 중..."
bash scripts/inject_build_date.sh

# Flutter 의존성 확인 및 설치
echo "📦 의존성 확인 중..."
flutter pub get

# 빌드 전 정리
echo "🧹 이전 빌드 정리 중..."
flutter clean

# Release APK 빌드
echo "🔨 Release APK 빌드 중..."
flutter build apk --release

# 빌드 결과 확인 및 Dropbox로 복사
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    echo "✅ 빌드 성공!"
    echo ""
    
    # Dropbox 폴더 생성 (없는 경우)
    DROPBOX_DIR="/Users/marcoskim/Dropbox/ACE_3_uversion"
    mkdir -p "$DROPBOX_DIR"
    
    # Be_Cool.apk로 이름 변경하여 Dropbox로 복사
    TARGET_FILE="$DROPBOX_DIR/Be_Cool.apk"
    cp "build/app/outputs/flutter-apk/app-release.apk" "$TARGET_FILE"
    
    echo "📦 설치 파일 위치:"
    echo "   원본: $(pwd)/build/app/outputs/flutter-apk/app-release.apk"
    echo "   복사: $TARGET_FILE"
    echo ""
    echo "📊 파일 정보:"
    ls -lh "$TARGET_FILE"
    echo ""
    echo "✅ Be_Cool.apk 파일이 Dropbox로 복사되었습니다!"
else
    echo "❌ 빌드 실패!"
    exit 1
fi

