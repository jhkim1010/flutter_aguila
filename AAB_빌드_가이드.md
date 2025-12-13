# AAB 빌드 가이드

## ✅ 현재 상태

AAB 파일이 성공적으로 생성되었습니다:
- **위치**: `build/app/outputs/bundle/release/app-release.aab`
- **크기**: 44MB
- **서명**: 현재 debug 키로 서명됨 (Google Play Console 업로드 불가)

## ⚠️ 중요: Release 키 설정 필요

Google Play Console에 업로드하려면 **release 키로 서명**해야 합니다.

### 방법 1: 자동 설정 스크립트 사용 (권장)

```bash
./setup_play_store.sh
```

이 스크립트가:
1. 서명 키 생성 (`~/android-keys/upload-keystore.jks`)
2. `android/key.properties` 파일 생성
3. 안내 메시지 표시

### 방법 2: 수동 설정

#### 1. 서명 키 생성

```bash
mkdir -p ~/android-keys
keytool -genkey -v \
    -keystore ~/android-keys/upload-keystore.jks \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -alias upload
```

**입력 정보:**
- 키스토어 비밀번호: 안전한 비밀번호 입력 (기억해두세요!)
- 키 비밀번호: 키스토어 비밀번호와 같으면 Enter
- 이름, 조직 등: 앱 정보 입력

#### 2. key.properties 파일 생성

`android/key.properties` 파일을 생성하고 다음 내용을 입력:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=/Users/marcoskim/android-keys/upload-keystore.jks
```

⚠️ **주의**: `key.properties` 파일은 Git에 올리지 마세요! (이미 .gitignore에 추가되어 있습니다)

## 🔨 Release 키로 AAB 다시 빌드

`key.properties` 파일을 생성한 후:

```bash
flutter build appbundle --release
```

또는 빌드 스크립트 사용:

```bash
./build_aab.sh
```

## 📤 Google Play Console 업로드

1. **Google Play Console 접속**
   - https://play.google.com/console
   - 앱 선택 또는 새 앱 생성

2. **AAB 파일 업로드**
   - 프로덕션 > 새 버전 만들기
   - `build/app/outputs/bundle/release/app-release.aab` 파일 업로드

3. **앱 정보 입력**
   - 출시 노트 작성
   - 스크린샷, 앱 설명 등 필수 정보 입력

4. **검토 제출**
   - 모든 정보 확인 후 검토 제출
   - 검토 완료까지 1-3일 소요

## 🔍 빌드 확인

AAB 파일이 올바르게 생성되었는지 확인:

```bash
ls -lh build/app/outputs/bundle/release/app-release.aab
```

## ⚠️ 문제 해결

### "서명이 일치하지 않습니다" 오류
- 같은 키 파일로 서명했는지 확인
- `key.properties` 파일의 경로와 비밀번호 확인

### "Application ID가 이미 사용 중입니다"
- `android/app/build.gradle.kts`에서 `applicationId` 확인
- 현재: `com.example.flutter_app`
- 고유한 ID로 변경 필요할 수 있음

### 빌드 경고 메시지
- "Release app bundle failed to strip debug symbols" 경고는 무시해도 됩니다
- AAB 파일은 정상적으로 생성되었습니다

## 📝 참고

- 키 파일(`upload-keystore.jks`)을 **절대 분실하지 마세요**
- 키 파일을 안전한 곳에 백업하세요
- 키 파일을 분실하면 앱 업데이트가 불가능합니다

