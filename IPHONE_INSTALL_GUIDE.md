# iPhone용 IPA 파일 설치 가이드

## ⚠️ IPA 파일을 공유해도 설치가 안 되는 이유

iOS는 보안상의 이유로 **무작위로 IPA 파일을 설치할 수 없습니다**. 설치하려면 다음 중 하나가 필요합니다:

1. **기기가 프로비저닝 프로파일에 등록되어 있어야 함** (Ad Hoc 배포)
2. **TestFlight를 통한 배포** (App Store Connect 필요)
3. **개발자 인증서로 서명된 앱** (기기가 신뢰해야 함)

---

## 해결 방법

### 방법 1: Ad Hoc 배포 (특정 기기만 설치 가능) ⭐ 추천

**이 방법은 설치하려는 iPhone의 UDID가 프로비저닝 프로파일에 등록되어 있어야 합니다.**

#### 1단계: iPhone의 UDID 확인

**iPhone에서:**
1. 설정 앱 열기
2. 일반 > 정보 이동
3. 아래로 스크롤하여 **UDID** 찾기 (길게 눌러서 복사)

**또는 Mac에서:**
1. iPhone을 Mac에 USB로 연결
2. Finder에서 iPhone 선택
3. UDID 표시 (클릭하면 복사됨)

**또는 Xcode에서:**
1. Xcode > Window > Devices and Simulators
2. 연결된 iPhone 선택
3. Identifier 복사 (UDID)

#### 2단계: Apple Developer에 기기 등록

1. **Apple Developer 웹사이트 접속**
   - https://developer.apple.com/account/ 접속
   - 로그인

2. **기기 등록**
   - **Certificates, Identifiers & Profiles** 클릭
   - 왼쪽 메뉴에서 **Devices** 클릭
   - **+** 버튼 클릭
   - **Register a New Device** 선택
   - **UDID** 붙여넣기
   - **Name** 입력 (예: "My iPhone")
   - **Continue** > **Register** 클릭

#### 3단계: Ad Hoc 프로비저닝 프로파일 생성

1. **Apple Developer에서 프로비저닝 프로파일 생성**
   - **Profiles** 메뉴 클릭
   - **+** 버튼 클릭
   - **Ad Hoc** 선택
   - **App ID** 선택 (com.coolsistema.becoolaguila)
   - **Certificates** 선택
   - **Devices**에서 등록한 iPhone 선택
   - **Name** 입력 (예: "Be Cool Ad Hoc")
   - **Generate** 클릭
   - 프로파일 다운로드

#### 4단계: Xcode에서 Ad Hoc IPA 생성

1. **Xcode에서 프로젝트 열기**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Archive 생성**
   - **Product** > **Archive**
   - 완료될 때까지 대기

3. **Distribute App**
   - Organizer 창에서 **Distribute App** 클릭
   - **Ad Hoc** 선택 ⚠️ **중요: Ad Hoc 선택!**
   - **Next** 클릭
   - **Automatically manage signing** 선택
   - **Next** 클릭
   - **Export** 클릭
   - 저장 위치 선택

#### 5단계: iPhone에 설치

**방법 A: Finder 사용 (macOS Catalina 이상)**
1. iPhone을 Mac에 USB로 연결
2. Finder에서 iPhone 선택
3. **파일** 탭에서 IPA 파일을 드래그 앤 드롭
4. iPhone에서 설치 확인

**방법 B: Xcode 사용**
1. Xcode > **Window** > **Devices and Simulators**
2. 연결된 iPhone 선택
3. **Installed Apps** 섹션에서 **+** 버튼 클릭
4. IPA 파일 선택

**방법 C: AirDrop 사용**
1. Mac에서 IPA 파일 선택
2. 우클릭 > **공유** > **AirDrop**
3. iPhone 선택하여 전송
4. iPhone에서 설치

---

### 방법 2: TestFlight 배포 (여러 기기에 쉽게 배포) ⭐⭐ 가장 쉬움

**이 방법은 App Store Connect에 앱을 업로드해야 하지만, 여러 기기에 쉽게 배포할 수 있습니다.**

#### 1단계: App Store Connect에 업로드

1. **Xcode에서 Archive 생성**
   - **Product** > **Archive**

2. **App Store Connect에 업로드**
   - Organizer에서 **Distribute App** 클릭
   - **App Store Connect** 선택
   - **Upload** 선택
   - **Next** 클릭
   - **Automatically manage signing** 선택
   - **Upload** 클릭
   - 업로드 완료 대기 (몇 분 소요)

#### 2단계: TestFlight에서 테스터 추가

1. **App Store Connect 접속**
   - https://appstoreconnect.apple.com/ 접속
   - 로그인

2. **앱 선택**
   - **내 앱** 메뉴에서 앱 선택

3. **TestFlight 탭**
   - **TestFlight** 탭 클릭
   - 빌드가 처리될 때까지 대기 (10-30분)

4. **내부 테스터 추가**
   - **내부 테스터** 섹션에서
   - **+** 버튼 클릭
   - 테스터 이메일 추가
   - 또는 **외부 테스터** 섹션에서 외부 테스터 그룹 생성

5. **빌드 배포**
   - 처리된 빌드 선택
   - **테스터에게 배포** 클릭
   - 테스터 그룹 선택

#### 3단계: iPhone에서 설치

1. **TestFlight 앱 설치** (App Store에서)
2. **이메일 확인**
   - 테스터 이메일로 초대 링크 수신
   - 링크 클릭하여 TestFlight에서 앱 설치

---

### 방법 3: 개발자 인증서 신뢰 (개발용)

**이 방법은 개발 중인 기기에만 사용 가능합니다.**

#### 1단계: iPhone에서 개발자 신뢰

1. **IPA 파일 설치 시도**
   - AirDrop, 이메일, 또는 웹에서 IPA 다운로드
   - 설치 시도

2. **설정에서 개발자 신뢰**
   - 설정 앱 열기
   - **일반** > **VPN 및 기기 관리** (또는 **프로파일 및 기기 관리**)
   - 개발자 인증서 찾기
   - **신뢰** 버튼 클릭
   - 확인

3. **앱 재설치**
   - 이제 앱이 설치됩니다

---

## 현재 IPA 파일이 설치 안 되는 이유 확인

### 체크리스트

- [ ] **IPA 파일이 Ad Hoc으로 빌드되었는가?**
  - Development로 빌드된 경우: 특정 기기에만 설치 가능
  - App Store로 빌드된 경우: TestFlight 또는 App Store를 통해서만 설치 가능

- [ ] **iPhone의 UDID가 프로비저닝 프로파일에 등록되어 있는가?**
  - Ad Hoc 배포의 경우 필수

- [ ] **개발자 인증서가 신뢰되었는가?**
  - 설정 > 일반 > VPN 및 기기 관리에서 확인

- [ ] **iPhone에 개발자 모드가 활성화되어 있는가?**
  - 설정 > 개인정보 보호 및 보안 > 개발자 모드
  - iOS 16 이상에서 필요할 수 있음

---

## 빠른 해결책

**가장 빠른 방법: TestFlight 사용**

1. Xcode에서 Archive 생성
2. App Store Connect에 업로드
3. TestFlight에서 테스터 추가
4. iPhone에서 TestFlight 앱으로 설치

**또는 Ad Hoc 배포:**

1. iPhone UDID 확인
2. Apple Developer에 기기 등록
3. Ad Hoc 프로비저닝 프로파일 생성
4. Xcode에서 Ad Hoc으로 IPA 재생성
5. iPhone에 설치

---

## 문제 해결

### "앱을 설치할 수 없습니다" 오류

**원인:** 프로비저닝 프로파일에 기기가 등록되지 않음

**해결:**
- iPhone UDID를 Apple Developer에 등록
- Ad Hoc 프로비저닝 프로파일로 IPA 재생성

### "신뢰할 수 없는 개발자" 오류

**원인:** 개발자 인증서가 신뢰되지 않음

**해결:**
- 설정 > 일반 > VPN 및 기기 관리에서 개발자 인증서 신뢰

### "이 앱은 더 이상 사용할 수 없습니다" 오류

**원인:** 프로비저닝 프로파일이 만료됨

**해결:**
- 새로운 프로비저닝 프로파일로 IPA 재생성
- 또는 TestFlight 사용 (자동 갱신)

---

## 권장 사항

**프로덕션 배포:** TestFlight 사용
- 가장 안정적
- 자동 업데이트 가능
- 여러 기기에 쉽게 배포

**테스트 배포:** Ad Hoc 사용
- 빠른 배포
- App Store Connect 불필요
- 제한된 기기만 가능
