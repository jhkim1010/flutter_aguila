# iPad 앱 크래시 문제 해결 가이드

앱이 실행을 시도하다가 종료되는 문제를 해결하는 방법입니다.

## 1. 개발자 모드 확인 및 활성화

### iPad에서 개발자 모드 활성화:
1. **설정** 앱 열기
2. **개인정보 보호 및 보안** (또는 **개인정보 보호**) 선택
3. **개발자 모드** 찾기
4. **개발자 모드** 토글을 **켜기**로 변경
5. iPad **재시작** (필수!)
6. 재시작 후 "개발자 모드를 사용하시겠습니까?" 팝업에서 **켜기** 선택

## 2. 앱 신뢰 설정 확인

1. **설정** > **일반** > **VPN 및 기기 관리** (또는 **기기 관리**)
2. **기업용 앱** 섹션에서 개발자 이름 찾기
3. 개발자 이름 탭
4. **"[개발자 이름] 신뢰"** 버튼 탭
5. 확인 팝업에서 **신뢰** 선택

## 3. Xcode에서 Development 빌드로 다시 설치

### 방법 1: Xcode에서 직접 빌드 및 설치

1. **Xcode 열기**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **iPad를 Mac에 USB로 연결**

3. **Xcode에서 기기 선택**
   - 상단 툴바에서 기기 선택 (iPad 선택)

4. **Product > Build** (⌘B) 실행
   - 빌드가 성공하면 자동으로 iPad에 설치됩니다

5. **Product > Run** (⌘R) 실행
   - 앱이 실행되고 크래시 로그를 확인할 수 있습니다

### 방법 2: Flutter로 Development 빌드

```bash
cd /Users/marcoskim/Trabajos_Programming/flutter_app
flutter run --release
```

## 4. 크래시 로그 확인

### Xcode에서 크래시 로그 보기:
1. Xcode > **Window** > **Devices and Simulators**
2. 왼쪽에서 **iPad** 선택
3. **View Device Logs** 버튼 클릭
4. 최근 크래시 로그 확인
5. 크래시 원인 확인 (예: 코드 서명, 권한, 메모리 등)

### iPad에서 직접 확인:
1. **설정** > **개인정보 보호 및 보안** > **분석 및 개선**
2. **분석 데이터** 선택
3. 앱 이름으로 시작하는 항목 찾기
4. 크래시 로그 확인

## 5. 프로비저닝 프로파일 재생성

1. **Xcode** 열기
2. **Runner** 프로젝트 선택
3. **Runner** 타겟 선택
4. **Signing & Capabilities** 탭
5. **Automatically manage signing** 체크 해제 후 다시 체크
6. **Team** 선택 확인
7. **Product > Clean Build Folder** (⇧⌘K)
8. 다시 빌드

## 6. 앱 삭제 후 재설치

1. iPad에서 앱 **삭제**
2. Xcode에서 **Clean Build Folder** (⇧⌘K)
3. **Product > Build** (⌘B) 실행
4. 앱이 자동으로 설치됩니다

## 7. 일반적인 크래시 원인 및 해결

### 원인 1: 코드 서명 문제
**해결:**
- Xcode > Preferences > Accounts에서 Apple ID 확인
- Signing & Capabilities에서 Team 확인
- Automatically manage signing 활성화

### 원인 2: 프로비저닝 프로파일 만료
**해결:**
- Xcode에서 프로비저닝 프로파일 자동 갱신
- 또는 수동으로 Apple Developer에서 갱신

### 원인 3: 개발자 모드 비활성화
**해결:**
- 설정에서 개발자 모드 활성화
- iPad 재시작

### 원인 4: 앱 권한 문제
**해결:**
- Info.plist에 필요한 권한 설명 추가 확인
- 설정 > 앱 이름에서 권한 확인

### 원인 5: 앱 코드 문제
**해결:**
- Xcode에서 크래시 로그 확인
- Flutter 코드에서 에러 확인
- `flutter doctor` 실행하여 환경 확인

## 8. 빠른 해결 체크리스트

- [ ] 개발자 모드 활성화 및 iPad 재시작
- [ ] 설정에서 앱 신뢰 설정
- [ ] Xcode에서 Clean Build Folder 실행
- [ ] Development 빌드로 다시 설치
- [ ] 크래시 로그 확인
- [ ] 프로비저닝 프로파일 재생성
- [ ] 앱 삭제 후 재설치

## 9. Xcode에서 크래시 로그 확인하는 방법

1. **Xcode** > **Window** > **Devices and Simulators**
2. 왼쪽에서 **iPad** 선택
3. **Open Console** 버튼 클릭
4. 앱 실행 시도
5. 콘솔에서 에러 메시지 확인

## 10. 여전히 문제가 있는 경우

다음 정보를 확인하세요:
- iPad iOS 버전
- Xcode 버전
- 크래시 로그의 정확한 에러 메시지
- 앱이 언제 크래시하는지 (시작 시? 특정 화면?)

이 정보를 바탕으로 추가 진단이 가능합니다.
