# Apple Developer Program 가입 후 설정 가이드

## 현재 상황

✅ Apple Developer Program 가입 완료
⚠️ 인증서 및 프로비저닝 프로파일 설정 필요

## Xcode에서 인증서 설정하기

### 1단계: Xcode Organizer 열기

Archive 파일이 열려있어야 합니다. 없다면:
```bash
open build/ios/archive/Runner.xcarchive
```

### 2단계: Distribute App 클릭

1. Archive 선택 후 **"Distribute App"** 버튼 클릭

### 3단계: Release Testing 선택

1. **"Release Testing"** 옵션 선택 (두 명의 사람 아이콘)
2. **"Distribute"** 버튼 클릭

### 4단계: 배포 방법 선택

다음 화면에서:
1. **"Ad Hoc"** 선택
2. **Next** 클릭

### 5단계: 자동 서명 설정

1. **"Automatically manage signing"** 선택 (권장)
   - Xcode가 자동으로 인증서와 프로비저닝 프로파일을 생성합니다
2. **Team 선택**: "JungHo Kim (W93P494PLH)" 선택
3. **Next** 클릭

### 6단계: 기기 등록 (선택사항)

- 설치할 iPhone의 UDID를 등록할 수 있습니다
- 나중에 Apple Developer 포털에서도 등록 가능
- **Next** 클릭

### 7단계: Export

1. 저장 위치 선택 (예: Desktop 또는 Dropbox)
2. **Export** 버튼 클릭
3. IPA 파일이 생성됩니다!

## 인증서가 없다는 오류가 나타나면

### 해결 방법 1: Xcode에서 인증서 다운로드

1. Xcode 메뉴: **Xcode > Settings** (또는 Preferences)
2. **Accounts** 탭 선택
3. Apple ID 선택 (또는 추가)
4. **"Download Manual Profiles"** 클릭
5. 또는 **"Manage Certificates"** 클릭하여 인증서 생성

### 해결 방법 2: Apple Developer 포털에서 설정

1. https://developer.apple.com/account 방문
2. **Certificates, Identifiers & Profiles** 선택
3. **Certificates** 섹션에서 인증서 생성
4. **Profiles** 섹션에서 Ad Hoc 프로비저닝 프로파일 생성

## 생성된 IPA 파일을 다른 iPhone에 설치하기

### 방법 1: Finder 사용 (권장)

1. **iPhone을 Mac에 USB로 연결**
2. **Finder에서 iPhone 선택**
3. **IPA 파일을 Finder 창으로 드래그 앤 드롭**
4. **iPhone에서 신뢰 설정:**
   - 설정 > 일반 > VPN 및 기기 관리
   - 개발자 앱에서 "신뢰" 선택

### 방법 2: AirDrop 사용

1. **Mac과 iPhone에서 AirDrop 활성화**
2. **IPA 파일을 AirDrop으로 전송**
3. **iPhone에서 받아서 설치**
4. **신뢰 설정**

### 방법 3: 이메일/클라우드 저장소

1. **IPA 파일을 이메일이나 클라우드에 업로드**
2. **iPhone에서 다운로드**
3. **파일 앱에서 IPA 파일 열기**
4. **설치 후 신뢰 설정**

## iPhone UDID 확인 방법

Ad Hoc 배포를 위해서는 iPhone의 UDID가 Apple Developer에 등록되어 있어야 합니다.

### iPhone에서:
1. 설정 > 일반 > 정보
2. UDID를 길게 눌러 복사

### Mac에서 (iPhone 연결 시):
1. Finder에서 iPhone 선택
2. 일반 탭에서 UDID 확인

## 문제 해결

### "No signing certificate found" 오류
- **해결**: Xcode Settings > Accounts에서 인증서 다운로드

### "No provisioning profiles found" 오류
- **해결**: "Automatically manage signing" 선택하면 자동 생성됨

### "Team does not have permission" 오류
- **해결**: Apple Developer Program 가입 확인 및 Xcode 재시작

## 다음 단계

1. ✅ Apple Developer Program 가입 완료
2. ⏳ Xcode Organizer에서 Release Testing 선택
3. ⏳ Ad Hoc 배포 선택
4. ⏳ IPA Export
5. ⏳ 다른 iPhone에 설치

---

**Xcode Organizer가 열렸다면 "Release Testing"을 선택하고 진행하세요!**

