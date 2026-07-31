---
slug: msix-code-signing
created: 2026-07-31
mode: quick
---

# MSIX 자체 서명 인증서로 서명해 Windows 설치 가능하게 만들기

## 문제

run 30655724741 이 만든 MSIX 는 msix 도구가 자동 생성한 테스트 인증서로 서명돼 있다.
패키지 내부 `AppxSignature.p7x` 의 서명 주체가 `Msix Testing Corporation` 이다.
Windows 는 신뢰되지 않은 인증서로 서명된 MSIX 설치를 거부하므로 그대로는 배포 불가다.

## 접근

상용 코드 서명 인증서 대신 자체 서명 인증서를 쓴다. 대상 PC 마다 최초 1회
관리자 권한으로 인증서를 `LocalMachine\TrustedPeople` 에 등록하는 비용을 감수한다.
등록 후에는 같은 인증서로 서명한 모든 버전이 추가 작업 없이 설치·업데이트된다.

## 작업

1. **인증서 생성** (로컬, macOS/openssl)
   - RSA 4096, `extendedKeyUsage=codeSigning`, `basicConstraints=CA:FALSE`
   - 유효기간 5년
   - PKCS#12(.pfx) 로 내보내기 — Windows signtool 호환 위해 3DES/SHA1 암호화 사용
   - 배포용 공개 인증서(.cer, DER) 별도 추출
   - 저장 위치: `~/code-signing/` — **저장소 밖**. 커밋 금지.

2. **publisher 문자열 일치**
   - MSIX 는 `AppxManifest.xml` 의 `Publisher` 와 서명 인증서 Subject 가
     완전히 일치해야 설치를 허용한다.
   - 인증서에서 RFC2253 형식 Subject 를 읽어 `pubspec.yaml` 의
     `msix_config.publisher` 에 그대로 넣는다.

3. **GitHub Secrets 등록**
   - `WINDOWS_CERT_PFX_BASE64` — PFX 를 base64 인코딩한 값
   - `WINDOWS_CERT_PASSWORD` — PFX 비밀번호
   - PFX 자체는 저장소에 절대 넣지 않는다.

4. **워크플로 수정** (`.github/workflows/windows-build.yml`)
   - 시크릿을 임시 PFX 파일로 디코딩
   - `msix:create` 에 `--certificate-path` / `--certificate-password` 전달
   - `--install-certificate false` 는 유지 (러너에 설치할 이유 없음)
   - 스텝 종료 시 PFX 삭제
   - 시크릿 미설정 시에도 빌드가 깨지지 않도록 분기 (테스트 인증서로 폴백)

5. **배포물**
   - 서명된 MSIX 를 `BeCool instaladores` 에 배치
   - `.cer` 와 PC 등록 안내문을 같은 폴더에 배치

## 검증

- `openssl pkcs12` 로 PFX 가 열리고 EKU 에 codeSigning 이 있는지 확인
- CI 성공 후 MSIX 의 `AppxSignature.p7x` 서명 주체가
  `Msix Testing Corporation` 이 아닌 `Cool Sistema` 인지 확인
- `AppxManifest.xml` 의 `Publisher` 가 인증서 Subject 와 일치하는지 확인

## 범위 밖

- SmartScreen 평판 — 자체 서명으로는 해결되지 않는다. 상용 인증서 영역.
- Inno Setup EXE 설치 프로그램 — 별도 작업.
