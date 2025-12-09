# iPad 앱 크래시 문제 해결 가이드

## 문제 분석

크래시 로그 분석 결과:
- **원인**: `flutter_secure_storage` 플러그인 초기화 중 null 포인터 접근
- **증상**: Release 빌드에 Debug 빌드(`Runner.debug.dylib`)가 섞여 있음
- **에러**: `EXC_BAD_ACCESS (SIGSEGV)` - 메모리 접근 오류

## 해결 방법

### 1. Xcode에서 Clean Build 수행

1. **Xcode 열기**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Clean Build Folder**
   - 상단 메뉴: **Product** > **Clean Build Folder** (⇧⌘K)
   - 또는: **Product** > **Clean** (⌘K)

3. **DerivedData 삭제** (선택사항)
   - Xcode > **Preferences** > **Locations**
   - **Derived Data** 경로 확인
   - Finder에서 해당 폴더의 `Runner-*` 폴더 삭제

### 2. Release 빌드로 다시 빌드

#### 방법 1: Xcode에서 직접 빌드 (권장)

1. **Xcode에서 기기 선택**
   - 상단 툴바에서 **iPad** 선택
   - 또는 **Any iOS Device** 선택

2. **Scheme 확인**
   - 상단 툴바에서 **Runner** 선택
   - **Edit Scheme** 클릭
   - **Run** > **Info** 탭에서 **Build Configuration**이 **Release**인지 확인
   - **Archive** > **Build Configuration**이 **Release**인지 확인

3. **Product > Build** (⌘B) 실행
   - Release 빌드로 빌드됩니다

4. **Product > Run** (⌘R) 실행
   - 앱이 실행되고 크래시가 해결되었는지 확인

#### 방법 2: Flutter로 Release 빌드

```bash
cd /Users/marcoskim/Trabajos_Programming/flutter_app
flutter build ios --release
```

그 다음 Xcode에서:
1. **Product > Archive** 실행
2. **Distribute App** > **Development** 또는 **Ad Hoc** 선택
3. IPA 파일 생성 후 iPad에 설치

### 3. flutter_secure_storage 플러그인 문제 해결

만약 여전히 크래시가 발생한다면:

#### 옵션 1: 플러그인 버전 확인
```bash
flutter pub outdated
flutter pub upgrade flutter_secure_storage
```

#### 옵션 2: Info.plist에 Keychain 설정 추가

`ios/Runner/Info.plist`에 다음 추가:
```xml
<key>Keychain Sharing</key>
<array>
    <string>$(AppIdentifierPrefix)com.coolsistema.becoolaguila</string>
</array>
```

### 4. Xcode Build Settings 확인

1. **Runner** 프로젝트 선택
2. **Runner** 타겟 선택
3. **Build Settings** 탭
4. 다음 설정 확인:
   - **Build Configuration**: Release
   - **Swift Compilation Mode**: Whole Module (Release)
   - **Optimization Level**: Optimize for Speed [-O]

### 5. 완전한 재빌드 절차

```bash
# 1. Flutter clean
cd /Users/marcoskim/Trabajos_Programming/flutter_app
flutter clean

# 2. 의존성 재설치
flutter pub get

# 3. iOS 의존성 재설치
cd ios
rm -rf Pods Podfile.lock .symlinks
export LANG=en_US.UTF-8
pod install
cd ..

# 4. Release 빌드
flutter build ios --release

# 5. Xcode에서 Archive
open ios/Runner.xcworkspace
```

## 추가 확인 사항

### Debug 빌드가 섞이지 않도록 확인

Xcode에서:
1. **Product** > **Scheme** > **Edit Scheme**
2. **Run** 탭 > **Info** > **Build Configuration**: **Debug**
3. **Archive** 탭 > **Build Configuration**: **Release** (중요!)
4. **Test** 탭 > **Build Configuration**: **Debug**

### 앱 삭제 후 재설치

1. iPad에서 앱 **완전히 삭제**
2. Xcode에서 **Clean Build Folder**
3. **Product > Build** 실행
4. 앱이 자동으로 설치됩니다

## 크래시가 계속 발생하는 경우

1. **Xcode Console 확인**
   - **Window** > **Devices and Simulators**
   - iPad 선택 > **Open Console**
   - 앱 실행 시 실시간 로그 확인

2. **크래시 로그 다시 확인**
   - **Open Recent Logs**에서 최신 크래시 로그 확인
   - 에러 메시지가 변경되었는지 확인

3. **flutter_secure_storage 사용 부분 확인**
   - 앱 시작 시 즉시 사용하는지 확인
   - 초기화 순서 확인

## 성공 확인

앱이 정상적으로 실행되면:
- ✅ 앱이 시작 화면까지 표시됨
- ✅ 크래시 없이 실행됨
- ✅ Xcode Console에 에러 없음
