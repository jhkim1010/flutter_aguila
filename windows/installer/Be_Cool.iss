; Be COOL - Inno Setup 설치 스크립트
;
; MSIX 와 달리 EXE 설치 프로그램은 Windows 가 인증서를 요구하지 않는다.
; 대상 PC 에 인증서를 미리 등록할 필요 없이 파일 하나로 설치된다.
;
; 컴파일 (Windows, Inno Setup 6 필요):
;   iscc /DAppVersion=1.0.0 /DSourceDir=..\..\build\windows\x64\runner\Release windows\installer\Be_Cool.iss
;
; AppVersion / SourceDir / OutputDir 은 CI 에서 주입한다. 로컬에서 직접 돌릴 때를
; 위해 기본값을 둔다.

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\..\build\windows\x64\runner\Release"
#endif
#ifndef OutputDir
  #define OutputDir "..\..\dist"
#endif

#define AppName "Be COOL"
#define AppPublisher "Cool Sistema"
#define AppExeName "Be_Cool.exe"

[Setup]
; AppId 는 절대 바꾸지 않는다. 이 값으로 기존 설치를 찾아 업그레이드하므로,
; 바뀌면 같은 앱이 두 번 설치된다.
AppId={{8F3C1A94-6E2D-4B7A-9C05-2D8E1F4A7B36}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
; 사용자 단위 설치. %LOCALAPPDATA%\Programs 에 들어가므로 UAC 승격 창이 뜨지
; 않고, 관리자 계정이 아닌 직원도 그대로 설치할 수 있다.
PrivilegesRequired=lowest
OutputDir={#OutputDir}
OutputBaseFilename=Be_Cool_Setup_v{#AppVersion}
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExeName}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
; Flutter Windows 빌드는 x64 전용이다.
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Release 디렉터리 전체를 재귀 복사한다. Be_Cool.exe 옆의 flutter_windows.dll,
; 플러그인 DLL, data\ (아이콘·에셋·ICU 데이터) 가 하나라도 빠지면 실행되지 않는다.
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent
