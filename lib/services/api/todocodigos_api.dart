import 'dart:convert';
import '../../models/todocodigos_response.dart';
import 'http_request_handler.dart';

/// Todocodigos 관련 API
class TodocodigosApi {
  final HttpRequestHandler _httpHandler;

  TodocodigosApi({required HttpRequestHandler httpHandler})
      : _httpHandler = httpHandler;

  /// Todocodigos 리스트 가져오기 (페이지네이션 지원)
  Future<Map<String, dynamic>> getTodocodigos({
    String? idTodocodigo,
    String? filteringWord,
    String? sortColumn,
    bool? sortAscending,
    Map<String, dynamic>? filters,
  }) async {
    const endpoint = '/api/todocodigos';
    final queryParams = <String, String>{};
    
    if (idTodocodigo != null && idTodocodigo.isNotEmpty) {
      queryParams['id_todocodigo'] = idTodocodigo;
    }
    
    if (filteringWord != null && filteringWord.isNotEmpty) {
      queryParams['filtering_word'] = filteringWord;
      print('✅ filteringWord 추가됨: "$filteringWord"');
    }
    
    if (sortColumn != null && sortColumn.isNotEmpty) {
      queryParams['sort_column'] = sortColumn;
      queryParams['sort_ascending'] = (sortAscending ?? true) ? 'true' : 'false';
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

  /// Todocodigos 리스트 가져오기 (TodocodigosResponse 모델 반환)
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

  /// Todocodigo 업데이트하기
  Future<Map<String, dynamic>> updateTodocodigo({
    String? idTodocodigo,
    String? tcodigo,
    required Map<String, dynamic> updatedData,
  }) async {
    // id_todocodigo가 필수
    if (idTodocodigo == null || idTodocodigo.isEmpty) {
      throw Exception('id_todocodigo가 필요합니다.');
    }
    
    final endpoint = '/api/todocodigos/id/$idTodocodigo';
    
    // 헤더 가져오기
    final headers = await _httpHandler.getDatabaseHeaders();
    
    // 요청 URL 생성
    final uri = Uri.parse('${_httpHandler.serverUrl}$endpoint');
    
    // 요청 바디 JSON 인코딩
    final bodyJson = json.encode(updatedData);
    
    print('\n');
    print('═══════════════════════════════════════════════════════════');
    print('═══════════════════════════════════════════════════════════');
    print('📤 TODOCODIGO 업데이트 요청');
    print('═══════════════════════════════════════════════════════════');
    print('🌐 URL: $uri');
    print('');
    print('📋 Headers:');
    headers.forEach((key, value) {
      final displayValue = key == 'x-db-password' ? '***' : value;
      print('   $key: $displayValue');
    });
    print('');
    print('📦 Body:');
    final bodyPreview = bodyJson.length > 1000 
        ? '${bodyJson.substring(0, 1000)}... (${bodyJson.length} bytes total)'
        : bodyJson;
    print('   $bodyPreview');
    print('═══════════════════════════════════════════════════════════');
    print('═══════════════════════════════════════════════════════════');
    print('\n');
    
    return await _httpHandler.performPutRequest(endpoint, updatedData);
  }
}
