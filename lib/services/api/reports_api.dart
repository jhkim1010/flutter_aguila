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
    
    return await _httpHandler.performGetRequest(
      endpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  /// 판매 보고서 가져오기
  Future<Map<String, dynamic>> getVentasReport({
    String? filteringWord,
    Map<String, dynamic>? filters,
  }) async {
    final endpoint = '/api/reporte/ventas';
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
}
