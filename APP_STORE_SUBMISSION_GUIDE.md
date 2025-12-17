# 앱 스토어 제출 가이드

## 1. 사전 준비사항

### Apple Developer 계정
- [Apple Developer Program](https://developer.apple.com/programs/)에 가입되어 있어야 합니다.
- 연간 $99 USD 비용이 필요합니다.

### 앱 정보 확인
- **앱 이름**: Be COOL
- **Bundle Identifier**: com.coolsistema.becoolaguila
- **현재 버전**: 1.0.0+1

## 2. Xcode에서 Archive 생성

### 2.1 프로젝트 열기
```bash
open ios/Runner.xcworkspace
```

### 2.2 서명 및 기능 설정
1. Xcode에서 프로젝트 선택 (왼쪽 상단 Runner)
2. **Signing & Capabilities** 탭 선택
3. **Automatically manage signing** 체크
4. **Team** 선택 (Apple Developer 계정)
5. Bundle Identifier 확인: `com.coolsistema.becoolaguila`

### 2.3 빌드 설정 확인
1. **Build Settings** 탭 선택
2. **Code Signing Identity** 확인:
   - Release: `Apple Distribution`
   - Debug: `Apple Development`
3. **Provisioning Profile** 확인:
   - Release: 자동으로 생성됨

### 2.4 Archive 빌드
1. 상단 메뉴에서 **Product** → **Scheme** → **Runner** 선택
2. 상단 메뉴에서 **Product** → **Destination** → **Any iOS Device (arm64)** 선택
3. 상단 메뉴에서 **Product** → **Archive** 선택
4. 빌드가 완료되면 **Organizer** 창이 자동으로 열립니다

## 3. App Store Connect 설정

### 3.1 App Store Connect 접속
- [App Store Connect](https://appstoreconnect.apple.com/)에 로그인

### 3.2 새 앱 생성
1. **내 앱** 클릭
2. **+** 버튼 클릭 → **새 앱** 선택
3. 다음 정보 입력:
   - **이름**: Be COOL
   - **기본 언어**: 스페인어 또는 한국어
   - **번들 ID**: com.coolsistema.becoolaguila (드롭다운에서 선택)
   - **SKU**: becool-aguila (고유 식별자)
   - **사용자 액세스**: 전체 액세스 또는 제한된 액세스

## 4. Archive 업로드

### 방법 1: Xcode Organizer 사용 (권장)
1. Xcode Organizer 창에서 생성된 Archive 선택
2. **Distribute App** 버튼 클릭
3. **App Store Connect** 선택 → **Next**
4. **Upload** 선택 → **Next**
5. **Automatically manage signing** 선택 → **Next**
6. **Upload** 클릭
7. 업로드 완료까지 대기 (몇 분 소요)

### 방법 2: 명령줄 사용
```bash
cd ios
xcodebuild -exportArchive \
  -archivePath ~/Library/Developer/Xcode/Archives/$(date +%Y-%m-%d)/Runner\ $(date +%Y-%m-%d,\ %H.%M).xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath ./build
```

## 5. App Store Connect에서 앱 정보 입력

### 5.1 앱 정보
- **이름**: Be COOL
- **부제목**: (선택사항)
- **카테고리**: 비즈니스 또는 생산성
- **개인정보 보호 정책 URL**: (필요시)

### 5.2 가격 및 판매 범위
- **가격**: 무료 또는 유료
- **판매 범위**: 모든 국가 또는 특정 국가 선택

### 5.3 앱 미리보기 및 스크린샷
- **필수 스크린샷**:
  - iPhone 6.7인치 디스플레이: 최소 1개
  - iPhone 6.5인치 디스플레이: 최소 1개
  - iPad Pro (12.9인치): (iPad 지원 시)
- **앱 미리보기 비디오**: (선택사항)
- **앱 아이콘**: 1024x1024px PNG

### 5.4 앱 설명
- **설명**: 앱의 기능과 특징 설명
- **키워드**: 검색 최적화를 위한 키워드 (쉼표로 구분)
- **프로모션 텍스트**: (선택사항)

### 5.5 버전 정보
- **버전**: 1.0.0
- **빌드 번호**: 1
- **새로운 기능**: 첫 번째 버전 출시

## 6. 제출 및 검토

### 6.1 제출 전 체크리스트
- [ ] 앱이 정상적으로 작동하는지 테스트
- [ ] 모든 필수 정보 입력 완료
- [ ] 스크린샷 업로드 완료
- [ ] 개인정보 보호 정책 URL 설정 (필요시)
- [ ] 연령 등급 설정
- [ ] 앱 검토 정보 입력 (테스트 계정 등)

### 6.2 제출
1. **버전** 섹션에서 **제출 검토** 버튼 클릭
2. **Export Compliance** 질문에 답변
3. **제출** 확인

### 6.3 검토 과정
- 일반적으로 24-48시간 소요
- 검토 상태는 App Store Connect에서 확인 가능
- 거부 시 피드백을 받고 수정 후 재제출

## 7. 유용한 명령어

### Flutter 빌드
```bash
# iOS Release 빌드
flutter build ipa --release

# 특정 버전으로 빌드
flutter build ipa --release --build-name=1.0.0 --build-number=1
```

### Xcode 빌드
```bash
# Archive 생성
xcodebuild -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/Runner.xcarchive \
  archive
```

## 8. 문제 해결

### 서명 오류
- Xcode에서 **Automatically manage signing** 활성화
- Apple Developer 계정에 올바른 권한이 있는지 확인

### Bundle Identifier 충돌
- App Store Connect에서 이미 사용 중인 번들 ID인지 확인
- 필요시 번들 ID 변경 (Xcode 프로젝트 설정에서)

### 업로드 실패
- 인터넷 연결 확인
- Xcode 및 Command Line Tools 최신 버전 확인
- ExportOptions.plist의 teamID 확인

## 참고 자료
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)

