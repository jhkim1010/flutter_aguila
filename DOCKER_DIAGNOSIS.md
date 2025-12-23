# Docker 컨테이너 진단 가이드

## 현재 상황
포트 3030에서 `docker-proxy`가 리스닝하고 있습니다. 이것은 Docker 컨테이너가 포트 3030을 사용하고 있다는 의미입니다.

## 확인할 사항

### 1. Docker 컨테이너 상태 확인
```bash
# 실행 중인 모든 컨테이너 확인
docker ps

# 포트 3030을 사용하는 컨테이너 확인
docker ps | grep 3030
# 또는
docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Ports}}" | grep 3030
```

### 2. Docker 컨테이너 로그 확인
```bash
# 포트 3030을 사용하는 컨테이너의 로그 확인
docker logs <container_id>
# 또는 컨테이너 이름으로
docker logs <container_name>

# 실시간 로그 확인
docker logs -f <container_id>
```

### 3. localhost:3030에서 직접 테스트
```bash
# 컨테이너가 응답하는지 확인
curl http://localhost:3030/api/health
# 또는
curl http://127.0.0.1:3030/api/health

# 더 자세한 정보
curl -v http://localhost:3030/api/health
```

### 4. Docker 컨테이너 내부 확인
```bash
# 컨테이너 내부로 들어가기
docker exec -it <container_id> /bin/bash
# 또는
docker exec -it <container_id> /bin/sh

# 컨테이너 내부에서 프로세스 확인
docker exec <container_id> ps aux

# 컨테이너 내부에서 포트 확인
docker exec <container_id> netstat -tulpn
```

### 5. Docker 컨테이너 재시작
```bash
# 컨테이너 재시작
docker restart <container_id>
# 또는
docker restart <container_name>

# 재시작 후 로그 확인
docker logs -f <container_id>
```

## 가능한 문제

### 1. 컨테이너가 실행 중이지만 서버가 응답하지 않음
- 컨테이너는 실행 중이지만 내부 서버가 크래시됨
- 서버가 시작되지 않음
- 데이터베이스 연결 문제

### 2. 컨테이너 포트 매핑 문제
- 호스트 포트 3030과 컨테이너 내부 포트가 매핑되지 않음
- 포트 매핑이 잘못됨

### 3. 컨테이너 내부 서버 설정 문제
- 서버가 다른 포트에서 실행 중
- 서버가 리스닝하지 않음

## 해결 방법

### 1. 컨테이너 상태 확인
```bash
docker ps -a | grep 3030
```

### 2. 컨테이너 로그 확인
```bash
docker logs <container_id> --tail 100
```

### 3. 컨테이너 재시작
```bash
docker restart <container_id>
```

### 4. 컨테이너 내부 서버 확인
```bash
docker exec <container_id> curl http://localhost:3030/api/health
```

## 다음 단계

1. ✅ 포트 3030 확인 - docker-proxy가 리스닝 중
2. ⏳ Docker 컨테이너 상태 확인 필요
3. ⏳ 컨테이너 로그 확인 필요
4. ⏳ localhost:3030에서 직접 테스트 필요

