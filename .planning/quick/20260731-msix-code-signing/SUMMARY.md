---
slug: msix-code-signing
status: complete
completed: 2026-07-31
commits:
  - 630dd2f
---

# Summary

MSIX 가 Cool Sistema 자체 서명 인증서로 서명되어 Windows 에서 설치 가능해졌다.
계획대로 진행했으나 인증서 DN 순서에서 한 번 걸렸다.

## 인증서

macOS 에서 openssl 로 생성했다 (Windows 불필요).

- RSA 4096, `extendedKeyUsage=codeSigning`, `basicConstraints=CA:FALSE`
- 유효기간 5년 — 2031-07-30 만료
- 저장 위치: `~/code-signing/` (권한 700, 저장소 밖)
  - `BeCool-codesign.pfx` — 개인키 포함, 권한 600
  - `BeCool-codesign.cer` — 배포용 공개 인증서
  - `.pfx-password.txt` — 권한 600

GitHub Secrets: `WINDOWS_CERT_PFX_BASE64`, `WINDOWS_CERT_PASSWORD`

## 걸린 지점: DN 순서

1차 인증서를 `-subj "/CN=.../O=.../C=AR"` 로 만들었더니 signtool 이 실패했다:

```
Error information: "Error: SignerSign() failed." (-2147024885/0x8007000b)
```

`0x8007000b` 은 ERROR_BAD_FORMAT 이고, MSIX 서명에서는 매니페스트 `Publisher` 와
인증서 Subject 불일치를 뜻한다. 인증서는 정상 선택됐고(Issued to: Cool Sistema)
매니페스트도 의도한 값이었는데도 실패했다.

원인은 DER 요소 순서다. openssl `-subj` 는 적은 순서 그대로 DER 을 만드는데,
X.500 관례는 일반 -> 구체 순서(C, O, CN)다. Windows 와 RFC2253 은 DER 을 역순으로
표시하므로, `/CN=/O=/C=` 로 만든 인증서는 Windows 에서
`C=AR, O=Cool Sistema, CN=Cool Sistema` 로 읽힌다 — 매니페스트와 반대다.

`-subj "/C=AR/O=Cool Sistema/CN=Cool Sistema"` 로 재발급해 해결했다. 확인 방법:

```
openssl x509 -in becool-cert.pem -noout -subject -nameopt RFC2253
subject=CN=Cool Sistema,O=Cool Sistema,C=AR   # 매니페스트와 같은 순서여야 한다
```

`pubspec.yaml` 은 손대지 않았다 — 인증서를 매니페스트에 맞췄다.

## 워크플로 (630dd2f)

- 시크릿을 `env:` 로 받아 PowerShell 변수로 참조 (run 본문에 `${{ }}` 직접 삽입 안 함)
- `RUNNER_TEMP` 에 PFX 디코딩 후 `--certificate-path` / `--certificate-password` 전달
- `finally` 블록에서 PFX 삭제 — 러너 디스크에 개인키를 남기지 않는다
- 시크릿 없으면 테스트 인증서로 폴백하고 경고만 출력 (포크에서 빌드가 깨지지 않도록)

## 검증

run 30657529026 성공. 아티팩트의 `AppxSignature.p7x` 서명 주체가
`Msix Testing Corporation` 에서 `Cool Sistema` 로 바뀐 것을 확인했고,
매니페스트 `Publisher="CN=Cool Sistema, O=Cool Sistema, C=AR"` 와 일치한다.

## 배포물

`~/Dropbox/ACE_3_uversion/BeCool instaladores/`

- `Be_Cool_windows_v1.0.0_2026-07-31.msix` (18.3MB, 서명됨)
- `Be_Cool_windows-x64_v1.0.0_2026-07-31.zip` (14.7MB, 포터블)
- `BeCool-codesign.cer` — 대상 PC 등록용
- `INSTALAR-Be_COOL-Windows.txt` — 스페인어/한국어 설치 안내

## 남은 것

- 대상 PC 마다 최초 1회 관리자 권한으로 `.cer` 를 `LocalMachine\TrustedPeople` 에
  등록해야 한다. 자체 서명의 구조적 한계이며 상용 인증서로만 없앨 수 있다.
- SmartScreen 평판은 자체 서명으로 해결되지 않는다.
- 인증서 만료 2031-07-30. 갱신 시 Subject 를 동일하게 유지해야 기존 설치가
  업데이트로 인식된다.
