import 'api/http_request_handler.dart';
import 'api/database_connection_api.dart';
import 'api/stocks_api.dart';
import 'api/codigos_api.dart';
import 'api/todocodigos_api.dart';
import 'api/reports_api.dart';
import '../models/stocks_response.dart';
import '../models/todocodigos_response.dart';

export 'api/database_connection_api.dart';

/// 데이터베이스 서비스 메인 클래스
/// 모든 API 서비스를 통합하여 제공합니다.
class DatabaseService {
  final String serverUrl;
  late final HttpRequestHandler _httpHandler;
  late final DatabaseConnectionApi _connectionApi;
  late final StocksApi _stocksApi;
  late final CodigosApi _codigosApi;
  late final TodocodigosApi _todocodigosApi;
  late final ReportsApi _reportsApi;

  // Tipos와 Temporadas 캐시
  List<Map<String, dynamic>>? _cachedTipos;
  List<Map<String, dynamic>>? _cachedTemporadas;
  bool _isLoadingTipos = false;
  bool _isLoadingTemporadas = false;

  DatabaseService({required this.serverUrl}) {
    _httpHandler = HttpRequestHandler(serverUrl: serverUrl);
    _connectionApi = DatabaseConnectionApi(httpHandler: _httpHandler);
    _stocksApi = StocksApi(httpHandler: _httpHandler);
    _codigosApi = CodigosApi(httpHandler: _httpHandler);
    _todocodigosApi = TodocodigosApi(httpHandler: _httpHandler);
    _reportsApi = ReportsApi(httpHandler: _httpHandler);
  }

  // ========== 연결 관련 API ==========
  
  /// 기존 데이터베이스 연결 끊기
  Future<void> disconnectDatabase() => _connectionApi.disconnectDatabase();

  /// 데이터베이스 연결
  Future<bool> connectToDatabase(
    DatabaseConnectionRequest request, {
    bool disconnectExisting = false,
  }) => _connectionApi.connectToDatabase(request, disconnectExisting: disconnectExisting);

  // ========== Stocks API ==========
  
  /// 재고 보고서 가져오기
  Future<Map<String, dynamic>> getStocksReport({
    String? filteringWord,
    Map<String, dynamic>? filters,
    String? maxUtime,
    String? sortColumn,
    bool? sortAscending,
  }) => _stocksApi.getStocksReport(
    filteringWord: filteringWord,
    filters: filters,
    maxUtime: maxUtime,
    sortColumn: sortColumn,
    sortAscending: sortAscending,
  );

  /// 재고 보고서 가져오기 (타입 안전)
  Future<StocksResponse> getStocksReportTyped({
    String? filteringWord,
    Map<String, dynamic>? filters,
    String? maxUtime,
    String? sortColumn,
    bool? sortAscending,
  }) => _stocksApi.getStocksReportTyped(
    filteringWord: filteringWord,
    filters: filters,
    maxUtime: maxUtime,
    sortColumn: sortColumn,
    sortAscending: sortAscending,
  );

  // ========== Codigos API ==========
  
  /// Codigos 리스트 가져오기
  Future<Map<String, dynamic>> getCodigos({
    String? idCodigo,
    String? filteringWord,
    String? sortColumn,
    bool? sortAscending,
    Map<String, dynamic>? filters,
  }) => _codigosApi.getCodigos(
    idCodigo: idCodigo,
    filteringWord: filteringWord,
    sortColumn: sortColumn,
    sortAscending: sortAscending,
    filters: filters,
  );

  /// Codigos 전체 리스트 가져오기
  Future<Map<String, dynamic>> getAllCodigos() => _codigosApi.getAllCodigos();

  /// Codigo 업데이트하기
  Future<Map<String, dynamic>> updateCodigo({
    String? idCodigo,
    String? codigo,
    required Map<String, dynamic> updatedData,
  }) => _codigosApi.updateCodigo(
    idCodigo: idCodigo,
    codigo: codigo,
    updatedData: updatedData,
  );

  // ========== Todocodigos API ==========
  
  /// Todocodigo 업데이트하기
  Future<Map<String, dynamic>> updateTodocodigo({
    String? idTodocodigo,
    String? tcodigo,
    required Map<String, dynamic> updatedData,
  }) => _todocodigosApi.updateTodocodigo(
    idTodocodigo: idTodocodigo,
    tcodigo: tcodigo,
    updatedData: updatedData,
  );
  
  /// Todocodigos 리스트 가져오기
  Future<Map<String, dynamic>> getTodocodigos({
    String? idTodocodigo,
    String? filteringWord,
    String? sortColumn,
    bool? sortAscending,
    Map<String, dynamic>? filters,
  }) => _todocodigosApi.getTodocodigos(
    idTodocodigo: idTodocodigo,
    filteringWord: filteringWord,
    sortColumn: sortColumn,
    sortAscending: sortAscending,
    filters: filters,
  );

  /// Todocodigos 리스트 가져오기 (타입 안전)
  Future<TodocodigosResponse> getTodocodigosTyped({
    String? idTodocodigo,
    String? filteringWord,
    String? sortColumn,
    bool? sortAscending,
  }) => _todocodigosApi.getTodocodigosTyped(
    idTodocodigo: idTodocodigo,
    filteringWord: filteringWord,
    sortColumn: sortColumn,
    sortAscending: sortAscending,
  );

  // ========== Reports API ==========
  
  /// resumen_del_dia 데이터 가져오기
  Future<Map<String, dynamic>> getResumenDelDia({
    DateTime? date,
    String? sucursal,
  }) => _reportsApi.getResumenDelDia(
    date: date,
    sucursal: sucursal,
  );

  /// 아이템 보고서 가져오기
  Future<Map<String, dynamic>> getItemsReport({
    String? filteringWord,
    Map<String, dynamic>? filters,
  }) => _reportsApi.getItemsReport(
    filteringWord: filteringWord,
    filters: filters,
  );

  /// 고객 보고서 가져오기
  Future<Map<String, dynamic>> getClientesReport({
    Map<String, dynamic>? filters,
    int? limit,
    int? offset,
  }) => _reportsApi.getClientesReport(
    filters: filters,
    limit: limit,
    offset: offset,
  );

  /// 지출 보고서 가져오기
  Future<Map<String, dynamic>> getGastosReport({
    String? filteringWord,
    Map<String, dynamic>? filters,
  }) => _reportsApi.getGastosReport(
    filteringWord: filteringWord,
    filters: filters,
  );

  /// 판매 보고서 가져오기
  Future<Map<String, dynamic>> getVentasReport({
    String? filteringWord,
    String? currentDate,
    String? unit, // 'vcode', 'day', 'month', 'year'
    Map<String, dynamic>? filters,
  }) => _reportsApi.getVentasReport(
    filteringWord: filteringWord,
    currentDate: currentDate,
    unit: unit,
    filters: filters,
  );

  /// FVentas 보고서 가져오기
  Future<Map<String, dynamic>> getFVentasReport({
    String? filteringWord,
    String? currentDate,
    String? unit, // 'vcode', 'day', 'month', 'year'
    Map<String, dynamic>? filters,
    String? lastIdFventa, // 페이지네이션용
  }) => _reportsApi.getFVentasReport(
    filteringWord: filteringWord,
    currentDate: currentDate,
    unit: unit,
    filters: filters,
    lastIdFventa: lastIdFventa,
  );
  
  /// FVentas 특정 항목 조회
  Future<Map<String, dynamic>> getFVentasItem({
    required String tipofactura,
    required String numfactura,
  }) => _reportsApi.getFVentasItem(
    tipofactura: tipofactura,
    numfactura: numfactura,
  );
  
  /// FVentas 배치 동기화
  Future<Map<String, dynamic>> syncFVentasBatch({
    required List<Map<String, dynamic>> data,
  }) => _reportsApi.syncFVentasBatch(
    data: data,
  );
  
  /// FVentas 업데이트
  Future<Map<String, dynamic>> updateFVentasItem({
    required String tipofactura,
    required String numfactura,
    required Map<String, dynamic> data,
  }) => _reportsApi.updateFVentasItem(
    tipofactura: tipofactura,
    numfactura: numfactura,
    data: data,
  );
  
  /// FVentas 삭제
  Future<Map<String, dynamic>> deleteFVentasItem({
    required String tipofactura,
    required String numfactura,
  }) => _reportsApi.deleteFVentasItem(
    tipofactura: tipofactura,
    numfactura: numfactura,
  );

  /// 알림 보고서 가져오기
  Future<Map<String, dynamic>> getAlertasReport({
    String? filteringWord,
    Map<String, dynamic>? filters,
  }) => _reportsApi.getAlertasReport(
    filteringWord: filteringWord,
    filters: filters,
  );

  /// 수입 보고서 가져오기
  Future<Map<String, dynamic>> getIngresosReport({
    String? filteringWord,
    Map<String, dynamic>? filters,
  }) => _reportsApi.getIngresosReport(
    filteringWord: filteringWord,
    filters: filters,
  );

  /// vdetalle 데이터 가져오기 (vcode 상세 정보)
  Future<Map<String, dynamic>> getVdetalle({
    required int vcodeId,
    required int sucursal,
  }) => _reportsApi.getVdetalle(
    vcodeId: vcodeId,
    sucursal: sucursal,
  );

  // ========== Tipos & Temporadas API ==========
  
  /// Tipos 리스트 가져오기 (캐시 사용)
  Future<List<Map<String, dynamic>>> getTipos({bool forceRefresh = false}) async {
    if (_cachedTipos != null && !forceRefresh) {
      return _cachedTipos!;
    }
    
    if (_isLoadingTipos) {
      // 이미 로딩 중이면 대기
      while (_isLoadingTipos) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _cachedTipos ?? [];
    }
    
    try {
      _isLoadingTipos = true;
      final response = await _reportsApi.getTipos();
      
      if (response.containsKey('data') && response['data'] is List) {
        _cachedTipos = List<Map<String, dynamic>>.from(response['data']);
        final count = _cachedTipos!.length;
        final showComboBox = count > 1;
        print('✅ Tipos: $count개, 콤보박스 표시: ${showComboBox ? "예" : "아니오"}');
        return _cachedTipos!;
      }
      
      print('⚠️ Tipos 데이터가 비어있거나 형식이 올바르지 않습니다.');
      return [];
    } catch (e) {
      print('❌ Tipos 로드 오류: $e');
      return [];
    } finally {
      _isLoadingTipos = false;
    }
  }

  /// Temporadas 리스트 가져오기 (캐시 사용)
  Future<List<Map<String, dynamic>>> getTemporadas({bool forceRefresh = false}) async {
    if (_cachedTemporadas != null && !forceRefresh) {
      return _cachedTemporadas!;
    }
    
    if (_isLoadingTemporadas) {
      // 이미 로딩 중이면 대기
      while (_isLoadingTemporadas) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _cachedTemporadas ?? [];
    }
    
    try {
      _isLoadingTemporadas = true;
      final response = await _reportsApi.getTemporadas();
      
      if (response.containsKey('data') && response['data'] is List) {
        _cachedTemporadas = List<Map<String, dynamic>>.from(response['data']);
        final count = _cachedTemporadas!.length;
        final showComboBox = count > 1;
        print('✅ Temporadas: $count개, 콤보박스 표시: ${showComboBox ? "예" : "아니오"}');
        return _cachedTemporadas!;
      }
      
      print('⚠️ Temporadas 데이터가 비어있거나 형식이 올바르지 않습니다.');
      return [];
    } catch (e) {
      print('❌ Temporadas 로드 오류: $e');
      return [];
    } finally {
      _isLoadingTemporadas = false;
    }
  }

  /// Tipos와 Temporadas 캐시 초기화 (연결 변경 시 호출)
  void clearTiposTemporadasCache() {
    _cachedTipos = null;
    _cachedTemporadas = null;
  }

  /// 리소스 정리 (HTTP 클라이언트 연결 풀 정리)
  void dispose() {
    _httpHandler.dispose();
    _connectionApi.dispose();
  }
}
