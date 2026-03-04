#!/bin/bash

# Flutter 앱을 실행하면서 모든 로그를 파일로 저장하는 스크립트
# 사용법: ./run_with_log.sh [device_id]
# 예: ./run_with_log.sh macos

# 로그 파일 디렉토리 생성
LOG_DIR="logs"
mkdir -p "$LOG_DIR"

# 타임스탬프를 포함한 로그 파일명 생성
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOG_DIR/flutter_log_${TIMESTAMP}.txt"

# 디바이스 ID가 제공되었는지 확인
if [ -z "$1" ]; then
  # 디바이스 ID가 없으면 기본값 사용 (macos)
  DEVICE="macos"
else
  DEVICE="$1"
fi

# 디바이스 ID를 기반으로 플랫폼 정보 추정
PLATFORM_INFO=""
case "$DEVICE" in
  macos|windows|linux)
    PLATFORM_INFO="대형화면 (Desktop: $DEVICE)"
    ;;
  ipad*|iPad*)
    PLATFORM_INFO="대형화면 (Tablet: iPad)"
    ;;
  *)
    PLATFORM_INFO="핸드폰 (Mobile: $DEVICE)"
    ;;
esac

echo "📝 로그 파일: $LOG_FILE"
echo "📱 플랫폼 정보: $PLATFORM_INFO"

# macOS/iOS 빌드 시 xcodebuild 필요 여부 사전 확인
if [[ "$DEVICE" == "macos" || "$DEVICE" == "ios" || "$DEVICE" == iphone* || "$DEVICE" == ipad* ]]; then
  if ! command -v xcodebuild &>/dev/null; then
    echo ""
    echo "❌ xcodebuild를 찾을 수 없습니다. macOS/iOS 빌드에는 Xcode 또는 Xcode Command Line Tools가 필요합니다."
    echo ""
    echo "해결 방법:"
    echo "  1) Xcode Command Line Tools만 설치:  xcode-select --install"
    echo "  2) 또는 App Store에서 Xcode 설치 후 터미널에서:"
    echo "     sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
    echo "     sudo xcodebuild -license accept"
    echo ""
    exit 1
  fi
  # CocoaPods 필요 여부 사전 확인 (플러그인 사용 시 필수)
  if ! command -v pod &>/dev/null; then
    echo ""
    echo "❌ CocoaPods가 설치되어 있지 않습니다. macOS/iOS 플러그인 빌드에 필요합니다."
    echo ""
    echo "해결 방법 (둘 중 하나):"
    echo "  • Homebrew:  brew install cocoapods"
    echo "  • Ruby gem:  sudo gem install cocoapods"
    echo ""
    echo "설치 후 다시 실행하세요:  ./run_with_log.sh $DEVICE"
    echo ""
    exit 1
  fi
fi

echo "🚀 Flutter 앱 실행 중..."
echo ""

# 플랫폼 정보를 로그 파일 첫 줄에 기록
echo "=== 플랫폼 정보: $PLATFORM_INFO ===" > "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Flutter 앱 실행 및 로그 저장
# tee 명령어로 동시에 콘솔과 파일에 출력
# 2>&1: stderr를 stdout으로 리다이렉션하여 모든 출력을 캡처
# -a 옵션으로 파일에 append (플랫폼 정보 다음에 추가)
flutter run -d "$DEVICE" 2>&1 | tee -a "$LOG_FILE"

echo ""
echo "✅ 로그가 저장되었습니다: $LOG_FILE"
echo "📱 플랫폼 정보: $PLATFORM_INFO"

