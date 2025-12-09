# 프로비저닝 프로파일 문제 해결 가이드

## ⚠️ 중요: 개발자 모드 활성화 필요!

**가장 흔한 문제**: iPad에서 개발자 모드가 비활성화되어 있습니다.

### iPad에서 개발자 모드 활성화 (필수!)

1. **iPad의 설정 앱 열기**
2. **설정** → **개인정보 보호 및 보안** 이동
3. 아래로 스크롤하여 **개발자 모드** 찾기
4. **개발자 모드** 토글을 **켜기**
5. **iPad 재시작** (메시지가 나타나면 재시작)

재시작 후:
- Xcode의 Devices 창에서 iPad가 "Ready" 상태가 됩니다
- 경고 배너가 사라집니다
- 이제 Archive가 정상적으로 작동합니다

---

## 현재 문제
iPad가 연결되어 있지만 개발자 모드가 비활성화되어 있어 Xcode가 프로비저닝 프로파일을 생성하지 못하고 있습니다.

## 해결 방법

### 방법 1: Xcode에서 기기 직접 등록 (가장 확실한 방법)

1. **Xcode에서 기기 확인**
   - Xcode 상단 메뉴: **Window** > **Devices and Simulators**
   - 왼쪽에서 연결된 iPad 선택
   - iPad가 "Ready" 상태인지 확인

2. **Xcode에서 프로비저닝 프로파일 새로고침**
   - Xcode 상단 메뉴: **Xcode** > **Settings** (또는 **Preferences**)
   - **Accounts** 탭 클릭
   - 본인의 Apple ID 선택
   - **Download Manual Profiles** 버튼 클릭 (있다면)
   - 또는 **Team** 옆의 **Manage Certificates...** 클릭하여 인증서 확인

3. **Runner 프로젝트에서 서명 설정 확인**
   - Xcode에서 `ios/Runner.xcworkspace` 열기
   - 왼쪽 네비게이터에서 **Runner** 프로젝트 선택
   - 중앙에서 **Runner** 타겟 선택
   - **Signing & Capabilities** 탭 클릭
   - **Team** 드롭다운에서 **W93P494PLH** 선택
   - **Automatically manage signing** 체크 확인
   - 만약 에러 메시지가 보이면:
     - "Add Account..." 클릭하여 Apple ID 로그인
     - 또는 "Register Device" 버튼이 보이면 클릭

4. **기기 등록 시도**
   - **Signing & Capabilities** 탭에서
   - **Provisioning Profile** 섹션 확인
   - "Register Device" 또는 "Add Device" 버튼이 보이면 클릭

### 방법 2: Xcode에서 직접 빌드 시도

1. **Xcode에서 프로젝트 열기**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **기기 선택**
   - Xcode 상단 툴바에서 기기 선택 드롭다운 클릭
   - 연결된 iPad 선택 (실제 기기, Simulator 아님)

3. **일반 빌드 먼저 시도**
   - **Product** > **Build** (⌘B)
   - 빌드가 성공하면 프로비저닝 프로파일이 생성된 것입니다

4. **Archive 시도**
   - 빌드가 성공한 후 **Product** > **Archive** 시도

### 방법 3: Apple Developer 웹사이트에서 기기 수동 등록

1. **iPad의 UDID 확인**
   - Xcode > **Window** > **Devices and Simulators**
   - 연결된 iPad 선택
   - **Identifier** 복사 (UDID)

2. **Apple Developer 웹사이트 접속**
   - https://developer.apple.com/account/ 접속
   - 로그인

3. **기기 등록**
   - **Certificates, Identifiers & Profiles** 클릭
   - 왼쪽 메뉴에서 **Devices** 클릭
   - **+** 버튼 클릭
   - **Register a New Device** 선택
   - **UDID** 붙여넣기
   - **Name** 입력 (예: "My iPad")
   - **Continue** > **Register** 클릭

4. **Xcode에서 프로비저닝 프로파일 새로고침**
   - Xcode > **Preferences** > **Accounts**
   - Apple ID 선택 > **Download Manual Profiles** 클릭

### 방법 4: Bundle ID 확인 및 변경

만약 Bundle ID가 이미 사용 중이라면:

1. **Xcode에서 Bundle ID 확인**
   - **Signing & Capabilities** 탭에서
   - **Bundle Identifier** 확인: `com.coolsistema.becoolaguila`

2. **Apple Developer에서 확인**
   - https://developer.apple.com/account/resources/identifiers/list
   - 해당 Bundle ID가 등록되어 있는지 확인

3. **필요시 Bundle ID 변경**
   - 고유한 Bundle ID로 변경 (예: `com.coolsistema.becoolaguila2`)

## 빠른 체크리스트

- [ ] iPad가 Mac에 USB로 연결되어 있음
- [ ] iPad에서 "이 컴퓨터를 신뢰" 선택함
- [ ] Xcode > Window > Devices and Simulators에서 iPad가 "Ready" 상태
- [ ] Xcode > Preferences > Accounts에서 Apple ID 로그인됨
- [ ] Runner 프로젝트 > Signing & Capabilities에서 Team 선택됨
- [ ] "Automatically manage signing" 체크됨

## 다음 단계

위 방법 중 하나를 시도한 후:
1. **Product** > **Build** 먼저 시도
2. 빌드 성공 후 **Product** > **Archive** 시도
3. Archive 성공 시 Organizer에서 **Distribute App** 클릭
