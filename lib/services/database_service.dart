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
  }) => _codigosApi.getCodigos(
    idCodigo: idCodigo,
    filteringWord: filteringWord,
    sortColumn: sortColumn,
    sortAscending: sortAscending,
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
  }) => _todocodigosApi.getTodocodigos(
    idTodocodigo: idTodocodigo,
    filteringWord: filteringWord,
    sortColumn: sortColumn,
    sortAscending: sortAscending,
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
  }) => _reportsApi.getClientesReport(filters: filters);

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

  /// 리소스 정리 (HTTP 클라이언트 연결 풀 정리)
  void dispose() {
    _httpHandler.dispose();
    _connectionApi.dispose();
  }
}
