# SPEC: Flutter Web 지원 추가
생성일: 2026-07-06
상태: EXECUTE 완료 — 로컬 검증(flutter analyze / build web) 대기

## 목표
Flutter Aguila 앱을 웹 브라우저에서 실행 가능하게 하고, 기존 nginx 서버(API 서버와 동일 도메인)에 배포한다.
기존 iOS/Android/데스크톱 기능에는 영향을 주지 않는다.

## 배경 및 컨텍스트

### 마지막 로그 확인 결과 (logs/flutter_log_20260515_220122.txt)
- 치명적 에러 없음. buildTipoSelector 중복 ID 제거 등 정상 디버그 로그만 존재.
- 웹 지원 작업과 충돌하는 미해결 이슈 없음.

### 웹 빌드를 막는 요소 (dart:io를 import하는 9개 파일)

| 파일 | 문제 | 웹 대응 |
|---|---|---|
| `lib/utils/ssl_client_helper.dart` | `HttpClient`+`badCertificateCallback` (자체서명 인증서 우회) | 웹은 브라우저가 TLS 처리 → 조건부 import로 웹에서는 기본 `http.Client()` 반환. **서버 인증서가 유효해야 함(동일 도메인 nginx 배포로 해결)** |
| `lib/utils/log_file_writer.dart` | `File` 기반 로그 저장 | 웹에서는 콘솔 로깅만 (kIsWeb 가드) |
| `lib/utils/device_info_helper.dart` | `Platform.*` + network_info_plus | kIsWeb 분기, 웹은 브라우저 정보 반환 |
| `lib/services/pdf_service.dart` | PDF를 `File`로 저장 | 웹은 bytes → 브라우저 다운로드 (조건부 import 헬퍼) |
| `lib/services/excel_service.dart` | Excel을 `File`로 저장 | 동일 (브라우저 다운로드) |
| `lib/screens/helpers/biometric_auth_handler.dart` | `Platform.isIOS`, local_auth | 웹은 생체인증 skip (기존 데스크톱과 동일 경로) |
| `lib/screens/report_screen_legacy.dart` | dart:io 사용 (내보내기 관련) | kIsWeb 가드 또는 헬퍼 경유로 변경 |
| `lib/screens/reports/stocks_report_view.dart` | dart:io 사용 | 동일 |
| `lib/services/local_database_service.dart` | sqflite + dart:io | **실제 미사용** (lib/examples/ 에서만 참조) → 수정 불필요, entrypoint에서 import되지 않음만 확인 |

### 기타 확인 사항
- `lib/main.dart`: window_manager import — 런타임에는 isDesktop() 가드가 있으나 **컴파일 타임에 웹에서 깨질 수 있음** → 조건부 import 래퍼 필요
- `lib/utils/platform_utils.dart`: `defaultTargetPlatform` 사용이라 웹 안전. 단 `isDesktop()`이 웹에서 뭘 반환할지 정의 필요 → **웹은 화면 크기 기반으로 desktop/tablet/mobile 판정하는 `isWeb()` 추가**
- `web/` 디렉토리 이미 존재 (index.html, manifest.json, icons) → flutter create 재실행 불필요
- 오프라인 캐시: 웹 미지원 확정 (사용자 결정 — 어차피 미사용 코드)
- CORS: 동일 도메인 배포이므로 불필요. 단, 로컬 개발 시(`flutter run -d chrome`)에는 API 서버에 CORS 허용 또는 프록시 필요 → nginx에 개발용 CORS 설정 옵션 문서화

## 기술 스택
- 언어/프레임워크: Flutter 3.x / Dart 3.0+
- DB: 원격 PostgreSQL (백엔드 API 경유, 앱에서 직접 연결 없음 → pool 영향 없음. 단, 웹 사용자 증가 시 백엔드 pool 부하 주의)
- ESLint: 해당 없음 (Dart) → `flutter analyze`로 대체
- 상태관리: 기존 구조 유지

## 태스크 목록

### Phase A — 웹 호환 코드 수정 (완료)
- [x] TASK-1: 조건부 import 인프라 생성 — `lib/utils/web_compat/web_file_saver.dart` (+ `_stub`, `_html`)
  ※ 구현 중 확인: Flutter 웹에서 dart:io는 스텁으로 컴파일되고 런타임에만 예외 발생
  → 조건부 import는 dart:html이 필요한 파일 저장에만 사용, 나머지는 kIsWeb 런타임 가드로 처리 (변경 최소화)
- [x] TASK-2: `ssl_client_helper.dart` → 웹에서는 기본 http.Client 반환 (kIsWeb 가드)
- [x] TASK-3: `main.dart` → window_manager/로그/생체인증 진입을 `!kIsWeb` 가드로 차단
- [x] TASK-4: `log_file_writer.dart` → 웹에서 파일 로깅 비활성 (콘솔만)
- [x] TASK-5: `device_info_helper.dart` → getPlatform()에 'web' 추가, getMacAddress()는 웹에서 null
- [x] TASK-6: `biometric_auth_handler.dart` → 웹에서 생체인증 skip, exit() 차단
- [x] TASK-7: `pdf_service.dart` / `excel_service.dart` → 웹에서 브라우저 다운로드 (saveFileOnWeb), 네이티브 경로 무변경
- [x] TASK-8: 호출부 6곳(report_share_helper 2, stocks_report_view 2, clientes_report_section 2)에 웹 조기 반환 + 완료 스낵바, Platform.isX 평가 지점 단락 가드
- [x] TASK-9: `platform_utils.dart` → `isWeb()` 추가, isDesktop() 웹 동작 문서화
- [x] (추가) `web/index.html`, `web/manifest.json` 앱 이름 브랜딩 (Be COOL)

### Phase B — 검증
- [x] 정적 검증: main.dart 도달 그래프 75개 파일 분석 — sqflite/local_database_service/examples 미도달 확인,
  dart:html 직접 import 없음, kIsWeb 사용 파일 전부 import 확인, 괄호 균형 확인
- [ ] TASK-10: `flutter analyze` 오류 0개 확인 — **로컬 실행 필요** (샌드박스에 Flutter SDK 없음)
- [ ] TASK-11: `flutter build web --release` 성공 확인 — **로컬 실행 필요**
- [ ] TASK-12: 기존 플랫폼 회귀 확인 — macOS 디버그 실행 + 최신 로그 파일에 신규 에러 없는지 확인 — **로컬 실행 필요**

### Phase C — 배포 준비 (완료)
- [x] TASK-13: `docs/WEB_DEPLOY_GUIDE.md` — nginx 설정(하위경로/서브도메인), SPA fallback, gzip, 캐시, 개발용 CORS(커스텀 헤더 x-db-* 포함), SSL 인증서 확인, PostgreSQL pool 점검 항목
- [x] TASK-14: `build_web.sh` — base-href 파라미터 지원, analyze 포함

## 완료 기준
- `flutter analyze` 오류 0개
- `flutter build web --release` 성공
- 웹에서: 서버 연결 → 로그인 → Ventas/Stocks 리포트 조회 → PDF/Excel 다운로드 동작
- iOS/Android/macOS/Windows/Linux 기존 동작 무변경 (API 인터페이스 변경 없음)
- 리포트 테이블 헤더/행 칼럼 정렬 일치 (Core Value) — 웹 렌더러에서도 확인

## 금지사항 / 주의사항
- 백엔드 API 인터페이스 변경 금지
- 기존 네이티브 플랫폼 코드 경로 동작 변경 금지 (조건부 분기만 추가)
- `report_screen_legacy.dart`(6583줄)는 dart:io 사용 부분만 최소 수정 — 리팩터링 금지
- 자체서명 인증서 우회는 웹에서 불가능 — 운영 서버에 유효한 인증서(Let's Encrypt 등) 필요 여부를 배포 전 확인
- 웹 사용자 증가 시 백엔드 PostgreSQL pool 고갈 주의 — 배포 가이드에 pool 설정 점검 항목 포함
- HTML 렌더러 vs CanvasKit: 대용량 테이블 성능 고려해 CanvasKit 기본, 필요 시 비교 테스트
