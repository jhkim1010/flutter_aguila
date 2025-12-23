# 서버 진단 가이드

## 현재 상황
502 Bad Gateway 에러가 계속 발생하고 있습니다. 여러 Node.js 프로세스가 실행 중입니다.

## 발견된 문제

### 1. 여러 Node.js 프로세스 실행 중
```
- nodemon/ts-node 프로세스들 (여러 개)
- nest start 프로세스
- node src/server.js 프로세스 (PID 3364625)
- 좀비 프로세스들 (defunct)
```

### 2. 포트 확인 필요
포트 확인을 위해서는 root 권한이 필요합니다.

## 진단 명령어

### 1. 포트 확인 (sudo 필요)
```bash
sudo netstat -tulpn | grep :3000
# 또는
sudo ss -tulpn | grep :3000
# 또는
sudo lsof -i :3000
```

### 2. 서버 로그 확인
```bash
# 각 서버의 로그 파일 확인
# 예: PM2를 사용하는 경우
pm2 logs

# 또는 Docker를 사용하는 경우
docker logs <container_name>

# 또는 직접 로그 파일 확인
tail -f /var/log/nginx/error.log
tail -f /home/node/app/logs/*.log
```

### 3. nginx 설정 확인
```bash
# nginx 설정 파일 확인
sudo cat /etc/nginx/sites-available/default
# 또는
sudo cat /etc/nginx/conf.d/*.conf

# nginx 에러 로그 확인
sudo tail -f /var/log/nginx/error.log
```

### 4. 서버 프로세스 상태 확인
```bash
# 특정 프로세스의 상태 확인
ps aux | grep 3364625  # node src/server.js 프로세스

# 프로세스가 응답하는지 확인
curl http://localhost:3000/health
# 또는
curl http://127.0.0.1:3000/api/health
```

### 5. 데이터베이스 연결 확인
```bash
# PostgreSQL 연결 확인
psql -U inquieta -d inquieta14 -h localhost -c "SELECT 1;"

# 연결 풀 상태 확인 (서버 코드에서)
```

## 가능한 원인

### 1. 포트 충돌
- 여러 서버가 같은 포트를 사용하려고 시도
- nginx가 잘못된 포트로 프록시 설정

### 2. 서버 응답 없음
- 서버가 실행 중이지만 요청에 응답하지 않음
- 데이터베이스 연결 문제로 인한 타임아웃

### 3. 연결 풀 고갈
- PostgreSQL 연결 풀이 가득 참
- 연결이 제대로 해제되지 않음

### 4. 메모리 부족
- 서버가 메모리 부족으로 응답하지 않음
- 좀비 프로세스들이 리소스 점유

## 해결 방법

### 1. 불필요한 프로세스 정리
```bash
# 좀비 프로세스 정리
sudo kill -9 <defunct_process_pid>

# 중복된 서버 프로세스 종료 (하나만 남기기)
kill <pid>
```

### 2. 서버 재시작
```bash
# PM2를 사용하는 경우
pm2 restart all

# 또는 직접 실행 중인 서버 재시작
kill <server_pid>
# 그 다음 서버 다시 시작
```

### 3. nginx 재시작
```bash
sudo systemctl restart nginx
# 또는
sudo service nginx restart
```

### 4. 데이터베이스 연결 확인
- PostgreSQL 서버가 실행 중인지 확인
- 연결 풀 설정 확인
- 연결 수 제한 확인

## 다음 단계

1. **포트 확인**: 어떤 포트를 사용하는지 확인
2. **서버 로그 확인**: 에러 메시지 확인
3. **nginx 로그 확인**: 프록시 에러 확인
4. **서버 재시작**: 깨끗한 상태로 재시작

## 참고

- 502 Bad Gateway는 nginx가 백엔드 서버에 연결할 수 없을 때 발생
- 서버가 실행 중이어도 응답하지 않으면 502 에러 발생
- 데이터베이스 연결 문제도 502 에러를 유발할 수 있음

