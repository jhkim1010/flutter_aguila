#!/bin/bash
# ============================================================
# Flutter Web 빌드 스크립트
# 사용법:
#   ./build_web.sh              # 루트 경로 배포용 (base-href = /)
#   ./build_web.sh /app/        # 하위 경로 배포용 (base-href = /app/)
# ============================================================
set -e

BASE_HREF="${1:-/}"

# base-href 형식 검증 (슬래시로 시작하고 끝나야 함)
if [[ "$BASE_HREF" != /*/ && "$BASE_HREF" != "/" ]]; then
  echo "❌ base-href는 '/'로 시작하고 끝나야 합니다. 예: /app/"
  exit 1
fi

echo "🌐 Flutter Web 빌드 시작 (base-href: $BASE_HREF)"

# 의존성 확인
flutter pub get

# 정적 분석 — error만 빌드 중단 사유로 처리 (info/warning은 통과)
# 이 프로젝트는 기존 info/warning이 많아서 fatal로 처리하면 빌드가 항상 멈춤
echo "🔍 flutter analyze 실행 중 (error만 확인)..."
flutter analyze --no-fatal-infos --no-fatal-warnings

# 웹 릴리즈 빌드
echo "🏗️ 웹 릴리즈 빌드 중..."
flutter build web --release --base-href "$BASE_HREF"

echo ""
echo "✅ 빌드 완료: build/web/"
echo ""
echo "📦 서버 배포 예시 (nginx):"
echo "   rsync -avz --delete build/web/ user@server:/var/www/aguila-web/"
echo "   (자세한 내용은 docs/WEB_DEPLOY_GUIDE.md 참고)"
