# Windows 빌드 가이드

Windows에서 Flutter 앱을 빌드하는 방법입니다.

## 사전 요구사항

1. Flutter가 설치되어 있어야 합니다.
2. Flutter가 PATH 환경 변수에 추가되어 있거나, 설치 경로를 알고 있어야 합니다.

## Flutter 설치 경로 확인 방법

PowerShell에서 다음 명령어로 Flutter 경로를 확인할 수 있습니다:

```powershell
where.exe flutter
```

또는 Flutter가 설치된 일반적인 위치:
- `C:\src\flutter`
- `C:\flutter`
- `%LOCALAPPDATA%\flutter`
- `%USERPROFILE%\flutter`

## 빌드 방법

### 방법 1: 자동 빌드 스크립트 (권장)

Flutter가 PATH에 있는 경우:

```powershell
.\build_windows.ps1
```

또는 배치 파일:

```cmd
build_windows.bat
```

### 방법 2: 수동 Flutter 경로 입력

Flutter가 PATH에 없는 경우:

```powershell
.\build_windows_manual.ps1
```

스크립트가 Flutter 경로를 요청하면 설치 경로를 입력하세요 (예: `C:\src\flutter`)

### 방법 3: 수동 빌드

1. 빌드 날짜 주입:
   ```powershell
   .\scripts\inject_build_date_simple.ps1
   ```

2. Flutter 빌드:
   ```powershell
   flutter build windows --release --no-pub
   ```

   또는 Flutter가 PATH에 없는 경우:
   ```powershell
   C:\src\flutter\bin\flutter.bat build windows --release --no-pub
   ```
   (경로를 실제 Flutter 설치 경로로 변경하세요)

## Flutter를 PATH에 추가하는 방법

1. Flutter 설치 경로의 `bin` 폴더를 찾습니다 (예: `C:\src\flutter\bin`)

2. 시스템 환경 변수에 추가:
   - Windows 키 + R을 눌러 `sysdm.cpl` 실행
   - "고급" 탭 → "환경 변수" 클릭
   - "시스템 변수"에서 `Path` 선택 → "편집"
   - "새로 만들기" 클릭 → Flutter bin 경로 추가 (예: `C:\src\flutter\bin`)
   - 모든 창 확인

3. PowerShell을 다시 시작하고 확인:
   ```powershell
   flutter --version
   ```

## 빌드 결과

빌드가 성공하면 실행 파일이 다음 위치에 생성됩니다:

```
build\windows\runner\Release\Be_Cool.exe
```

## Windows 설치 파일 생성 (Inno Setup)

실행 파일을 빌드한 후, Inno Setup을 사용하여 설치 파일(.exe)을 생성할 수 있습니다.

### 사전 요구사항

1. **Inno Setup 6 설치**
   - 다운로드: https://jrsoftware.org/isdl.php
   - 기본 설치 경로: `C:\Program Files (x86)\Inno Setup 6\`

2. **Flutter Windows 빌드 완료**
   - 위의 빌드 방법으로 실행 파일을 먼저 생성해야 합니다

### 설치 파일 생성

PowerShell에서 다음 명령어 실행:

```powershell
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer.iss
```

### ⚠️ 중요: installer.iss 파일 확인

**5번째 줄이 올바른지 반드시 확인하세요:**

올바른 형식:
```iss
#define MyAppVersion "1.0.0"
```

잘못된 형식 (오류 발생):
```iss
$11.0.0"  // ❌ 잘못됨
```

### 문제 해결

#### Inno Setup 컴파일 오류: MyAppVersion 선언 오류

**증상:**
- 컴파일 시 오류 발생
- `installer.iss` 파일의 5번째 줄이 잘못됨

**해결 방법:**

1. **에디터에서 직접 수정**
   - `installer.iss` 파일을 텍스트 에디터로 열기
   - 5번째 줄 확인: `#define MyAppVersion "1.0.0"` 형식이어야 함
   - 잘못된 경우 수정 후 저장

2. **파일이 계속 되돌아가는 경우**
   - 에디터에서 파일을 열어 5번째 줄을 직접 확인
   - `#define MyAppVersion "1.0.0"` 형식으로 수정
   - 저장 후 다시 컴파일 시도
   - 일부 에디터는 자동 저장이나 인코딩 변환으로 인해 문제가 발생할 수 있음

3. **수정 후 재컴파일**
   ```powershell
   & "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer.iss
   ```

### 생성되는 설치 파일

- **위치**: `build\installers\Be_COOL_Setup_1.0.0.exe`
- 이 파일을 다른 Windows PC로 전송하여 설치할 수 있습니다

## 문제 해결

### "Flutter not found" 오류

- Flutter가 PATH에 추가되어 있는지 확인
- `flutter --version` 명령어로 확인
- `build_windows_manual.ps1`을 사용하여 수동으로 경로 지정

### PowerShell 실행 정책 오류

관리자 권한으로 PowerShell을 열고:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 인코딩 오류

PowerShell에서 UTF-8 인코딩을 사용하도록 설정:

```powershell
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
```

