import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'platform_utils.dart';

/// 로그를 파일에 저장하는 유틸리티 클래스
class LogFileWriter {
  static File? _logFile;
  static bool _isInitialized = false;
  static final List<String> _logBuffer = [];
  static const int _maxBufferSize = 100; // 버퍼 크기 제한
  static String? _platformInfo; // 플랫폼 정보 저장

  /// 로그 파일 작성자 초기화
  static Future<void> initialize({BuildContext? context}) async {
    // 웹: 파일 시스템이 없으므로 파일 로깅 비활성화 (콘솔 로깅만 사용)
    if (kIsWeb) {
      debugPrint('🌐 웹 플랫폼: 파일 로깅 비활성화 (콘솔 로깅만 사용)');
      return;
    }
    try {
      // 디버그 모드에서만 파일 로깅 활성화
      if (kDebugMode) {
        // 아직 초기화되지 않았으면 파일 생성
        if (!_isInitialized) {
          final directory = await getApplicationDocumentsDirectory();
          final logDir = Directory('${directory.path}/logs');
          if (!await logDir.exists()) {
            await logDir.create(recursive: true);
          }

          final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
          _logFile = File('${logDir.path}/app_log_$timestamp.txt');
          
          // 파일 생성 확인
          if (!await _logFile!.exists()) {
            await _logFile!.create(recursive: true);
          }
          
          // 기존 버퍼의 로그를 파일에 쓰기
          if (_logBuffer.isNotEmpty) {
            await _writeToFile(_logBuffer.join('\n'));
            _logBuffer.clear();
          }
          
          _isInitialized = true;
          await _writeToFile('=== 앱 시작: ${DateTime.now()} ===');
          
          // 초기화 완료 확인 로그
          print('📝 로그 파일 초기화 완료: ${_logFile!.path}');
        }
        
        // context가 있고 플랫폼 정보가 아직 기록되지 않았으면 기록
        if (context != null && _platformInfo == null) {
          String platformInfo = _getPlatformInfo(context);
          _platformInfo = platformInfo;
          await _writeToFile('=== 플랫폼 정보: $platformInfo ===');
          await _writeToFile('');
          print('📱 플랫폼 정보: $platformInfo');
        }
      }
    } catch (e) {
      debugPrint('⚠️ 로그 파일 초기화 실패: $e');
    }
  }
  
  /// 플랫폼 정보 가져오기
  static String _getPlatformInfo(BuildContext? context) {
    if (PlatformUtils.isDesktop()) {
      return '대형화면 (Desktop: macOS/Windows/Linux)';
    } else if (context != null && PlatformUtils.isIPad(context)) {
      return '대형화면 (Tablet: iPad)';
    } else {
      return '핸드폰 (Mobile: Android/iOS)';
    }
  }
  
  /// 현재 플랫폼 정보 가져오기
  static String? getPlatformInfo() {
    return _platformInfo;
  }

  /// 로그를 파일에 쓰기 (내부 메서드)
  static Future<void> _writeToFile(String message) async {
    // 웹: 파일 쓰기 미지원 — 조용히 무시
    if (kIsWeb) return;
    if (_logFile == null) {
      // 아직 초기화되지 않았으면 버퍼에 저장
      _logBuffer.add(message);
      if (_logBuffer.length > _maxBufferSize) {
        _logBuffer.removeAt(0);
      }
      return;
    }

    try {
      await _logFile!.writeAsString(
        '$message\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
      // debugPrint를 호출하지 않아 무한 루프 방지
      // print('⚠️ 로그 파일 쓰기 실패: $e');
    }
  }
  
  /// 파일에 직접 쓰기 (외부에서 호출 가능, 무한 루프 방지용)
  static Future<void> writeToFile(String message) async {
    await _writeToFile(message);
  }

  /// 로그 작성 (debugPrint를 오버라이드하여 사용)
  static void log(String message) {
    // 기본 debugPrint도 실행
    debugPrint(message);
    
    // 파일에도 저장
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      _writeToFile('[$timestamp] $message');
    }
  }

  /// 로그 파일 경로 가져오기
  static String? getLogFilePath() {
    return _logFile?.path;
  }

  /// 로그 파일 삭제
  static Future<void> clearLogs() async {
    if (_logFile != null && await _logFile!.exists()) {
      await _logFile!.delete();
      _logFile = null;
      _isInitialized = false;
    }
  }

  /// 모든 로그 파일 목록 가져오기
  static Future<List<File>> getAllLogFiles() async {
    // 웹: 파일 시스템 없음
    if (kIsWeb) return [];
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');
      
      if (!await logDir.exists()) {
        return [];
      }

      final files = logDir.listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.txt'))
          .toList();
      
      // 최신 파일부터 정렬
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      return files;
    } catch (e) {
      debugPrint('⚠️ 로그 파일 목록 가져오기 실패: $e');
      return [];
    }
  }
  
  /// 로그 파일에서 플랫폼 정보 읽기
  static Future<String?> readPlatformInfoFromLogFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }
      
      final content = await file.readAsString();
      final lines = content.split('\n');
      
      // 플랫폼 정보 라인 찾기
      for (final line in lines) {
        if (line.contains('=== 플랫폼 정보:')) {
          // "=== 플랫폼 정보: 대형화면 (Desktop: macOS/Windows/Linux) ===" 형식에서 추출
          final match = RegExp(r'=== 플랫폼 정보: (.+?) ===').firstMatch(line);
          if (match != null) {
            return match.group(1);
          }
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('⚠️ 로그 파일에서 플랫폼 정보 읽기 실패: $e');
      return null;
    }
  }
  
  /// 로그 파일이 대형화면용인지 확인
  static Future<bool> isLargeScreenLog(String filePath) async {
    final platformInfo = await readPlatformInfoFromLogFile(filePath);
    if (platformInfo == null) return false;
    return platformInfo.contains('대형화면');
  }
  
  /// 로그 파일이 핸드폰용인지 확인
  static Future<bool> isMobileLog(String filePath) async {
    final platformInfo = await readPlatformInfoFromLogFile(filePath);
    if (platformInfo == null) return false;
    return platformInfo.contains('핸드폰');
  }
}

// 전역 변수로 무한 루프 방지 플래그
bool _isFileLogging = false;

/// debugPrint를 오버라이드하여 파일에도 저장하는 확장
void setupFileLogging() {
  // 웹: 파일 로깅 미지원
  if (kIsWeb) return;
  if (kDebugMode) {
    // 기존 debugPrint를 백업
    final originalDebugPrint = debugPrint;
    
    // 새로운 debugPrint 설정
    debugPrint = (String? message, {int? wrapWidth}) {
      // 원래 debugPrint 실행
      originalDebugPrint(message, wrapWidth: wrapWidth);
      
      // 파일에도 저장 (무한 루프 방지)
      if (message != null && !_isFileLogging && !message.contains('📝 로그 파일 경로')) {
        _isFileLogging = true;
        try {
          final timestamp = DateTime.now().toIso8601String();
          // 비동기로 파일에 쓰기 (await 없이 실행하여 블로킹 방지)
          LogFileWriter.writeToFile('[$timestamp] $message').catchError((e) {
            // 에러 무시 (무한 루프 방지)
          });
        } catch (e) {
          // 에러 무시 (무한 루프 방지)
        } finally {
          _isFileLogging = false;
        }
      }
    };
  }
}

