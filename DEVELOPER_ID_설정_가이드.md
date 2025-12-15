# Developer ID 인증서 설정 가이드

## 현재 상황

✅ Apple Development 인증서: 있음
❌ Developer ID Application 인증서: 없음

**다른 Mac에서 경고 없이 실행하려면 Developer ID Application 인증서가 필요합니다.**

## Developer ID 인증서 발급 방법

### 방법 1: Xcode에서 자동 생성 (권장)

1. **Xcode 열기**
   ```bash
   open -a Xcode macos/Runner.xcworkspace
   ```

2. **프로젝트 설정 열기**
   - 왼쪽 프로젝트 네비게이터에서 "Runner" 프로젝트 선택
   - "Runner" 타겟 선택
   - "Signing & Capabilities" 탭 선택

3. **Team 설정**
   - "Team" 드롭다운에서 Apple Developer 계정 선택
   - "Automatically manage signing" 체크

4. **Release 빌드 설정**
   - 상단에서 "Release" 구성 선택
   - "Signing Certificate"에서 "Developer ID Application" 선택
   - 없으면 "Manage Certificates..." 클릭하여 생성

### 방법 2: Apple Developer 웹사이트에서 생성

1. **Apple Developer 포털 접속**
   - https://developer.apple.com/account 접속
   - 로그인

2. **인증서 생성**
   - "Certificates, Identifiers & Profiles" 선택
   - "Certificates" 섹션에서 "+" 버튼 클릭
   - "Developer ID Application" 선택
   - CSR 파일 생성 (Keychain Access에서)
   - CSR 파일 업로드하여 인증서 다운로드
   - 다운로드한 인증서 더블클릭하여 Keychain에 설치

### 방법 3: 터미널에서 확인 및 생성

```bash
# 현재 인증서 확인
security find-identity -v -p codesigning

# Developer ID 인증서가 없으면 Xcode에서 생성 필요
```

## 인증서 발급 후 DMG 재생성

Developer ID 인증서를 발급받은 후:

```bash
./build_macos_installer.sh
```

스크립트가 자동으로 Developer ID 인증서를 찾아서 서명합니다.

## 현재 상태로도 사용 가능

현재 DMG 파일도 다른 Mac에서 사용 가능하지만, 사용자가 다음 중 하나를 해야 합니다:

1. **DMG의 "앱_실행하기.command" 실행**
2. **앱 우클릭 > "열기" 선택** (첫 실행 시)
3. **터미널에서 실행:**
   ```bash
   xattr -cr "/Applications/Be COOL.app"
   ```

## 참고사항

- **Apple Developer Program 가입 필요**: Developer ID 인증서는 유료 프로그램($99/년) 가입이 필요합니다
- **인증서 유효기간**: 1년 (갱신 필요)
- **서명된 앱의 장점**: 
  - Gatekeeper 경고 없음
  - 사용자 신뢰도 향상
  - 자동 업데이트 가능 (Notarization 필요)
