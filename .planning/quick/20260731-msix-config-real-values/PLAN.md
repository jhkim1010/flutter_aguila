---
slug: msix-config-real-values
created: 2026-07-31
mode: quick
---

# pubspec.yaml msix_config 플레이스홀더를 실제 값으로 교체

## 문제

Windows Build 워크플로의 MSIX 단계가 실패한다 (run 30654185780):

```
invalid identity name ("identity_name"): "com.yourcompany.flutter_aguila".
need to be a string between 3 and 50 characters in length that consists of
alpha-numeric, period, and dash characters.
```

`pubspec.yaml` 의 `msix_config` 가 `flutter create` 기본 플레이스홀더 그대로다.
포터블 ZIP 단계까지는 성공하지만 MSIX 단계에서 job 이 죽어 아티팩트 업로드 단계가
아예 실행되지 않는다.

## 변경

`pubspec.yaml` 의 `msix_config` 세 필드만 교체한다.

| 필드 | 기존 | 변경 |
|---|---|---|
| `display_name` | `Flutter Águila` | `Be COOL` |
| `publisher_display_name` | `Your Name` | `Cool Sistema` |
| `identity_name` | `com.yourcompany.flutter_aguila` | `com.coolsistema.becoolaguila` |

`identity_name` 은 `android/app/build.gradle.kts` 의 `applicationId` 와 동일하게 맞춘다.
`display_name` 은 `android/app/src/main/res/values/strings.xml` 의 `app_name`,
`macos` / `ios` 표시명과 동일한 `Be COOL` 로 통일한다.

`logo_path` 는 건드리지 않는다 — Windows 러너에서만 쓰이므로 백슬래시 경로가 맞다.

## 범위 밖

- MSIX 코드 서명 인증서 — 없으면 생성은 되지만 설치 시 신뢰 오류가 난다.
  인증서 확보는 별도 작업.
- `windows-build.yml` 수정 — 워크플로 자체는 정상이다.

## 검증

1. `flutter pub get` 이 통과한다 (YAML 파싱 오류 없음)
2. `gh workflow run windows-build.yml -f build_msix=true` 재실행 시
   MSIX 단계가 통과하고 아티팩트 2개(ZIP, MSIX)가 업로드된다
