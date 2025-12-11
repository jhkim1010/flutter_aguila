import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import '../secure_storage_helper.dart';
import '../../utils/ssl_client_helper.dart';

/// 공통 HTTP 요청 핸들러
class HttpRequestHandler {
  final String serverUrl;
  late final http.Client _httpClient;

  HttpRequestHandler({required this.serverUrl}) {
    // 자체 서명 인증서를 허용하는 커스텀 클라이언트 사용
    _httpClient = SslClientHelper.createUnsafeClient();
  }

  /// 리소스 정리
  void dispose() {
    _httpClient.close();
  }

  /// 저장된 데이터베이스 연결 정보를 읽어와서 헤더로 변환
  Future<Map<String, String>> getDatabaseHeaders() async {
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
      throw Exception('Invalid or missing database headers: ${e.toString()}');
    }
  }

  /// 공통 GET 요청 메서드 (오류 처리 포함)
  Future<Map<String, dynamic>> performGetRequest(
    String endpoint, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      // 데이터베이스 연결 정보를 헤더로 가져오기
      final headers = await getDatabaseHeaders();
      return await performGetRequestWithHeaders(
        endpoint,
        headers: headers,
        queryParameters: queryParameters,
      );
    } catch (e) {
      print('❌ GET $endpoint 오류: $e');
      return _handleError(e);
    }
  }

  /// 헤더를 직접 지정하는 GET 요청 메서드
  Future<Map<String, dynamic>> performGetRequestWithHeaders(
    String endpoint, {
    required Map<String, String> headers,
    Map<String, String>? queryParameters,
  }) async {
    try {
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
      
      final response = await _httpClient.get(
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
      
      if (response.statusCode == 200) {
        try {
          final decoded = json.decode(response.body);
          int itemCount = 0;
          if (decoded is Map) {
            if (decoded.containsKey('data') && decoded['data'] is List) {
              itemCount = (decoded['data'] as List).length;
            } else if (decoded.containsKey('summary') && decoded['summary'] is Map) {
              itemCount = decoded['summary']['total_items'] ?? 0;
            } else {
              itemCount = decoded.length;
            }
            print('✅ 응답 성공: ${itemCount}개 항목');
            return decoded as Map<String, dynamic>;
          } else if (decoded is List) {
            itemCount = decoded.length;
            print('✅ 응답 성공: ${itemCount}개 항목');
            return {'data': decoded};
          } else {
            print('✅ 응답 성공');
            return {'result': decoded};
          }
        } catch (e) {
          print('❌ JSON 파싱 오류: $e');
          throw Exception('JSON 파싱 오류: 서버 응답을 파싱할 수 없습니다.');
        }
      } else {
        String errorMessage = _extractErrorMessage(response);
        print('❌ HTTP 오류: $errorMessage');
        throw Exception('서버 오류 (${response.statusCode}): $errorMessage');
      }
    } catch (e) {
      print('❌ GET $endpoint 오류: $e');
      return _handleError(e);
    }
  }

  /// 공통 POST 요청 메서드 (오류 처리 포함)
  Future<Map<String, dynamic>> performPostRequest(
    String endpoint,
    Map<String, dynamic> body, {
    int timeoutSeconds = 10,
  }) async {
    try {
      final headers = await getDatabaseHeaders();
      
      print('=== POST $endpoint 요청 ===');
      print('URL: $serverUrl$endpoint');
      print('Headers: $headers');
      print('Timeout: ${timeoutSeconds}초');
      
      final response = await _httpClient.post(
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
          int itemCount = 0;
          if (decoded is Map) {
            if (decoded.containsKey('data') && decoded['data'] is List) {
              itemCount = (decoded['data'] as List).length;
            } else if (decoded.containsKey('summary') && decoded['summary'] is Map) {
              itemCount = decoded['summary']['total_items'] ?? 0;
            } else {
              itemCount = decoded.length;
            }
            print('✅ 응답 성공: ${itemCount}개 항목');
            return decoded as Map<String, dynamic>;
          } else if (decoded is List) {
            itemCount = decoded.length;
            print('✅ 응답 성공: ${itemCount}개 항목');
            return {'data': decoded};
          } else {
            print('✅ 응답 성공');
            return {'result': decoded};
          }
        } catch (e) {
          print('❌ JSON 파싱 오류: $e');
          throw Exception('JSON 파싱 오류: 서버 응답을 파싱할 수 없습니다.');
        }
      } else {
        String errorMessage = _extractErrorMessage(response);
        print('❌ HTTP 오류: $errorMessage');
        throw Exception('서버 오류 (${response.statusCode}): $errorMessage');
      }
    } catch (e) {
      print('❌ POST $endpoint 오류: $e');
      return _handleError(e);
    }
  }

  /// 공통 PUT 요청 메서드 (오류 처리 포함)
  Future<Map<String, dynamic>> performPutRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final headers = await getDatabaseHeaders();
      
      print('=== PUT $endpoint 요청 ===');
      print('URL: $serverUrl$endpoint');
      
      final response = await _httpClient.put(
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
            print('✅ 응답 성공 (빈 응답)');
            return {'success': true};
          }
          final decoded = json.decode(response.body);
          int itemCount = 0;
          if (decoded is Map) {
            if (decoded.containsKey('data') && decoded['data'] is List) {
              itemCount = (decoded['data'] as List).length;
            } else {
              itemCount = decoded.length;
            }
            print('✅ 응답 성공: ${itemCount}개 항목');
            return decoded as Map<String, dynamic>;
          } else if (decoded is List) {
            itemCount = decoded.length;
            print('✅ 응답 성공: ${itemCount}개 항목');
            return {'data': decoded};
          } else {
            print('✅ 응답 성공');
            return {'result': decoded};
          }
        } catch (e) {
          print('❌ JSON 파싱 오류: $e');
          throw Exception('JSON 파싱 오류: 서버 응답을 파싱할 수 없습니다.');
        }
      } else {
        String errorMessage = _extractErrorMessage(response);
        print('❌ HTTP 오류: $errorMessage');
        throw Exception('서버 오류 (${response.statusCode}): $errorMessage');
      }
    } catch (e) {
      print('❌ PUT $endpoint 오류: $e');
      return _handleError(e);
    }
  }

  /// 에러 메시지 추출
  String _extractErrorMessage(http.Response response) {
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
      if (response.body.isNotEmpty) {
        errorMessage = response.body;
      }
    }
    return errorMessage;
  }

  /// 에러 처리
  Map<String, dynamic> _handleError(dynamic e) {
    String errorMessage = e.toString();
    if (errorMessage.contains('SocketException') || 
        errorMessage.contains('Failed host lookup')) {
      throw Exception('네트워크 오류: 서버에 연결할 수 없습니다. 서버 URL과 인터넷 연결을 확인하세요.');
    } else if (errorMessage.contains('timeout')) {
      throw Exception('요청 타임아웃: 서버가 응답하지 않습니다. 서버가 실행 중인지 확인하세요.');
    } else if (errorMessage.contains('CERTIFICATE_VERIFY_FAILED') ||
               errorMessage.contains('HandshakeException') ||
               errorMessage.contains('self signed certificate')) {
      throw Exception('SSL 인증서 오류: 자체 서명 인증서가 감지되었습니다. SSL 클라이언트 설정을 확인하세요.');
    } else {
      throw Exception('요청 실패: $errorMessage');
    }
  }
}
