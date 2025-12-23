# 다음 단계: 서버 로그 확인

## 확인된 사항
- ✅ Nginx 타임아웃: 60초 (정상)
- ✅ 포트 3030: docker-proxy가 리스닝 중
- ❌ Empty reply from server: 서버가 응답을 보내지 못함

## 즉시 확인할 사항

### 1. Docker 컨테이너 로그 확인 (가장 중요!)
```bash
# 최근 로그 확인
docker logs syncace --tail 200

# 에러만 필터링
docker logs syncace --tail 500 | grep -i "error\|exception\|crash\|kill\|timeout\|502\|resumen_del_dia" -A 5 -B 5

# 실시간 로그 모니터링
docker logs -f syncace
```

### 2. 요청 처리 중 로그 확인
```bash
# 터미널 1: 로그 모니터링
docker logs -f syncace

# 터미널 2: 요청 보내기
curl -v -X POST http://localhost:3030/api/resumen_del_dia \
  -H "Content-Type: application/json" \
  -H "x-db-name: inquieta14" \
  -H "x-db-user: inquieta" \
  -H "x-db-password: se2021mi09" \
  -d '{"date":"2025-12-17"}'
```

### 3. 컨테이너 상태 확인
```bash
# 컨테이너 상태 확인
docker ps -a | grep syncace

# 컨테이너 리소스 사용량 확인
docker stats syncace --no-stream

# 컨테이너 내부 프로세스 확인
docker exec syncace ps aux
```

### 4. 데이터베이스 연결 확인
```bash
# PostgreSQL 연결 상태 확인
sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity WHERE datname = 'inquieta14';"

# 대기 중인 쿼리 확인
sudo -u postgres psql -c "SELECT pid, state, query, wait_event_type, wait_event FROM pg_stat_activity WHERE datname = 'inquieta14' AND state != 'idle';"

# 잠금 상태 확인
sudo -u postgres psql -c "SELECT * FROM pg_locks WHERE NOT granted;"
```

## 예상되는 문제

### 1. 서버가 요청 처리 중 예외 발생
- 데이터베이스 함수 호출 실패 (`ventas_rpt_a_day`)
- 외래키 제약 조건 위반 (`creditoventas`)
- 서버가 예외를 처리하지 못하고 크래시

### 2. 서버 프로세스 문제
- 서버가 요청 처리 중 종료됨
- 메모리 부족으로 프로세스가 kill됨
- 서버가 응답을 보내기 전에 타임아웃

### 3. 데이터베이스 연결 문제
- 데이터베이스 연결 풀 고갈
- 데이터베이스 쿼리 실행 중 타임아웃
- 트랜잭션이 롤백되지 않아 연결이 잠김

## 로그에서 찾을 패턴

### 데이터베이스 함수 오류
```
[Ventas 보고서 오류] 함수 ventas_rpt_a_day 호출 실패
function ventas_rpt_a_day(date, date) does not exist
```

### 외래키 제약 조건 위반
```
insert or update on table "creditoventas" violates foreign key constraint "creditoventa_cliente.fr"
```

### 서버 크래시
```
Error: Cannot read property 'xxx' of undefined
TypeError: ...
FATAL ERROR: ...
```

### 타임아웃
```
ETIMEDOUT
ECONNRESET
Request timeout
```

## 해결 방법

### 1. 서버 로그 확인 후 원인 파악
로그를 확인하여 정확한 오류 메시지를 찾아야 합니다.

### 2. 서버 재시작 (임시 해결)
```bash
docker restart syncace
docker logs -f syncace
```

### 3. 서버 코드 수정 필요 사항
- 예외 처리를 추가하여 항상 HTTP 응답을 보내도록 수정
- 데이터베이스 함수 호출 실패 시 적절한 에러 응답
- 외래키 제약 조건 위반 시 명확한 에러 메시지
- 타임아웃 발생 시 504 Gateway Timeout 응답

## 다음 단계

1. ✅ Nginx 타임아웃 확인 (60초)
2. ⏳ Docker 컨테이너 로그 확인 필요
3. ⏳ 서버 프로세스 상태 확인 필요
4. ⏳ 데이터베이스 연결 상태 확인 필요
5. ⏳ 서버 코드에서 예외 처리 개선 필요

## 중요

**Docker 컨테이너 로그를 확인하면 정확한 원인을 파악할 수 있습니다.**
로그 결과를 공유해 주시면 더 구체적인 해결 방법을 제시하겠습니다.

