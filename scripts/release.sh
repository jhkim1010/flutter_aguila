#!/usr/bin/env bash
#
# 릴리스 원커맨드 스크립트
#
# 빌드 날짜 주입 → APK 빌드 → commit·push → Windows CI 대기 → 아티팩트 다운로드
# → 모든 설치 파일을 Dropbox 배포 폴더로 복사, 까지 한 번에 진행한다.
#
# Windows 설치 파일을 CI 에서 받아오는 이유:
#   macOS 호스트에서 `flutter build windows` 는 다음으로 거부된다.
#     "build windows" only supported on Windows hosts.
#   그래서 windows-latest 러너에서 빌드하는데, CI 는 GitHub 서버에서 돌기 때문에
#   로컬 Dropbox 폴더에 직접 쓸 수 없다. 로컬이 아티팩트를 내려받아야 한다.
#
# 사용법: ./scripts/release.sh [옵션]

set -euo pipefail

# ============================================
# 설정
# ============================================

readonly REPO="jhkim1010/flutter_aguila"
readonly WORKFLOW="windows-build.yml"
readonly BRANCH="main"

# 배포본 보관 폴더. 기존 설치 파일이 전부 여기 있다.
readonly DEFAULT_DEST="$HOME/Dropbox/ACE_3_uversion/BeCool instaladores"

# 빌드 날짜 주입 스크립트가 건드리는 파일. 이것만 스테이징한다.
readonly BUILD_DATE_FILES=(
  "android/app/src/main/res/values/strings.xml"
  "ios/Runner/Info.plist"
  "macos/Runner/Info.plist"
)

readonly APK_SOURCE="build/app/outputs/flutter-apk/app-release.apk"

# CI 대기 상한. 워크플로 자체 timeout 이 45분이라 여유를 둔다.
readonly CI_WAIT_TIMEOUT_SECONDS=3600

# ============================================
# 옵션
# ============================================

DEST="$DEFAULT_DEST"
DO_APK=true
DO_PUSH=true
DO_WAIT=true
RUN_ID=""

usage() {
  cat <<'EOF'
사용법: ./scripts/release.sh [옵션]

빌드 날짜 주입 → APK 빌드 → commit·push → Windows CI 대기 → 아티팩트 다운로드
→ 설치 파일 3종을 Dropbox 배포 폴더로 복사.

복사되는 파일:
  Be_Cool_Setup_v{version}_{date}.exe             Windows 설치 프로그램
  Be_Cool_android_v{version}_{date}.apk           Android APK
  Be_Cool_windows_portable_v{version}_{date}.zip  설치 없이 쓰는 Windows 포터블

옵션:
  --no-apk         APK 빌드를 건너뛴다. Windows 만 다시 받을 때 쓴다.
  --no-push        commit·push 를 건너뛴다. 이미 push 된 상태에서 재실행할 때.
  --no-wait        CI 완료를 기다리지 않는다. run 을 띄우고 바로 끝낸다.
  --run-id <id>    새로 트리거하지 않고 지정한 run 의 아티팩트를 받는다.
  --dest <dir>     복사 대상 폴더를 바꾼다.
                   기본값: ~/Dropbox/ACE_3_uversion/BeCool instaladores
  -h, --help       이 도움말.

예시:
  ./scripts/release.sh                  전체 파이프라인
  ./scripts/release.sh --no-apk         Windows 만 다시 받기
  ./scripts/release.sh --run-id 30873981193 --no-apk --no-push
                                        지난 run 의 아티팩트만 회수
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-apk)  DO_APK=false; shift ;;
    --no-push) DO_PUSH=false; shift ;;
    --no-wait) DO_WAIT=false; shift ;;
    --run-id)
      [[ $# -ge 2 ]] || { echo "❌ --run-id 에 값이 필요합니다." >&2; exit 1; }
      RUN_ID="$2"; shift 2 ;;
    --dest)
      [[ $# -ge 2 ]] || { echo "❌ --dest 에 값이 필요합니다." >&2; exit 1; }
      DEST="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "❌ 알 수 없는 옵션: $1" >&2; echo >&2; usage >&2; exit 1 ;;
  esac
done

# ============================================
# 유틸
# ============================================

log()  { echo "$*"; }
step() { echo; echo "▶ $*"; }
warn() { echo "⚠️  $*" >&2; }
die()  { echo "❌ $*" >&2; exit 1; }

# 스크립트 종료 시 임시 디렉터리를 반드시 지운다.
WORKDIR=""
cleanup() {
  [[ -n "$WORKDIR" && -d "$WORKDIR" ]] && rm -rf "$WORKDIR"
}
trap cleanup EXIT

# 같은 이름의 배포본을 조용히 덮어쓰지 않는다.
# 내용이 같으면 건너뛰고, 다르면 _2, _3 ... 을 붙여 새로 넣는다.
copy_artifact() {
  local src="$1" base="$2" ext="$3"
  local target="$DEST/$base.$ext"

  if [[ ! -f "$src" ]]; then
    warn "원본이 없어 건너뜁니다: $src"
    return 1
  fi

  if [[ -e "$target" ]]; then
    if cmp -s "$src" "$target"; then
      log "   = $base.$ext (내용 동일, 건너뜀)"
      return 0
    fi
    local n=2
    while [[ -e "$DEST/${base}_$n.$ext" ]]; do
      if cmp -s "$src" "$DEST/${base}_$n.$ext"; then
        log "   = ${base}_$n.$ext (내용 동일, 건너뜀)"
        return 0
      fi
      n=$((n + 1))
    done
    warn "$base.$ext 가 이미 있고 내용이 다릅니다. ${base}_$n.$ext 로 넣습니다."
    target="$DEST/${base}_$n.$ext"
  fi

  cp "$src" "$target"
  log "   ✓ $(basename "$target")  ($(du -h "$target" | cut -f1 | tr -d ' '))"
}

# ============================================
# 프리플라이트
# ============================================

step "프리플라이트"

cd "$(dirname "$0")/.."
readonly PROJECT_ROOT="$PWD"

command -v git >/dev/null     || die "git 이 없습니다."
command -v gh >/dev/null      || die "GitHub CLI(gh) 가 없습니다. brew install gh"
gh auth status >/dev/null 2>&1 || die "gh 인증이 안 되어 있습니다. gh auth login"

if [[ "$DO_APK" == true ]]; then
  command -v flutter >/dev/null || die "flutter 가 없습니다."
fi

[[ -d "$DEST" ]] || die "배포 폴더가 없습니다: $DEST
Dropbox 동기화가 아직 안 끝났을 수 있습니다. --dest 로 경로를 지정할 수도 있습니다."

current_branch="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$current_branch" != "$BRANCH" ]]; then
  warn "현재 브랜치가 '$current_branch' 입니다 ('$BRANCH' 아님)."
  warn "Windows CI 는 '$BRANCH' push 에서 트리거됩니다."
  if [[ "$DO_PUSH" == true ]]; then
    die "브랜치를 '$BRANCH' 로 옮기거나 --no-push 를 쓰세요."
  fi
fi

# 이미 스테이징된 변경이 있으면 빌드 날짜 커밋에 섞여 들어간다.
if [[ "$DO_PUSH" == true ]] && ! git diff --cached --quiet; then
  die "스테이징된 변경이 있습니다. 먼저 커밋하거나 unstage 하세요:
$(git diff --cached --name-only | sed 's/^/  /')"
fi

# pubspec.yaml 의 `version: 1.0.0+1` 에서 1.0.0 만 뽑는다.
VERSION="$(grep -m1 '^version:' pubspec.yaml | sed -E 's/^version:[[:space:]]*([^+]+).*/\1/' | tr -d '[:space:]')"
[[ -n "$VERSION" ]] || die "pubspec.yaml 에서 version 을 읽지 못했습니다."

log "   저장소:   $REPO"
log "   브랜치:   $current_branch"
log "   버전:     $VERSION"
log "   대상 폴더: $DEST"

# ============================================
# 1. 빌드 날짜 주입
# ============================================

step "빌드 날짜 주입"
bash scripts/inject_build_date.sh >/dev/null || die "빌드 날짜 주입 실패."

BUILD_DATE="$(date +%Y-%m-%d)"
log "   빌드 날짜: $BUILD_DATE"

# ============================================
# 2. APK 빌드
# ============================================

if [[ "$DO_APK" == true ]]; then
  step "APK 빌드 (몇 분 걸립니다)"
  flutter build apk --release || die "APK 빌드 실패."
  [[ -f "$APK_SOURCE" ]] || die "APK 가 생성되지 않았습니다: $APK_SOURCE"
  log "   ✓ $APK_SOURCE ($(du -h "$APK_SOURCE" | cut -f1 | tr -d ' '))"
else
  step "APK 빌드 건너뜀 (--no-apk)"
fi

# ============================================
# 3. commit·push — 이 push 가 Windows CI 를 트리거한다
# ============================================

if [[ "$DO_PUSH" == true ]]; then
  step "빌드 날짜 커밋 후 push"

  # 빌드 날짜 파일만 스테이징한다. 작업 트리의 다른 변경은 건드리지 않는다.
  for f in "${BUILD_DATE_FILES[@]}"; do
    [[ -f "$f" ]] && git add "$f"
  done

  if git diff --cached --quiet; then
    log "   커밋할 변경 없음 (같은 날 재실행)."
  else
    git commit -q -m "chore: bump injected build date to $BUILD_DATE" \
      -m "Output of scripts/inject_build_date.sh, run before cutting a release." \
      || die "커밋 실패."
    log "   ✓ $(git rev-parse --short HEAD)"
  fi

  git push origin "$BRANCH" || die "push 실패."
  log "   ✓ push 완료"
else
  step "push 건너뜀 (--no-push)"
fi

HEAD_SHA="$(git rev-parse HEAD)"

# ============================================
# 4. Windows CI run 확보
# ============================================

if [[ -z "$RUN_ID" ]]; then
  step "Windows CI run 찾는 중"

  # push 후 run 이 API 에 뜨기까지 몇 초 걸린다.
  for _ in $(seq 1 15); do
    RUN_ID="$(gh run list -R "$REPO" --workflow="$WORKFLOW" \
                --json databaseId,headSha,status \
                --jq "[.[] | select(.headSha == \"$HEAD_SHA\")] | first | .databaseId // empty" 2>/dev/null || true)"
    [[ -n "$RUN_ID" ]] && break
    sleep 4
  done

  # 같은 날 재실행이면 커밋이 없어 push 가 no-op 이 되고 CI 도 안 돈다.
  # 그때는 workflow_dispatch 로 직접 띄운다.
  if [[ -z "$RUN_ID" ]]; then
    log "   현재 커밋에 해당하는 run 이 없습니다. workflow_dispatch 로 띄웁니다."
    gh workflow run "$WORKFLOW" -R "$REPO" --ref "$BRANCH" || die "workflow_dispatch 실패."
    for _ in $(seq 1 15); do
      sleep 4
      RUN_ID="$(gh run list -R "$REPO" --workflow="$WORKFLOW" --limit 1 \
                  --json databaseId --jq '.[0].databaseId // empty' 2>/dev/null || true)"
      [[ -n "$RUN_ID" ]] && break
    done
    [[ -n "$RUN_ID" ]] || die "run 을 찾지 못했습니다. 수동 확인:
  gh run list -R $REPO --workflow=$WORKFLOW"
  fi
fi

log "   run: $RUN_ID"
log "   https://github.com/$REPO/actions/runs/$RUN_ID"

if [[ "$DO_WAIT" == false ]]; then
  step "CI 대기 건너뜀 (--no-wait)"
  log "완료되면 아래로 회수하세요:"
  log "  ./scripts/release.sh --run-id $RUN_ID --no-apk --no-push"
  exit 0
fi

# ============================================
# 5. CI 완료 대기
# ============================================

step "Windows CI 완료 대기 (보통 5~7분)"

deadline=$(( $(date +%s) + CI_WAIT_TIMEOUT_SECONDS ))
while :; do
  read -r ci_status ci_conclusion <<<"$(gh run view "$RUN_ID" -R "$REPO" \
    --json status,conclusion --jq '"\(.status) \(.conclusion // "-")"')"

  [[ "$ci_status" == "completed" ]] && break

  if (( $(date +%s) > deadline )); then
    die "CI 대기가 ${CI_WAIT_TIMEOUT_SECONDS}초를 넘었습니다. 상태: $ci_status
  gh run view $RUN_ID -R $REPO"
  fi

  printf '\r   상태: %-12s  (%ds 경과)' "$ci_status" "$(( $(date +%s) - deadline + CI_WAIT_TIMEOUT_SECONDS ))"
  sleep 15
done
printf '\r%*s\r' 50 ''

if [[ "$ci_conclusion" != "success" ]]; then
  die "CI 가 '$ci_conclusion' 로 끝났습니다. 로그:
  gh run view $RUN_ID -R $REPO --log-failed"
fi
log "   ✓ CI 성공"

# ============================================
# 6. 아티팩트 다운로드
# ============================================

step "아티팩트 다운로드"

WORKDIR="$(mktemp -d)"
gh run download "$RUN_ID" -R "$REPO" -D "$WORKDIR" \
  || die "아티팩트 다운로드 실패. 30일이 지나 만료됐을 수 있습니다."

setup_exe="$(find "$WORKDIR" -type f -name '*.exe' | head -1)"
portable_zip="$(find "$WORKDIR" -type f -name '*.zip' | head -1)"

[[ -n "$setup_exe" ]] || die "setup.exe 를 찾지 못했습니다. run $RUN_ID 의 아티팩트를 확인하세요."
log "   ✓ $(basename "$setup_exe")"
[[ -n "$portable_zip" ]] && log "   ✓ $(basename "$portable_zip")"

# ============================================
# 7. Dropbox 배포 폴더로 복사
# ============================================

step "배포 폴더로 복사"
log "   $DEST"

copy_artifact "$setup_exe" "Be_Cool_Setup_v${VERSION}_${BUILD_DATE}" "exe"

if [[ -n "$portable_zip" ]]; then
  copy_artifact "$portable_zip" "Be_Cool_windows_portable_v${VERSION}_${BUILD_DATE}" "zip"
fi

if [[ "$DO_APK" == true ]]; then
  copy_artifact "$PROJECT_ROOT/$APK_SOURCE" "Be_Cool_android_v${VERSION}_${BUILD_DATE}" "apk"
fi

# ============================================
# 완료
# ============================================

echo
echo "✅ 릴리스 완료 — v$VERSION ($BUILD_DATE)"
echo "   $DEST"
