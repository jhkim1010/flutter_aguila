# nginx 설정 수정 가이드

## 문제
서버는 포트 3030에서 실행 중이지만, nginx가 포트 3000으로 프록시하고 있어서 502 에러가 발생합니다.

## 해결 방법

### 1. nginx 설정 파일 찾기
```bash
# proxy_pass가 있는 모든 파일 찾기
sudo find /etc/nginx -name "*.conf" -type f | xargs grep -l "proxy_pass"

# 또는 모든 proxy_pass 확인
sudo grep -r "proxy_pass" /etc/nginx/

# 포트 번호가 있는 proxy_pass 확인
sudo grep -r "proxy_pass.*:" /etc/nginx/
```

### 2. nginx 설정 파일 확인
```bash
# 기본 설정 파일 확인
sudo cat /etc/nginx/sites-available/default
sudo cat /etc/nginx/sites-enabled/default

# 모든 설정 파일 확인
sudo ls -la /etc/nginx/sites-available/
sudo ls -la /etc/nginx/sites-enabled/
```

### 3. 포트 3030 확인
```bash
# 포트 3030에서 리스닝하는지 확인
sudo ss -tulpn | grep :3030
# 또는
sudo lsof -i -P -n | grep :3030
```

### 4. nginx 설정 수정
nginx 설정 파일에서 `proxy_pass`를 찾아 포트를 변경:

```nginx
# 수정 전 (포트가 명시되어 있지 않을 수도 있음)
location /api/ {
    proxy_pass http://localhost:3000;
    # 또는
    proxy_pass http://127.0.0.1:3000;
    # 또는 변수 사용
    proxy_pass $backend_url;
}

# 수정 후
location /api/ {
    proxy_pass http://localhost:3030;
    # 또는
    proxy_pass http://127.0.0.1:3030;
}
```

### 5. nginx 설정 테스트
```bash
# 설정 파일 문법 확인
sudo nginx -t
```

### 6. nginx 재시작
```bash
# nginx 재시작
sudo systemctl restart nginx
# 또는
sudo service nginx restart

# 재시작 후 상태 확인
sudo systemctl status nginx
```

## 전체 설정 예시

```nginx
server {
    listen 80;
    server_name sync.coolsistema.com;

    location /api/ {
        proxy_pass http://localhost:3030;  # 3000 → 3030으로 변경
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
}
```

## 확인 사항

### 1. 포트 3030에서 서버가 실행 중인지 확인
```bash
sudo ss -tulpn | grep :3030
```

### 2. 서버가 포트 3030에서 응답하는지 확인
```bash
curl http://localhost:3030/api/health
```

### 3. nginx 재시작 후 테스트
```bash
curl https://sync.coolsistema.com/api/health
```

## 다음 단계

1. **모든 proxy_pass 확인**: 포트 번호가 있는 proxy_pass 찾기
2. **설정 파일 확인**: 실제 사용 중인 설정 파일 확인
3. **포트 변경**: 3000 → 3030으로 변경
4. **nginx 재시작**: 변경사항 적용

## 참고

- nginx 설정 파일을 수정한 후 반드시 `nginx -t`로 문법 확인
- 설정 파일을 수정한 후 nginx를 재시작해야 변경사항이 적용됨
- 포트 3030에서 서버가 실행 중인지 확인 필요
