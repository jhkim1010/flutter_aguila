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
      : _httpHandler = httpHandler;

  /// 기존 데이터베이스 연결 끊기
  Future<void> disconnectDatabase() async {
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

      try {
        final response = await http.post(
          Uri.parse('${_httpHandler.serverUrl}/api/disconnect'),
          headers: headers,
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('⚠️ 연결 끊기 타임아웃 (무시하고 계속 진행)');
            return http.Response('', 200);
          },
        );

        if (response.statusCode == 200) {
          print('✅ 기존 연결이 성공적으로 끊어졌습니다.');
        } else {
          print('⚠️ 연결 끊기 응답: HTTP ${response.statusCode} (무시하고 계속 진행)');
        }
      } catch (e) {
        print('⚠️ 연결 끊기 실패 (무시하고 계속 진행): $e');
      }
    } catch (e) {
      print('⚠️ 연결 끊기 중 오류 발생 (무시하고 계속 진행): $e');
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
    print('Headers: Content-Type: application/json');
    
    try {
      final response = await http.post(
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
        throw Exception(
          'HTTP ${response.statusCode}: ${response.body.isNotEmpty ? response.body : "서버에서 오류 응답을 받았습니다"}'
        );
      }
    } catch (e) {
      print('❌ 연결 오류: ${e.toString()}');
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup')) {
        throw Exception('네트워크 오류: 서버에 연결할 수 없습니다. 서버 URL과 인터넷 연결을 확인하세요.');
      } else if (e.toString().contains('timeout')) {
        throw Exception('연결 타임아웃: 서버가 응답하지 않습니다. 서버가 실행 중인지 확인하세요.');
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
        final testRead = testPrefs.getString(testKey);
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
