# nginx 설정 확인 완료

## 확인 결과
nginx 설정은 이미 포트 3030으로 올바르게 설정되어 있습니다:
- `/etc/nginx/sites-enabled/sync.coolsistema.com.conf`에서 `proxy_pass http://127.0.0.1:3030;` 확인

## 다음 확인 사항

### 1. 포트 3030에서 서버가 실행 중인지 확인
```bash
sudo ss -tulpn | grep :3030
# 또는
sudo lsof -i -P -n | grep :3030
```

### 2. 서버가 포트 3030에서 응답하는지 확인
```bash
curl http://localhost:3030/api/health
# 또는
curl http://127.0.0.1:3030/api/health
```

### 3. nginx 설정 파일 상세 확인
```bash
sudo cat /etc/nginx/sites-enabled/sync.coolsistema.com.conf
```

### 4. nginx 에러 로그 확인
```bash
sudo tail -f /var/log/nginx/error.log
```

### 5. nginx 재시작 (필요한 경우)
```bash
# 설정 파일 문법 확인
sudo nginx -t

# nginx 재시작
sudo systemctl restart nginx

# 재시작 후 상태 확인
sudo systemctl status nginx
```

## 가능한 문제

### 1. 서버가 포트 3030에서 실행되지 않음
- 서버 프로세스는 있지만 포트 3030에서 리스닝하지 않음
- 서버가 다른 포트에서 실행 중일 수 있음

### 2. 서버가 응답하지 않음
- 서버가 실행 중이지만 요청에 응답하지 않음
- 데이터베이스 연결 문제로 인한 타임아웃

### 3. nginx 설정 문제
- 설정 파일에 다른 문제가 있을 수 있음
- proxy_read_timeout, proxy_connect_timeout 등 설정 확인 필요

## 해결 방법

### 1. 서버 포트 확인
```bash
# 모든 Node.js 프로세스가 사용하는 포트 확인
sudo lsof -i -P -n | grep node | grep LISTEN
```

### 2. 서버 로그 확인
```bash
# 서버 디렉토리로 이동
cd /home/node/app
# 또는
cd /app

# 로그 확인
tail -f logs/*.log
# 또는
pm2 logs
```

### 3. 서버 재시작
```bash
# 서버 재시작
pm2 restart all
# 또는
cd /home/node/app && npm start
```

## 확인 순서

1. ✅ nginx 설정 확인 - 포트 3030으로 올바르게 설정됨
2. ⏳ 포트 3030에서 서버 실행 확인 필요
3. ⏳ 서버 응답 확인 필요
4. ⏳ nginx 에러 로그 확인 필요

