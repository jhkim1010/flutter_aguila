---
type: quick
slug: release-installers-to-dropbox
created: 2026-08-04
files_modified:
  - scripts/release.sh
---

# Quick Task: 릴리스 원커맨드 스크립트

빌드부터 Dropbox 배포까지 한 번에 끝내는 `scripts/release.sh`를 만든다.

## 배경

설치 파일이 두 경로로 갈린다:
- **APK** — macOS 로컬에서 `flutter build apk --release`로 빌드 가능
- **Windows setup.exe** — `flutter build windows`가 macOS 호스트를 거부하므로 GitHub Actions
  (`windows-build.yml`, windows-latest 러너)에서만 만들어진다

CI는 GitHub 서버에서 돌기 때문에 사용자 Mac의 Dropbox 폴더에 직접 쓸 수 없다. 로컬이
아티팩트를 받아와야 한다. 지금까지는 이 과정을 수동으로 했다.

## 목표

`./scripts/release.sh` 한 번으로:

1. `scripts/inject_build_date.sh`로 빌드 날짜 주입
2. `flutter build apk --release`
3. 빌드 날짜 파일만 커밋 후 push (push가 `windows-build.yml`을 트리거)
4. Windows CI 완료까지 대기
5. 아티팩트 다운로드
6. **모든 설치 파일**을 `~/Dropbox/ACE_3_uversion/BeCool instaladores`로 날짜별 이름 복사
   - `Be_Cool_Setup_v{version}_{date}.exe`
   - `Be_Cool_android_v{version}_{date}.apk`
   - `Be_Cool_windows_portable_v{version}_{date}.zip`

## 결정 사항

- **목적지 고정:** `~/Dropbox/ACE_3_uversion/BeCool instaladores`. 기존 배포본이 전부 여기 있다.
  최상위 `ACE_3_uversion/Be_Cool.apk`는 Gradle 훅이 덮어쓰는 "최신본" 슬롯이라 이력이 남지 않는다.
- **이름 규칙은 기존 파일을 따른다** (`Be_Cool_Setup_v1.0.0_2026-07-31.exe`,
  `Be_Cool_android_v1.0.0_2026-07-31.apk`). 포터블 ZIP은 전례가 없어 같은 꼴로 새로 정한다.
- **같은 날 재실행 시 덮어쓰지 않는다.** 내용이 다르면 `_2`, `_3` 접미사를 붙인다.
  Dropbox 배포본을 조용히 날리지 않기 위함이다.
- **빌드 날짜 파일만 스테이징한다.** 작업 트리에 다른 변경이 있어도 휩쓸어 커밋하지 않는다.
- **같은 날 두 번 돌리면 커밋할 것이 없어 push가 no-op이 되고 CI도 안 돈다.**
  이 경우 HEAD sha에 해당하는 기존 run을 찾고, 없으면 `workflow_dispatch`로 직접 띄운다.

## 작업

### Task 1: scripts/release.sh 작성

- `set -euo pipefail`, 모든 단계에 에러 핸들링
- 주석은 한국어, 변수·함수명은 영어 (프로젝트 컨벤션)
- 프리플라이트: `gh` 설치·인증, `flutter` 설치, 브랜치 확인, Dropbox 폴더 존재
- 플래그: `--no-apk`, `--no-push`, `--no-wait`, `--run-id N`, `--dest DIR`, `-h`
- 실행 권한 부여

**검증:**
- `bash -n scripts/release.sh` — 문법 에러 없음
- `shellcheck` 있으면 통과
- `./scripts/release.sh -h` — 사용법 출력
- 프리플라이트 단계까지 실제 동작 확인 (빌드는 돌리지 않음)

## Success Criteria

- `scripts/release.sh`가 존재하고 실행 가능하다
- `-h`가 사용법을 출력한다
- 문법 검사를 통과한다
- 목적지 경로가 `BeCool instaladores`로 고정되어 있다
- 세 가지 설치 파일을 모두 복사한다
