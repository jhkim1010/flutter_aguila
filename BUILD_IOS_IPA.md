# iPad용 IPA 파일 생성 가이드

## 자동 빌드 (권장)

스크립트를 실행하세요:
```bash
./build_ios.sh
```

## 수동 빌드 (자동 빌드가 실패하는 경우)

### 1. Xcode에서 프로젝트 열기
```bash
open ios/Runner.xcworkspace
```

### 2. Xcode에서 설정 확인
1. 왼쪽 네비게이터에서 **Runner** 프로젝트 선택
2. 중앙에서 **Runner** 타겟 선택
3. 상단 탭에서 **Signing & Capabilities** 선택
4. 다음 설정 확인:
   - ✅ **Team**: W93P494PLH (또는 본인의 Development Team)
   - ✅ **Automatically manage signing** 체크되어 있는지 확인
   - ✅ **Bundle Identifier**: com.coolsistema.becoolaguila

### 3. Archive 생성 및 IPA 파일 내보내기

#### 단계별 설명:

**Step 1: Archive 생성**
- Xcode 상단 메뉴바에서 **Product** (제품) 메뉴 클릭
- 드롭다운 메뉴에서 **Archive** (아카이브) 선택
- 빌드가 시작되고 완료될 때까지 기다립니다 (몇 분 소요)
- ⚠️ **중요**: Archive 중에 Xcode Components 다운로드 창이 나타날 수 있습니다
  - 이것은 정상적인 과정입니다 (필요한 SDK 다운로드)
  - 이 창은 닫아도 되고, 다운로드는 백그라운드에서 계속됩니다
- 완료되면 자동으로 **Organizer** (오거나이저) 창이 열립니다
- 만약 Organizer 창이 안 보이면: **Window** > **Organizer** 메뉴에서 열 수 있습니다

**Step 2: Organizer 창에서 IPA 파일 내보내기**
- Archive가 완료되면 나타나는 **Organizer** 창에서:
  - 방금 생성된 Archive 항목이 보입니다 (날짜/시간 표시)
  - 오른쪽에 **Distribute App** (앱 배포) 버튼이 있습니다
  - 이 버튼을 클릭하세요

**Step 3: 배포 방법 선택**
- **Distribute App** 버튼을 클릭하면 새 창이 열립니다
- 다음 중 하나를 선택:
  - **Ad Hoc** (애드혹): 특정 iPad 기기에만 설치 가능 (테스트용, 추천)
  - **Development** (개발): 개발용
  - **App Store Connect**: App Store에 배포할 때 사용
- **Ad Hoc** 또는 **Development** 선택 후 **Next** (다음) 클릭

**Step 4: 서명 및 프로비저닝 프로파일 설정**
- 자동으로 서명 설정이 표시됩니다
- **Automatically manage signing** (자동 서명 관리)이 선택되어 있는지 확인
- **Next** 클릭

**Step 5: IPA 파일 저장**
- **Export** (내보내기) 버튼 클릭
- 저장할 위치 선택 (예: Desktop, Downloads)
- **Export** 클릭
- IPA 파일이 선택한 위치에 저장됩니다

### 4. IPA 파일 복사
생성된 IPA 파일을 Dropbox로 복사:
```bash
# IPA 파일 위치 확인 (보통 ~/Desktop 또는 다운로드 폴더)
# 예시:
cp ~/Desktop/Be\ COOL.ipa /Users/marcoskim/Dropbox/ACE_3_uversion/Be_Cool.ipa
```

## iPad에 설치하는 방법

### 방법 1: Finder 사용 (macOS Catalina 이상)
1. iPad를 Mac에 USB로 연결
2. Finder에서 iPad 선택
3. **파일** 탭에서 IPA 파일을 드래그 앤 드롭

### 방법 2: Xcode 사용
1. Xcode > **Window** > **Devices and Simulators**
2. 연결된 iPad 선택
3. **Installed Apps** 섹션에서 **+** 버튼 클릭
4. IPA 파일 선택

### 방법 3: TestFlight 사용 (App Store Connect 배포인 경우)
1. App Store Connect에 업로드
2. TestFlight에서 테스터 추가
3. iPad에서 TestFlight 앱으로 설치

## 문제 해결

### 프로비저닝 프로파일 오류
- Xcode에서 **Automatically manage signing**이 체크되어 있는지 확인
- Apple Developer 계정에 로그인되어 있는지 확인
- Bundle ID가 고유한지 확인

### 코드 서명 오류
- Development Team이 올바르게 선택되어 있는지 확인
- Xcode > Preferences > Accounts에서 Apple ID 확인
