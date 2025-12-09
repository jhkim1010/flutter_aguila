# iPad용 IPA 파일 생성 - 문제 해결 가이드

## 현재 문제
프로비저닝 프로파일을 생성하려면 등록된 기기가 필요합니다.

## 해결 방법

### 방법 1: iPad를 Mac에 연결하기 (가장 간단)

1. **iPad를 USB 케이블로 Mac에 연결**
2. iPad에서 "이 컴퓨터를 신뢰하시겠습니까?" 메시지가 나오면 **신뢰** 선택
3. Xcode에서 기기 확인:
   - Xcode 상단 메뉴: **Window** > **Devices and Simulators**
   - 연결된 iPad가 보이는지 확인
4. 다시 Archive 시도:
   - **Product** > **Archive**
   - 이제 프로비저닝 프로파일이 자동으로 생성됩니다

### 방법 2: Apple Developer 웹사이트에서 기기 ID 추가

1. **Apple Developer 웹사이트 접속**
   - https://developer.apple.com/account/ 접속
   - 로그인

2. **기기 등록**
   - **Certificates, Identifiers & Profiles** 클릭
   - 왼쪽 메뉴에서 **Devices** 클릭
   - **+** 버튼 클릭
   - iPad의 UDID 입력 (iPad 설정 > 일반 > 정보에서 확인 가능)
   - 기기 이름 입력 후 저장

3. **Xcode에서 프로비저닝 프로파일 새로고침**
   - Xcode > **Preferences** > **Accounts**
   - 본인의 Apple ID 선택
   - **Download Manual Profiles** 클릭

4. **다시 Archive 시도**

### 방법 3: Xcode에서 자동 서명 설정 확인

1. **Xcode에서 프로젝트 열기**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Runner 프로젝트 선택**
   - 왼쪽 네비게이터에서 **Runner** (파란색 아이콘) 클릭

3. **Runner 타겟 선택**
   - 중앙 영역에서 **TARGETS** 아래 **Runner** 선택

4. **Signing & Capabilities 탭 확인**
   - 상단 탭에서 **Signing & Capabilities** 클릭
   - 다음 설정 확인:
     - ✅ **Team**: W93P494PLH 선택되어 있는지
     - ✅ **Automatically manage signing** 체크되어 있는지
     - ✅ **Bundle Identifier**: com.coolsistema.becoolaguila

5. **기기 연결 후 Archive**
   - iPad를 연결한 상태에서
   - **Product** > **Archive** 실행

## Archive 완료 후 IPA 파일 내보내기

Archive가 성공하면 Organizer 창에 Archive가 나타납니다:

1. **Organizer 창 확인**
   - **Window** > **Organizer** (또는 Archive 완료 시 자동으로 열림)
   - 왼쪽에서 **Archives** 선택
   - 방금 생성한 Archive 항목 클릭

2. **Distribute App 클릭**
   - 오른쪽에 **Distribute App** 버튼 클릭

3. **배포 방법 선택**
   - **Ad Hoc** 선택 (테스트용)
   - **Next** 클릭

4. **서명 설정**
   - **Automatically manage signing** 선택
   - **Next** 클릭

5. **IPA 파일 저장**
   - **Export** 클릭
   - 저장 위치 선택 (예: Desktop)
   - **Export** 클릭

6. **Dropbox로 복사**
   ```bash
   # 저장된 IPA 파일을 Dropbox로 복사
   cp ~/Desktop/Be\ COOL.ipa /Users/marcoskim/Dropbox/ACE_3_uversion/Be_Cool.ipa
   ```

## 빠른 해결책

**가장 빠른 방법**: iPad를 Mac에 USB로 연결하고 다시 Archive를 시도하세요!
