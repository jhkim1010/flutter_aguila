import 'dart:convert';
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
    print('  - 요청 방식: POST (다른 보고서는 GET 사용)');
    print('  - 타임아웃: 60초 (다른 보고서는 10초)');
    if (body.containsKey('date')) {
      print('  - 날짜: ${body['date']}');
    }
    if (body.containsKey('sucursal')) {
      print('  - Sucursal: ${body['sucursal']}');
    }
    
    // resumen_del_dia는 복잡한 처리가 필요하므로 타임아웃을 60초로 증가
    // 서버에서 데이터베이스 함수 호출 및 외래키 제약 조건 처리에 시간이 걸릴 수 있음
    return await _httpHandler.performPostRequest(endpoint, body, timeoutSeconds: 60);
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
    int? limit,
    int? offset,
  }) async {
    final endpoint = '/api/reporte/clientes';
    final queryParams = <String, String>{};
    
    // 페이지네이션 파라미터 추가
    if (limit != null) {
      queryParams['limit'] = limit.toString();
    }
    if (offset != null) {
      queryParams['offset'] = offset.toString();
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

  /// 지출 보고서 가져오기
  Future<Map<String, dynamic>> getGastosReport({
    String? filteringWord,
    String? rubroCode,
    Map<String, dynamic>? filters,
  }) async {
    final endpoint = '/api/gastos';
    final queryParams = <String, String>{};
    
    // filteringWord 파라미터 추가
    if (filteringWord != null && filteringWord.isNotEmpty) {
      queryParams['filtering_word'] = filteringWord;
    }
    
    // rubroCode 파라미터 추가
    if (rubroCode != null && rubroCode.isNotEmpty) {
      queryParams['rubro'] = rubroCode;
    }
    
    // filters에서 fecha_inicio와 fecha_fin 추출하여 쿼리 파라미터로 추가
    if (filters != null) {
      if (filters.containsKey('fecha_inicio')) {
        queryParams['fecha_inicio'] = filters['fecha_inicio'].toString();
      }
      if (filters.containsKey('fecha_fin')) {
        queryParams['fecha_fin'] = filters['fecha_fin'].toString();
      }
      
      // 다른 필터들도 추가
      filters.forEach((key, value) {
        if (value != null && key != 'fecha_inicio' && key != 'fecha_fin') {
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
      
      // 최종 요청 URL 구성
      final uri = Uri.parse('${_httpHandler.serverUrl}$endpoint');
      final uriWithQuery = queryParams.isNotEmpty
          ? uri.replace(queryParameters: queryParams)
          : uri;
      
      print('\n═══════════════════════════════════════════════════════════');
      print('═══════════════════════════════════════════════════════════');
      print('=== Ventas 보고서 요청 (descontado 포함) ===');
      print('═══════════════════════════════════════════════════════════');
      print('📡 요청 메서드: GET');
      print('🔗 최종 URL: $uriWithQuery');
      print('\n📋 요청 헤더:');
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
      
      // Query Parameters 출력 (체크박스 파라미터 강조)
      if (queryParams.isNotEmpty) {
        print('\n📝 Query Parameters (URL에 포함됨):');
        queryParams.forEach((key, value) {
          // 체크박스 파라미터 강조 표시
          if (key == 'descontado' || key == 'reservado' || key == 'credito') {
            print('  ✅ $key: $value ⬅️ [체크박스 상태]');
          } else {
            print('  $key: $value');
          }
        });
      }
      
      print('\n💡 참고: GET 요청이므로 Request Body는 없습니다.');
      print('   모든 파라미터는 URL의 Query String으로 전송됩니다.');
      print('═══════════════════════════════════════════════════════════');
      print('═══════════════════════════════════════════════════════════\n');
      
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

  /// FVentas 보고서 가져오기
  /// GET /api/fventas - 목록 조회
  /// 날짜 필터링: fecha, fecha_inicio, fecha_fin
  /// 검색: filtering_word (clientenombre, dni, numfactura, tipofactura에서 검색)
  /// 필터링: sucursal
  /// 페이지네이션: last_id_fventa (id_fventa 기준)
  Future<Map<String, dynamic>> getFVentasReport({
    String? filteringWord,
    String? currentDate,
    String? unit, // 'vcode', 'day', 'month', 'year'
    Map<String, dynamic>? filters,
    String? lastIdFventa, // 페이지네이션용
  }) async {
    final endpoint = '/api/fventas';
    final queryParams = <String, String>{};
    
    // filtering_word 파라미터 추가 (clientenombre, dni, numfactura, tipofactura에서 검색)
    if (filteringWord != null && filteringWord.isNotEmpty) {
      queryParams['filtering_word'] = filteringWord;
    }
    
    // 날짜 필터링 파라미터
    if (filters != null) {
      // fecha (단일 날짜)
      if (filters.containsKey('fecha')) {
        queryParams['fecha'] = filters['fecha'].toString();
      }
      
      // fecha_inicio와 fecha_fin (날짜 범위)
      if (filters.containsKey('fecha_inicio')) {
        queryParams['fecha_inicio'] = filters['fecha_inicio'].toString();
      }
      if (filters.containsKey('fecha_fin')) {
        queryParams['fecha_fin'] = filters['fecha_fin'].toString();
      }
      
      // sucursal 필터링
      if (filters.containsKey('sucursal')) {
        queryParams['sucursal'] = filters['sucursal'].toString();
      }
      
      // 다른 필터들도 추가 (fecha, fecha_inicio, fecha_fin, sucursal 제외)
      filters.forEach((key, value) {
        if (value != null && 
            key != 'fecha' && 
            key != 'fecha_inicio' && 
            key != 'fecha_fin' && 
            key != 'sucursal') {
          queryParams[key] = value.toString();
        }
      });
    }
    
    // current_date 파라미터 추가 (기존 호환성을 위해)
    if (currentDate != null && currentDate.isNotEmpty) {
      // fecha로 변환 (filters에 fecha가 없을 때만)
      if (filters == null || !filters.containsKey('fecha')) {
        queryParams['fecha'] = currentDate;
      }
    }
    
    // unit 파라미터 추가 (기존 호환성을 위해)
    if (unit != null && unit.isNotEmpty) {
      queryParams['unit'] = unit;
    }
    
    // 페이지네이션: last_id_fventa
    if (lastIdFventa != null && lastIdFventa.isNotEmpty) {
      queryParams['last_id_fventa'] = lastIdFventa;
    }
    
    // 디버깅: fventas 요청 파라미터 로깅
    print('📋 FVentas 요청 파라미터:');
    print('  - filteringWord: $filteringWord');
    print('  - currentDate: $currentDate');
    print('  - unit: $unit');
    print('  - filters: $filters');
    print('  - queryParams: $queryParams');
    if (filters != null) {
      print('  - filters[fecha_inicio]: ${filters['fecha_inicio']}');
      print('  - filters[fecha_fin]: ${filters['fecha_fin']}');
    }
    
    // FVentas 요청: 필요한 헤더만 필터링
    try {
      final allHeaders = await _httpHandler.getDatabaseHeaders();
      
      // 필요한 헤더만 선택: x-db-user, x-db-password, x-db-name, Content-Type
      final fventasHeaders = <String, String>{
        'Content-Type': allHeaders['Content-Type'] ?? 'application/json',
        'x-db-user': allHeaders['x-db-user'] ?? '',
        'x-db-password': allHeaders['x-db-password'] ?? '',
        'x-db-name': allHeaders['x-db-name'] ?? '',
      };
      
      // 빈 값이 있는지 확인
      if (fventasHeaders['x-db-user']!.isEmpty || 
          fventasHeaders['x-db-password']!.isEmpty || 
          fventasHeaders['x-db-name']!.isEmpty) {
        throw Exception('필수 헤더 정보가 없습니다: x-db-user, x-db-password, x-db-name');
      }
      
      // 디버깅: 헤더 정보 로깅 (비밀번호는 마스킹)
      print('📋 FVentas 요청 헤더:');
      fventasHeaders.forEach((key, value) {
        if (key.toLowerCase().contains('password')) {
          print('  - $key: ${'*' * (value.length > 0 ? value.length : 8)}');
        } else {
          print('  - $key: $value');
        }
      });
      
      // 최종 요청 URL 구성
      final uri = Uri.parse('${_httpHandler.serverUrl}$endpoint');
      final finalUri = queryParams.isNotEmpty
          ? uri.replace(queryParameters: queryParams)
          : uri;
      print('📋 FVentas 최종 요청 URL: $finalUri');
      
      // 필터링된 헤더로 직접 GET 요청 수행
      final response = await _httpHandler.performGetRequestWithHeaders(
        endpoint,
        headers: fventasHeaders,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      
      return response;
    } catch (e) {
      print('⚠️ 헤더 가져오기 실패: $e');
      rethrow;
    }
  }
  
  /// FVentas 특정 항목 조회
  /// GET /api/fventas/:tipofactura/:numfactura - 특정 항목 조회
  Future<Map<String, dynamic>> getFVentasItem({
    required String tipofactura,
    required String numfactura,
  }) async {
    final endpoint = '/api/fventas/$tipofactura/$numfactura';
    
    try {
      final allHeaders = await _httpHandler.getDatabaseHeaders();
      
      final fventasHeaders = <String, String>{
        'Content-Type': allHeaders['Content-Type'] ?? 'application/json',
        'x-db-user': allHeaders['x-db-user'] ?? '',
        'x-db-password': allHeaders['x-db-password'] ?? '',
        'x-db-name': allHeaders['x-db-name'] ?? '',
      };
      
      if (fventasHeaders['x-db-user']!.isEmpty || 
          fventasHeaders['x-db-password']!.isEmpty || 
          fventasHeaders['x-db-name']!.isEmpty) {
        throw Exception('필수 헤더 정보가 없습니다: x-db-user, x-db-password, x-db-name');
      }
      
      return await _httpHandler.performGetRequestWithHeaders(
        endpoint,
        headers: fventasHeaders,
      );
    } catch (e) {
      print('⚠️ FVentas 항목 조회 실패: $e');
      rethrow;
    }
  }
  
  /// FVentas 배치 동기화
  /// POST /api/fventas
  /// {
  ///   "operation": "BATCH_SYNC",
  ///   "data": [...]
  /// }
  Future<Map<String, dynamic>> syncFVentasBatch({
    required List<Map<String, dynamic>> data,
  }) async {
    final endpoint = '/api/fventas';
    final body = <String, dynamic>{
      'operation': 'BATCH_SYNC',
      'data': data,
    };
    
    try {
      final allHeaders = await _httpHandler.getDatabaseHeaders();
      
      final fventasHeaders = <String, String>{
        'Content-Type': allHeaders['Content-Type'] ?? 'application/json',
        'x-db-user': allHeaders['x-db-user'] ?? '',
        'x-db-password': allHeaders['x-db-password'] ?? '',
        'x-db-name': allHeaders['x-db-name'] ?? '',
      };
      
      if (fventasHeaders['x-db-user']!.isEmpty || 
          fventasHeaders['x-db-password']!.isEmpty || 
          fventasHeaders['x-db-name']!.isEmpty) {
        throw Exception('필수 헤더 정보가 없습니다: x-db-user, x-db-password, x-db-name');
      }
      
      print('=== FVentas 배치 동기화 요청 ===');
      print('  - 엔드포인트: $endpoint');
      print('  - 데이터 항목 수: ${data.length}');
      
      // POST 요청을 위한 헤더와 바디 준비
      final response = await _httpHandler.performPostRequest(
        endpoint,
        body,
        timeoutSeconds: 60, // 배치 동기화는 시간이 걸릴 수 있으므로 60초로 설정
      );
      
      return response;
    } catch (e) {
      print('⚠️ FVentas 배치 동기화 실패: $e');
      rethrow;
    }
  }
  
  /// FVentas 업데이트
  /// PUT /api/fventas/:tipofactura/:numfactura
  Future<Map<String, dynamic>> updateFVentasItem({
    required String tipofactura,
    required String numfactura,
    required Map<String, dynamic> data,
  }) async {
    final endpoint = '/api/fventas/$tipofactura/$numfactura';
    
    try {
      // PUT 요청 수행 (헤더는 performPutRequest 내부에서 처리)
      final response = await _httpHandler.performPutRequest(
        endpoint,
        data,
      );
      
      return response;
    } catch (e) {
      print('⚠️ FVentas 업데이트 실패: $e');
      rethrow;
    }
  }
  
  /// FVentas 삭제
  /// DELETE /api/fventas/:tipofactura/:numfactura
  Future<Map<String, dynamic>> deleteFVentasItem({
    required String tipofactura,
    required String numfactura,
  }) async {
    final endpoint = '/api/fventas/$tipofactura/$numfactura';
    
    try {
      // DELETE 요청 수행 (헤더는 performDeleteRequest 내부에서 처리)
      final response = await _httpHandler.performDeleteRequest(
        endpoint,
      );
      
      return response;
    } catch (e) {
      print('⚠️ FVentas 삭제 실패: $e');
      rethrow;
    }
  }

  /// vdetalle 데이터 가져오기 (vcode 상세 정보)
  Future<Map<String, dynamic>> getVdetalle({
    required int vcodeId,
    required int sucursal,
  }) async {
    final endpoint = '/api/vdetalles';
    final queryParams = <String, String>{
      'vcode_id': vcodeId.toString(),
      'sucursal': sucursal.toString(),
    };
    
    // 헤더 가져오기
    final headers = await _httpHandler.getDatabaseHeaders();
    
    // URL 구성
    final uri = Uri.parse('${_httpHandler.serverUrl}$endpoint');
    final uriWithQuery = uri.replace(queryParameters: queryParams);
    
    print('\n═══════════════════════════════════════════════════════════');
    print('═══════════════════════════════════════════════════════════');
    print('=== Vdetalles 요청 ===');
    print('URL: $uriWithQuery');
    print('Headers:');
    headers.forEach((key, value) {
      // 비밀번호는 마스킹 처리
      if (key.toLowerCase().contains('password')) {
        print('  $key: ${'*' * (value.length > 0 ? value.length : 8)}');
      } else {
        print('  $key: $value');
      }
    });
    print('Query Parameters:');
    queryParams.forEach((key, value) {
      print('  $key: $value');
    });
    print('═══════════════════════════════════════════════════════════');
    
    final response = await _httpHandler.performGetRequest(
      endpoint,
      queryParameters: queryParams,
    );
    
    print('=== Vdetalles 응답 바디 ===');
    try {
      final responseJson = json.encode(response);
      if (responseJson.length > 2000) {
        print('${responseJson.substring(0, 2000)}... (${responseJson.length} bytes total)');
      } else {
        print(responseJson);
      }
    } catch (e) {
      print('응답 바디 직렬화 오류: $e');
      print('응답: $response');
    }
    print('═══════════════════════════════════════════════════════════\n');
    
    return response;
  }

  /// Tipos 리스트 가져오기
  Future<Map<String, dynamic>> getTipos() async {
    final endpoint = '/api/tipos';
    return await _httpHandler.performGetRequest(endpoint);
  }

  /// Temporadas 리스트 가져오기
  Future<Map<String, dynamic>> getTemporadas() async {
    final endpoint = '/api/temporadas';
    return await _httpHandler.performGetRequest(endpoint);
  }

  /// Cliente 상세 정보 가져오기 (cuit으로)
  Future<Map<String, dynamic>> getClienteDetail({
    required String cuit,
  }) async {
    final endpoint = '/api/cliente/detail';
    final queryParams = <String, String>{
      'cuit': cuit,
    };
    
    print('\n═══════════════════════════════════════════════════════════');
    print('=== Cliente 상세 정보 요청 ===');
    print('CUIT: $cuit');
    print('═══════════════════════════════════════════════════════════\n');
    
    final response = await _httpHandler.performGetRequest(
      endpoint,
      queryParameters: queryParams,
    );
    
    print('=== Cliente 상세 정보 응답 ===');
    try {
      final responseJson = json.encode(response);
      if (responseJson.length > 2000) {
        print('${responseJson.substring(0, 2000)}... (${responseJson.length} bytes total)');
      } else {
        print(responseJson);
      }
    } catch (e) {
      print('응답 바디 직렬화 오류: $e');
      print('응답: $response');
    }
    print('═══════════════════════════════════════════════════════════\n');
    
    return response;
  }
}
