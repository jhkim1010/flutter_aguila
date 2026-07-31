---
slug: msix-config-real-values
status: complete
completed: 2026-07-31
commits:
  - 3b272ff
  - b7ff40e
---

# Summary

Windows MSIX 빌드가 통과하도록 두 지점을 고쳤다. 계획보다 한 단계가 늘었다 —
`identity_name` 을 고치자 그 다음 실패가 드러났기 때문이다.

## 1차: pubspec.yaml msix_config (3b272ff)

계획대로 세 필드를 교체했다.

| 필드 | 기존 | 변경 |
|---|---|---|
| `display_name` | `Flutter Águila` | `Be COOL` |
| `publisher_display_name` | `Your Name` | `Cool Sistema` |
| `identity_name` | `com.yourcompany.flutter_aguila` | `com.coolsistema.becoolaguila` |

결과: `invalid identity name` 은 사라졌고 `flutter_app.msix` (18MB) 가 실제로
생성됐다. 하지만 run 30655247769 은 여전히 실패했다.

## 2차: 워크플로 인증서 프롬프트 (b7ff40e) — 계획 밖

MSIX 를 만든 직후 msix 도구가 멈췄다:

```
Do you want to install the certificate: "test_certificate.pfx" ? (y/N)
Unhandled exception: type 'Null' is not a subtype of type 'FutureOr<String>'
```

서명 인증서를 지정하지 않으면 msix 가 자체 서명 테스트 인증서를 만든 뒤 머신
저장소에 설치할지 묻는다. 러너에는 stdin 이 없어 read 가 null 을 반환하고 크래시한다.
`--install-certificate false` 로 프롬프트를 껐다.

같은 커밋에서 업로드 단계 두 개에 `if: ${{ !cancelled() }}` 를 걸었다. run
30654185780 과 30655247769 둘 다 포터블 ZIP 은 완성됐는데 MSIX 실패로 job 이 죽어
아티팩트가 하나도 남지 않았다. MSIX 업로드는 `if-no-files-found: warn` 으로 낮췄다 —
패킹 전에 실패하면 파일이 정말 없을 수 있다.

## 검증

- `flutter pub get` 통과 (YAML 파싱 정상)
- `python3 -c "yaml.safe_load(...)"` 로 워크플로 YAML 검증
- run 30655724741 **성공**, 아티팩트 2개 업로드:
  - `Be_Cool-windows-x64-1.0.0` (14.7MB)
  - `Be_Cool-windows-msix-1.0.0` (18.2MB)

## 남은 것

MSIX 는 **서명되지 않았다**. 자체 서명 테스트 인증서로 패킹돼 있어 그대로는 설치할 수
없다. 실제 배포하려면 코드 서명 인증서를 구해 `msix_config` 에 `publisher`
(인증서 subject) 와 `certificate_path` / `certificate_password` 를 추가하고,
워크플로에서 인증서를 시크릿으로 주입해야 한다. 그전까지 Windows 실배포는 포터블 ZIP 이
현실적이다. 배포본 파일명에 `SIN-FIRMAR` 를 붙여 구분해 두었다.
