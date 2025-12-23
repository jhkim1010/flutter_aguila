import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../secure_storage_helper.dart';
import 'http_request_handler.dart';

export 'http_request_handler.dart';

class DatabaseConnectionRequest {
  final String databaseName;
  final String username;
  final String password;

  DatabaseConnectionRequest({
    required this.databaseName,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'databaseName': databaseName,
      'username': username,
      'password': password,
    };
  }
}

/// 데이터베이스 연결 관련 API
class DatabaseConnectionApi {
  final HttpRequestHandler _httpHandler;

  DatabaseConnectionApi({required HttpRequestHandler httpHandler})
      : _httpHandler = httpHandler {
    // HttpRequestHandler의 클라이언트를 재사용하여 pool 낭비 방지
  }

  /// 리소스 정리 (HttpRequestHandler가 관리하므로 여기서는 아무것도 하지 않음)
  void dispose() {
    // HttpRequestHandler의 클라이언트를 재사용하므로 여기서는 정리하지 않음
  }
  
  /// HttpRequestHandler의 클라이언트를 반환 (내부 사용)
  http.Client get _httpClient => _httpHandler.httpClient;

  /// 기존 데이터베이스 연결 끊기
  /// 재시도 로직을 포함하여 서버에 확실히 전달되도록 보장
  Future<void> disconnectDatabase({int maxRetries = 3}) async {
    try {
      final headers = await _httpHandler.getDatabaseHeaders();
      final databaseName = headers['x-db-name'] ?? '';
      
      if (databaseName.isEmpty) {
        print('ℹ️ 끊을 기존 연결이 없습니다.');
        return;
      }

      print('=== 기존 연결 끊기 시도 ===');
      print('URL: ${_httpHandler.serverUrl}/api/disconnect');
      print('Headers: $headers');

      bool success = false;
      int attempt = 0;

      // 재시도 로직: 서버에 확실히 전달되도록 보장
      while (attempt < maxRetries && !success) {
        attempt++;
        print('🔄 연결 끊기 시도 $attempt/$maxRetries');

        try {
          final response = await _httpClient.post(
            Uri.parse('${_httpHandler.serverUrl}/api/disconnect'),
            headers: headers,
          ).timeout(
            const Duration(seconds: 10), // 타임아웃 증가: 5초 → 10초
            onTimeout: () {
              print('⚠️ 연결 끊기 타임아웃 (시도 $attempt/$maxRetries)');
              throw TimeoutException('Disconnect timeout', const Duration(seconds: 10));
            },
          );

          if (response.statusCode == 200) {
            print('✅ 기존 연결이 성공적으로 끊어졌습니다.');
            success = true;
          } else {
            print('⚠️ 연결 끊기 응답: HTTP ${response.statusCode} (시도 $attempt/$maxRetries)');
            if (attempt < maxRetries) {
              await Future.delayed(const Duration(milliseconds: 500));
            }
          }
        } catch (e) {
          print('⚠️ 연결 끊기 실패 (시도 $attempt/$maxRetries): $e');
          
          // 네트워크 오류가 아닌 경우에만 재시도
          final errorMessage = e.toString();
          if (errorMessage.contains('SocketException') || 
              errorMessage.contains('Failed host lookup') ||
              errorMessage.contains('TimeoutException')) {
            if (attempt < maxRetries) {
              print('🔄 네트워크 오류로 재시도 중... (${attempt + 1}/$maxRetries)');
              await Future.delayed(Duration(milliseconds: 500 * attempt)); // 지수 백오프
            } else {
              print('❌ 최대 재시도 횟수 초과. 서버에 연결 풀 정리 요청이 전달되지 않았을 수 있습니다.');
            }
          } else {
            // 다른 종류의 오류는 재시도하지 않음
            print('❌ 재시도 불가능한 오류: $e');
            break;
          }
        }
      }

      if (!success) {
        print('⚠️ 경고: 연결 끊기 요청이 서버에 전달되지 않았을 수 있습니다.');
        print('   → Node.js 서버에서 타임아웃 기반 자동 정리 기능을 확인하세요.');
      }
    } catch (e) {
      print('❌ 연결 끊기 중 치명적 오류 발생: $e');
      print('   → 서버에 연결 풀 정리 요청이 전달되지 않았을 수 있습니다.');
    }
  }

  /// 데이터베이스 연결
  Future<bool> connectToDatabase(
    DatabaseConnectionRequest request, {
    bool disconnectExisting = false,
  }) async {
    if (disconnectExisting) {
      final existingHeaders = await _httpHandler.getDatabaseHeaders();
      final existingDbName = existingHeaders['x-db-name'] ?? '';
      final existingDbUser = existingHeaders['x-db-user'] ?? '';
      
      if (existingDbName.isNotEmpty && 
          (existingDbName != request.databaseName || existingDbUser != request.username)) {
        print('🔄 기존 연결($existingDbName/$existingDbUser)과 다른 연결로 전환합니다.');
        await disconnectDatabase();
      } else if (existingDbName.isNotEmpty && 
                 existingDbName == request.databaseName && 
                 existingDbUser == request.username) {
        print('ℹ️ 동일한 연결이므로 기존 연결을 끊지 않습니다.');
      }
    } else {
      print('ℹ️ disconnect 요청을 보내지 않습니다. (disconnectExisting=false)');
    }

    final url = '${_httpHandler.serverUrl}/api/health';
    final requestBody = jsonEncode(request.toJson());
    
    print('=== 연결 시도 ===');
    print('URL: $url');
    print('Request Body: $requestBody');
    print('Headers: Content-Type: application/json');
    
    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          print('❌ 연결 타임아웃 (60초 초과)');
          throw Exception('Connection timeout: 서버 응답이 60초를 초과했습니다. 서버 상태를 확인하거나 잠시 후 다시 시도해주세요.');
        },
      );

      print('=== 응답 정보 ===');
      print('Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ 연결 성공');
        await _saveConnectionInfo(request);
        return true;
      } else {
        print('❌ 연결 실패: HTTP ${response.statusCode}');
        final errorBody = response.body.isNotEmpty ? response.body : '서버에서 오류 응답을 받았습니다';
        
        // 서버 측 설정 오류인 경우 더 명확한 메시지 제공
        if (errorBody.contains('dbHost is not defined') || 
            errorBody.contains('dbHost') && errorBody.contains('not defined')) {
          throw Exception(
            '서버 설정 오류: 데이터베이스 호스트(dbHost)가 서버에 설정되지 않았습니다.\n'
            '서버 관리자에게 문의하여 서버의 환경 변수나 설정 파일에 DB_HOST를 설정해달라고 요청하세요.\n'
            '원본 오류: HTTP ${response.statusCode}: $errorBody'
          );
        }
        
        throw Exception(
          'HTTP ${response.statusCode}: $errorBody'
        );
      }
    } catch (e) {
      print('❌ 연결 오류: ${e.toString()}');
      final errorMessage = e.toString();
      if (errorMessage.contains('SocketException') || 
          errorMessage.contains('Failed host lookup')) {
        throw Exception('네트워크 오류: 서버에 연결할 수 없습니다. 서버 URL과 인터넷 연결을 확인하세요.');
      } else if (errorMessage.contains('timeout')) {
        throw Exception('연결 타임아웃: 서버가 응답하지 않습니다. 서버가 실행 중인지 확인하세요.');
      } else if (errorMessage.contains('CERTIFICATE_VERIFY_FAILED') ||
                 errorMessage.contains('HandshakeException') ||
                 errorMessage.contains('self signed certificate')) {
        throw Exception('SSL 인증서 오류: 자체 서명 인증서가 감지되었습니다. SSL 클라이언트 설정을 확인하세요.');
      } else {
        throw Exception('연결 실패: ${e.toString()}');
      }
    }
  }

  /// 연결 정보 저장
  Future<void> _saveConnectionInfo(DatabaseConnectionRequest request) async {
    try {
      print('💾 데이터베이스 정보 저장 시도:');
      print('   database_name: ${request.databaseName}');
      print('   username: ${request.username}');
      print('   password: *** (길이: ${request.password.length})');
      
      final isMacOS = defaultTargetPlatform == TargetPlatform.macOS;
      
      if (isMacOS) {
        print('🍎 macOS 개발 환경: 모든 데이터를 SharedPreferences에 저장');
      } else {
        print('💾 하이브리드 저장 방식 사용:');
        print('   - database_name, username → SharedPreferences (안정적)');
        print('   - password → SecureStorage (보안)');
      }
      
      // 1단계: database_name 저장
      print('📝 [1/3] database_name 저장 시도...');
      final dbNameSaved = await SecureStorageHelper.save('database_name', request.databaseName);
      if (!dbNameSaved) {
        print('❌ [1/3] database_name 저장 실패!');
        throw Exception('database_name 저장 실패');
      }
      print('✅ [1/3] database_name 저장 성공');
      
      // 2단계: username 저장
      print('📝 [2/3] username 저장 시도...');
      final usernameSaved = await SecureStorageHelper.save('username', request.username);
      if (!usernameSaved) {
        print('❌ [2/3] username 저장 실패!');
        throw Exception('username 저장 실패');
      }
      print('✅ [2/3] username 저장 성공');
      
      // 3단계: password 저장
      print('📝 [3/3] password 저장 시도...');
      final passwordSaved = isMacOS 
          ? await SecureStorageHelper.save('password', request.password)
          : await SecureStorageHelper.saveSecure('password', request.password);
      
      if (!passwordSaved) {
        print('❌ [3/3] password 저장 실패!');
        throw Exception('password 저장 실패');
      }
      print('✅ [3/3] password 저장 성공');
      
      // 저장 확인
      await _verifySavedInfo(request, isMacOS);
      
      print('✅ 데이터베이스 정보 저장 완료');
      if (isMacOS) {
        print('🍎 macOS 저장 프로세스 완료!');
      }
    } catch (e) {
      print('❌ 데이터베이스 정보 저장 실패: $e');
      print('   오류 상세: ${e.toString()}');
      print('   스택 트레이스: ${StackTrace.current}');
      
      if (defaultTargetPlatform == TargetPlatform.macOS) {
        await _diagnoseMacOSStorage();
      }
      
      throw Exception('연결은 성공했지만 정보 저장에 실패했습니다: ${e.toString()}');
    }
  }

  /// 저장된 정보 확인
  Future<void> _verifySavedInfo(DatabaseConnectionRequest request, bool isMacOS) async {
    print('🔍 저장 확인 단계 시작...');
    
    // database_name 확인
    final savedDbName = await SecureStorageHelper.read('database_name');
    if (savedDbName == null || savedDbName != request.databaseName) {
      throw Exception('database_name 저장 확인 실패: ${savedDbName == null ? "읽을 수 없음" : "값 불일치"}');
    }
    print('✅ [확인 1/3] database_name 확인 완료: "$savedDbName"');
    
    // username 확인
    final savedUsername = await SecureStorageHelper.read('username');
    if (savedUsername == null || savedUsername != request.username) {
      throw Exception('username 저장 확인 실패: ${savedUsername == null ? "읽을 수 없음" : "값 불일치"}');
    }
    print('✅ [확인 2/3] username 확인 완료: "$savedUsername"');
    
    // password 확인
    final savedPassword = isMacOS
        ? await SecureStorageHelper.read('password')
        : await SecureStorageHelper.readSecure('password');
    
    if (savedPassword == null || savedPassword.isEmpty || savedPassword != request.password) {
      throw Exception('password 저장 확인 실패: ${savedPassword == null ? "읽을 수 없음" : savedPassword.isEmpty ? "빈 값" : "값 불일치"}');
    }
    print('✅ [확인 3/3] password 확인 완료: 길이 ${savedPassword.length}');
  }

  /// macOS 저장소 진단
  Future<void> _diagnoseMacOSStorage() async {
    print('');
    print('🔍 macOS 저장 실패 상세 분석:');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    print('📊 저장소 상태 확인:');
    
    // SharedPreferences 상태
    try {
      final testPrefs = await SharedPreferences.getInstance();
      final testKey = 'test_${DateTime.now().millisecondsSinceEpoch}';
      final testSaved = await testPrefs.setString(testKey, 'test');
      if (testSaved) {
        final _ = testPrefs.getString(testKey);
        await testPrefs.remove(testKey);
        print('   ✅ SharedPreferences: 정상 작동');
      } else {
        print('   ❌ SharedPreferences: 저장 실패');
      }
    } catch (prefError) {
      print('   ❌ SharedPreferences: 오류 발생 - $prefError');
    }
    
    // SecureStorage 상태
    try {
      const testStorage = FlutterSecureStorage(
        mOptions: MacOsOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
          synchronizable: false,
        ),
      );
      final testKey = 'test_${DateTime.now().millisecondsSinceEpoch}';
      await testStorage.write(key: testKey, value: 'test');
      await Future.delayed(const Duration(milliseconds: 100));
      final testRead = await testStorage.read(key: testKey);
      await testStorage.delete(key: testKey);
      if (testRead == 'test') {
        print('   ✅ SecureStorage: 정상 작동');
      } else {
        print('   ❌ SecureStorage: 읽기 실패');
      }
    } catch (storageError) {
      print('   ❌ SecureStorage: 오류 발생 - $storageError');
    }
    
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');
    print('💡 해결 방법:');
    print('   1. 앱을 완전히 종료하고 다시 실행');
    print('   2. macOS Keychain 접근 권한 확인');
    print('   3. 디스크 공간 확인');
    print('   4. 앱 권한 설정 확인 (시스템 설정 > 개인정보 보호)');
    print('');
  }
}
