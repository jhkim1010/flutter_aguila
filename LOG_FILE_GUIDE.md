# 로그 파일 저장 가이드

Flutter 앱 실행 시 모든 로그를 파일로 자동 저장하는 방법입니다.

## 방법 1: 쉘 스크립트 사용 (권장)

### 사용법

```bash
# macOS에서 실행
./run_with_log.sh macos

# iOS 시뮬레이터에서 실행
./run_with_log.sh ios

# Android 에뮬레이터에서 실행
./run_with_log.sh emulator-5554
```

### 로그 파일 위치

로그 파일은 프로젝트 루트의 `logs/` 디렉토리에 저장됩니다:

```
flutter_aguila/
  └── logs/
      └── flutter_log_20251231_181500.txt
```

파일명 형식: `flutter_log_YYYYMMDD_HHMMSS.txt`

## 방법 2: 앱 내부 로그 저장

앱 내부에서도 `debugPrint`로 출력된 모든 로그가 자동으로 파일에 저장됩니다.

### 로그 파일 위치

- **macOS**: `~/Library/Containers/com.yourcompany.flutter_app/Data/Documents/logs/`
- **iOS**: 앱의 Documents 디렉토리 내 `logs/` 폴더
- **Android**: `/data/data/com.yourcompany.flutter_app/files/logs/`

### 로그 파일 확인 방법

1. **macOS에서 확인**:
   ```bash
   # 로그 파일 경로 확인 (앱 실행 시 콘솔에 출력됨)
   # 또는 Finder에서 직접 확인
   open ~/Library/Containers/com.yourcompany.flutter_app/Data/Documents/logs/
   ```

2. **프로그래밍 방식으로 확인**:
   ```dart
   import 'utils/log_file_writer.dart';
   
   // 모든 로그 파일 목록 가져오기
   final logFiles = await LogFileWriter.getAllLogFiles();
   for (var file in logFiles) {
     print('로그 파일: ${file.path}');
   }
   
   // 현재 로그 파일 경로 확인
   final currentLogPath = LogFileWriter.getLogFilePath();
   print('현재 로그 파일: $currentLogPath');
   ```

## 로그 파일 형식

로그 파일은 다음과 같은 형식으로 저장됩니다:

```
[2025-12-31T18:15:00] === 앱 시작: 2025-12-31 18:15:00.123 ===
[2025-12-31T18:15:01] 📊 [ReportTableBuilder:176] buildTableFromList 함수 시작
[2025-12-31T18:15:02]    → 파일: report_table_builder.dart
[2025-12-31T18:15:02]    → 라인: 176
...
```

## 주의사항

1. **디버그 모드에서만 작동**: 로그 파일 저장은 `kDebugMode`가 `true`일 때만 활성화됩니다.
2. **로그 파일 크기**: 로그 파일이 너무 커지지 않도록 주의하세요. 필요시 오래된 로그 파일을 삭제하세요.
3. **성능**: 파일 쓰기는 비동기로 처리되므로 앱 성능에 큰 영향을 주지 않습니다.

## 로그 파일 삭제

```dart
// 현재 로그 파일 삭제
await LogFileWriter.clearLogs();

// 또는 파일 시스템에서 직접 삭제
```

## 문제 해결

### 로그 파일이 생성되지 않는 경우

1. 앱이 디버그 모드로 실행되고 있는지 확인하세요.
2. 파일 시스템 권한을 확인하세요.
3. 콘솔에 "📝 로그 파일 경로: ..." 메시지가 출력되는지 확인하세요.

### 로그 파일이 너무 큰 경우

- 주기적으로 오래된 로그 파일을 삭제하세요.
- 필요시 로그 레벨을 조정하여 불필요한 로그를 줄이세요.

