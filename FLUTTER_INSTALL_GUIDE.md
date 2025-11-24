# Flutter 설치 가이드 (Windows)

## 1. Flutter SDK 다운로드 및 설치

### 방법 1: 공식 웹사이트에서 다운로드 (권장)

1. **Flutter 공식 웹사이트 방문**
   - https://flutter.dev/docs/get-started/install/windows

2. **Flutter SDK 다운로드**
   - 최신 안정 버전의 zip 파일을 다운로드합니다
   - 예: `flutter_windows_3.x.x-stable.zip`

3. **압축 해제**
   - `C:\src\flutter` 경로에 압축을 해제합니다 (다른 경로도 가능하지만 공백이 없는 경로 권장)
   - 예: `C:\src\flutter\bin\flutter.bat` 파일이 있어야 합니다

### 방법 2: Git을 사용한 설치

```powershell
# Git이 설치되어 있다면
cd C:\src
git clone https://github.com/flutter/flutter.git -b stable
```

## 2. 환경 변수 설정

### PowerShell에서 설정 (현재 세션용)

```powershell
# Flutter 경로를 환경 변수에 추가 (예: C:\src\flutter\bin)
$env:PATH += ";C:\src\flutter\bin"
```

### 영구적으로 설정하기

1. **시스템 환경 변수 설정**
   - Windows 검색에서 "환경 변수" 검색
   - "시스템 환경 변수 편집" 선택
   - "환경 변수" 버튼 클릭
   - "시스템 변수" 섹션에서 `Path` 선택 후 "편집"
   - "새로 만들기" 클릭 후 `C:\src\flutter\bin` 추가
   - 모든 창에서 "확인" 클릭

2. **새 PowerShell 창 열기** (변경사항 적용)

## 3. Flutter 설치 확인

새 PowerShell 창을 열고 다음 명령어 실행:

```powershell
flutter --version
flutter doctor
```

`flutter doctor` 명령어는 필요한 추가 도구들을 확인하고 설치 방법을 안내합니다.

## 4. 필요한 추가 도구 설치

### Android Studio 설치 (안드로이드 개발용)

1. **Android Studio 다운로드**
   - https://developer.android.com/studio
   - 설치 시 "Android SDK", "Android SDK Platform", "Android Virtual Device" 포함

2. **Flutter 플러그인 설치**
   - Android Studio 실행
   - File > Settings > Plugins
   - "Flutter" 검색 후 설치 (Dart 플러그인도 자동 설치됨)

### Visual Studio 설치 (Windows 개발용, 선택사항)

- Windows 앱 개발 시에만 필요
- https://visualstudio.microsoft.com/downloads/
- "Desktop development with C++" 워크로드 설치

## 5. Flutter 설정 완료

```powershell
# Flutter 설정 확인
flutter doctor -v

# 라이선스 동의
flutter doctor --android-licenses
```

## 6. 프로젝트 실행 준비

설치가 완료되면 프로젝트 폴더에서:

```powershell
# 의존성 설치
flutter pub get

# 사용 가능한 디바이스 확인
flutter devices

# 앱 실행
flutter run
```

## 문제 해결

### "flutter 명령을 찾을 수 없습니다"
- 환경 변수 설정이 제대로 되지 않았을 수 있습니다
- PowerShell을 재시작하거나 시스템을 재부팅해보세요

### Android 라이선스 문제
```powershell
flutter doctor --android-licenses
```
모든 라이선스에 "y" 입력

### VS Code 사용 시
- VS Code에 Flutter 확장 프로그램 설치 권장
- Extensions에서 "Flutter" 검색 후 설치

## 빠른 설치 스크립트 (PowerShell)

다음 스크립트를 관리자 권한으로 실행하면 자동으로 환경 변수를 설정합니다:

```powershell
# Flutter 경로 설정 (본인의 설치 경로로 변경)
$flutterPath = "C:\src\flutter\bin"

# 시스템 환경 변수에 추가
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$flutterPath", [EnvironmentVariableTarget]::Machine)

Write-Host "환경 변수가 설정되었습니다. PowerShell을 재시작해주세요."
```

