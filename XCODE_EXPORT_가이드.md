# Xcode에서 직접 Ad Hoc IPA Export 가이드

## 현재 상황
✅ Archive 생성 완료
❌ 자동 IPA 생성 실패 (인증서/프로파일 문제)

## 해결 방법: Xcode에서 직접 Export

### 1단계: Organizer 창에서 Export

1. **Xcode에서 Organizer 창 확인**
   - Archive가 완료되면 자동으로 열립니다
   - 또는 **Window** > **Organizer** 메뉴에서 열 수 있습니다

2. **Archive 선택**
   - 왼쪽에서 방금 생성한 Archive 선택 (날짜/시간 표시)

3. **Distribute App 클릭**
   - 오른쪽에 **"Distribute App"** 버튼 클릭

### 2단계: 배포 방법 선택

1. **배포 방법 선택 창에서:**
   - **"Ad Hoc"** 선택 ⚠️ 중요!
   - **"Next"** 클릭

### 3단계: 서명 설정

1. **서명 옵션 선택:**
   - **"Automatically manage signing"** 선택 (권장)
   - 또는 **"Manually manage signing"** 선택 후 인증서 선택
   - **"Next"** 클릭

2. **프로비저닝 프로파일 확인:**
   - 자동으로 생성되거나 선택됩니다
   - **"Next"** 클릭

### 4단계: IPA 파일 저장

1. **Export 버튼 클릭**
2. **저장 위치 선택**
   - 예: Desktop 또는 Downloads
   - **"Export"** 클릭
3. **IPA 파일 생성 완료**
   - 선택한 위치에 IPA 파일이 생성됩니다

### 5단계: IPA 파일 복사

생성된 IPA 파일을 Dropbox 폴더로 복사:

```bash
# 예시 (실제 파일명에 맞게 수정)
cp ~/Desktop/Runner.ipa ~/Dropbox/ACE_3_uversion/Be_Cool.ipa
```

또는 Finder에서 직접 복사:
- 생성된 IPA 파일을 `~/Dropbox/ACE_3_uversion/` 폴더로 드래그 앤 드롭
- 이름을 `Be_Cool.ipa`로 변경

## 문제 해결

### "No signing certificate" 오류
- Xcode > Preferences > Accounts에서 Apple ID 로그인 확인
- Signing & Capabilities에서 Team 선택 확인

### "No profiles found" 오류
- Apple Developer 웹사이트에서 프로비저닝 프로파일 생성 필요
- 또는 Xcode에서 "Automatically manage signing" 사용

### Ad Hoc 옵션이 보이지 않으면
- Development 방법으로 Export 시도
- 또는 Apple Developer 계정 권한 확인

## Development 방법 (대안)

만약 Ad Hoc이 작동하지 않으면:

1. **Distribute App** 클릭
2. **"Development"** 선택
3. 나머지 단계는 동일

⚠️ Development 방법은 연결된 기기에만 설치 가능합니다.
