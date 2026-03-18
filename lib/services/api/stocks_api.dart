import '../../models/stocks_response.dart';
import 'http_request_handler.dart';

/// Stocks 관련 API
class StocksApi {
  final HttpRequestHandler _httpHandler;

  StocksApi({required HttpRequestHandler httpHandler})
      : _httpHandler = httpHandler;

  /// 재고 보고서 가져오기 (페이지네이션 지원)
  Future<Map<String, dynamic>> getStocksReport({
    String? filteringWord,
    Map<String, dynamic>? filters,
    String? maxUtime,
    String? sortColumn,
    bool? sortAscending,
  }) async {
    const endpoint = '/api/reporte/stocks';
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
    
    if (maxUtime != null && maxUtime.isNotEmpty) {
      queryParams['max_utime'] = maxUtime;
    }
    
    if (sortColumn != null && sortColumn.isNotEmpty) {
      queryParams['sort_column'] = sortColumn;
      queryParams['sort_ascending'] = (sortAscending ?? true) ? 'true' : 'false';
    }
    
    // 스톡 보고서 요청 헤더와 쿼리 파라미터 출력
    final headers = await _httpHandler.getDatabaseHeaders();
    print('\n');
    print('═══════════════════════════════════════════════════════════');
    print('═══════════════════════════════════════════════════════════');
    final uri = Uri.parse('${_httpHandler.serverUrl}$endpoint').replace(
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
    
    return await _httpHandler.performGetRequest(
      endpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  /// 재고 보고서 가져오기 (StocksResponse 모델 반환)
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
}
