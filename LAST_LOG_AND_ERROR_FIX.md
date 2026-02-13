# 마지막 로그 확인 및 오류 해결 가이드

## 1. 로그 파일 위치

### Flutter 실행 로그 (run_with_log 사용 시)
- **위치**: `flutter_aguila/logs/flutter_log_YYYYMMDD_HHMMSS.txt`
- **확인**: 프로젝트 루트에서 `logs` 폴더를 연 뒤, **수정일시가 가장 최근인 파일**이 마지막 로그입니다.

```powershell
# PowerShell: 마지막 로그 파일 찾기
Get-ChildItem logs -Filter "*.txt" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
```

### 앱 내부 로그 (디버그 모드)
- **Windows**: `%USERPROFILE%\AppData\Roaming\com.yourcompany.flutter_app\...\logs\app_log_*.txt`
- **macOS**: `~/Library/Containers/.../Documents/logs/`
- 앱 실행 시 콘솔에 `📝 로그 파일 초기화 완료: (경로)` 로 출력됩니다.

### Docker/서버 로그 (502·API 오류 시)
- **컨테이너 로그**: `docker logs syncace --tail 200`
- **Nginx**: `sudo tail -100 /var/log/nginx/error.log`

---

## 2. 자주 발생하는 “엄청난 오류”와 해결책

### (1) Inno Setup: `Undeclared identifier: MyAppVersion`
- **증상**: `installer.iss` 컴파일 시 14번째 줄 근처에서 `MyAppVersion` 오류.
- **원인**: 5번째 줄이 `$11.0.0"` 처럼 잘못되어 있음.
- **해결**:
  1. `installer.iss` 5번째 줄을 아래처럼 수정:
     ```iss
     #define MyAppVersion "11.0.0"
     ```
  2. 또는 **빌드 스크립트**를 사용하면 자동 수정됨:
     ```powershell
     .\build_windows_installer.ps1
     ```

### (2) 502 Bad Gateway / Empty reply from server
- **증상**: resumen del día 등 특정 API만 502 또는 `Empty reply from server`.
- **원인**: 서버/DB 타임아웃, `ventas_rpt_a_day` 함수 없음·시그니처 불일치, 트랜잭션 롤백 등.
- **해결**:
  1. **마지막 서버 로그** 확인:
     ```bash
     docker logs syncace --tail 200
     docker logs syncace --tail 500 | grep -i "error\|exception\|timeout\|502"
     ```
  2. **직접 API 호출**로 재현:
     ```bash
     curl -X POST http://localhost:3030/api/resumen_del_dia \
       -H "Content-Type: application/json" \
       -H "x-db-name: inquieta14" \
       -d '{"date":"2025-12-17"}' -w "\n시간: %{time_total}초\n"
     ```
  3. DB 함수 확인:
     ```sql
     SELECT n.nspname, p.proname, pg_get_function_arguments(p.oid)
     FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid
     WHERE p.proname = 'ventas_rpt_a_day';
     ```
- **상세**: `RESUMEN_DEL_DIA_502_FIX.md`, `EMPTY_REPLY_DIAGNOSIS.md`, `SERVER_FIX_GUIDE.md` 참고.

### (3) 서버 함수 없음: `function does not exist`
- **증상**: `ventas_rpt_a_day` 호출 시 "function does not exist".
- **해결**: `SERVER_FIX_GUIDE.md` 참고. 스키마·인자 타입(date/timestamp/text) 맞추거나, 서버에서 fallback 쿼리 사용.

### (4) Flutter 빌드/실행 오류
- **마지막 빌드 로그**는 터미널에 바로 출력됩니다. 복사해서 보관하면 됩니다.
- **로그 파일로 남기려면**:
  ```bash
  # macOS/Linux
  ./run_with_log.sh macos
  ```
  Windows에서는 PowerShell에서:
  ```powershell
  New-Item -ItemType Directory -Force -Path logs | Out-Null
  $ts = Get-Date -Format "yyyyMMdd_HHmmss"
  flutter run -d windows 2>&1 | Tee-Object -FilePath "logs\flutter_log_$ts.txt"
  ```
  이후 `logs` 폴더에서 **가장 최근 파일**이 마지막 로그입니다.

---

## 3. “마지막 로그”만 빠르게 보는 방법

1. **Flutter/앱 로그**: `logs` 폴더에서 수정일이 가장 최근인 `.txt` 파일 열기.
2. **서버 로그**: `docker logs syncace --tail 300` 실행 후 출력 저장.
3. **빌드 오류**: 방금 실행한 `flutter build ...` 또는 `.\build_windows_installer.ps1` 터미널 출력을 복사해 텍스트 파일로 저장.

---

## 4. 정리

| 오류 종류           | 확인할 “마지막 로그”        | 참고 문서                    |
|--------------------|-----------------------------|------------------------------|
| Inno Setup         | 터미널 출력                 | `FIX_INSTALLER_ISS.md`       |
| 502 / Empty reply  | `docker logs syncace`       | `RESUMEN_DEL_DIA_502_FIX.md`, `EMPTY_REPLY_DIAGNOSIS.md` |
| function not exist | 서버 로그 + DB 쿼리 결과    | `SERVER_FIX_GUIDE.md`        |
| Flutter 빌드/앱    | `logs/flutter_log_*.txt` 또는 터미널 | `LOG_FILE_GUIDE.md`  |

현재 프로젝트에는 `logs/` 안에 로그 파일이 없을 수 있습니다.  
**지금 겪는 오류 메시지(전체)를 복사해 주시면**, 그에 맞춰 원인과 해결 단계를 구체적으로 적어 드리겠습니다.
