# Windows 실행 및 설치 가이드

이 문서는 Flutter Águila 앱을 **Windows에서 실행**하고 **배포용으로 빌드**하는 방법을 요약합니다.

---

## 1. 사전 요구 사항

- **Windows 10** 이상 (64비트 권장)
- **Flutter SDK** 설치 및 `flutter` 명령이 PATH에 등록됨  
  - 설치 경로 확인: 아래 [Flutter 설치 경로 확인](#flutter-설치-경로-확인) 참고
- **Visual Studio 2022** (또는 2019) + **"Desktop development with C++"** 워크로드  
  - [Visual Studio 다운로드](https://visualstudio.microsoft.com/downloads/) → 설치 시 "C++를 사용한 데스크톱 개발" 선택

필요 시 Flutter가 Visual Studio를 인식하는지 확인:

```powershell
flutter doctor -v
```

`[✓] Windows Version`, `[✓] Visual Studio` 가 체크되어 있어야 합니다.

---

## 2. 개발 모드로 실행

프로젝트 루트에서:

```powershell
cd c:\Users\marcoskim\Trabajos\flutter_aguila
flutter pub get
flutter run -d windows
```

- `-d windows`: Windows 데스크톱으로 실행
- 디버그 빌드로 실행되며, 핫 리로드 사용 가능

---

## 3. 릴리스 빌드 (실행 파일 생성)

```powershell
flutter build windows
```

**출력 위치:**

```
build\windows\x64\runner\Release\
```

이 폴더에 다음이 생성됩니다.

- **`flutter_app.exe`** — 실행 파일
- **`*.dll`** — Flutter/엔진 등 필수 DLL
- **`data\`** — 리소스 폴더

**실행 방법:**  
위 `Release` 폴더 전체를 그대로 복사한 뒤, **같은 폴더 안에서** `flutter_app.exe`를 더블클릭하여 실행합니다.  
(exe만 옮기면 안 되고, 반드시 같은 폴더에 있는 DLL과 `data` 폴더가 함께 있어야 합니다.)

---

## 4. 배포용으로 전달하는 방법

### 4.1 폴더 압축 (가장 간단)

1. `build\windows\x64\runner\Release\` 폴더 전체를 ZIP으로 압축
2. 사용자에게 ZIP 전달
3. 사용자는 압축 해제 후 `flutter_app.exe` 실행

### 4.2 설치 프로그램(인스톨러) 만들기 (선택)

Flutter는 기본적으로 인스톨러를 만들지 않습니다. 원하면 아래 과정대로 exe + DLL + data를 묶어 설치 파일(.exe 또는 .msix)을 만들 수 있습니다.

---

## 5. 설치 파일 생성 과정 (상세)

### 5.1 Inno Setup으로 설치 파일(.exe) 만들기

**ISS로 설치 파일을 만들 때 사용하는 명령 (순서대로)**

> **중요:** **2번(flutter build windows)** 이 성공해야 `build\windows\x64\runner\Release\` 폴더가 생깁니다. 이 폴더가 없이 3번(Inno Setup)을 실행하면 "No files found matching ... Release\*" 오류가 납니다. 빌드가 실패하면 `lib/generated/build_info.dart` 존재 여부를 확인하고, 없으면 1번 스크립트를 실행하세요.

1. **빌드 정보 파일 생성** (최초 1회 또는 빌드 날짜를 갱신할 때):

   `lib/generated/build_info.dart` 파일이 없으면 Windows 빌드가 실패합니다.  
   프로젝트에 기본 파일이 있지만, **빌드 날짜를 주입**하려면 다음을 실행하세요.

   ```powershell
   cd c:\Users\marcoskim\Trabajos\flutter_aguila
   .\scripts\inject_build_date.ps1
   ```

2. **릴리스 빌드** (실행 파일·DLL 생성):

```powershell
cd c:\Users\marcoskim\Trabajos\flutter_aguila
flutter build windows
```

- 완료 후 `build\windows\x64\runner\Release\` 폴더에 exe, dll, data 폴더가 있어야 합니다. 없으면 3번으로 넘어가지 마세요.

3. **Inno Setup으로 .iss 스크립트 컴파일** (설치 exe 생성):

```powershell
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" "c:\Users\marcoskim\Trabajos\flutter_aguila\installer.iss"
```

- Inno Setup을 다른 경로에 설치했다면 `ISCC.exe` 경로만 실제 경로로 바꾸면 됩니다.
- 결과물은 스크립트의 `OutputDir`(예: `build\installers`)에 `*_Setup_*.exe` 형태로 생성됩니다.

---

**1단계: Inno Setup 설치**

- [Inno Setup 다운로드](https://jrsoftware.org/isdl.php)에서 최신 버전 설치 (예: `innosetup-6.x.x.exe`)
- 설치 후 **Inno Setup Compiler**가 사용 가능한지 확인

**2단계: 릴리스 빌드 준비**

```powershell
cd c:\Users\marcoskim\Trabajos\flutter_aguila
flutter build windows
```

빌드 결과가 `build\windows\x64\runner\Release\` 에 있는지 확인합니다.

**3단계: Inno Setup 스크립트(.iss) 작성**

프로젝트 루트에 `installer.iss` (또는 `packaging/installer.iss`) 파일을 만들고 아래 내용을 넣습니다.  
경로는 실제 프로젝트 경로에 맞게 수정하세요.

```iss
; Flutter Águila - Windows 설치 스크립트 (Inno Setup)
#define MyAppName "Flutter Águila"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Your Name"
#define MyAppExeName "flutter_app.exe"
#define MyAppAssocName "Flutter Águila"
; 빌드 결과물 경로 (프로젝트 루트 기준)
#define BuildOutput "build\windows\x64\runner\Release"

[Setup]
AppId={{YOUR-GUID-HERE}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=installer_output
OutputBaseFilename=FlutterAguila_Setup_{#MyAppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "korean"; MessagesFile: "compiler:Languages\Korean.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Release 폴더 전체 내용을 앱 설치 경로로 복사
Source: "{#BuildOutput}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: dirifempty; Name: "{app}"
```

- `AppId`: 고유 GUID로 변경 권장 (예: `{12345678-1234-1234-1234-123456789ABC}`)
- `OutputDir`: 컴파일 후 생성되는 설치 파일이 저장될 폴더 (프로젝트 내 `installer_output` 등)
- 한국어 설치 화면을 쓰려면 `MessagesFile: "compiler:Languages\Korean.isl"` 사용

**4단계: 스크립트 컴파일**

- **GUI**: Inno Setup Compiler 실행 → `File` → `Open` → `installer.iss` 선택 → `Build` → `Compile`
- **명령줄** (Inno Setup이 PATH에 있거나 전체 경로 지정):

```powershell
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" "c:\Users\marcoskim\Trabajos\flutter_aguila\installer.iss"
```

**5단계: 결과 확인**

- 스크립트의 `OutputDir`에 지정한 폴더(예: `installer_output`)에 `FlutterAguila_Setup_1.0.0.exe` 같은 단일 설치 파일이 생성됩니다.
- 이 exe를 사용자에게 배포하면, 실행 시 설치 경로 선택 → 바로가기 생성 → 제거 프로그램 등록까지 한 번에 진행됩니다.

---

### 5.2 MSIX 패키지로 설치 파일(.msix) 만들기

Microsoft 스토어 또는 엔터프라이즈 배포용으로 MSIX 패키지를 만들 수 있습니다.

**1단계: msix 패키지 도구 설치**

```powershell
dart pub global activate msix
```

**2단계: pubspec.yaml에 msix 설정 추가 (선택)**

`pubspec.yaml`에 예시처럼 추가할 수 있습니다.

```yaml
msix_config:
  display_name: Flutter Águila
  publisher_display_name: Your Name
  identity_name: com.yourcompany.flutter_aguila
  logo_path: assets\icon.png
```

**3단계: Windows 빌드 후 MSIX 생성**

cd trabajos 
cd flutter_aguila
flutter build windows
msix pack

& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" "c:\Users\marcoskim\Trabajos\flutter_aguila\installer.iss"

- `msix`가 `build\windows\x64\runner\Release` 내용을 기반으로 `.msix` 패키지를 생성합니다.
- 생성된 `.msix`는 더블클릭으로 설치하거나, 스토어 제출용으로 사용할 수 있습니다.

자세한 옵션은 [Flutter Windows MSIX 문서](https://docs.flutter.dev/deployment/windows#building-a-windows-msix-installer)를 참고하세요.

---

### 5.3 설치 파일 생성 요약

| 방법 | 결과물 | 용도 |
|------|--------|------|
| **Inno Setup** | `FlutterAguila_Setup_1.0.0.exe` | 일반 사용자 배포, 시작 메뉴/바탕화면 바로가기, 제거 프로그램 |
| **MSIX** | `*.msix` | 스토어/엔터프라이즈, UWP 스타일 설치 |
| **ZIP** | `Release` 폴더 압축 | 간단 전달, 설치 없이 압축 해제 후 실행 |

---

## 6. 요약

| 목적           | 명령어 / 위치 |
|----------------|----------------|
| 개발 중 실행   | `flutter run -d windows` |
| 릴리스 빌드    | `flutter build windows` |
| 실행 파일 위치 | `build\windows\x64\runner\Release\` |
| 배포           | `Release` 폴더 전체를 ZIP으로 전달하거나, Inno Setup/MSIX로 설치 파일 생성 |

---

## 7. 문제 해결

- **Visual Studio를 찾을 수 없음**  
  `flutter doctor -v`에서 안내하는 대로 Visual Studio에 "C++를 사용한 데스크톱 개발" 워크로드를 설치합니다.

- **exe 실행 시 DLL 오류**  
  exe와 같은 폴더에 모든 DLL과 `data` 폴더가 있는지 확인합니다. `Release` 폴더 전체를 그대로 사용해야 합니다.

- **다른 PC에서 실행**  
  동일한 `Release` 폴더 전체를 복사해 옮기면 됩니다. 해당 PC에 Flutter나 Visual Studio를 설치할 필요는 없습니다.

- **ISS 컴파일 시 "No files found matching ... Release\*" 오류**  
  `[Files]` 섹션에서 참조하는 `build\windows\x64\runner\Release\` 폴더가 없을 때 발생합니다.  
  **해결:**  
  1. `lib/generated/build_info.dart` 가 있는지 확인하세요. 없으면 `scripts\inject_build_date.ps1` 를 실행하거나, 프로젝트에 포함된 기본 `build_info.dart` 가 있는지 확인하세요.  
  2. 프로젝트 루트에서 `flutter build windows`를 실행하세요. 빌드가 성공해야 `build\windows\x64\runner\Release\` 아래에 exe, dll, `data` 폴더가 생깁니다.  
  3. 그 다음에 Inno Setup으로 `installer.iss`를 컴파일하세요.

#### Flutter 설치 경로 확인

Flutter가 어디에 설치되었는지 확인하는 방법입니다.

- **PowerShell / CMD**
  ```powershell
  where flutter
  ```
  출력된 경로가 `...\flutter\bin\flutter.bat` 형태라면, Flutter **설치 폴더**는 그 `bin`의 한 단계 위입니다.  
  예: `C:\src\flutter\bin\flutter.bat` → 설치 경로는 `C:\src\flutter`

- **PowerShell (실행 파일 경로만 보기)**
  ```powershell
  (Get-Command flutter).Source
  ```
  여기서 나온 파일의 부모가 `bin`이면, 그 부모 폴더가 Flutter 설치 경로입니다.

- **flutter doctor로 확인**
  ```powershell
  flutter doctor -v
  ```
  출력 맨 위에 `[✓] Flutter (Channel ..., version ... • C:\...\flutter)` 처럼 **설치 경로**가 함께 표시됩니다.
