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
    // HTTP 상태 코드에 따른 기본 메시지
    String errorMessage = _getDefaultErrorMessage(response.statusCode);
    
    try {
      // JSON 응답인지 확인
      final errorBody = json.decode(response.body);
      if (errorBody is Map && errorBody.containsKey('message')) {
        errorMessage = errorBody['message'].toString();
      } else if (errorBody is Map && errorBody.containsKey('error')) {
        errorMessage = errorBody['error'].toString();
      }
    } catch (e) {
      // JSON 파싱 실패 시 HTML 또는 일반 텍스트 응답 처리
      if (response.body.isNotEmpty) {
        final body = response.body.trim();
        
        // HTML 응답인지 확인
        if (body.toLowerCase().contains('<html>') || 
            body.toLowerCase().contains('<!doctype')) {
          errorMessage = _extractMessageFromHtml(body, response.statusCode);
        } else {
          // 일반 텍스트 응답
          errorMessage = body;
        }
      }
    }
    
    return errorMessage;
  }

  /// HTTP 상태 코드에 따른 기본 에러 메시지 반환
  String _getDefaultErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return '잘못된 요청입니다. 요청 형식을 확인해주세요.';
      case 401:
        return '인증이 필요합니다. 로그인 정보를 확인해주세요.';
      case 403:
        return '접근 권한이 없습니다.';
      case 404:
        return '요청한 리소스를 찾을 수 없습니다.';
      case 500:
        return '서버 내부 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
      case 502:
        return '게이트웨이 오류: 백엔드 서버에 연결할 수 없습니다. 서버 관리자에게 문의하거나 잠시 후 다시 시도해주세요.';
      case 503:
        return '서비스를 일시적으로 사용할 수 없습니다. 잠시 후 다시 시도해주세요.';
      case 504:
        return '게이트웨이 타임아웃: 서버 응답 시간이 초과되었습니다.';
      default:
        return 'HTTP $statusCode 오류가 발생했습니다.';
    }
  }

  /// HTML 응답에서 메시지 추출
  String _extractMessageFromHtml(String htmlBody, int statusCode) {
    // 502 Bad Gateway HTML 응답 처리
    if (statusCode == 502) {
      if (htmlBody.toLowerCase().contains('502 bad gateway') ||
          htmlBody.toLowerCase().contains('bad gateway')) {
        return '게이트웨이 오류 (502): 백엔드 서버에 연결할 수 없습니다. 서버가 실행 중인지 확인하거나 서버 관리자에게 문의해주세요.';
      }
    }
    
    // HTML 태그 제거 시도
    String cleaned = htmlBody
        .replaceAll(RegExp(r'<[^>]*>', multiLine: true), '')
        .replaceAll(RegExp(r'\s+', multiLine: true), ' ')
        .trim();
    
    // 의미 있는 텍스트가 있으면 사용, 없으면 기본 메시지
    if (cleaned.length > 10 && cleaned.length < 500) {
      return cleaned;
    }
    
    return _getDefaultErrorMessage(statusCode);
  }

  /// 에러 처리
  Map<String, dynamic> _handleError(dynamic e) {
    String errorMessage = e.toString();
    
    // HTML 응답이 포함되어 있는지 확인하고 정제
    if (errorMessage.toLowerCase().contains('<html>') || 
        errorMessage.toLowerCase().contains('<!doctype')) {
      errorMessage = _cleanErrorMessage(errorMessage);
    }
    
    // HTTP 상태 코드 추출 (502, 503 등)
    int? statusCode = _extractStatusCode(errorMessage);
    
    if (errorMessage.contains('SocketException') || 
        errorMessage.contains('Failed host lookup')) {
      throw Exception('네트워크 오류: 서버에 연결할 수 없습니다. 서버 URL과 인터넷 연결을 확인하세요.');
    } else if (errorMessage.contains('timeout')) {
      throw Exception('요청 타임아웃: 서버가 응답하지 않습니다. 서버가 실행 중인지 확인하세요.');
    } else if (errorMessage.contains('CERTIFICATE_VERIFY_FAILED') ||
               errorMessage.contains('HandshakeException') ||
               errorMessage.contains('self signed certificate')) {
      throw Exception('SSL 인증서 오류: 자체 서명 인증서가 감지되었습니다. SSL 클라이언트 설정을 확인하세요.');
    } else if (statusCode != null) {
      // HTTP 상태 코드가 있으면 해당하는 메시지 사용
      throw Exception(_getDefaultErrorMessage(statusCode));
    } else {
      // HTML 태그와 불필요한 정보 제거
      String cleanedMessage = _cleanErrorMessage(errorMessage);
      throw Exception(cleanedMessage);
    }
  }

  /// 에러 메시지에서 HTTP 상태 코드 추출
  int? _extractStatusCode(String errorMessage) {
    // "서버 오류 (502):" 또는 "HTTP 502" 패턴 찾기
    final statusCodeMatch = RegExp(r'(?:서버 오류|HTTP|오류)\s*\(?(\d{3})\)?').firstMatch(errorMessage);
    if (statusCodeMatch != null && statusCodeMatch.group(1) != null) {
      return int.tryParse(statusCodeMatch.group(1)!);
    }
    
    // "502 Bad Gateway" 패턴 찾기
    final badGatewayMatch = RegExp(r'(\d{3})\s+Bad Gateway').firstMatch(errorMessage);
    if (badGatewayMatch != null && badGatewayMatch.group(1) != null) {
      return int.tryParse(badGatewayMatch.group(1)!);
    }
    
    return null;
  }

  /// 에러 메시지 정제 (HTML 태그 제거 및 불필요한 정보 제거)
  String _cleanErrorMessage(String errorMessage) {
    // "Exception: " 제거
    String cleaned = errorMessage.replaceAll(RegExp(r'Exception:\s*'), '');
    
    // "요청 실패: " 제거 (중복 방지)
    cleaned = cleaned.replaceAll(RegExp(r'요청 실패:\s*'), '');
    
    // "서버 오류 (502): " 같은 패턴에서 상태 코드만 남기고 메시지 정제
    cleaned = cleaned.replaceAll(RegExp(r'서버 오류\s*\(\d{3}\):\s*'), '');
    
    // HTML 태그 제거
    if (cleaned.toLowerCase().contains('<html>') || 
        cleaned.toLowerCase().contains('<!doctype')) {
      cleaned = cleaned
          .replaceAll(RegExp(r'<[^>]*>', multiLine: true), '')
          .replaceAll(RegExp(r'\s+', multiLine: true), ' ')
          .trim();
    }
    
    // 502 Bad Gateway 감지
    if (cleaned.toLowerCase().contains('502') && 
        cleaned.toLowerCase().contains('bad gateway')) {
      return '게이트웨이 오류 (502): 백엔드 서버에 연결할 수 없습니다. 서버가 실행 중인지 확인하거나 서버 관리자에게 문의해주세요.';
    }
    
    // 의미 있는 메시지만 남기기 (너무 길면 잘라내기)
    if (cleaned.length > 200) {
      cleaned = cleaned.substring(0, 200) + '...';
    }
    
    return cleaned.trim();
  }
}
