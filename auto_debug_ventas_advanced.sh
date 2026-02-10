#!/bin/bash

# 고급 자동 디버깅 루틴: ventas 보고서의 day/month/year 유닛 칼럼 너비 문제 자동 분석 및 수정
# 사용법: ./auto_debug_ventas_advanced.sh [--auto-fix]

set -e

LOG_DIR="logs"
LATEST_LOG=""
AUTO_FIX=false

# 명령줄 인자 처리
if [ "$1" == "--auto-fix" ]; then
    AUTO_FIX=true
    echo "🔧 자동 수정 모드 활성화"
fi

echo "🔍 고급 자동 디버깅 루틴 시작..."
echo "=========================================="

# 최신 로그 파일 찾기
find_latest_log() {
    if [ -d "$LOG_DIR" ]; then
        LATEST_LOG=$(ls -t "$LOG_DIR"/flutter_log_*.txt 2>/dev/null | head -n 1)
        if [ -n "$LATEST_LOG" ]; then
            echo "📄 최신 로그 파일: $LATEST_LOG"
            echo "   → 파일 크기: $(du -h "$LATEST_LOG" | cut -f1)"
            echo "   → 수정 시간: $(stat -f "%Sm" "$LATEST_LOG" 2>/dev/null || stat -c "%y" "$LATEST_LOG" 2>/dev/null)"
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

# 로그에서 특정 패턴 추출
extract_pattern() {
    local log_file="$1"
    local pattern="$2"
    grep "$pattern" "$log_file" 2>/dev/null | tail -n 20 || echo ""
}

# 상세 로그 분석
analyze_log_detailed() {
    local log_file="$1"
    echo ""
    echo "📊 상세 로그 분석 중..."
    echo "----------------------------------------"
    
    # 1. API 요청 분석
    echo ""
    echo "1️⃣ API 요청 분석:"
    local day_requests=$(grep -c "unit.*day\|unit:.*day" "$log_file" 2>/dev/null || echo "0")
    local month_requests=$(grep -c "unit.*month\|unit:.*month" "$log_file" 2>/dev/null || echo "0")
    local year_requests=$(grep -c "unit.*year\|unit:.*year" "$log_file" 2>/dev/null || echo "0")
    local vcode_requests=$(grep -c "unit.*vcode\|unit:.*vcode" "$log_file" 2>/dev/null || echo "0")
    
    echo "   → day 유닛 요청: $day_requests개"
    echo "   → month 유닛 요청: $month_requests개"
    echo "   → year 유닛 요청: $year_requests개"
    echo "   → vcode 유닛 요청: $vcode_requests개"
    
    # 2. buildTableFromList 호출 분석
    echo ""
    echo "2️⃣ buildTableFromList 호출 분석:"
    local build_calls=$(grep -c "buildTableFromList" "$log_file" 2>/dev/null || echo "0")
    echo "   → 총 호출 횟수: $build_calls개"
    
    # unit 파라미터 분석
    echo ""
    echo "   → unit 파라미터 값 분석:"
    extract_pattern "$log_file" "unit 파라미터.*:" | head -n 10 | sed 's/^/      /'
    
    # 3. finalIsVentasDayMonthYear 분석
    echo ""
    echo "3️⃣ finalIsVentasDayMonthYear 값 분석:"
    local final_true=$(grep -c "finalIsVentasDayMonthYear: true" "$log_file" 2>/dev/null || echo "0")
    local final_false=$(grep -c "finalIsVentasDayMonthYear: false" "$log_file" 2>/dev/null || echo "0")
    echo "   → true: $final_true개"
    echo "   → false: $final_false개"
    
    if [ "$final_false" -gt 0 ]; then
        echo ""
        echo "   ⚠️  finalIsVentasDayMonthYear가 false인 경우 상세:"
        extract_pattern "$log_file" "finalIsVentasDayMonthYear: false" | head -n 5 | sed 's/^/      /'
    fi
    
    # 4. 칼럼 너비 2배 증가 적용 여부
    echo ""
    echo "4️⃣ 칼럼 너비 2배 증가 적용 여부:"
    local doubled_applied=$(grep -c "✅✅✅.*칼럼 너비 2배 증가 적용됨" "$log_file" 2>/dev/null || echo "0")
    local doubled_not_applied=$(grep -c "❌❌❌.*칼럼 너비 2배 증가 적용 안 됨" "$log_file" 2>/dev/null || echo "0")
    echo "   → 적용됨: $doubled_applied개"
    echo "   → 적용 안 됨: $doubled_not_applied개"
    
    if [ "$doubled_not_applied" -gt 0 ]; then
        echo ""
        echo "   ⚠️  적용 안 된 경우 상세:"
        extract_pattern "$log_file" "❌❌❌.*칼럼 너비 2배 증가 적용 안 됨" | head -n 3 | sed 's/^/      /'
    fi
    
    # 5. shouldDoubleColumnWidths 분석
    echo ""
    echo "5️⃣ shouldDoubleColumnWidths 값 분석:"
    local should_true=$(grep -c "shouldDoubleColumnWidths.*true" "$log_file" 2>/dev/null || echo "0")
    local should_false=$(grep -c "shouldDoubleColumnWidths.*false" "$log_file" 2>/dev/null || echo "0")
    echo "   → true: $should_true개"
    echo "   → false: $should_false개"
    
    # 6. isLargeScreen 분석
    echo ""
    echo "6️⃣ isLargeScreen 값 분석:"
    local large_screen_true=$(grep -c "isLargeScreen: true\|isLargeScreen.*true" "$log_file" 2>/dev/null || echo "0")
    local large_screen_false=$(grep -c "isLargeScreen: false\|isLargeScreen.*false" "$log_file" 2>/dev/null || echo "0")
    echo "   → true: $large_screen_true개"
    echo "   → false: $large_screen_false개"
    
    # 7. constraints.maxWidth 분석
    echo ""
    echo "7️⃣ constraints.maxWidth 값 분석:"
    extract_pattern "$log_file" "constraints.maxWidth:" | head -n 5 | sed 's/^/      /'
    
    # 문제 진단
    echo ""
    echo "=========================================="
    echo "🔍 문제 진단:"
    echo "=========================================="
    
    local issues_found=0
    
    if [ "$doubled_applied" -eq 0 ] && [ "$doubled_not_applied" -gt 0 ]; then
        echo "❌ 문제 1: 칼럼 너비 2배 증가가 적용되지 않았습니다."
        issues_found=$((issues_found + 1))
        
        if [ "$final_false" -gt 0 ]; then
            echo "   → 원인: finalIsVentasDayMonthYear가 false입니다."
            echo "   → 해결: unit 파라미터 또는 데이터 구조 확인 필요"
        fi
        
        if [ "$should_false" -gt 0 ]; then
            echo "   → 원인: shouldDoubleColumnWidths가 false입니다."
            if [ "$large_screen_false" -gt 0 ]; then
                echo "   → 하위 원인: isLargeScreen이 false입니다 (화면 너비 < 800px)"
            fi
            if [ "$final_false" -gt 0 ]; then
                echo "   → 하위 원인: finalIsVentasDayMonthYear가 false입니다"
            fi
        fi
    fi
    
    if [ "$vcode_requests" -gt "$day_requests" ] && [ "$day_requests" -eq 0 ]; then
        echo "⚠️  문제 2: day/month/year 유닛 요청이 없습니다."
        echo "   → 해결: 앱에서 day/month/year 유닛 버튼을 클릭해주세요"
        issues_found=$((issues_found + 1))
    fi
    
    if [ "$issues_found" -eq 0 ] && [ "$doubled_applied" -gt 0 ]; then
        echo "✅ 문제 없음: 칼럼 너비 2배 증가가 정상적으로 적용되고 있습니다!"
        return 0
    elif [ "$issues_found" -eq 0 ]; then
        echo "⚠️  로그에 충분한 정보가 없습니다."
        echo "   → 앱을 실행하고 day/month/year 유닛을 선택해주세요"
        return 2
    else
        return 1
    fi
}

# 자동 수정 시도
auto_fix() {
    echo ""
    echo "🔧 자동 수정 시도 중..."
    
    local file="lib/widgets/report_table_builder.dart"
    
    if [ ! -f "$file" ]; then
        echo "   ❌ 파일을 찾을 수 없습니다: $file"
        return 1
    fi
    
    # 이미 디버깅 코드가 있는지 확인
    if grep -q "✅✅✅.*칼럼 너비 2배 증가 적용됨" "$file" 2>/dev/null; then
        echo "   ✅ 디버깅 코드가 이미 존재합니다."
    else
        echo "   ⚠️  복잡한 코드 변경이 필요합니다. 수동으로 확인해주세요."
        return 1
    fi
    
    # finalIsVentasDayMonthYear 로직 확인
    if grep -q "finalIsVentasDayMonthYear.*=.*isVentasDayMonthYearFromUnit" "$file" 2>/dev/null; then
        echo "   ✅ finalIsVentasDayMonthYear 로직이 올바르게 설정되어 있습니다."
    else
        echo "   ⚠️  finalIsVentasDayMonthYear 로직을 확인해주세요."
        return 1
    fi
    
    return 0
}

# 메인 함수
main() {
    # 최신 로그 파일 찾기
    if ! find_latest_log; then
        echo ""
        echo "📱 앱을 실행하고 ventas 메뉴에서 day/month/year 유닛을 선택해주세요."
        echo "   그 후 이 스크립트를 다시 실행하세요."
        exit 1
    fi
    
    # 상세 로그 분석
    analyze_log_detailed "$LATEST_LOG"
    analyze_status=$?
    
    if [ $analyze_status -eq 0 ]; then
        echo ""
        echo "✅✅✅ 문제가 해결되었습니다!"
        exit 0
    elif [ $analyze_status -eq 1 ]; then
        echo ""
        if [ "$AUTO_FIX" == true ]; then
            auto_fix
            fix_status=$?
            if [ $fix_status -eq 0 ]; then
                echo ""
                echo "✅ 자동 수정이 완료되었습니다."
                echo "📱 앱을 다시 실행하고 day/month/year 유닛을 선택해주세요."
            else
                echo ""
                echo "⚠️  자동 수정에 실패했습니다. 수동으로 확인이 필요합니다."
            fi
        else
            echo "💡 자동 수정을 시도하려면: ./auto_debug_ventas_advanced.sh --auto-fix"
        fi
        echo ""
        echo "📄 상세 로그: $LATEST_LOG"
        exit 1
    else
        echo ""
        echo "📱 앱을 실행하고 ventas 메뉴에서 day/month/year 유닛을 선택해주세요."
        echo "   그 후 이 스크립트를 다시 실행하세요."
        exit 2
    fi
}

# 스크립트 실행
main
