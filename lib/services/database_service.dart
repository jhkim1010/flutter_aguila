import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'secure_storage_helper.dart';
import '../models/stocks_response.dart';
import '../models/todocodigos_response.dart';

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

class DatabaseService {
  final String serverUrl;
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  DatabaseService({required this.serverUrl});

  /// 기존 데이터베이스 연결 끊기 (선택적 - 서버에 disconnect API가 있는 경우)
  Future<void> disconnectDatabase() async {
    try {
      // 저장된 기존 연결 정보 가져오기
      final headers = await _getDatabaseHeaders();
      
      // 기존 연결 정보가 없으면 끊을 연결이 없음
      final databaseName = headers['x-db-name'] ?? '';
      if (databaseName.isEmpty) {
        print('ℹ️ 끊을 기존 연결이 없습니다.');
        return;
      }

      print('=== 기존 연결 끊기 시도 ===');
      print('URL: $serverUrl/api/disconnect');
      print('Headers: $headers');

      // 서버에 disconnect API가 있다면 호출 (없어도 오류 무시)
      try {
        final response = await http.post(
          Uri.parse('$serverUrl/api/disconnect'),
          headers: headers,
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('⚠️ 연결 끊기 타임아웃 (무시하고 계속 진행)');
            return http.Response('', 200); // 타임아웃 시 성공으로 처리
          },
        );

        if (response.statusCode == 200) {
          print('✅ 기존 연결이 성공적으로 끊어졌습니다.');
        } else {
          print('⚠️ 연결 끊기 응답: HTTP ${response.statusCode} (무시하고 계속 진행)');
        }
      } catch (e) {
        // disconnect API가 없거나 오류가 발생해도 무시하고 계속 진행
        print('⚠️ 연결 끊기 실패 (무시하고 계속 진행): $e');
      }
    } catch (e) {
      // 오류가 발생해도 무시하고 계속 진행
      print('⚠️ 연결 끊기 중 오류 발생 (무시하고 계속 진행): $e');
    }
  }

  /// 공통 GET 요청 메서드 (오류 처리 포함)
  Future<Map<String, dynamic>> _performGetRequest(
    String endpoint, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      // 데이터베이스 연결 정보를 헤더로 가져오기
      final headers = await _getDatabaseHeaders();
      
      // 쿼리 파라미터가 있으면 URL에 추가
      final uri = Uri.parse('$serverUrl$endpoint');
      final uriWithQuery = queryParameters != null && queryParameters.isNotEmpty
          ? uri.replace(queryParameters: queryParameters)
          : uri;
      
      print('=== GET $endpoint 요청 ===');
      print('URL: $uriWithQuery');
      print('Headers: $headers');
      if (queryParameters != null && queryParameters.isNotEmpty) {
        print('Query Parameters: $queryParameters');
      }
      
      final response = await http.get(
        uriWithQuery,
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('❌ 요청 타임아웃 (10초 초과)');
          throw Exception('요청 타임아웃: 서버 응답이 10초를 초과했습니다. 서버가 실행 중인지 확인하세요.');
        },
      );

      print('=== 응답 정보 ===');
      print('Status Code: ${response.statusCode}');
      
      // 응답 바디 출력 (GET 요청이므로 응답 바디만 있음)
      if (response.body.isNotEmpty) {
        try {
          final decoded = json.decode(response.body);
          print('📦 Response Body:');
          // JSON을 보기 좋게 포맷팅하여 출력 (너무 길면 일부만 출력)
          final jsonString = json.encode(decoded);
          if (jsonString.length > 2000) {
            print('${jsonString.substring(0, 2000)}... (truncated, total length: ${jsonString.length})');
          } else {
            print(jsonString);
          }
        } catch (e) {
          print('📦 Response Body (raw):');
          if (response.body.length > 2000) {
            print('${response.body.substring(0, 2000)}... (truncated, total length: ${response.body.length})');
          } else {
            print(response.body);
          }
        }
      } else {
        print('📦 Response Body: (empty)');
      }

      if (response.statusCode == 200) {
        try {
          final decoded = json.decode(response.body);
          if (decoded is Map) {
            return decoded as Map<String, dynamic>;
          } else if (decoded is List) {
            return {'data': decoded};
          } else {
            return {'result': decoded};
          }
        } catch (e) {
          print('❌ JSON 파싱 오류: $e');
          throw Exception('JSON 파싱 오류: 서버 응답을 파싱할 수 없습니다. 응답: ${response.body}');
        }
      } else {
        // HTTP 오류 상태 코드 처리
        String errorMessage = 'HTTP ${response.statusCode} 오류';
        try {
          final errorBody = json.decode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'].toString();
          } else if (errorBody is Map && errorBody.containsKey('error')) {
            errorMessage = errorBody['error'].toString();
          } else if (response.body.isNotEmpty) {
            errorMessage = response.body;
          }
        } catch (e) {
          // JSON 파싱 실패 시 원본 응답 사용
          if (response.body.isNotEmpty) {
            errorMessage = response.body;
          }
        }
        
        print('❌ HTTP 오류: $errorMessage');
        throw Exception('서버 오류 (${response.statusCode}): $errorMessage');
      }
    } catch (e) {
      print('❌ GET $endpoint 오류: $e');
      
      // 이미 Exception이면 그대로 전달, 아니면 새로운 Exception 생성
      if (e is Exception) {
        rethrow;
      } else {
        // 네트워크 오류 등 다른 오류 처리
        String errorMessage = e.toString();
        if (errorMessage.contains('SocketException') || 
            errorMessage.contains('Failed host lookup')) {
          throw Exception('네트워크 오류: 서버에 연결할 수 없습니다. 서버 URL과 인터넷 연결을 확인하세요.');
        } else if (errorMessage.contains('timeout')) {
          throw Exception('요청 타임아웃: 서버가 응답하지 않습니다. 서버가 실행 중인지 확인하세요.');
        } else {
          throw Exception('요청 실패: $errorMessage');
        }
      }
    }
  }

  /// 저장된 데이터베이스 연결 정보를 읽어와서 헤더로 변환
  Future<Map<String, String>> _getDatabaseHeaders() async {
    try {
      final isMacOS = defaultTargetPlatform == TargetPlatform.macOS;
      
      // macOS 개발 환경: 모든 데이터를 SharedPreferences에서 읽기
      // 다른 플랫폼: 하이브리드 방식 (일반 데이터는 SharedPreferences, 비밀번호는 SecureStorage)
      final databaseName = await SecureStorageHelper.read('database_name') ?? '';
      final username = await SecureStorageHelper.read('username') ?? '';
      final password = isMacOS
          ? await SecureStorageHelper.read('password') ?? ''  // macOS: SharedPreferences
          : await SecureStorageHelper.readSecure('password') ?? '';  // 다른 플랫폼: SecureStorage

      // 헤더가 비어있으면 경고 출력
      if (databaseName.isEmpty || username.isEmpty || password.isEmpty) {
        print('⚠️ 저장된 데이터베이스 연결 정보가 없거나 불완전합니다.');
        print('   → 데이터베이스에 다시 연결해주세요.');
        throw Exception('Invalid or missing database headers: database_name, username, 또는 password가 저장되지 않았습니다. 데이터베이스에 다시 연결해주세요.');
      }

      final headers = {
        'Content-Type': 'application/json',
        'x-db-name': databaseName,
        'x-db-user': username,
        'x-db-password': password,
        'x-db-ssl': 'false',
      };
      
      
      return headers;
    } catch (e) {
      print('❌ 데이터베이스 헤더 읽기 오류: $e');
      // 저장된 정보가 없거나 오류 발생 시 예외를 다시 던짐
      throw Exception('Invalid or missing database headers: ${e.toString()}');
    }
  }

  Future<bool> connectToDatabase(DatabaseConnectionRequest request, {bool disconnectExisting = false}) async {
    // 새로운 연결 전에 기존 연결 끊기 (기본값을 false로 변경하여 disconnect 요청을 기본적으로 보내지 않음)
    if (disconnectExisting) {
      // 기존 연결 정보 확인
      final existingHeaders = await _getDatabaseHeaders();
      final existingDbName = existingHeaders['x-db-name'] ?? '';
      final existingDbUser = existingHeaders['x-db-user'] ?? '';
      
      // 기존 연결이 있고, 새로운 연결과 다른 경우에만 끊기
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

    final url = '$serverUrl/api/health';
    final requestBody = jsonEncode(request.toJson());
    
    // 디버깅을 위한 로그 출력
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

      // 응답 정보 로그 출력
      print('=== 응답 정보 ===');
      print('Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ 연결 성공');
        // 연결 성공 시 데이터베이스 정보를 저장 (재시도 로직 포함)
        try {
          print('💾 데이터베이스 정보 저장 시도:');
          print('   database_name: ${request.databaseName}');
          print('   username: ${request.username}');
          print('   password: *** (길이: ${request.password.length})');
          
          // macOS 특화 저장 분석 시작
          final isMacOS = defaultTargetPlatform == TargetPlatform.macOS;
          
          // macOS 개발 환경에서는 모든 데이터를 SharedPreferences에 저장 (Keychain 접근 문제 회피)
          if (isMacOS) {
            print('🍎 macOS 개발 환경: 모든 데이터를 SharedPreferences에 저장');
            print('💾 저장 방식:');
            print('   - database_name, username, password → SharedPreferences (개발용)');
            print('   ⚠️  주의: 프로덕션에서는 SecureStorage 사용 권장');
          } else {
            // 다른 플랫폼: 하이브리드 저장 방식
            print('💾 하이브리드 저장 방식 사용:');
            print('   - database_name, username → SharedPreferences (안정적)');
            print('   - password → SecureStorage (보안)');
          }
          
          // 1단계: database_name 저장
          print('📝 [1/3] database_name 저장 시도...');
          final dbNameSaved = await SecureStorageHelper.save('database_name', request.databaseName);
          if (!dbNameSaved) {
            print('❌ [1/3] database_name 저장 실패!');
            if (isMacOS) {
              print('   🔍 macOS 분석: SharedPreferences 저장 실패');
              print('   💡 가능한 원인:');
              print('      - 파일 권한 문제');
              print('      - 디스크 공간 부족');
              print('      - Preferences 디렉토리 접근 불가');
            }
            throw Exception('database_name 저장 실패');
          }
          print('✅ [1/3] database_name 저장 성공');
          
          // 2단계: username 저장
          print('📝 [2/3] username 저장 시도...');
          final usernameSaved = await SecureStorageHelper.save('username', request.username);
          if (!usernameSaved) {
            print('❌ [2/3] username 저장 실패!');
            if (isMacOS) {
              print('   🔍 macOS 분석: SharedPreferences 저장 실패');
              print('   💡 가능한 원인:');
              print('      - 파일 권한 문제');
              print('      - 디스크 공간 부족');
              print('      - Preferences 디렉토리 접근 불가');
            }
            throw Exception('username 저장 실패');
          }
          print('✅ [2/3] username 저장 성공');
          
          // 3단계: password 저장
          print('📝 [3/3] password 저장 시도...');
          final passwordSaved = isMacOS 
              ? await SecureStorageHelper.save('password', request.password)  // macOS: SharedPreferences
              : await SecureStorageHelper.saveSecure('password', request.password);  // 다른 플랫폼: SecureStorage
          
          if (!passwordSaved) {
            print('❌ [3/3] password 저장 실패!');
            if (isMacOS) {
              print('   🔍 macOS 분석: SharedPreferences 저장 실패');
              print('   💡 가능한 원인:');
              print('      - 파일 권한 문제');
              print('      - 디스크 공간 부족');
              print('      - Preferences 디렉토리 접근 불가');
            } else {
              print('   🔍 분석: Keychain 저장 실패');
              print('   💡 가능한 원인:');
              print('      - Keychain 접근 권한 없음');
              print('      - Keychain 잠금 상태');
              print('      - Keychain 동기화 문제');
            }
            throw Exception('password 저장 실패');
          }
          print('✅ [3/3] password 저장 성공');
          
          // 저장 확인 단계
          print('🔍 저장 확인 단계 시작...');
          
          // 4단계: database_name 확인
          print('📖 [확인 1/3] database_name 읽기...');
          final savedDbName = await SecureStorageHelper.read('database_name');
          if (savedDbName == null) {
            print('❌ [확인 1/3] database_name 읽기 실패: null 반환');
            throw Exception('database_name 저장 확인 실패: 읽을 수 없음');
          }
          if (savedDbName != request.databaseName) {
            print('❌ [확인 1/3] database_name 불일치!');
            print('   원본: "${request.databaseName}"');
            print('   저장된 값: "$savedDbName"');
            throw Exception('database_name 저장 확인 실패: 값 불일치');
          }
          print('✅ [확인 1/3] database_name 확인 완료: "$savedDbName"');
          
          // 5단계: username 확인
          print('📖 [확인 2/3] username 읽기...');
          final savedUsername = await SecureStorageHelper.read('username');
          if (savedUsername == null) {
            print('❌ [확인 2/3] username 읽기 실패: null 반환');
            throw Exception('username 저장 확인 실패: 읽을 수 없음');
          }
          if (savedUsername != request.username) {
            print('❌ [확인 2/3] username 불일치!');
            print('   원본: "${request.username}"');
            print('   저장된 값: "$savedUsername"');
            throw Exception('username 저장 확인 실패: 값 불일치');
          }
          print('✅ [확인 2/3] username 확인 완료: "$savedUsername"');
          
          // 6단계: password 확인 (가장 중요)
          print('📖 [확인 3/3] password 읽기...');
          final savedPassword = isMacOS
              ? await SecureStorageHelper.read('password')  // macOS: SharedPreferences
              : await SecureStorageHelper.readSecure('password');  // 다른 플랫폼: SecureStorage
          
          if (savedPassword == null) {
            print('❌ [확인 3/3] password 읽기 실패: null 반환');
            if (isMacOS) {
              print('   🔍 macOS 분석: SharedPreferences에서 읽기 실패');
              print('   💡 가능한 원인:');
              print('      - 저장은 성공했지만 읽기 실패');
              print('      - 파일 접근 권한 문제');
            } else {
              print('   🔍 분석: Keychain에서 읽기 실패');
              print('   💡 가능한 원인:');
              print('      - Keychain 접근 권한 없음');
              print('      - 저장은 성공했지만 읽기 실패');
              print('      - Keychain 동기화 지연');
            }
            throw Exception('password 저장 확인 실패: 읽을 수 없음');
          }
          if (savedPassword.isEmpty) {
            print('❌ [확인 3/3] password 비어있음!');
            throw Exception('password 저장 확인 실패: 빈 값');
          }
          if (savedPassword != request.password) {
            print('❌ [확인 3/3] password 불일치!');
            print('   원본 길이: ${request.password.length}');
            print('   저장된 길이: ${savedPassword.length}');
            if (isMacOS) {
              print('   🔍 macOS 분석: SharedPreferences 값 불일치');
              print('   💡 가능한 원인:');
              print('      - 저장 중 값 변경');
              print('      - 파일 접근 권한 문제');
            } else {
              print('   🔍 분석: Keychain 값 불일치');
              print('   💡 가능한 원인:');
              print('      - Keychain 동기화 지연');
              print('      - 저장 중 값 변경');
              print('      - Keychain 접근 권한 문제');
            }
            throw Exception('password 저장 확인 실패: 값 불일치');
          }
          print('✅ [확인 3/3] password 확인 완료: 길이 ${savedPassword.length}');
          
          print('✅ 데이터베이스 정보 저장 완료:');
          print('   저장된 database_name: "$savedDbName"');
          print('   저장된 username: "$savedUsername"');
          print('   저장된 password: *** (길이: ${savedPassword.length})');
          
          if (isMacOS) {
            print('🍎 macOS 저장 프로세스 완료!');
          }
        } catch (e) {
          print('❌ 데이터베이스 정보 저장 실패: $e');
          print('   오류 상세: ${e.toString()}');
          print('   스택 트레이스: ${StackTrace.current}');
          
          // macOS 특화 오류 분석
          if (defaultTargetPlatform == TargetPlatform.macOS) {
            print('');
            print('🔍 macOS 저장 실패 상세 분석:');
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            
            // 각 저장소 상태 확인
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
          
          // 저장 실패 시 연결도 실패로 처리
          throw Exception('연결은 성공했지만 정보 저장에 실패했습니다: ${e.toString()}');
        }
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

  /// 공통 POST 요청 메서드 (오류 처리 포함)
  Future<Map<String, dynamic>> _performPostRequest(
    String endpoint,
    Map<String, dynamic> body, {
    int timeoutSeconds = 10,
  }) async {
    try {
      // 데이터베이스 연결 정보를 헤더로 가져오기
      final headers = await _getDatabaseHeaders();
      
      print('=== POST $endpoint 요청 ===');
      print('URL: $serverUrl$endpoint');
      print('Headers: $headers');
      print('Timeout: ${timeoutSeconds}초');
      
      final response = await http.post(
        Uri.parse('$serverUrl$endpoint'),
        headers: headers,
        body: json.encode(body),
      ).timeout(
        Duration(seconds: timeoutSeconds),
        onTimeout: () {
          print('❌ 요청 타임아웃 (${timeoutSeconds}초 초과)');
          throw Exception('요청 타임아웃: 서버 응답이 ${timeoutSeconds}초를 초과했습니다. 서버가 실행 중인지 확인하세요.');
        },
      );

      print('=== 응답 정보 ===');
      print('Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final decoded = json.decode(response.body);
          if (decoded is Map) {
            return decoded as Map<String, dynamic>;
          } else if (decoded is List) {
            return {'data': decoded};
          } else {
            return {'result': decoded};
          }
        } catch (e) {
          print('❌ JSON 파싱 오류: $e');
          throw Exception('JSON 파싱 오류: 서버 응답을 파싱할 수 없습니다. 응답: ${response.body}');
        }
      } else {
        // HTTP 오류 상태 코드 처리
        String errorMessage = 'HTTP ${response.statusCode} 오류';
        try {
          final errorBody = json.decode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'].toString();
          } else if (errorBody is Map && errorBody.containsKey('error')) {
            errorMessage = errorBody['error'].toString();
          } else if (response.body.isNotEmpty) {
            errorMessage = response.body;
          }
        } catch (e) {
          // JSON 파싱 실패 시 원본 응답 사용
          if (response.body.isNotEmpty) {
            errorMessage = response.body;
          }
        }
        
        print('❌ HTTP 오류: $errorMessage');
        throw Exception('서버 오류 (${response.statusCode}): $errorMessage');
      }
    } catch (e) {
      print('❌ POST $endpoint 오류: $e');
      
      // 이미 Exception이면 그대로 전달, 아니면 새로운 Exception 생성
      if (e is Exception) {
        rethrow;
      } else {
        // 네트워크 오류 등 다른 오류 처리
        String errorMessage = e.toString();
        if (errorMessage.contains('SocketException') || 
            errorMessage.contains('Failed host lookup')) {
          throw Exception('네트워크 오류: 서버에 연결할 수 없습니다. 서버 URL과 인터넷 연결을 확인하세요.');
        } else if (errorMessage.contains('timeout')) {
          throw Exception('요청 타임아웃: 서버가 응답하지 않습니다. 서버가 실행 중인지 확인하세요.');
        } else {
          throw Exception('요청 실패: $errorMessage');
        }
      }
    }
  }

  /// resumen_del_dia 데이터 가져오기
  Future<Map<String, dynamic>> getResumenDelDia({
    DateTime? date,
    String? sucursal,
  }) async {
    final endpoint = '/api/resumen_del_dia';
    
    // 바디에 date와 sucursal 포함
    final body = <String, dynamic>{};
    
    if (date != null) {
      // 날짜를 YYYY-MM-DD 형식으로 변환
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      body['date'] = dateStr;
    }
    
    if (sucursal != null && sucursal.isNotEmpty) {
      body['sucursal'] = sucursal;
    }
    
    // 디버깅: API 호출 정보 출력
    print('  - 서버 URL: $serverUrl');
    print('  - 엔드포인트: $endpoint');
    print('  - 날짜: ${body['date'] ?? '없음'}');
    print('  - Sucursal: ${body['sucursal'] ?? '없음'}');
    print('  - 요청 바디: $body');
    
    // resumen_del_dia는 데이터가 많을 수 있으므로 더 긴 타임아웃 사용
    final result = await _performPostRequest(endpoint, body, timeoutSeconds: 30);
    
    
    return result;
  }

  /// 재고 보고서 가져오기 (페이지네이션 지원)
  /// 
  /// 응답 구조:
  /// - filters: 적용된 필터 정보
  /// - sucursal: 지점 번호 또는 'all'
  /// - bcolorview: valor1이 '1'인지 여부
  /// - valor1: Parametros에서 조회한 valor1 값
  /// - filtering_word: 검색어
  /// - sort_column: 정렬 컬럼
  /// - sort_ascending: 오름차순 여부
  /// - summary: 요약 정보
  /// - total_items: 반환된 데이터 개수
  /// - source_table: 사용된 소스 테이블 이름
  /// - data: 재고 데이터 배열 (최대 100개)
  ///   - bcolorview = false: codigo, descripcion, first_date, last_date, pre1~pre5, 
  ///     totaling, totalventa, todayingreso, todayventa, totalreservado, cntoffset, 
  ///     stockreal, porcentaje, sucursal, id_codigo1
  ///   - bcolorview = true: tcode, tdesc, first_date, last_date, pre1~pre5, 
  ///     totaling3, totalventa3, todaying3, todayvnt3, totalreservado3, cntoffset3, 
  ///     stockreal3, porcentaje, sucursal, ref_id_todocodigo
  /// - pagination: 페이지네이션 정보 (count, total, hasMore, nextMaxUtime)
  /// 
  /// 사용 예시:
  /// ```dart
  /// final response = await databaseService.getStocksReport();
  /// final stocksResponse = StocksResponse.fromMap(response);
  /// ```
  Future<Map<String, dynamic>> getStocksReport({
    String? filteringWord,
    Map<String, dynamic>? filters,
    String? maxUtime,
    String? sortColumn,
    bool? sortAscending,
  }) async {
    final endpoint = '/api/reporte/stocks';
    final queryParams = <String, String>{};
    
    // filtering word를 쿼리 파라미터에 추가
    if (filteringWord != null && filteringWord.isNotEmpty) {
      queryParams['filtering_word'] = filteringWord;
    }
    
    // filters를 쿼리 파라미터로 변환
    if (filters != null) {
      filters.forEach((key, value) {
        if (value != null) {
          queryParams[key] = value.toString();
        }
      });
    }
    
    // 페이지네이션 파라미터 추가
    if (maxUtime != null && maxUtime.isNotEmpty) {
      queryParams['max_utime'] = maxUtime;
    }
    
    // 정렬 파라미터 추가
    if (sortColumn != null && sortColumn.isNotEmpty) {
      queryParams['sort_column'] = sortColumn;
      queryParams['sort_ascending'] = (sortAscending ?? true) ? 'true' : 'false';
    }
    
    // 스톡 보고서 요청 헤더와 쿼리 파라미터 출력
    final headers = await _getDatabaseHeaders();
    print('\n');
    print('═══════════════════════════════════════════════════════════');
    print('═══════════════════════════════════════════════════════════');
    final uri = Uri.parse('$serverUrl$endpoint').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    print('🌐 URL: $uri');
    print('');
    print('📋 Headers:');
    headers.forEach((key, value) {
      final displayValue = key == 'x-db-password' ? '***' : value;
      print('   $key: $displayValue');
    });
    if (queryParams.isNotEmpty) {
      print('');
      print('🔍 Query Parameters:');
      queryParams.forEach((key, value) {
        print('   $key: $value');
      });
    }
    print('═══════════════════════════════════════════════════════════');
    print('\n');
    
    return await _performGetRequest(endpoint, queryParameters: queryParams.isNotEmpty ? queryParams : null);
  }

  /// 재고 보고서 가져오기 (StocksResponse 모델 반환)
  /// 
  /// getStocksReport()의 타입 안전 버전입니다.
  /// 응답을 StocksResponse 모델로 자동 파싱하여 반환합니다.
  Future<StocksResponse> getStocksReportTyped({
    String? filteringWord,
    Map<String, dynamic>? filters,
    String? maxUtime,
    String? sortColumn,
    bool? sortAscending,
  }) async {
    final response = await getStocksReport(
      filteringWord: filteringWord,
      filters: filters,
      maxUtime: maxUtime,
      sortColumn: sortColumn,
      sortAscending: sortAscending,
    );
    return StocksResponse.fromMap(response);
  }

  /// 아이템 보고서 가져오기
  Future<Map<String, dynamic>> getItemsReport({
    Map<String, dynamic>? filters,
  }) async {
    final endpoint = '/api/reporte/items';
    final queryParams = <String, String>{};
    
    if (filters != null) {
      filters.forEach((key, value) {
        if (value != null) {
          queryParams[key] = value.toString();
        }
      });
    }
    
    return await _performGetRequest(
      endpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  /// 고객 보고서 가져오기
  Future<Map<String, dynamic>> getClientesReport({
    Map<String, dynamic>? filters,
  }) async {
    final endpoint = '/api/reporte/clientes';
    final queryParams = <String, String>{};
    
    if (filters != null) {
      filters.forEach((key, value) {
        if (value != null) {
          queryParams[key] = value.toString();
        }
      });
    }
    
    return await _performGetRequest(
      endpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  /// 지출 보고서 가져오기
  Future<Map<String, dynamic>> getGastosReport({
    Map<String, dynamic>? filters,
  }) async {
    final endpoint = '/api/reporte/gastos';
    final queryParams = <String, String>{};
    
    if (filters != null) {
      filters.forEach((key, value) {
        if (value != null) {
          queryParams[key] = value.toString();
        }
      });
    }
    
    return await _performGetRequest(
      endpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  /// 판매 보고서 가져오기
  Future<Map<String, dynamic>> getVentasReport({
    Map<String, dynamic>? filters,
  }) async {
    final endpoint = '/api/reporte/ventas';
    final queryParams = <String, String>{};
    
    if (filters != null) {
      filters.forEach((key, value) {
        if (value != null) {
          queryParams[key] = value.toString();
        }
      });
    }
    
    return await _performGetRequest(
      endpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  /// 알림 보고서 가져오기
  Future<Map<String, dynamic>> getAlertasReport({
    Map<String, dynamic>? filters,
  }) async {
    final endpoint = '/api/reporte/alertas';
    final queryParams = <String, String>{};
    
    if (filters != null) {
      filters.forEach((key, value) {
        if (value != null) {
          queryParams[key] = value.toString();
        }
      });
    }
    
    return await _performGetRequest(
      endpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  /// Codigos 리스트 가져오기 (페이지네이션 지원)
  Future<Map<String, dynamic>> getCodigos({
    String? idCodigo,
    String? filteringWord,
    String? sortColumn,
    bool? sortAscending,
  }) async {
    final endpoint = '/api/codigos';
    final queryParams = <String, String>{};
    
    // id_codigo 파라미터 추가 (다음 페이지 요청용)
    if (idCodigo != null && idCodigo.isNotEmpty) {
      queryParams['id_codigo'] = idCodigo;
    }
    
    // filteringWord 파라미터 추가
    if (filteringWord != null && filteringWord.isNotEmpty) {
      queryParams['filtering_word'] = filteringWord;
      print('✅ filteringWord 추가됨: "$filteringWord"');
    } else {
      print('⚠️ filteringWord가 비어있거나 null입니다.');
    }
    
    // 정렬 파라미터 추가
    if (sortColumn != null && sortColumn.isNotEmpty) {
      queryParams['sort_column'] = sortColumn;
      queryParams['sort_ascending'] = (sortAscending ?? true) ? 'true' : 'false';
    }
    
    // 요청 URL 출력
    final uri = Uri.parse('$serverUrl$endpoint').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    print('🌐 Codigos 요청 URL: $uri');
    
    return await _performGetRequest(
      endpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  /// Codigos 전체 리스트 가져오기 (모든 페이지 자동 로드)
  Future<Map<String, dynamic>> getAllCodigos() async {
    final allData = <dynamic>[];
    String? nextMaxUtime;
    bool hasMore = true;
    int pageCount = 0;
    
    print('=== Codigos 전체 로드 시작 ===');
    
    while (hasMore) {
      pageCount++;
      print('📄 페이지 $pageCount 로드 중... ${nextMaxUtime != null ? "(id_codigo=$nextMaxUtime)" : "(첫 페이지)"}');
      
      final response = await getCodigos(idCodigo: nextMaxUtime);
      
      // 데이터 추가
      if (response.containsKey('data') && response['data'] is List) {
        final pageData = response['data'] as List;
        allData.addAll(pageData);
        print('✅ 페이지 $pageCount: ${pageData.length}개 항목 로드됨 (총 ${allData.length}개)');
      }
      
      // 페이지네이션 정보 확인
      // pagination.id_codigo가 있으면 다음 페이지가 있다고 판단
      if (response.containsKey('pagination') && response['pagination'] is Map) {
        final pagination = response['pagination'] as Map<String, dynamic>;
        // pagination.id_codigo가 있으면 다음 페이지가 있음
        if (pagination.containsKey('id_codigo') && pagination['id_codigo'] != null) {
          nextMaxUtime = pagination['id_codigo']?.toString();
          hasMore = true;
        } else {
          nextMaxUtime = null;
          hasMore = false;
          print('ℹ️ 마지막 페이지입니다.');
        }
      } else {
        // 페이지네이션 정보가 없으면 더 이상 요청하지 않음
        hasMore = false;
        nextMaxUtime = null;
        print('⚠️ 페이지네이션 정보가 없습니다. 로드 완료로 간주합니다.');
      }
    }
    
    print('🎉 Codigos 전체 로드 완료: 총 ${allData.length}개 항목, ${pageCount}페이지');
    
    return {
      'data': allData,
      'pagination': {
        'total': allData.length,
        'loadedPages': pageCount,
      },
    };
  }

  /// Todocodigos 리스트 가져오기 (페이지네이션 지원)
  /// 
  /// 응답 구조:
  /// - filters: 적용된 필터 정보
  /// - filtering_word: 검색어 (tcodigo 또는 tdesc에서 검색)
  /// - sort_column: 정렬 컬럼 (기본값: tcodigo)
  /// - sort_ascending: 오름차순 여부 (기본값: true)
  /// - data: Todocodigos 데이터 배열 (최대 100개)
  ///   각 항목: id_todocodigo, tcodigo, tdesc, tpre1~tpre5, torgpre, ttelacodigo, 
  ///   ttelakg, tinfo1~tinfo3, utime, borrado, fotonombre, pubip, ip, mac, bmobile,
  ///   ref_id_temporada, ref_id_tipo, ref_id_origen, ref_id_empresa, memo,
  ///   estatus_precios, tprecio_dolar, utime_modificado, id_todocodigo_centralizado,
  ///   b_mostrar_vcontrol, d_oferta_mode, id_serial, str_prefijo
  /// - pagination: 페이지네이션 정보 (count, total, hasMore, id_todocodigo)
  /// 
  /// 사용 예시:
  /// ```dart
  /// final response = await databaseService.getTodocodigos();
  /// final todocodigosResponse = TodocodigosResponse.fromMap(response);
  /// ```
  Future<Map<String, dynamic>> getTodocodigos({
    String? idTodocodigo,
    String? filteringWord,
    String? sortColumn,
    bool? sortAscending,
  }) async {
    final endpoint = '/api/todocodigos';
    final queryParams = <String, String>{};
    
    // id_todocodigo 파라미터 추가 (다음 페이지 요청용)
    if (idTodocodigo != null && idTodocodigo.isNotEmpty) {
      queryParams['id_todocodigo'] = idTodocodigo;
    }
    
    // filteringWord 파라미터 추가
    if (filteringWord != null && filteringWord.isNotEmpty) {
      queryParams['filtering_word'] = filteringWord;
      print('✅ filteringWord 추가됨: "$filteringWord"');
    }
    
    // 정렬 파라미터 추가
    if (sortColumn != null && sortColumn.isNotEmpty) {
      queryParams['sort_column'] = sortColumn;
      queryParams['sort_ascending'] = (sortAscending ?? true) ? 'true' : 'false';
    }
    
    // Todocodigos 요청 헤더와 쿼리 파라미터 출력
    final headers = await _getDatabaseHeaders();
    print('\n');
    print('═══════════════════════════════════════════════════════════');
    print('═══════════════════════════════════════════════════════════');
    final uri = Uri.parse('$serverUrl$endpoint').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    print('🌐 Todocodigos 요청 URL: $uri');
    print('');
    print('📋 Headers:');
    headers.forEach((key, value) {
      final displayValue = key == 'x-db-password' ? '***' : value;
      print('   $key: $displayValue');
    });
    if (queryParams.isNotEmpty) {
      print('');
      print('🔍 Query Parameters:');
      queryParams.forEach((key, value) {
        print('   $key: $value');
      });
    }
    print('═══════════════════════════════════════════════════════════');
    print('\n');
    
    return await _performGetRequest(
      endpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  /// Todocodigos 리스트 가져오기 (TodocodigosResponse 모델 반환)
  /// 
  /// getTodocodigos()의 타입 안전 버전입니다.
  /// 응답을 TodocodigosResponse 모델로 자동 파싱하여 반환합니다.
  Future<TodocodigosResponse> getTodocodigosTyped({
    String? idTodocodigo,
    String? filteringWord,
    String? sortColumn,
    bool? sortAscending,
  }) async {
    final response = await getTodocodigos(
      idTodocodigo: idTodocodigo,
      filteringWord: filteringWord,
      sortColumn: sortColumn,
      sortAscending: sortAscending,
    );
    return TodocodigosResponse.fromMap(response);
  }

  /// Codigo 업데이트하기
  /// id_codigo가 있으면 우선 사용, 없으면 codigo 사용
  Future<Map<String, dynamic>> updateCodigo({
    String? idCodigo,
    String? codigo,
    required Map<String, dynamic> updatedData,
  }) async {
    // id_codigo를 우선적으로 사용 (편집 시 매우 중요)
    final identifier = idCodigo ?? codigo;
    if (identifier == null || identifier.isEmpty) {
      throw Exception('id_codigo 또는 codigo가 필요합니다.');
    }
    
    // id_codigo가 있으면 그것을 사용, 없으면 codigo 사용
    final endpoint = idCodigo != null 
        ? '/api/codigos/id/$idCodigo'
        : '/api/codigos/$codigo';
    
    print('=== Codigo 업데이트 ===');
    print('id_codigo: $idCodigo');
    print('codigo: $codigo');
    print('endpoint: $endpoint');
    
    return await _performPutRequest(endpoint, updatedData);
  }

  /// 공통 PUT 요청 메서드 (오류 처리 포함)
  Future<Map<String, dynamic>> _performPutRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      // 데이터베이스 연결 정보를 헤더로 가져오기
      final headers = await _getDatabaseHeaders();
      
      print('');
      print('═══════════════════════════════════════════════════════════');
      print('🌐 HTTP PUT 요청 상세 정보');
      print('═══════════════════════════════════════════════════════════');
      print('📍 요청 URL:');
      print('   $serverUrl$endpoint');
      print('');
      print('📋 요청 헤더:');
      headers.forEach((key, value) {
        // 비밀번호는 마스킹 처리
        if (key.toLowerCase().contains('password') || key.toLowerCase().contains('auth')) {
          print('   $key: ${value.toString().substring(0, value.toString().length > 10 ? 10 : value.toString().length)}...');
        } else {
          print('   $key: $value');
        }
      });
      print('');
      print('📦 요청 Body (JSON):');
      try {
        final jsonBody = json.encode(body);
        print('   $jsonBody');
      } catch (e) {
        print('   ⚠️ JSON 변환 실패: $e');
        print('   $body');
      }
      print('═══════════════════════════════════════════════════════════');
      print('');
      
      final response = await http.put(
        Uri.parse('$serverUrl$endpoint'),
        headers: headers,
        body: json.encode(body),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('❌ 요청 타임아웃 (10초 초과)');
          throw Exception('요청 타임아웃: 서버 응답이 10초를 초과했습니다. 서버가 실행 중인지 확인하세요.');
        },
      );

      print('=== 응답 정보 ===');
      print('Status Code: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        try {
          if (response.body.isEmpty) {
            return {'success': true};
          }
          final decoded = json.decode(response.body);
          if (decoded is Map) {
            return decoded as Map<String, dynamic>;
          } else if (decoded is List) {
            return {'data': decoded};
          } else {
            return {'result': decoded};
          }
        } catch (e) {
          print('❌ JSON 파싱 오류: $e');
          throw Exception('JSON 파싱 오류: 서버 응답을 파싱할 수 없습니다. 응답: ${response.body}');
        }
      } else {
        // HTTP 오류 상태 코드 처리
        String errorMessage = 'HTTP ${response.statusCode} 오류';
        try {
          final errorBody = json.decode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'].toString();
          } else if (errorBody is Map && errorBody.containsKey('error')) {
            errorMessage = errorBody['error'].toString();
          } else if (response.body.isNotEmpty) {
            errorMessage = response.body;
          }
        } catch (e) {
          // JSON 파싱 실패 시 원본 응답 사용
          if (response.body.isNotEmpty) {
            errorMessage = response.body;
          }
        }
        
        print('❌ HTTP 오류: $errorMessage');
        throw Exception('서버 오류 (${response.statusCode}): $errorMessage');
      }
    } catch (e) {
      print('❌ PUT $endpoint 오류: $e');
      
      // 이미 Exception이면 그대로 전달, 아니면 새로운 Exception 생성
      if (e is Exception) {
        rethrow;
      } else {
        // 네트워크 오류 등 다른 오류 처리
        String errorMessage = e.toString();
        if (errorMessage.contains('SocketException') || 
            errorMessage.contains('Failed host lookup')) {
          throw Exception('네트워크 오류: 서버에 연결할 수 없습니다. 서버 URL과 인터넷 연결을 확인하세요.');
        } else if (errorMessage.contains('timeout')) {
          throw Exception('요청 타임아웃: 서버가 응답하지 않습니다. 서버가 실행 중인지 확인하세요.');
        } else {
          throw Exception('요청 실패: $errorMessage');
        }
      }
    }
  }
}

