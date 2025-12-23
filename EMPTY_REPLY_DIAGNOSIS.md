# Empty Reply from Server 오류 진단 가이드

## 문제 상황
```bash
curl: (52) Empty reply from server
시간: 0.005174초
```

서버가 요청을 받았지만 응답을 보내지 못하고 있습니다. 이것이 502 Bad Gateway의 근본 원인입니다.

## 가능한 원인

### 1. 서버가 요청 처리 중 예외 발생
- 데이터베이스 함수 호출 실패 (`ventas_rpt_a_day`)
- 외래키 제약 조건 위반으로 인한 트랜잭션 롤백
- 서버가 예외를 처리하지 못하고 크래시

### 2. 서버 프로세스 문제
- 서버가 요청 처리 중 종료됨
- 메모리 부족으로 프로세스가 kill됨
- 서버가 응답을 보내기 전에 타임아웃

### 3. 데이터베이스 연결 문제
- 데이터베이스 연결 풀 고갈
- 데이터베이스 쿼리 실행 중 타임아웃
- 트랜잭션이 롤백되지 않아 연결이 잠김

## 즉시 확인할 사항

### 1. Docker 컨테이너 로그 확인 (가장 중요!)
```bash
# 최근 로그 확인 (에러 포함)
docker logs syncace --tail 200

# 실시간 로그 모니터링 (다른 터미널에서)
docker logs -f syncace

# 에러만 필터링
docker logs syncace --tail 500 | grep -i "error\|exception\|crash\|kill\|timeout\|502"
```

### 2. 서버 프로세스 상태 확인
```bash
# Node.js 프로세스 확인
ps aux | grep node | grep -v grep

# 프로세스가 응답하는지 확인
ps aux | grep 3364625  # 이전에 확인한 PID

# 메모리 사용량 확인
free -h

# 프로세스 메모리 사용량
ps aux --sort=-%mem | head -10
```

### 3. 요청 처리 중 로그 확인
```bash
# 요청을 보내면서 동시에 로그 확인
# 터미널 1: 로그 모니터링
docker logs -f syncace

# 터미널 2: 요청 보내기
curl -X POST http://localhost:3030/api/resumen_del_dia \
  -H "Content-Type: application/json" \
  -H "x-db-name: inquieta14" \
  -H "x-db-user: inquieta" \
  -H "x-db-password: se2021mi09" \
  -d '{"date":"2025-12-17"}' \
  -v
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

### 5. Nginx 에러 로그 확인
```bash
# Nginx 에러 로그 확인
sudo tail -50 /var/log/nginx/error.log

# 실시간 에러 로그 모니터링
sudo tail -f /var/log/nginx/error.log
```

## 예상되는 로그 패턴

### 1. 데이터베이스 함수 오류
```
[Ventas 보고서 오류] 함수 ventas_rpt_a_day 호출 실패
function ventas_rpt_a_day(date, date) does not exist
```

### 2. 외래키 제약 조건 위반
```
insert or update on table "creditoventas" violates foreign key constraint "creditoventa_cliente.fr"
```

### 3. 서버 크래시
```
Error: Cannot read property 'xxx' of undefined
TypeError: ...
FATAL ERROR: ...
```

### 4. 타임아웃
```
ETIMEDOUT
ECONNRESET
Request timeout
```

## 해결 방법

### 1. 서버 로그에서 정확한 오류 확인
```bash
docker logs syncace --tail 500 > server_logs.txt
cat server_logs.txt | grep -i "error\|exception\|crash" -A 5 -B 5
```

### 2. 서버 재시작 (임시 해결)
```bash
# 컨테이너 재시작
docker restart syncace

# 재시작 후 로그 확인
docker logs -f syncace
```

### 3. 서버 코드 수정 필요 사항
- 예외 처리를 추가하여 항상 HTTP 응답을 보내도록 수정
- 데이터베이스 함수 호출 실패 시 적절한 에러 응답
- 외래키 제약 조건 위반 시 명확한 에러 메시지
- 타임아웃 발생 시 504 Gateway Timeout 응답

## 다음 단계

1. ✅ Empty reply from server 확인됨
2. ⏳ Docker 컨테이너 로그 확인 필요
3. ⏳ 서버 프로세스 상태 확인 필요
4. ⏳ 데이터베이스 연결 상태 확인 필요
5. ⏳ 서버 코드에서 예외 처리 개선 필요

## 참고

- "Empty reply from server"는 서버가 요청을 받았지만 응답을 생성하지 못했다는 의미
- 이것은 서버 코드에서 예외가 발생했지만 적절히 처리되지 않았을 가능성이 높음
- 서버 로그를 확인하면 정확한 원인을 파악할 수 있음

