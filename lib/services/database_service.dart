import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DatabaseConnectionRequest {
  final String databaseName;
  final String username;
  final String password;
  final int? port;

  DatabaseConnectionRequest({
    required this.databaseName,
    required this.username,
    required this.password,
    this.port,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'databaseName': databaseName,
      'username': username,
      'password': password,
    };
    
    // 포트 번호가 있을 때만 포함
    if (port != null) {
      json['port'] = port!;
    }
    
    return json;
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
  );

  DatabaseService({required this.serverUrl});

  /// 공통 GET 요청 메서드 (오류 처리 포함)
  Future<Map<String, dynamic>> _performGetRequest(String endpoint) async {
    try {
      // 데이터베이스 연결 정보를 헤더로 가져오기
      final headers = await _getDatabaseHeaders();
      
      print('=== GET $endpoint 요청 ===');
      print('URL: $serverUrl$endpoint');
      print('Headers: $headers');
      
      final response = await http.get(
        Uri.parse('$serverUrl$endpoint'),
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
      print('Response Body: ${response.body}');

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
      final databaseName = await _storage.read(key: 'database_name') ?? '';
      final username = await _storage.read(key: 'username') ?? '';
      final password = await _storage.read(key: 'password') ?? '';
      // 포트는 항상 5432로 고정
      const port = '5432';
      
      // serverUrl에서 host 추출 (예: http://localhost:3030 -> localhost)
      String host = 'localhost';
      try {
        final uri = Uri.parse(serverUrl);
        host = uri.host.isNotEmpty ? uri.host : 'localhost';
      } catch (e) {
        // URL 파싱 실패 시 기본값 사용
        host = 'localhost';
      }

      return {
        'Content-Type': 'application/json',
        'x-db-host': host,
        'x-db-port': port,
        'x-db-name': databaseName,
        'x-db-user': username,
        'x-db-password': password,
        'x-db-ssl': 'false',
      };
    } catch (e) {
      // 저장된 정보가 없거나 오류 발생 시 기본 헤더 반환
      return {
        'Content-Type': 'application/json',
        'x-db-host': 'localhost',
        'x-db-port': '5432',
        'x-db-name': '',
        'x-db-user': '',
        'x-db-password': '',
        'x-db-ssl': 'false',
      };
    }
  }

  Future<bool> connectToDatabase(DatabaseConnectionRequest request) async {
    final url = '$serverUrl/api/health';
    final requestBody = jsonEncode(request.toJson());
    
    // 디버깅을 위한 로그 출력
    print('=== 연결 시도 ===');
    print('URL: $url');
    print('Request Body: $requestBody');
    print('Headers: Content-Type: application/json');
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('❌ 연결 타임아웃 (10초 초과)');
          throw Exception('Connection timeout: 서버 응답이 10초를 초과했습니다');
        },
      );

      // 응답 정보 로그 출력
      print('=== 응답 정보 ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('Response Headers: ${response.headers}');

      if (response.statusCode == 200) {
        print('✅ 연결 성공');
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

  /// resumen_del_dia 데이터 가져오기
  Future<Map<String, dynamic>> getResumenDelDia() async {
    return await _performGetRequest('/api/resumen_del_dia');
  }
}

