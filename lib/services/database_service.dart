import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

      return {
        'Content-Type': 'application/json',
        'x-db-name': databaseName,
        'x-db-user': username,
        'x-db-password': password,
        'x-db-ssl': 'false',
      };
    } catch (e) {
      // 저장된 정보가 없거나 오류 발생 시 기본 헤더 반환
      return {
        'Content-Type': 'application/json',
        'x-db-name': '',
        'x-db-user': '',
        'x-db-password': '',
        'x-db-ssl': 'false',
      };
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
        const Duration(seconds: 60),
        onTimeout: () {
          print('❌ 연결 타임아웃 (60초 초과)');
          throw Exception('Connection timeout: 서버 응답이 60초를 초과했습니다. 서버 상태를 확인하거나 잠시 후 다시 시도해주세요.');
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
      print('Body: ${json.encode(body)}');
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
    
    // resumen_del_dia는 데이터가 많을 수 있으므로 더 긴 타임아웃 사용
    return await _performPostRequest(endpoint, body, timeoutSeconds: 30);
  }

  /// 재고 보고서 가져오기 (페이지네이션 지원)
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
    print('📊 스톡 보고서 GET 요청');
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
      if (response.containsKey('pagination') && response['pagination'] is Map) {
        final pagination = response['pagination'] as Map<String, dynamic>;
        hasMore = pagination['hasMore'] == true;
        nextMaxUtime = pagination['nextMaxUtime']?.toString();
        
        print('📊 페이지네이션 정보:');
        print('   - count: ${pagination['count']}');
        print('   - total: ${pagination['total']}');
        print('   - hasMore: $hasMore');
        print('   - nextMaxUtime: $nextMaxUtime');
      } else {
        // 페이지네이션 정보가 없으면 더 이상 요청하지 않음
        hasMore = false;
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

  /// Codigo 업데이트하기
  Future<Map<String, dynamic>> updateCodigo(
    String codigo,
    Map<String, dynamic> updatedData,
  ) async {
    final endpoint = '/api/codigos/$codigo';
    
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
      
      print('=== PUT $endpoint 요청 ===');
      print('URL: $serverUrl$endpoint');
      print('Headers: $headers');
      print('Body: ${json.encode(body)}');
      
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
      print('Response Body: ${response.body}');

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

