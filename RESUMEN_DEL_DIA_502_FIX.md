# resumen_del_dia만 502 Bad Gateway 오류 발생 원인 및 해결 방법

## 문제 상황
- ✅ 다른 메뉴들은 모두 정상 작동
- ❌ `resumen del dia` 보고서에서만 502 Bad Gateway 오류 발생

## 원인 분석

### 1. 요청 방식 차이
- **resumen_del_dia**: POST 요청 사용 (타임아웃 30초 → 60초로 증가)
- **다른 보고서들**: GET 요청 사용 (타임아웃 10초)

### 2. 서버 측 처리 복잡도
`/api/resumen_del_dia` 엔드포인트는:
- 데이터베이스 함수 호출 (`ventas_rpt_a_day`)
- 외래키 제약 조건 처리 (`creditoventas` 테이블)
- 복잡한 트랜잭션 처리
- 더 많은 데이터 처리

### 3. 가능한 서버 측 문제
1. **데이터베이스 함수 오류**
   - `ventas_rpt_a_day` 함수가 존재하지 않거나 시그니처 불일치
   - 함수 호출 실패 시 fallback 처리 중 타임아웃

2. **외래키 제약 조건 위반**
   - `creditoventas` 테이블에 삽입/업데이트 시 `cliente` 테이블 참조 실패
   - 트랜잭션 롤백으로 인한 지연

3. **서버 타임아웃**
   - Nginx나 서버에서 30초 이내 응답하지 못함
   - 데이터베이스 쿼리 실행 시간 초과

## 해결 방법

### 1. 클라이언트 측 수정 (완료)
- ✅ 타임아웃을 30초에서 60초로 증가
- ✅ 더 자세한 로깅 추가

### 2. 서버 측 확인 필요

#### A. 서버 로그 확인
```bash
# Docker 컨테이너 로그 확인
docker logs syncace --tail 200 | grep -i "resumen_del_dia\|502\|timeout\|error"

# Nginx 에러 로그 확인
sudo tail -100 /var/log/nginx/error.log | grep -i "502\|timeout"
```

#### B. 직접 API 테스트
```bash
# localhost에서 직접 테스트 (타임아웃 확인)
time curl -X POST http://localhost:3030/api/resumen_del_dia \
  -H "Content-Type: application/json" \
  -H "x-db-name: inquieta14" \
  -H "x-db-user: inquieta" \
  -H "x-db-password: se2021mi09" \
  -d '{"date":"2025-12-17"}' \
  -w "\n시간: %{time_total}초\n"
```

#### C. 데이터베이스 함수 확인
```sql
-- ventas_rpt_a_day 함수 확인
SELECT n.nspname as schema_name, 
       p.proname as function_name, 
       pg_get_function_arguments(p.oid) as arguments,
       pg_get_function_result(p.oid) as return_type
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname IN ('ventas_rpt_a_day', 'venta_rpt_a_day');
```

#### D. 외래키 제약 조건 확인
```sql
-- creditoventas 테이블의 외래키 제약 조건 확인
SELECT
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name = 'creditoventas';
```

### 3. 서버 측 수정 필요 사항

#### A. 타임아웃 설정 증가
- Nginx `proxy_read_timeout` 증가 (기본 60초 → 120초)
- Node.js 서버 타임아웃 설정 확인

#### B. 에러 처리 개선
- 데이터베이스 함수 호출 실패 시 더 빠른 fallback
- 외래키 제약 조건 위반 시 더 명확한 에러 메시지
- 타임아웃 발생 시 적절한 HTTP 응답 (504 Gateway Timeout)

#### C. 트랜잭션 최적화
- 불필요한 트랜잭션 롤백 방지
- 데이터베이스 연결 풀 관리 개선

## 다음 단계

1. ✅ 클라이언트 타임아웃 증가 (60초)
2. ⏳ 서버 로그 확인
3. ⏳ 직접 API 테스트로 응답 시간 확인
4. ⏳ 데이터베이스 함수 및 제약 조건 확인
5. ⏳ 서버 측 타임아웃 설정 조정
6. ⏳ 서버 측 에러 처리 개선

## 참고

- POST 요청은 GET 요청보다 더 많은 리소스를 사용하고 처리 시간이 길 수 있음
- 서버에서 복잡한 데이터베이스 작업을 수행할 때는 충분한 타임아웃이 필요함
- 502 Bad Gateway는 Nginx가 백엔드 서버에 연결할 수 없거나 응답을 받지 못할 때 발생

