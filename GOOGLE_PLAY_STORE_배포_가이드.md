# Google Play Store 배포 가이드

## ⚠️ 중요 사항

**APK 파일만으로는 바로 업로드할 수 없습니다.** 다음 단계들이 필요합니다:

1. ✅ Google Play Console 계정 생성 (일회성 $25 등록비)
2. ✅ 앱 서명 키 생성 및 설정
3. ✅ AAB (Android App Bundle) 형식으로 빌드 (권장)
4. ✅ 앱 스토어 리스팅 정보 작성
5. ✅ 정책 준수 확인

---

## 1단계: Google Play Console 계정 생성

1. **Google Play Console 접속**
   - https://play.google.com/console 접속
   - Google 계정으로 로그인

2. **개발자 등록**
   - 일회성 등록비 $25 결제
   - 개발자 정보 입력
   - 약관 동의

3. **계정 생성 완료**
   - 계정이 활성화되면 앱을 업로드할 수 있습니다

---

## 2단계: 앱 서명 키 생성

현재 프로젝트는 **debug 키로 서명**되어 있어서 Google Play Store에 업로드할 수 없습니다. **release 키**를 생성해야 합니다.

### 키 생성 방법

```bash
cd android/app
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**입력 정보:**
- 비밀번호: 안전한 비밀번호 입력 (기억해두세요!)
- 이름, 조직 등: 앱 정보 입력

### 키 파일 보안
- `upload-keystore.jks` 파일을 **절대 공유하거나 Git에 올리지 마세요**
- 안전한 곳에 백업하세요 (분실 시 앱 업데이트 불가능)

---

## 3단계: 앱 서명 설정

### 1. 키 파일을 안전한 위치로 이동

```bash
# 키 파일을 프로젝트 외부로 이동 (Git에 올라가지 않도록)
mkdir -p ~/android-keys
mv android/app/upload-keystore.jks ~/android-keys/
```

### 2. key.properties 파일 생성

`android/key.properties` 파일 생성:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=/Users/marcoskim/android-keys/upload-keystore.jks
```

⚠️ **주의**: `key.properties` 파일도 Git에 올리지 마세요!

### 3. build.gradle.kts 수정

`android/app/build.gradle.kts` 파일 수정:

```kotlin
// 파일 상단에 추가
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ... 기존 설정 ...
    
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

### 4. .gitignore에 추가

`.gitignore` 파일에 다음 추가:

```
android/key.properties
android/app/upload-keystore.jks
*.jks
*.keystore
```

---

## 4단계: Application ID 변경

현재 `com.example.flutter_app`로 되어 있는데, **고유한 Application ID**로 변경해야 합니다.

### 1. build.gradle.kts 수정

```kotlin
defaultConfig {
    applicationId = "com.coolsistema.becoolaguila"  // 고유한 ID로 변경
    // ...
}
```

### 2. AndroidManifest.xml 확인

`android/app/src/main/AndroidManifest.xml`에서 패키지명 확인

---

## 5단계: AAB (Android App Bundle) 빌드

Google Play Store는 **AAB 형식을 권장**합니다 (APK보다 작고 최적화됨).

### 빌드 명령어

```bash
flutter build appbundle --release
```

### 빌드된 파일 위치

```
build/app/outputs/bundle/release/app-release.aab
```

---

## 6단계: Google Play Console에 앱 업로드

### 1. 새 앱 생성

1. Google Play Console 접속
2. **"앱 만들기"** 클릭
3. 앱 이름, 기본 언어, 앱 또는 게임 선택
4. 무료/유료 선택
5. 정책 동의

### 2. 앱 정보 입력

**필수 정보:**
- 앱 이름
- 짧은 설명 (80자)
- 전체 설명 (4000자)
- 앱 아이콘 (512x512px)
- 기능 그래픽 (1024x500px)
- 스크린샷 (최소 2개, 권장 8개)
- 연락처 이메일
- 개인정보처리방침 URL (필수)

### 3. 앱 업로드

1. **프로덕션** (또는 **내부 테스트**) 메뉴로 이동
2. **"새 버전 만들기"** 클릭
3. **AAB 파일 업로드** (또는 APK)
4. 출시 노트 작성
5. **"저장"** 클릭

### 4. 앱 검토 제출

1. 모든 필수 정보 입력 확인
2. 정책 준수 확인
3. **"검토 제출"** 클릭
4. 검토 완료까지 1-3일 소요

---

## 7단계: 앱 업데이트

앱을 업데이트할 때:

1. `pubspec.yaml`에서 버전 업데이트:
   ```yaml
   version: 1.0.1+2  # + 뒤의 숫자가 versionCode
   ```

2. AAB 다시 빌드:
   ```bash
   flutter build appbundle --release
   ```

3. Google Play Console에서 새 버전 업로드

---

## 현재 프로젝트 설정 확인

### 필요한 수정 사항

1. ✅ **Application ID 변경**
   - 현재: `com.example.flutter_app`
   - 변경 필요: `com.coolsistema.becoolaguila` (또는 고유한 ID)

2. ✅ **서명 키 설정**
   - 현재: debug 키 사용
   - 변경 필요: release 키 생성 및 설정

3. ✅ **버전 정보 확인**
   - `pubspec.yaml`에서 버전 확인

---

## 빠른 시작 스크립트

서명 설정이 완료되면 다음 스크립트를 사용할 수 있습니다:

```bash
# AAB 빌드 스크립트 (추후 생성 예정)
./build_aab.sh
```

---

## 문제 해결

### "서명이 일치하지 않습니다" 오류
- 같은 키 파일로 서명했는지 확인
- 키 파일을 분실하지 않았는지 확인

### "Application ID가 이미 사용 중입니다"
- 다른 Application ID 사용
- 또는 기존 앱의 소유권 확인

### "정책 위반" 오류
- Google Play 정책 확인
- 앱 권한, 개인정보처리방침 등 확인

---

## 참고 자료

- [Google Play Console 도움말](https://support.google.com/googleplay/android-developer)
- [Flutter 앱 배포 가이드](https://docs.flutter.dev/deployment/android)
- [Android 앱 서명](https://developer.android.com/studio/publish/app-signing)
