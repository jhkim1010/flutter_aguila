# Flutter Aguila 웹 배포 가이드

작성일: 2026-07-06
관련 SPEC: `.gsd/spec-web-support.md`

## 개요

앱을 기존 nginx 서버(백엔드 API와 동일 도메인)에 배포하는 가이드입니다.
동일 도메인 배포이므로 **CORS 설정이 필요 없습니다.**

## 1. 사전 확인 (중요)

### SSL 인증서
웹에서는 자체서명 인증서 우회(`SslClientHelper.createUnsafeClient`)가 **작동하지 않습니다.**
브라우저가 TLS를 직접 처리하므로 서버에 **유효한 인증서**(Let's Encrypt 등)가 필요합니다.

```bash
# 서버 인증서 확인
curl -vI https://<서버도메인> 2>&1 | grep -i "SSL certificate\|issuer"
```

자체서명 인증서를 쓰고 있다면 배포 전에 Let's Encrypt로 교체하세요:

```bash
sudo certbot --nginx -d <서버도메인>
```

### 백엔드 PostgreSQL Pool
웹 배포로 접속자가 늘면 백엔드의 pool이 고갈될 수 있습니다. 배포 전 점검:

- `max` 연결 수가 PostgreSQL `max_connections`의 10% 이하인지
- 모든 `pool.connect()`에 대응하는 `client.release()`가 `finally`에 있는지
- `idleTimeoutMillis` 설정(권장 30000)이 있는지

## 2. 빌드

```bash
# 루트 경로 배포 (https://도메인/ 에서 서비스)
./build_web.sh

# 하위 경로 배포 (https://도메인/app/ 에서 서비스)
./build_web.sh /app/
```

결과물: `build/web/`

## 3. 서버 업로드

```bash
ssh user@server "sudo mkdir -p /var/www/aguila-web && sudo chown \$USER /var/www/aguila-web"
rsync -avz --delete build/web/ user@server:/var/www/aguila-web/
```

## 4. nginx 설정

### 옵션 A: 하위 경로 배포 (권장 — 기존 API와 충돌 없음)

`./build_web.sh /app/` 으로 빌드한 뒤, 기존 server 블록에 추가:

```nginx
# Flutter 웹 앱 (기존 server 블록 안에 추가)
location /app/ {
    alias /var/www/aguila-web/;
    index index.html;
    # SPA 라우팅: 없는 경로는 index.html로
    try_files $uri $uri/ /app/index.html;
}

# 정적 자산 캐싱 (해시 파일명이므로 장기 캐시 가능)
location ~* ^/app/.+\.(js|wasm|css|png|jpg|ico|woff2?)$ {
    alias /var/www/aguila-web/;
    rewrite ^/app/(.*)$ /$1 break;
    expires 7d;
    add_header Cache-Control "public";
}
```

주의: `index.html`과 `flutter_bootstrap.js`는 캐시하면 안 됩니다(배포 갱신이 반영 안 됨).
위 설정은 index.html을 캐시 대상에서 제외하고 있습니다.

### 옵션 B: 서브도메인 배포

```nginx
server {
    listen 443 ssl;
    server_name app.<도메인>;

    ssl_certificate     /etc/letsencrypt/live/<도메인>/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/<도메인>/privkey.pem;

    root /var/www/aguila-web;
    index index.html;

    # gzip 압축 (main.dart.js가 수 MB이므로 필수)
    gzip on;
    gzip_types application/javascript application/wasm text/css application/json;
    gzip_min_length 1024;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # API 프록시 (동일 오리진 유지 → CORS 불필요)
    location /api/ {
        proxy_pass http://localhost:<백엔드포트>/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

서브도메인 배포 시 앱의 서버 URL 입력란에 `https://app.<도메인>/api` 형태로 입력하면
동일 오리진이므로 CORS가 필요 없습니다.

적용:

```bash
sudo nginx -t && sudo systemctl reload nginx
```

## 5. 로컬 개발/테스트

```bash
# Chrome에서 실행
flutter run -d chrome

# 특정 포트로 실행 (백엔드 CORS 허용 필요 시 포트 고정에 유용)
flutter run -d chrome --web-port 8080
```

로컬 개발 시(`localhost:8080` → 원격 API)는 오리진이 다르므로 CORS가 필요합니다.
**개발 기간에만** 백엔드 nginx에 아래를 추가하고, 끝나면 제거하세요:

```nginx
# ⚠️ 개발용 CORS — 운영 배포 후 제거할 것
location /api/ {
    if ($request_method = OPTIONS) {
        add_header Access-Control-Allow-Origin "http://localhost:8080";
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
        add_header Access-Control-Allow-Headers "Content-Type, x-db-name, x-db-user, x-db-password";
        return 204;
    }
    add_header Access-Control-Allow-Origin "http://localhost:8080" always;
    add_header Access-Control-Allow-Headers "Content-Type, x-db-name, x-db-user, x-db-password" always;
    proxy_pass http://localhost:<백엔드포트>/;
}
```

참고: 이 앱은 DB 자격증명을 커스텀 헤더(`x-db-name`, `x-db-user`, `x-db-password`)로
전송하므로 preflight(OPTIONS) 처리와 `Access-Control-Allow-Headers`에 해당 헤더 등록이 필수입니다.

## 6. 웹 플랫폼 동작 차이

| 기능 | 네이티브 | 웹 |
|---|---|---|
| PDF/Excel 내보내기 | 파일 저장 + 공유/미리보기 다이얼로그 | 브라우저 다운로드 |
| 생체 인증 (iOS) | Face ID/Touch ID | 생략 (바로 메인 화면) |
| 파일 로그 | 문서 폴더에 저장 (디버그) | 브라우저 콘솔만 |
| MAC 주소 | 플랫폼별 조회 | 불가 (null 반환) |
| 오프라인 SQLite 캐시 | (미사용) | 미지원 |
| 자체서명 인증서 | 우회 가능 | 불가 — 유효한 인증서 필요 |
| 창 관리 (window_manager) | 데스크톱에서 활성 | 비활성 |

## 7. 배포 후 확인 체크리스트

- [ ] `https://<도메인>/app/` 접속 → 로딩 화면 후 연결 화면 표시
- [ ] 서버 연결 → 로그인 성공
- [ ] Ventas / Stocks / Items / Gastos 리포트 조회
- [ ] 리포트 테이블 헤더/행 칼럼 정렬 일치 확인 (Core Value)
- [ ] PDF 다운로드 → 파일 열림 확인
- [ ] Excel 다운로드 → 파일 열림 확인
- [ ] 브라우저 콘솔(F12)에 에러 없는지 확인
- [ ] 모바일 브라우저(iPhone/Android)에서 레이아웃 확인
- [ ] 백엔드 로그에 신규 에러 없는지 확인 (`항상 마지막 로그파일 확인`)
- [ ] PostgreSQL 연결 수 모니터링: `SELECT count(*) FROM pg_stat_activity;`

## 8. 트러블슈팅

- **빌드 시 web 템플릿 경고/오류**: `flutter create . --platforms web` 로 템플릿 재생성
  (기존 index.html 커스텀 내용은 백업 후 병합)
- **대용량 테이블 스크롤 성능 저하**: CanvasKit 렌더러가 기본입니다.
  `flutter build web --release --web-renderer html` 로 비교 테스트 가능 (구버전 Flutter만 해당)
- **한글/스페인어 폰트 깨짐 (PDF)**: 웹에서도 PDF 생성은 동일한 pdf 패키지를 사용하므로
  네이티브와 동일하게 동작합니다. 문제가 있으면 폰트 에셋 로딩을 확인하세요.
- **새로고침 시 404**: nginx `try_files` 설정(SPA fallback) 확인
