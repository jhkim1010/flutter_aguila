# syncace 컨테이너 진단 및 수정 가이드

## 확인된 정보
- 컨테이너 이름: `syncace`
- 컨테이너 ID: `029e40f70746`
- 포트 매핑: `0.0.0.0:3030->3030/tcp` (정상)

## 다음 확인 사항

### 1. 컨테이너 상태 확인
```bash
docker ps -a | grep syncace
```

### 2. 컨테이너 로그 확인 (중요!)
```bash
# 최근 100줄 로그 확인
docker logs syncace --tail 100

# 실시간 로그 확인
docker logs syncace -f

# 에러만 확인
docker logs syncace 2>&1 | grep -i error
```

### 3. localhost:3030에서 직접 테스트
```bash
# 헬스 체크
curl http://localhost:3030/api/health

# resumen_del_dia 엔드포인트 테스트
curl -X POST http://localhost:3030/api/resumen_del_dia \
  -H "Content-Type: application/json" \
  -H "x-db-name: inquieta14" \
  -H "x-db-user: inquieta" \
  -H "x-db-password: se2021mi09" \
  -d '{"date":"2025-12-17"}'

# 더 자세한 정보
curl -v http://localhost:3030/api/health
```

### 4. 컨테이너 내부 확인
```bash
# 컨테이너 내부로 들어가기
docker exec -it syncace /bin/bash
# 또는
docker exec -it syncace /bin/sh

# 컨테이너 내부에서 프로세스 확인
docker exec syncace ps aux

# 컨테이너 내부에서 포트 확인
docker exec syncace netstat -tulpn
# 또는
docker exec syncace ss -tulpn
```

### 5. 컨테이너 재시작
```bash
# 컨테이너 재시작
docker restart syncace

# 재시작 후 로그 확인
docker logs syncace -f
```

## 가능한 문제

### 1. 컨테이너 내부 서버가 응답하지 않음
- 서버가 크래시되었거나 시작되지 않음
- 데이터베이스 연결 문제
- 메모리 부족

### 2. 컨테이너 내부 서버가 다른 포트에서 실행 중
- 서버가 3030이 아닌 다른 포트에서 실행 중일 수 있음

### 3. 컨테이너 리소스 부족
- 메모리 부족으로 서버가 응답하지 않음
- CPU 부족

## 해결 방법

### 1. 컨테이너 로그 확인
```bash
docker logs syncace --tail 200
```

### 2. 컨테이너 재시작
```bash
docker restart syncace
docker logs syncace -f
```

### 3. 컨테이너 리소스 확인
```bash
docker stats syncace
```

### 4. 컨테이너 내부 서버 확인
```bash
docker exec syncace curl http://localhost:3030/api/health
```

## 다음 단계

1. ✅ 컨테이너 확인 - syncace가 포트 3030 사용 중
2. ⏳ 컨테이너 로그 확인 필요
3. ⏳ localhost:3030에서 직접 테스트 필요
4. ⏳ 컨테이너 재시작 고려

## 중요

502 에러가 발생하는 이유는:
- nginx는 올바르게 설정됨 (포트 3030)
- 포트 3030에서 docker-proxy가 리스닝 중
- 하지만 컨테이너 내부 서버가 응답하지 않을 수 있음

**컨테이너 로그를 확인하여 실제 문제를 파악해야 합니다.**

