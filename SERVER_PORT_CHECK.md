# 서버 포트 확인 가이드

## 현재 상황
포트 3000에서 리스닝하는 프로세스가 없습니다. 이것이 502 에러의 원인일 수 있습니다.

## 확인할 사항

### 1. 모든 포트 확인
```bash
# 모든 리스닝 포트 확인
sudo ss -tulpn | grep LISTEN

# Node.js 프로세스가 사용하는 포트 확인
sudo lsof -i -P -n | grep node
```

### 2. nginx 설정 확인
```bash
# nginx 설정 파일 확인
sudo cat /etc/nginx/sites-available/default
# 또는
sudo cat /etc/nginx/conf.d/*.conf
# 또는
sudo cat /etc/nginx/sites-enabled/*

# nginx가 어떤 포트로 프록시하는지 확인
sudo grep -r "proxy_pass" /etc/nginx/
```

### 3. 실행 중인 Node.js 프로세스 확인
```bash
# 실행 중인 Node.js 프로세스와 포트 확인
ps aux | grep node
sudo netstat -tulpn | grep node
# 또는
sudo ss -tulpn | grep node
```

### 4. 서버 로그 확인
```bash
# 각 서버의 로그 확인
# 예: PM2를 사용하는 경우
pm2 logs

# 또는 직접 로그 파일 확인
tail -f /var/log/nginx/error.log
tail -f /home/node/app/logs/*.log
tail -f /app/logs/*.log
```

## 가능한 원인

### 1. 서버가 다른 포트에서 실행 중
- 서버가 3000이 아닌 다른 포트(예: 3001, 8080 등)에서 실행 중일 수 있음
- nginx 설정이 잘못된 포트로 프록시하고 있을 수 있음

### 2. 서버가 실행되지 않음
- 서버 프로세스가 있지만 리스닝하지 않는 상태
- 서버가 시작되지 않았거나 크래시됨

### 3. 서버가 리스닝하지 않음
- 서버가 실행 중이지만 특정 포트에서 리스닝하지 않음
- 서버 설정 문제

## 해결 방법

### 1. 서버 포트 확인
```bash
# 모든 리스닝 포트 확인
sudo ss -tulpn | grep LISTEN

# Node.js 프로세스가 사용하는 포트 확인
sudo lsof -i -P -n | grep node
```

### 2. nginx 설정 확인 및 수정
nginx 설정에서 `proxy_pass`가 올바른 포트를 가리키는지 확인:
```nginx
location /api/ {
    proxy_pass http://localhost:3000;  # 이 포트가 실제 서버 포트와 일치하는지 확인
    ...
}
```

### 3. 서버 재시작
서버가 실행되지 않았다면 재시작:
```bash
# PM2를 사용하는 경우
pm2 restart all

# 또는 직접 실행 중인 서버 재시작
cd /home/node/app
npm start
# 또는
cd /app
npm start
```

### 4. 서버 로그 확인
서버가 시작되지 않는 이유를 확인:
```bash
# 서버 로그 확인
tail -f /var/log/nginx/error.log
# 또는 서버 디렉토리에서
cd /home/node/app
npm start
```

## 다음 단계

1. **모든 포트 확인**: 어떤 포트에서 리스닝하는지 확인
2. **nginx 설정 확인**: nginx가 어떤 포트로 프록시하는지 확인
3. **포트 불일치 수정**: nginx 설정과 실제 서버 포트를 일치시키기
4. **서버 재시작**: 서버가 실행되지 않았다면 재시작

