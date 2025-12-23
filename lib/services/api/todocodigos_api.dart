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
  }) async {
    final endpoint = '/api/todocodigos';
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
    
    // Todocodigos 요청 헤더와 쿼리 파라미터 출력
    final headers = await _httpHandler.getDatabaseHeaders();
    print('\n');
    print('═══════════════════════════════════════════════════════════');
    print('═══════════════════════════════════════════════════════════');
    final uri = Uri.parse('${_httpHandler.serverUrl}$endpoint').replace(
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
    final identifier = idTodocodigo ?? tcodigo;
    if (identifier == null || identifier.isEmpty) {
      throw Exception('id_todocodigo 또는 tcodigo가 필요합니다.');
    }
    
    final endpoint = idTodocodigo != null 
        ? '/api/todocodigos/id/$idTodocodigo'
        : '/api/todocodigos/$tcodigo';
    
    print('=== Todocodigo 업데이트 ===');
    print('id_todocodigo: $idTodocodigo');
    print('tcodigo: $tcodigo');
    print('endpoint: $endpoint');
    
    return await _httpHandler.performPutRequest(endpoint, updatedData);
  }
}
