import 'http_request_handler.dart';

/// Codigos 관련 API
class CodigosApi {
  final HttpRequestHandler _httpHandler;

  CodigosApi({required HttpRequestHandler httpHandler})
      : _httpHandler = httpHandler;

  /// Codigos 리스트 가져오기 (페이지네이션 지원)
  Future<Map<String, dynamic>> getCodigos({
    String? idCodigo,
    String? filteringWord,
    String? sortColumn,
    bool? sortAscending,
    Map<String, dynamic>? filters,
  }) async {
    final endpoint = '/api/codigos';
    final queryParams = <String, String>{};
    
    if (idCodigo != null && idCodigo.isNotEmpty) {
      queryParams['id_codigo'] = idCodigo;
    }
    
    if (filteringWord != null && filteringWord.isNotEmpty) {
      queryParams['filtering_word'] = filteringWord;
      print('✅ filteringWord 추가됨: "$filteringWord"');
    } else {
      print('⚠️ filteringWord가 비어있거나 null입니다.');
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
      
      if (response.containsKey('data') && response['data'] is List) {
        final pageData = response['data'] as List;
        allData.addAll(pageData);
        print('✅ 페이지 $pageCount: ${pageData.length}개 항목 로드됨 (총 ${allData.length}개)');
      }
      
      if (response.containsKey('pagination') && response['pagination'] is Map) {
        final pagination = response['pagination'] as Map<String, dynamic>;
        if (pagination.containsKey('id_codigo') && pagination['id_codigo'] != null) {
          nextMaxUtime = pagination['id_codigo']?.toString();
          hasMore = true;
        } else {
          nextMaxUtime = null;
          hasMore = false;
          print('ℹ️ 마지막 페이지입니다.');
        }
      } else {
        hasMore = false;
        nextMaxUtime = null;
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
  Future<Map<String, dynamic>> updateCodigo({
    String? idCodigo,
    String? codigo,
    required Map<String, dynamic> updatedData,
  }) async {
    final identifier = idCodigo ?? codigo;
    if (identifier == null || identifier.isEmpty) {
      throw Exception('id_codigo 또는 codigo가 필요합니다.');
    }
    
    final endpoint = idCodigo != null 
        ? '/api/codigos/id/$idCodigo'
        : '/api/codigos/$codigo';
    
    print('=== Codigo 업데이트 ===');
    print('id_codigo: $idCodigo');
    print('codigo: $codigo');
    print('endpoint: $endpoint');
    
    return await _httpHandler.performPutRequest(endpoint, updatedData);
  }

  /// Codigo madre(todocodigo)에 연결된 모든 codigo hijo 일괄 업데이트
  /// 서버: PUT /api/codigos/by-todocodigo/:idTodocodigo
  /// body: codigo 테이블 필드 (pre1..pre5, borrado, liquidacion, promocion 등)
  Future<Map<String, dynamic>> updateCodigosByTodocodigo({
    required String idTodocodigo,
    required Map<String, dynamic> updatedData,
  }) async {
    if (idTodocodigo.isEmpty) {
      throw Exception('id_todocodigo가 필요합니다.');
    }
    final endpoint = '/api/codigos/by-todocodigo/$idTodocodigo';
    print('=== Codigos bulk update by todocodigo ===');
    print('id_todocodigo: $idTodocodigo');
    print('endpoint: $endpoint');
    return await _httpHandler.performPutRequest(endpoint, updatedData);
  }
}
