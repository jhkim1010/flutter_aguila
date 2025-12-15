import 'http_request_handler.dart';

/// 보고서 관련 API
class ReportsApi {
  final HttpRequestHandler _httpHandler;

  ReportsApi({required HttpRequestHandler httpHandler})
      : _httpHandler = httpHandler;

  /// resumen_del_dia 데이터 가져오기
  Future<Map<String, dynamic>> getResumenDelDia({
    DateTime? date,
    String? sucursal,
  }) async {
    final endpoint = '/api/resumen_del_dia';
    final body = <String, dynamic>{};
    
    if (date != null) {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      body['date'] = dateStr;
    }
    
    if (sucursal != null && sucursal.isNotEmpty) {
      body['sucursal'] = sucursal;
    }
    
    print('=== Reports API 요청 ===');
    print('  - 엔드포인트: $endpoint');
    if (body.containsKey('date')) {
      print('  - 날짜: ${body['date']}');
    }
    if (body.containsKey('sucursal')) {
      print('  - Sucursal: ${body['sucursal']}');
    }
    
    return await _httpHandler.performPostRequest(endpoint, body, timeoutSeconds: 30);
  }

  /// 아이템 보고서 가져오기
  Future<Map<String, dynamic>> getItemsReport({
    String? filteringWord,
    Map<String, dynamic>? filters,
  }) async {
    final endpoint = '/api/reporte/items';
    final queryParams = <String, String>{};
    
    if (filteringWord != null && filteringWord.isNotEmpty) {
      queryParams['filtering_word'] = filteringWord;
    }
    
    if (filters != null) {
      filters.forEach((key, value) {
        if (value != null) {
          queryParams[key] = value.toString();
        }
      });
    }
    
    return await _httpHandler.performGetRequest(
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
    
    return await _httpHandler.performGetRequest(
      endpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  /// 지출 보고서 가져오기
  Future<Map<String, dynamic>> getGastosReport({
    String? filteringWord,
    Map<String, dynamic>? filters,
  }) async {
    final endpoint = '/api/reporte/gastos';
    final queryParams = <String, String>{};
    
    if (filteringWord != null && filteringWord.isNotEmpty) {
      queryParams['filtering_word'] = filteringWord;
    }
    
    if (filters != null) {
      filters.forEach((key, value) {
        if (value != null) {
          queryParams[key] = value.toString();
        }
      });
    }
    
    return await _httpHandler.performGetRequest(
      endpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  /// 판매 보고서 가져오기
  Future<Map<String, dynamic>> getVentasReport({
    String? filteringWord,
    String? currentDate,
    String? unit, // 'vcode', 'day', 'month', 'year'
    Map<String, dynamic>? filters,
  }) async {
    final endpoint = '/api/reporte/ventas';
    final queryParams = <String, String>{};
    
    if (filteringWord != null && filteringWord.isNotEmpty) {
      queryParams['filtering_word'] = filteringWord;
    }
    
    // current_date 파라미터 추가 (필수)
    if (currentDate != null && currentDate.isNotEmpty) {
      queryParams['current_date'] = currentDate;
    }
    
    // unit 파라미터 추가
    if (unit != null && unit.isNotEmpty) {
      queryParams['unit'] = unit;
    }
    
    if (filters != null) {
      filters.forEach((key, value) {
        if (value != null) {
          queryParams[key] = value.toString();
        }
      });
    }
    
    // Ventas 요청: 필요한 헤더만 필터링
    try {
      final allHeaders = await _httpHandler.getDatabaseHeaders();
      
      // 필요한 헤더만 선택: x-db-user, x-db-password, x-db-name, Content-Type
      final ventasHeaders = <String, String>{
        'Content-Type': allHeaders['Content-Type'] ?? 'application/json',
        'x-db-user': allHeaders['x-db-user'] ?? '',
        'x-db-password': allHeaders['x-db-password'] ?? '',
        'x-db-name': allHeaders['x-db-name'] ?? '',
      };
      
      // 빈 값이 있는지 확인
      if (ventasHeaders['x-db-user']!.isEmpty || 
          ventasHeaders['x-db-password']!.isEmpty || 
          ventasHeaders['x-db-name']!.isEmpty) {
        throw Exception('필수 헤더 정보가 없습니다: x-db-user, x-db-password, x-db-name');
      }
      
      print('=== Ventas 요청 헤더 (필터링됨) ===');
      ventasHeaders.forEach((key, value) {
        // 비밀번호는 보안상 일부만 표시
        if (key == 'x-db-password') {
          if (value.length > 4) {
            final prefix = value.substring(0, 2);
            final suffix = value.substring(value.length - 2);
            final maskLength = value.length - 4;
            final masked = '*' * maskLength;
            print('  $key: $prefix$masked$suffix');
          } else {
            print('  $key: ****');
          }
        } else {
          print('  $key: $value');
        }
      });
      
      // Query Parameters 출력
      if (queryParams.isNotEmpty) {
        print('=== Ventas 요청 파라미터 ===');
        queryParams.forEach((key, value) {
          print('  $key: $value');
        });
      }
      
      // 필터링된 헤더로 직접 GET 요청 수행
      return await _httpHandler.performGetRequestWithHeaders(
        endpoint,
        headers: ventasHeaders,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
    } catch (e) {
      print('⚠️ 헤더 가져오기 실패: $e');
      rethrow;
    }
  }

  /// 알림 보고서 가져오기
  Future<Map<String, dynamic>> getAlertasReport({
    String? filteringWord,
    Map<String, dynamic>? filters,
  }) async {
    final endpoint = '/api/reporte/alertas';
    final queryParams = <String, String>{};
    
    if (filteringWord != null && filteringWord.isNotEmpty) {
      queryParams['filtering_word'] = filteringWord;
    }
    
    if (filters != null) {
      filters.forEach((key, value) {
        if (value != null) {
          queryParams[key] = value.toString();
        }
      });
    }
    
    return await _httpHandler.performGetRequest(
      endpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  /// 수입 보고서 가져오기
  Future<Map<String, dynamic>> getIngresosReport({
    String? filteringWord,
    Map<String, dynamic>? filters,
  }) async {
    final endpoint = '/api/reporte/ingresos';
    final queryParams = <String, String>{};
    
    if (filteringWord != null && filteringWord.isNotEmpty) {
      queryParams['filtering_word'] = filteringWord;
    }
    
    if (filters != null) {
      filters.forEach((key, value) {
        if (value != null) {
          queryParams[key] = value.toString();
        }
      });
    }
    
    return await _httpHandler.performGetRequest(
      endpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  /// vdetalle 데이터 가져오기 (vcode 상세 정보)
  Future<Map<String, dynamic>> getVdetalle({
    required int vcodeId,
    required int sucursal,
  }) async {
    final endpoint = '/api/vdetalle';
    final queryParams = <String, String>{
      'vcode_id': vcodeId.toString(),
      'sucursal': sucursal.toString(),
    };
    
    print('=== Vdetalle 요청 ===');
    print('  - 엔드포인트: $endpoint');
    print('  - vcode_id: $vcodeId');
    print('  - sucursal: $sucursal');
    
    return await _httpHandler.performGetRequest(
      endpoint,
      queryParameters: queryParams,
    );
  }
}
