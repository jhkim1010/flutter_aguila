#!/bin/bash

# GitHub 자동화 스크립트 (더 간단한 버전)
# 사용법: ./git_auto.sh [commit_message]

# 커밋 메시지 자동 생성 함수
generate_commit_message() {
    CHANGED_FILES=$(git status --short | awk '{print $2}')
    MESSAGE_PARTS=()
    
    for file in $CHANGED_FILES; do
        if [[ "$file" == *"database_service"* ]]; then MESSAGE_PARTS+=("데이터베이스 서비스")
        elif [[ "$file" == *"main_connection"* ]]; then MESSAGE_PARTS+=("연결 화면")
        elif [[ "$file" == *"resumen_del_dia"* ]]; then MESSAGE_PARTS+=("Resumen del Día")
        elif [[ "$file" == *"report_screen"* ]]; then MESSAGE_PARTS+=("보고서 화면")
        elif [[ "$file" == *"codigos"* ]]; then MESSAGE_PARTS+=("Codigos")
        elif [[ "$file" == *"stocks"* ]]; then MESSAGE_PARTS+=("Stocks")
        elif [[ "$file" == *".sh" ]]; then MESSAGE_PARTS+=("스크립트")
        fi
    done
    
    UNIQUE_PARTS=$(printf '%s\n' "${MESSAGE_PARTS[@]}" | sort -u | tr '\n' ', ' | sed 's/, $//')
    [ ! -z "$UNIQUE_PARTS" ] && echo "수정: $UNIQUE_PARTS" || echo "Update: $(date '+%Y-%m-%d %H:%M:%S')"
}

# 커밋 메시지 설정
COMMIT_MESSAGE="${1:-$(generate_commit_message)}"

echo "🚀 Git 자동화 시작..."
echo "📝 메시지: $COMMIT_MESSAGE"
echo ""

# 변경사항이 없으면 종료
if [ -z "$(git status --porcelain)" ]; then
    echo "ℹ️  변경사항 없음"
    exit 0
fi

# 자동으로 add, commit, push
git add -A && \
git commit -m "$COMMIT_MESSAGE" && \
git push origin $(git branch --show-current) && \
echo "✅ 완료!" || \
echo "❌ 실패"

