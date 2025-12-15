# 설치 파일 빌드 가이드

이 가이드는 macOS와 Android용 설치 파일을 생성하는 방법을 설명합니다.

## 📋 개요

`build_installers.sh` 스크립트를 사용하여 다른 기기에서 사용할 수 있는 설치 파일을 생성할 수 있습니다.

- **macOS**: DMG 파일 (다른 Mac에서 설치 가능)
- **Android**: APK 파일 (다른 Android 기기에서 설치 가능)

## 🚀 빠른 시작

### 1. 통합 스크립트 사용 (권장)

```bash
./build_installers.sh
```

스크립트를 실행하면 다음을 선택할 수 있습니다:
- `1`: macOS DMG만 빌드
- `2`: Android APK만 빌드
- `3`: 둘 다 빌드

### 2. 개별 스크립트 사용

#### macOS DMG 빌드
```bash
./build_macos_installer.sh
```

#### Android APK 빌드
```bash
./build_apk.sh
```

## 📦 생성되는 파일

### macOS
- **파일 형식**: `.dmg`
- **위치**: 
  - 로컬: `build/installers/Be_COOL_macOS_v{버전}_{빌드번호}.dmg`
  - Dropbox: `~/Dropbox/ACE_3_uversion/Be_COOL_macOS_v{버전}_{빌드번호}.dmg`

### Android
- **파일 형식**: `.apk`
- **위치**:
  - 로컬: `build/installers/Be_COOL_Android_v{버전}_{빌드번호}.apk`
  - Dropbox: `~/Dropbox/ACE_3_uversion/Be_COOL_Android_v{버전}_{빌드번호}.apk`

## 💻 macOS 설치 방법

### 다른 Mac에서 설치하기

1. **DMG 파일 전송**
   - Dropbox에서 DMG 파일 다운로드
   - 또는 USB, 이메일 등으로 전송

2. **DMG 파일 열기**
   - DMG 파일을 더블클릭하여 마운트

3. **앱 설치**
   - DMG 창에서 앱을 Applications 폴더로 드래그

4. **앱 실행**
   - Applications 폴더에서 앱 실행
   - 첫 실행 시 "손상된 앱" 경고가 나타날 수 있음

5. **경고 해결 방법**
   - **방법 1 (권장)**: 앱을 우클릭 > "열기" 선택
   - **방법 2**: 터미널에서 다음 명령어 실행:
     ```bash
     xattr -cr "/Applications/Be COOL.app"
     ```

### 코드 서명

- **서명된 앱**: Developer ID 인증서로 서명된 경우 다른 Mac에서 바로 실행 가능
- **서명되지 않은 앱**: 위의 경고 해결 방법 사용 필요

## 📱 Android 설치 방법

### 다른 Android 기기에서 설치하기

1. **APK 파일 전송**
   - Dropbox에서 APK 파일 다운로드
   - 또는 USB, 이메일, 클라우드 등으로 전송

2. **알 수 없는 소스 허용**
   - 설정 > 보안 > "알 수 없는 소스" 또는 "알 수 없는 앱 설치" 허용
   - (Android 버전에 따라 경로가 다를 수 있음)

3. **APK 파일 설치**
   - 파일 관리자에서 APK 파일 찾기
   - APK 파일을 탭하여 설치 시작
   - 설치 확인 대화상자에서 "설치" 선택

4. **앱 실행**
   - 설치 완료 후 앱 실행

### Android 버전별 설정 경로

- **Android 8.0 이상**: 
  - 설정 > 앱 > 특별 액세스 > 알 수 없는 앱 설치
  - 또는 APK 파일을 열 때 "이 출처 허용" 선택

- **Android 7.0 이하**:
  - 설정 > 보안 > 알 수 없는 소스 체크

## 🔧 문제 해결

### macOS 빌드 문제

#### "앱 번들을 찾을 수 없습니다"
```bash
# Flutter 클린 빌드
flutter clean
flutter pub get
flutter build macos --release
```

#### 코드 서명 오류
- Xcode에서 개발자 계정 설정 확인
- Keychain Access에서 인증서 확인

### Android 빌드 문제

#### Gradle 오류
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk --release
```

#### 키스토어 오류
- `android/key.properties` 파일 확인
- 키스토어 파일 경로 확인

## 📝 참고 사항

### 버전 정보
- 버전 번호는 `pubspec.yaml`의 `version` 필드에서 자동으로 읽어옵니다
- 형식: `{버전}_{빌드번호}` (예: `1.0.0_1`)

### Dropbox 자동 복사
- 모든 빌드 파일은 자동으로 Dropbox 폴더에 복사됩니다
- 위치: `~/Dropbox/ACE_3_uversion/`

### 빌드 시간
- macOS DMG: 약 2-5분
- Android APK: 약 1-3분
- 둘 다: 약 3-8분

## 🎯 다음 단계

### macOS
- DMG 파일을 다른 Mac으로 전송
- 설치 후 앱 실행 테스트

### Android
- APK 파일을 Android 기기로 전송
- 설치 후 앱 실행 테스트
- Google Play Store 배포를 원하면 `build_aab.sh` 사용

## 📚 관련 문서

- [macOS 빌드 가이드](build_macos_installer.sh)
- [Android 빌드 가이드](build_apk.sh)
- [Google Play Store 배포 가이드](GOOGLE_PLAY_STORE_배포_가이드.md)
