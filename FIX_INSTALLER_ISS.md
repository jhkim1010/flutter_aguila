# installer.iss 파일 수정 가이드

## 문제 상황
`installer.iss` 파일의 5번째 줄이 계속 `$11.0.0"`로 변경되는 문제가 발생하고 있습니다.

## 올바른 형식
```iss
#define MyAppName "Be COOL"
#define MyAppVersion "11.0.0"
#define MyAppPublisher "Cool Sistema"
```

## 잘못된 형식 (오류 발생)
```iss
#define MyAppName "Be COOL"
$11.0.0"  ❌ 잘못됨!
#define MyAppPublisher "Cool Sistema"
```

## 해결 방법

### 방법 1: 빌드 스크립트 사용 (권장)
빌드 스크립트가 자동으로 잘못된 형식을 수정합니다:
```powershell
.\build_windows_installer.ps1
```

### 방법 2: 파일 직접 수정
1. `installer.iss` 파일을 에디터로 엽니다
2. 5번째 줄을 확인합니다
3. `$11.0.0"`가 있으면 `#define MyAppVersion "11.0.0"`로 수정합니다
4. **중요**: `#define`을 반드시 포함해야 합니다
5. 파일을 저장합니다

### 방법 3: Git에서 복원
```powershell
git restore installer.iss
```

## 파일이 계속 변경되는 경우

### 가능한 원인
1. **에디터 자동 완성**: 에디터가 `#define`을 자동으로 제거할 수 있음
2. **파일 인코딩 문제**: 파일 저장 시 인코딩이 변경될 수 있음
3. **실수로 편집**: `#define`을 지우고 `$`만 남기는 실수

### 예방 방법
1. 파일을 편집할 때 5번째 줄을 주의 깊게 확인
2. `#define MyAppVersion`이 반드시 포함되어 있는지 확인
3. 빌드 스크립트를 사용하여 자동 수정 기능 활용

## 확인 방법
파일이 올바른지 확인:
```powershell
Select-String -Path installer.iss -Pattern '#define MyAppVersion'
```
결과가 나오면 올바른 형식입니다.

## 빌드 스크립트 자동 수정 기능
`build_windows_installer.ps1` 스크립트는 다음을 자동으로 수행합니다:
- 잘못된 형식(`$11.0.0"`) 감지
- 자동으로 올바른 형식(`#define MyAppVersion "11.0.0"`)으로 수정
- 버전 번호를 `pubspec.yaml`에서 자동으로 가져옴

