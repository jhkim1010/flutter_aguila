---
type: quick
slug: release-installers-to-dropbox
status: complete
created: 2026-08-04
completed: 2026-08-04
files_modified:
  - scripts/release.sh
---

# Summary: 릴리스 원커맨드 스크립트

**`./scripts/release.sh` 하나로 빌드 날짜 주입 → APK 빌드 → push → Windows CI 대기 → 아티팩트 다운로드 → Dropbox 배포 폴더 복사까지 진행한다**

## 결과

`scripts/release.sh` 신설 (실행 권한 포함). 복사 대상 3종:

| 파일 | 출처 |
|---|---|
| `Be_Cool_Setup_v{ver}_{date}.exe` | CI 아티팩트 (Inno Setup) |
| `Be_Cool_windows_portable_v{ver}_{date}.zip` | CI 아티팩트 |
| `Be_Cool_android_v{ver}_{date}.apk` | 로컬 `flutter build apk --release` |
| `Be_Cool_macOS_v{ver}_{date}.dmg` | 로컬 `build_macos_installer.sh` |

목적지 고정: `~/Dropbox/ACE_3_uversion/BeCool instaladores`

## 구현 결정

- **빌드 날짜 파일만 스테이징한다.** `git add -A` 를 쓰면 작업 트리의 무관한 변경까지
  릴리스 커밋에 딸려 들어간다. `BUILD_DATE_FILES` 배열에 든 3개만 add 한다.
- **이미 스테이징된 변경이 있으면 중단한다.** 그대로 두면 빌드 날짜 커밋에 섞인다.
- **덮어쓰지 않는다.** 같은 이름이 있으면 내용을 비교해서 같으면 건너뛰고, 다르면
  `_2`, `_3` 을 붙인다. Dropbox 배포본은 이미 배포됐을 수 있어 조용히 날리면 안 된다.
- **같은 날 재실행 시 CI 가 안 도는 문제를 처리한다.** 빌드 날짜가 그대로면 커밋할 것이
  없어 push 가 no-op 이 되고 push 트리거도 안 걸린다. HEAD sha 로 기존 run 을 찾고,
  없으면 `workflow_dispatch` 로 직접 띄운다.
- **run 조회에 재시도를 둔다.** push 직후 run 이 API 에 뜨기까지 몇 초 걸린다 (4초 × 15회).
- **`mktemp -d` + `trap cleanup EXIT`** — 중간에 죽어도 임시 디렉터리가 남지 않는다.
- **`--no-wait` 는 재개 명령을 출력한다.** 나중에 `--run-id N --no-apk --no-push` 로 회수.

## 검증

| 항목 | 결과 |
|---|---|
| `bash -n scripts/release.sh` | 통과 |
| `shellcheck` | 미설치 — 실행 못 함 |
| `-h` 사용법 출력 | 정상 |
| 알 수 없는 옵션 거부 | 정상 (사용법 출력 후 종료) |
| 실제 실행 `--run-id 30873981193 --no-apk --no-push` | **성공** — 프리플라이트 → CI 상태 확인 → 아티팩트 2개 다운로드 → 복사 |
| 중복 검사 | 동작 확인 — 내용 같은 setup.exe 를 "건너뜀" 처리 |

**미검증:** APK 빌드 경로와 commit·push 경로는 이번 실행에서 플래그로 건너뛰었다.
두 단계 모두 이 세션에서 수동으로는 성공했지만(APK 빌드 완료, `84c4dbe..23bb681` push),
스크립트를 통해서는 아직 돌려보지 않았다. `_2` 접미사 분기와 `workflow_dispatch`
폴백도 실행되지 않았다.

## 배포된 파일 (2026-08-04)

`~/Dropbox/ACE_3_uversion/BeCool instaladores/` 에 3종 모두 존재:

- `Be_Cool_Setup_v1.0.0_2026-08-04.exe` (12M)
- `Be_Cool_android_v1.0.0_2026-08-04.apk` (60M)
- `Be_Cool_windows_portable_v1.0.0_2026-08-04.zip` (14M)

## 후속: macOS DMG 추가 (2026-08-04)

`release.sh` 에 macOS 를 붙였다. DMG 자체는 기존 `build_macos_installer.sh` 가 만들고,
`release.sh` 는 그것을 호출한 뒤 산출물을 배포 폴더로 옮긴다. `--no-macos` 로 끌 수 있고,
darwin 이 아니면 프리플라이트에서 막는다.

### 발견한 버그 — 파일명에 캐리지 리턴

`pubspec.yaml` 이 **CRLF** 파일이라 다음 파싱이 값 끝에 `\r` 을 남겼다:

```sh
BUILD_NUMBER=$(grep '^version:' pubspec.yaml | sed 's/.*+//')   # → "1\r"
```

이 값이 DMG 파일명에 들어가 `Be_COOL_macOS_v1.0.0_1\r.dmg` 가 만들어졌다.
`ls` 로 디렉터리를 보면 멀쩡해 보이는데, 이름을 그대로 타이핑해 접근하면
`No such file or directory` 가 난다. 이 이름의 파일이 Dropbox 최상위에도 복사돼 있었다.

`build_macos_installer.sh`, `build_installers.sh`, `build_installers_all.sh` 세 곳 모두
같은 파싱을 쓰고 있었다. 전부 `| tr -d '\r'` 을 붙였다. Dropbox 의 깨진 이름 파일은
정상 이름으로 rename 했다.

`scripts/release.sh` 와 `.github/workflows/windows-build.yml` 은 `tr -d '[:space:]'` 를
쓰고 있어 영향이 없었다.

### 서명 상태

`security find-identity -v -p codesigning` → **0 valid identities**. DMG 는 서명되지 않는다.
다른 Mac 에서 "확인할 수 없는 개발자" 경고가 나며, DMG 안의 `앱_실행하기.command` 로
우회해야 한다. `release.sh` 가 이 경우 경고를 출력한다.

## 다음에 릴리스할 때

```bash
becool-release              # 4종 전부
becool-release --no-macos   # macOS 빼고
```
