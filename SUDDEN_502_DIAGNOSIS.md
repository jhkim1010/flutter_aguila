# 갑작스러운 502 Bad Gateway 오류 진단 가이드

## 문제 상황
어제까지만 해도 정상 작동했는데 갑자기 502 Bad Gateway 오류가 발생합니다.

## 가능한 원인

### 1. 서버/컨테이너 재시작 또는 크래시
- Docker 컨테이너가 재시작되었거나 크래시됨
- Node.js 프로세스가 종료됨
- 서버가 메모리 부족으로 종료됨

### 2. 데이터베이스 연결 문제
- PostgreSQL 연결 풀 고갈
- 데이터베이스 서버 다운
- 외래키 제약 조건 위반으로 인한 트랜잭션 롤백 및 연결 문제

### 3. 리소스 부족
- 메모리 부족
- CPU 과부하
- 디스크 공간 부족

### 4. 네트워크 문제
- Nginx 설정 변경
- 방화벽 규칙 변경
- 네트워크 인터페이스 문제

## 즉시 확인할 사항

### 1. Docker 컨테이너 상태 확인
```bash
# 실행 중인 컨테이너 확인
docker ps

# 포트 3030을 사용하는 컨테이너 확인
docker ps | grep 3030

# 모든 컨테이너 확인 (중지된 것 포함)
docker ps -a | grep syncace

# 컨테이너 로그 확인 (최근 100줄)
docker logs syncace --tail 100

# 실시간 로그 확인
docker logs -f syncace
```

### 2. Node.js 프로세스 확인
```bash
# Node.js 프로세스 확인
ps aux | grep node

# 포트 3030을 사용하는 프로세스 확인
sudo lsof -i :3030
# 또는
sudo ss -tulpn | grep :3030
```

### 3. 서버 리소스 확인
```bash
# 메모리 사용량 확인
free -h

# CPU 사용량 확인
top
# 또는
htop

# 디스크 공간 확인
df -h

# 시스템 로그 확인 (최근 오류)
sudo journalctl -xe --no-pager | tail -50
```

### 4. Nginx 상태 확인
```bash
# Nginx 상태 확인
sudo systemctl status nginx

# Nginx 에러 로그 확인
sudo tail -50 /var/log/nginx/error.log

# Nginx 설정 테스트
sudo nginx -t
```

### 5. 데이터베이스 연결 확인
```bash
# PostgreSQL 연결 확인
sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity;"

# 활성 연결 수 확인
sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity WHERE state = 'active';"

# 대기 중인 연결 확인
sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity WHERE state = 'idle in transaction';"
```

### 6. 직접 API 테스트
```bash
# localhost에서 직접 테스트
curl -v http://localhost:3030/api/health

# POST 요청 테스트
curl -X POST http://localhost:3030/api/resumen_del_dia \
  -H "Content-Type: application/json" \
  -H "x-db-name: inquieta14" \
  -H "x-db-user: inquieta" \
  -H "x-db-password: se2021mi09" \
  -d '{"date":"2025-12-17"}'
```

## 빠른 해결 방법

### 1. Docker 컨테이너 재시작
```bash
# 컨테이너 재시작
docker restart syncace

# 재시작 후 로그 확인
docker logs -f syncace
```

### 2. Nginx 재시작
```bash
# Nginx 재시작
sudo systemctl restart nginx

# 재시작 후 상태 확인
sudo systemctl status nginx
```

### 3. 서버 재시작 (최후의 수단)
```bash
# 서버 재부팅
sudo reboot
```

## 로그에서 확인할 패턴

### 1. 메모리 부족
```
Out of memory
Killed process
```

### 2. 데이터베이스 연결 문제
```
too many connections
connection pool exhausted
ECONNREFUSED
```

### 3. 컨테이너 크래시
```
container exited
container stopped
```

### 4. 외래키 제약 조건 위반 (현재 발생 중)
```
violates foreign key constraint
creditoventa_cliente.fr
```

## 외래키 제약 조건 위반 문제

현재 로그에서 확인된 오류:
```
insert or update on table "creditoventas" violates foreign key constraint "creditoventa_cliente.fr"
```

이 오류가 반복되면:
1. 트랜잭션이 롤백됨
2. 데이터베이스 연결이 지연될 수 있음
3. 서버가 요청을 처리하지 못해 502 오류 발생 가능

### 해결 방법
1. 외래키 제약 조건을 확인하고 데이터 무결성 확인
2. 참조되는 테이블(`cliente`)에 해당 레코드가 존재하는지 확인
3. 서버 코드에서 외래키 제약 조건 위반을 더 우아하게 처리하도록 수정

## 모니터링 명령어

### 실시간 모니터링
```bash
# 컨테이너 로그 실시간 모니터링
docker logs -f syncace

# 시스템 리소스 실시간 모니터링
watch -n 1 'free -h && echo "---" && df -h'

# 네트워크 연결 모니터링
watch -n 1 'sudo ss -tulpn | grep :3030'
```

## 다음 단계

1. ✅ 위의 확인 사항들을 순서대로 실행
2. ⏳ 로그에서 오류 패턴 확인
3. ⏳ 문제 원인 파악 후 적절한 해결 방법 적용
4. ⏳ 문제가 지속되면 서버 관리자에게 문의

