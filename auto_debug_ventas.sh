#!/bin/bash

# 자동 디버깅 루틴: ventas 보고서의 day/month/year 유닛 칼럼 너비 문제 자동 분석 및 수정
# 사용법: ./auto_debug_ventas.sh

set -e

LOG_DIR="logs"
LATEST_LOG=""
MAX_ITERATIONS=10
ITERATION=0

echo "🔍 자동 디버깅 루틴 시작..."
echo "=========================================="

# 최신 로그 파일 찾기
find_latest_log() {
    if [ -d "$LOG_DIR" ]; then
        LATEST_LOG=$(ls -t "$LOG_DIR"/flutter_log_*.txt 2>/dev/null | head -n 1)
        if [ -n "$LATEST_LOG" ]; then
            echo "📄 최신 로그 파일: $LATEST_LOG"
            return 0
        else
            echo "⚠️  로그 파일을 찾을 수 없습니다."
            return 1
        fi
    else
        echo "⚠️  logs 디렉토리가 없습니다."
        return 1
    fi
}

# 로그 분석: 칼럼 너비 2배 증가가 적용되었는지 확인
analyze_log() {
    local log_file="$1"
    echo ""
    echo "📊 로그 분석 중..."
    
    # 1. API 요청에서 day/month/year 유닛 확인
    local unit_requests=$(grep -c "unit.*day\|unit.*month\|unit.*year" "$log_file" 2>/dev/null || echo "0")
    echo "   → day/month/year 유닛 API 요청: $unit_requests개"
    
    # 2. buildTableFromList 호출 시 unit 파라미터 확인
    local build_calls=$(grep -c "buildTableFromList" "$log_file" 2>/dev/null || echo "0")
    echo "   → buildTableFromList 호출: $build_calls개"
    
    # 3. 칼럼 너비 2배 증가 적용 확인
    local doubled_applied=$(grep -c "✅✅✅.*칼럼 너비 2배 증가 적용됨" "$log_file" 2>/dev/null || echo "0")
    local doubled_not_applied=$(grep -c "❌❌❌.*칼럼 너비 2배 증가 적용 안 됨" "$log_file" 2>/dev/null || echo "0")
    echo "   → 칼럼 너비 2배 증가 적용됨: $doubled_applied개"
    echo "   → 칼럼 너비 2배 증가 적용 안 됨: $doubled_not_applied개"
    
    # 4. unit 파라미터가 vcode인 경우 확인
    local unit_vcode=$(grep -c "unit.*vcode\|unit 파라미터.*vcode" "$log_file" 2>/dev/null || echo "0")
    echo "   → unit 파라미터가 vcode인 경우: $unit_vcode개"
    
    # 5. finalIsVentasDayMonthYear 값 확인
    local final_true=$(grep -c "finalIsVentasDayMonthYear: true" "$log_file" 2>/dev/null || echo "0")
    local final_false=$(grep -c "finalIsVentasDayMonthYear: false" "$log_file" 2>/dev/null || echo "0")
    echo "   → finalIsVentasDayMonthYear: true=$final_true, false=$final_false"
    
    # 문제 진단
    if [ "$doubled_applied" -gt 0 ]; then
        echo ""
        echo "✅ 칼럼 너비 2배 증가가 적용되었습니다!"
        return 0  # 성공
    elif [ "$doubled_not_applied" -gt 0 ]; then
        echo ""
        echo "❌ 칼럼 너비 2배 증가가 적용되지 않았습니다."
        echo "   → 원인 분석 중..."
        
        # finalIsVentasDayMonthYear가 false인 경우
        if [ "$final_false" -gt 0 ]; then
            echo "   → 문제: finalIsVentasDayMonthYear가 false입니다."
            return 1  # 문제 발견
        fi
        
        # unit 파라미터가 vcode인 경우
        if [ "$unit_vcode" -gt 0 ] && [ "$final_false" -gt 0 ]; then
            echo "   → 문제: unit 파라미터가 vcode로 전달되고 있습니다."
            return 1  # 문제 발견
        fi
        
        return 1  # 문제 발견
    else
        echo ""
        echo "⚠️  로그에 충분한 정보가 없습니다. 앱을 실행하고 day/month/year 유닛을 선택해주세요."
        return 2  # 정보 부족
    fi
}

# 디버깅 코드 추가 (필요한 경우)
add_debugging_code() {
    echo ""
    echo "🔧 디버깅 코드 추가 중..."
    
    local file="lib/widgets/report_table_builder.dart"
    
    # 이미 디버깅 코드가 있는지 확인
    if grep -q "✅✅✅.*칼럼 너비 2배 증가 적용됨" "$file" 2>/dev/null; then
        echo "   → 디버깅 코드가 이미 존재합니다."
        return 0
    fi
    
    echo "   → 디버깅 코드를 추가합니다..."
    # 실제로는 여기서 sed나 다른 도구를 사용하여 코드를 추가할 수 있지만,
    # 복잡한 구조 변경이 필요하므로 수동으로 처리하는 것이 안전합니다.
    echo "   ⚠️  복잡한 코드 변경이 필요합니다. 수동으로 확인해주세요."
    return 1
}

# 메인 루프
main() {
    while [ $ITERATION -lt $MAX_ITERATIONS ]; do
        ITERATION=$((ITERATION + 1))
        echo ""
        echo "=========================================="
        echo "🔄 반복 $ITERATION/$MAX_ITERATIONS"
        echo "=========================================="
        
        # 최신 로그 파일 찾기
        if ! find_latest_log; then
            echo ""
            echo "📱 앱을 실행하고 ventas 메뉴에서 day/month/year 유닛을 선택해주세요."
            echo "   그 후 이 스크립트를 다시 실행하세요."
            exit 1
        fi
        
        # 로그 분석
        analyze_result=$(analyze_log "$LATEST_LOG")
        analyze_status=$?
        
        if [ $analyze_status -eq 0 ]; then
            echo ""
            echo "✅✅✅ 문제가 해결되었습니다!"
            echo "   → 칼럼 너비 2배 증가가 정상적으로 적용되고 있습니다."
            exit 0
        elif [ $analyze_status -eq 1 ]; then
            echo ""
            echo "🔧 문제를 발견했습니다. 수정이 필요합니다."
            echo "   → 로그 파일을 확인하여 구체적인 문제를 파악하세요: $LATEST_LOG"
            echo "   → 주요 검색어:"
            echo "     - 'finalIsVentasDayMonthYear'"
            echo "     - 'shouldDoubleColumnWidths'"
            echo "     - 'unit 파라미터'"
            echo ""
            echo "📱 앱을 다시 실행하고 day/month/year 유닛을 선택한 후,"
            echo "   최신 로그 파일을 확인해주세요."
            exit 1
        else
            echo ""
            echo "⚠️  로그에 충분한 정보가 없습니다."
            echo "📱 앱을 실행하고 ventas 메뉴에서 day/month/year 유닛을 선택해주세요."
            echo "   그 후 이 스크립트를 다시 실행하세요."
            exit 2
        fi
    done
    
    echo ""
    echo "⚠️  최대 반복 횟수($MAX_ITERATIONS)에 도달했습니다."
    echo "   → 수동으로 확인이 필요합니다."
    exit 1
}

# 스크립트 실행
main
