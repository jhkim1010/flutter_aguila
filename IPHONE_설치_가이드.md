# iPhone용 IPA 설치 파일 생성 가이드

## 현재 상황

Archive 파일이 성공적으로 생성되었습니다:
- 위치: `build/ios/archive/Runner.xcarchive`
- 크기: 165.9MB

하지만 IPA 파일 생성에는 Apple Developer 인증서와 프로비저닝 프로파일이 필요합니다.

## 방법 1: Xcode를 통한 IPA 생성 (권장)

### 단계별 가이드

1. **Archive 파일 열기**
   ```bash
   open build/ios/archive/Runner.xcarchive
   ```
   또는 Xcode에서:
   - Window > Organizer
   - Archives 탭에서 최신 Archive 선택

2. **IPA Export**
   - Archive 선택 후 "Distribute App" 버튼 클릭
   - 배포 방법 선택:
     - **Ad Hoc**: 특정 기기에만 설치 가능 (UDID 등록 필요)
     - **Development**: 개발용 (연결된 기기에만)
     - **Enterprise**: 엔터프라이즈 배포용

3. **Ad-Hoc 배포 선택 시**
   - 설치할 iPhone의 UDID가 Apple Developer에 등록되어 있어야 함
   - Ad-Hoc 프로비저닝 프로파일이 자동 생성됨

4. **IPA 파일 저장**
   - Export 위치 선택
   - IPA 파일이 생성됨

## 방법 2: Development 배포용 IPA 생성

개발자 인증서가 있는 경우:

```bash
cd /Users/marcoskim/Trabajos_Programming/flutter_aguila
flutter build ipa --release --export-method development
```

생성된 IPA 파일 위치: `build/ios/ipa/*.ipa`

## 방법 3: TestFlight 사용 (App Store Connect)

1. App Store Connect에 앱 업로드
2. TestFlight에 추가
3. 베타 테스터로 초대
4. iPhone에서 TestFlight 앱으로 설치

## 다른 iPhone에 설치하는 방법

### 방법 A: Finder를 통한 설치

1. **iPhone을 Mac에 USB로 연결**
2. **Finder에서 iPhone 선택**
3. **IPA 파일을 Finder 창으로 드래그 앤 드롭**
4. **iPhone에서 신뢰 설정:**
   - 설정 > 일반 > VPN 및 기기 관리
   - 개발자 앱 섹션에서 "신뢰" 선택

### 방법 B: AirDrop 사용

1. **Mac과 iPhone에서 AirDrop 활성화**
2. **IPA 파일을 AirDrop으로 전송**
3. **iPhone에서 파일 받기**
4. **설치 후 신뢰 설정**

### 방법 C: 이메일/클라우드 저장소

1. **IPA 파일을 이메일이나 클라우드에 업로드**
2. **iPhone에서 다운로드**
3. **파일 앱에서 IPA 파일 열기**
4. **설치 후 신뢰 설정**

## 중요 사항

### Ad-Hoc 배포의 경우:
- ✅ 설치하려는 iPhone의 UDID가 Apple Developer에 등록되어 있어야 함
- ✅ Ad-Hoc 프로비저닝 프로파일이 필요함
- ✅ 최대 100대의 기기에 설치 가능

### Development 배포의 경우:
- ✅ Mac에 연결된 iPhone에만 설치 가능
- ✅ 개발자 인증서 필요

### Enterprise 배포의 경우:
- ✅ Enterprise 인증서 필요
- ✅ 제한 없이 설치 가능

## iPhone UDID 확인 방법

### iPhone에서:
1. 설정 > 일반 > 정보
2. UDID를 길게 눌러 복사

### Mac에서 (iPhone 연결 시):
1. Finder에서 iPhone 선택
2. 일반 탭에서 UDID 확인

### 터미널에서:
```bash
# iPhone이 연결되어 있을 때
system_profiler SPUSBDataType | grep -A 11 iPhone
```

## 문제 해결

### "신뢰할 수 없는 개발자" 오류
- 설정 > 일반 > VPN 및 기기 관리에서 개발자 앱 신뢰

### "앱을 설치할 수 없음" 오류
- iPhone의 UDID가 Apple Developer에 등록되어 있는지 확인
- 프로비저닝 프로파일이 올바른지 확인

### 코드 서명 오류
- Xcode에서 Signing & Capabilities 확인
- Development Team이 올바르게 설정되어 있는지 확인

## 현재 Archive 정보

- **Bundle ID**: com.coolsistema.becoolaguila
- **버전**: 1.0.0 (Build 1)
- **팀 ID**: W93P494PLH
- **Archive 위치**: `build/ios/archive/Runner.xcarchive`

## 다음 단계

1. Xcode Organizer에서 Archive 열기
2. "Distribute App" 선택
3. 배포 방법 선택 (Ad-Hoc 권장)
4. IPA 파일 Export
5. Dropbox에 복사하여 다른 iPhone에 전송

