# Ad Hoc IPA 빌드 단계별 가이드

## 현재 상태
✅ Flutter 의존성 설치 완료
✅ iOS Pods 설치 완료
✅ Xcode 프로젝트 준비 완료

## 다음 단계

### 1단계: Xcode에서 Archive 생성

Xcode가 이미 열려있습니다. 다음을 수행하세요:

1. **Xcode 상단 메뉴에서:**
   - **Product** > **Archive** 클릭
   - Archive 생성이 시작됩니다 (몇 분 소요)

2. **Archive 완료 대기**
   - 빌드가 완료될 때까지 기다립니다
   - 완료되면 자동으로 **Organizer** 창이 열립니다

3. **Archive 완료 확인**
   - Organizer 창에 Archive가 표시되면 성공입니다

### 2단계: Ad Hoc IPA 생성

터미널에서 다음 명령어를 실행하세요:

```bash
cd /Users/marcoskim/Trabajos_Programming/flutter_app
./export_ipa.sh ad-hoc
```

이 명령어는:
- 최신 Archive 파일을 찾습니다
- Ad Hoc 배포용 IPA를 생성합니다
- Dropbox 폴더에 `Be_Cool.ipa` 파일을 저장합니다

### 3단계: iPhone에 설치

1. **Finder에서 iPhone 연결**
   - iPhone을 Mac에 USB로 연결
   - Finder에서 iPhone 선택

2. **IPA 파일 설치**
   - 생성된 IPA 파일 위치: `~/Dropbox/ACE_3_uversion/Be_Cool.ipa`
   - Finder의 iPhone 파일 탭에서 IPA 파일을 드래그 앤 드롭
   - 또는 AirDrop으로 전송

3. **설치 확인**
   - iPhone에서 앱이 설치되는지 확인
   - 만약 "앱을 설치할 수 없습니다" 오류가 나면:
     - iPhone의 UDID가 Apple Developer에 등록되어 있는지 확인
     - 설정 > 일반 > VPN 및 기기 관리에서 개발자 인증서 신뢰

## 문제 해결

### Archive 생성 실패
- Xcode > Preferences > Accounts에서 Apple ID 로그인 확인
- Runner 프로젝트 > Signing & Capabilities에서 Team 선택 확인
- "Automatically manage signing" 체크 확인

### IPA 생성 실패
- Archive가 생성되었는지 확인
- Xcode > Window > Organizer에서 Archive 확인

### 설치 실패
- iPhone의 UDID가 Apple Developer에 등록되어 있는지 확인
- Ad Hoc 프로비저닝 프로파일이 생성되어 있는지 확인
- 설정 > 일반 > VPN 및 기기 관리에서 개발자 인증서 신뢰

## 빠른 명령어

```bash
# Archive 생성 후 IPA 생성
./export_ipa.sh ad-hoc

# 또는 전체 프로세스 다시 시작
./build_ad_hoc_ipa.sh
```
