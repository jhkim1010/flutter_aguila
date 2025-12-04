#!/bin/bash

# GitHub 푸시 자동화 스크립트 (no-prompt 모드)
# 사용법: ./git_push.sh [commit_message]
# commit_message가 없으면 변경된 파일을 분석해서 자동 생성

# 모든 프롬프트 비활성화 (no-prompt 모드)
export GIT_EDITOR=true  # 에디터 없이 진행
export GIT_MERGE_AUTOEDIT=no  # 머지 시 에디터 없이 진행

# 커밋 메시지 자동 생성 함수
generate_commit_message() {
    # 변경된 파일 목록 가져오기
    CHANGED_FILES=$(git diff --cached --name-only 2>/dev/null || git status --short | awk '{print $2}')
    
    if [ -z "$CHANGED_FILES" ]; then
        CHANGED_FILES=$(git status --short | awk '{print $2}')
    fi
    
    # 주요 변경사항 분석
    MESSAGE_PARTS=()
    
    # 파일별 변경사항 분석
    for file in $CHANGED_FILES; do
        if [[ "$file" == *"database_service"* ]]; then
            MESSAGE_PARTS+=("데이터베이스 서비스")
        elif [[ "$file" == *"main_connection"* ]]; then
            MESSAGE_PARTS+=("연결 화면")
        elif [[ "$file" == *"resumen_del_dia"* ]]; then
            MESSAGE_PARTS+=("Resumen del Día")
        elif [[ "$file" == *"report_screen"* ]]; then
            MESSAGE_PARTS+=("보고서 화면")
        elif [[ "$file" == *"codigos"* ]]; then
            MESSAGE_PARTS+=("Codigos")
        elif [[ "$file" == *"stocks"* ]]; then
            MESSAGE_PARTS+=("Stocks")
        elif [[ "$file" == *"platform_utils"* ]]; then
            MESSAGE_PARTS+=("플랫폼 유틸리티")
        elif [[ "$file" == *".sh" ]]; then
            MESSAGE_PARTS+=("빌드 스크립트")
        elif [[ "$file" == *"pubspec.yaml"* ]]; then
            MESSAGE_PARTS+=("의존성")
        elif [[ "$file" == *"Info.plist"* ]] || [[ "$file" == *"entitlements"* ]]; then
            MESSAGE_PARTS+=("macOS 설정")
        elif [[ "$file" == *"CMakeLists.txt"* ]]; then
            MESSAGE_PARTS+=("Windows 설정")
        fi
    done
    
    # 중복 제거 및 정렬
    UNIQUE_PARTS=$(printf '%s\n' "${MESSAGE_PARTS[@]}" | sort -u | tr '\n' ', ' | sed 's/, $//')
    
    # 변경사항 타입 분석
    if git diff --cached --stat 2>/dev/null | grep -q "insertion\|deletion"; then
        STATS=$(git diff --cached --shortstat 2>/dev/null || git diff --shortstat 2>/dev/null)
        if echo "$STATS" | grep -q "insertion"; then
            INSERTIONS=$(echo "$STATS" | grep -o '[0-9]* insertion' | grep -o '[0-9]*')
            if [ ! -z "$INSERTIONS" ] && [ "$INSERTIONS" -gt 10 ]; then
                TYPE="기능 추가"
            else
                TYPE="수정"
            fi
        else
            TYPE="수정"
        fi
    else
        TYPE="업데이트"
    fi
    
    # 최종 메시지 생성
    if [ ! -z "$UNIQUE_PARTS" ]; then
        COMMIT_MSG="$TYPE: $UNIQUE_PARTS"
    else
        COMMIT_MSG="Update: $(date '+%Y-%m-%d %H:%M:%S')"
    fi
    
    echo "$COMMIT_MSG"
}

# 커밋 메시지 설정
if [ -z "$1" ]; then
    # 커밋 메시지가 없으면 자동 생성
    COMMIT_MESSAGE=$(generate_commit_message)
else
    COMMIT_MESSAGE="$1"
fi

echo "🚀 GitHub 푸시 자동화 시작..."
echo "📝 커밋 메시지: $COMMIT_MESSAGE"
echo ""

# 현재 브랜치 확인
CURRENT_BRANCH=$(git branch --show-current)
echo "📍 현재 브랜치: $CURRENT_BRANCH"
echo ""

# 변경사항 확인
if [ -z "$(git status --porcelain)" ]; then
    echo "ℹ️  커밋할 변경사항이 없습니다."
    exit 0
fi

# 변경된 파일 표시
echo "📋 변경된 파일:"
git status --short
echo ""

# 모든 변경사항 추가
echo "➕ 모든 변경사항 추가 중..."
git add -A

# 커밋
echo "💾 커밋 중..."
git commit -m "$COMMIT_MESSAGE" --no-edit

# 커밋 결과 확인
if [ $? -eq 0 ]; then
    echo "✅ 커밋 완료"
    echo ""
    
    # 푸시
    echo "📤 GitHub에 푸시 중..."
    git push origin "$CURRENT_BRANCH"
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ GitHub 푸시 완료!"
        echo "🌐 브랜치: $CURRENT_BRANCH"
        echo "📝 커밋 메시지: $COMMIT_MESSAGE"
    else
        echo ""
        echo "❌ GitHub 푸시 실패"
        echo "💡 원격 저장소 설정을 확인하세요."
        exit 1
    fi
else
    echo ""
    echo "❌ 커밋 실패"
    exit 1
fi

