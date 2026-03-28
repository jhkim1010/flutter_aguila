import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/rendering.dart' show RenderBox, RenderFlex, FlexParentData, RenderViewport;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart';
import '../services/excel_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/platform_utils.dart';
import '../utils/mobile_layout_helper.dart';
import '../utils/report_data_utils.dart';
import '../widgets/report_utils.dart';
import '../widgets/items_date_range_selector.dart';
import '../widgets/report_table_builder.dart';
import '../widgets/codigos_builder.dart';
import '../widgets/resizable_data_table.dart';
import '../widgets/stocks_builder.dart';
import '../widgets/gastos_builder.dart';
import '../widgets/items_builder.dart';
import '../widgets/ingresos_builder.dart';
import '../widgets/report_data_builder.dart';
import '../widgets/report_filters.dart';
import '../widgets/report_header_builders.dart';
import '../widgets/report_total_row_builder.dart';
import '../widgets/report_filter_widgets.dart';
import '../services/secure_storage_helper.dart';
import '../services/codigos_column_width_storage.dart';
import '../services/stocks_column_width_storage.dart';
import '../services/gastos_column_width_storage.dart';
import '../services/report_column_width_storage.dart';
import '../generated/build_info.dart';

part 'reports/ventas_report_section.dart';
part 'reports/clientes_report_section.dart';
part 'reports/codigos_report_section.dart';
part 'helpers/report_data_loader.dart';
part 'helpers/report_filter_helper.dart';
part 'reports/stocks_report_section.dart';
part 'helpers/report_share_helper.dart';
part 'reports/ventas_controls_section.dart';
part 'helpers/report_utils_mixin.dart';

// Library-level constant accessible from all part files
const int _itemsPerPage = 100;

// ReportType is used by ReportScreenLegacy; export from report_screen.dart

/// 레거시 단일 대형 화면. 타입별로 분리된 뷰로 점진적 이전 예정.
class ReportScreenLegacy extends StatefulWidget {
  final String serverUrl;
  final ReportType reportType;
  final DateTime? initialDate; // ventas report용 초기 날짜
  final DateTime? initialItemsStartDate; // items report용 초기 시작 날짜
  final DateTime? initialItemsEndDate; // items report용 초기 종료 날짜
  final String? initialFilteringWord; // 초기 필터링 단어
  final String? initialSortColumn; // 초기 정렬 컬럼
  final bool? initialSortAscending; // 초기 정렬 방향
  final bool? initialVentasDescontado; // Ventas 보고서용 초기 descontado 필터
  final Function(String?, String?, bool?)? onStateChanged; // 상태 변경 콜백 (filteringWord, sortColumn, sortAscending)
  final Function(DateTime?, DateTime?)? onItemsDateRangeChanged; // items 보고서 날짜 범위 변경 콜백
  final bool useFullWidth; // 전체 너비 사용 여부 (resumen del dia에서 사용 시 true)
  final VoidCallback? onMenuPressed; // 메뉴 버튼 콜백 (useFullWidth가 true일 때 좁은 화면에서 사용)
  final List<String>? initialAvailableSucursales; // 초기 사용 가능한 sucursal 목록 (resumen del dia에서 전달)
  /// 슬림 ReportScreen에서 전달 시, 메뉴에서 다른 보고서 선택하면 이 콜백 호출 (순환 import 회피)
  final void Function(ReportType type)? onSwitchReport;

  const ReportScreenLegacy({
    super.key,
    required this.serverUrl,
    required this.reportType,
    this.initialDate,
    this.initialItemsStartDate,
    this.initialItemsEndDate,
    this.initialFilteringWord,
    this.initialSortColumn,
    this.initialSortAscending,
    this.initialVentasDescontado,
    this.onStateChanged,
    this.onItemsDateRangeChanged,
    this.useFullWidth = false,
    this.onMenuPressed,
    this.initialAvailableSucursales,
    this.onSwitchReport,
  });

  @override
  State<ReportScreenLegacy> createState() => _ReportScreenLegacyState();
}

/// Holds all state fields so that the part-of mixins can access them via
/// the `on _ReportScreenStateBase` constraint without circular dependencies.
abstract class _ReportScreenStateBase extends State<ReportScreenLegacy> {
  late final DatabaseService _databaseService;
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _originalGastosData;
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _filteringWordController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  int _displayedItemsCount = 100;

  String? _sortColumn;
  bool _sortAscending = true;
  final Map<String, String> _columnFilters = {};
  String? _selectedSucursal;
  List<String>? _availableSucursales;

  DateTime? _itemsStartDate;
  DateTime? _itemsEndDate;
  DateTime? _ventasStartDate;
  DateTime? _ventasEndDate;
  String _ventasUnit = 'vcode';
  bool _ventasDescontado = false;
  bool _ventasReservado = false;
  bool _ventasCredito = false;
  bool _ventasMovidos = false;
  bool _ingresosMovidos = false;
  String? _connectedDatabaseName;
  bool _alertasVCancelado = false;
  bool _alertasJefe = false;
  bool _alertasWeb = false;

  String? _clientesResponsableIns;
  String? _clientesProvincia;
  bool _clientesDeudores = false;
  bool _clientesReservadores = false;

  Map<String, dynamic>? _selectedCodigo;
  final Map<String, TextEditingController> _codigoEditControllers = {};
  final Map<String, FocusNode> _codigoFocusNodes = {};

  String? _selectedRubroCode;
  bool _isLoadingGastosDetail = false;
  String? _selectedCategoryCode;
  String? _selectedColorCode;
  String? _selectedIngresosCategoryCode;
  String? _selectedIngresosColorCode;
  String? _selectedCodigosColorCode;
  String? _selectedStocksColorCode;
  String? _selectedIngresosCompanyCode;
  bool _isEditingCodigo = false;
  String? _editedCodigoIdentifier;
  bool _isLoadingMoreCodigos = false;
  String? _codigosNextIdCodigo;
  bool _codigosHasMore = false;
  bool _codigosSoloBorrados = false;
  Map<String, double>? _codigosColumnWidths;
  String? _codigosColumnWidthsDbKey;
  Map<String, double>? _stocksColumnWidths;
  String? _stocksColumnWidthsDbKey;
  Map<String, double>? _gastosColumnWidths; // Gastos 상세 내역 칼럼 너비
  Map<String, double>? _itemsColumnWidths;
  String? _itemsColumnWidthsDbKey;
  Map<String, double>? _ingresosColumnWidths;
  String? _ingresosColumnWidthsDbKey;

  int _clientesOffset = 0;
  bool _clientesHasMore = false;
  bool _clientesIsLoadingMore = false;
  String? _clientesSortColumn;
  bool _clientesSortAscending = false;

  OverlayEntry? _clienteDetailOverlayEntry;
  Map<String, dynamic>? _currentClienteDetailData;
  Map<String, dynamic>? _currentClienteRowData;
  String? _codigosSortColumn = 'codigo';
  bool _codigosSortAscending = true;

  String? _stocksNextMaxUtime;
  bool _stocksHasMore = false;
  bool _isLoadingMoreStocks = false;
  String? _stocksSortColumn = 'codigo';
  bool _stocksSortAscending = true;

  List<Map<String, dynamic>> _tiposList = [];
  List<Map<String, dynamic>> _temporadasList = [];
  int? _selectedTipoId;
  int? _selectedTemporadaId;

  // Abstract methods implemented by mixins or _ReportScreenLegacyState
  Future<void> _loadData();
  void _loadMoreItems();
  Map<String, dynamic> _getDisplayedData();
  Color _getReportColor();
  Widget _buildFilteringWordFieldInAppBar();
  Widget _buildSucursalSelector();
  Future<void> _reloadDataWithFilters();
  String? _getInitialFilteringWordForNavigation(ReportType currentReportType, ReportType targetReportType);
  void _closeClienteDetailOverlay();
  void _notifyStateChanged();
  Widget _buildInfoCard(String title, Map<String, dynamic> data, {Color? reportColor});
  Widget _buildStocksHeader();
  Future<void> _sharePdfFile(File pdfFile);
  Future<void> _shareExcelFile(File excelFile);
}

class _ReportScreenLegacyState extends _ReportScreenStateBase
    with VentasReportMixin, ClientesReportMixin, CodigosReportMixin, ReportDataLoaderMixin, ReportFilterMixin, StocksReportMixin, ReportShareMixin, VentasControlsMixin, ReportUtilsMixin {

  @override
  void initState() {
    super.initState();
    print('🟦🟦🟦 [report_screen.dart:179] initState 호출 시작');
    print('   → 라인: 179');
    if (widget.reportType == ReportType.ventas) {
      print('   → _ventasUnit 초기값: $_ventasUnit');
      print('   → _ventasUnit 타입: ${_ventasUnit.runtimeType}');
      print('   → 호출 스택 (처음 5줄):');
      print('      ${StackTrace.current.toString().split("\n").take(5).join("\n      ")}');
    }
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [initState] ReportScreen 초기화');
    debugPrint('   → 파일: report_screen.dart');
    debugPrint('   → 라인: ${163}');
    debugPrint('   → reportType: ${widget.reportType}');
    if (widget.reportType == ReportType.ventas) {
      debugPrint('   → [Ventas] _ventasUnit 초기값: $_ventasUnit');
      debugPrint('   → [Ventas] _ventasUnit 타입: ${_ventasUnit.runtimeType}');
      debugPrint('   → 호출 스택 (처음 5줄):');
      debugPrint('      ${StackTrace.current.toString().split("\n").take(5).join("\n      ")}');
    }
    debugPrint('   → initialFilteringWord: ${widget.initialFilteringWord}');
    debugPrint('   → initialFilteringWord가 null인지: ${widget.initialFilteringWord == null}');
    debugPrint('   → initialFilteringWord가 비어있는지: ${widget.initialFilteringWord?.isEmpty ?? true}');
    
    _databaseService = DatabaseService(serverUrl: widget.serverUrl);
    // 스크롤 리스너 추가 (무한 스크롤)
    _scrollController.addListener(_onScroll);
    // filteringWord 변경 감지 리스너 추가 (debounce 처리)
    _filteringWordController.addListener(_onFilteringWordChangedDebounced);
    
    // 초기 필터링 단어 설정
    // alertas가 아닌 보고서로 이동할 때는 initialFilteringWord를 무시하고 초기화
    if (widget.reportType != ReportType.alertas) {
      debugPrint('   → alertas가 아닌 보고서 - filteringWord 초기화');
      debugPrint('      → 초기화 전 _filteringWordController.text: "${_filteringWordController.text}"');
      _filteringWordController.clear();
      debugPrint('      → 초기화 후 _filteringWordController.text: "${_filteringWordController.text}"');
    } else if (widget.initialFilteringWord != null && widget.initialFilteringWord!.isNotEmpty) {
      debugPrint('   → alertas 보고서 - initialFilteringWord 설정: "${widget.initialFilteringWord}"');
      _filteringWordController.text = widget.initialFilteringWord!;
    } else {
      debugPrint('   → initialFilteringWord가 null이거나 비어있음 - filteringWord 초기화');
      _filteringWordController.clear();
    }
    debugPrint('   → 최종 _filteringWordController.text: "${_filteringWordController.text}"');
    debugPrint('═══════════════════════════════════════════════════════');
    
    // 초기 사용 가능한 sucursal 목록 설정 (resumen del dia에서 전달된 경우)
    if (widget.initialAvailableSucursales != null && widget.initialAvailableSucursales!.isNotEmpty) {
      _availableSucursales = widget.initialAvailableSucursales;
      debugPrint('🔍 [initState] initialAvailableSucursales 설정됨: $_availableSucursales');
    }
    
    // 초기 정렬 정보 설정
    if (widget.initialSortColumn != null) {
      if (widget.reportType == ReportType.stocks) {
        _stocksSortColumn = widget.initialSortColumn;
        _stocksSortAscending = widget.initialSortAscending ?? true;
      } else if (widget.reportType == ReportType.codigos || widget.reportType == ReportType.todocodigos) {
        _codigosSortColumn = widget.initialSortColumn;
        _codigosSortAscending = widget.initialSortAscending ?? true;
      } else {
        _sortColumn = widget.initialSortColumn;
        _sortAscending = widget.initialSortAscending ?? true;
      }
    }
    
    // Stocks, Items, Ingresos, Codigos, Todocodigos 보고서의 경우 tipos/temporadas 로드
    if (widget.reportType == ReportType.stocks || 
        widget.reportType == ReportType.items || 
        widget.reportType == ReportType.ingresos || 
        widget.reportType == ReportType.codigos || 
        widget.reportType == ReportType.todocodigos) {
      _loadTiposAndTemporadas();
    }
    
    // Items, Ingresos, Gastos 및 Alertas 보고서의 경우 기본 날짜 설정 (오늘 날짜 또는 초기값)
    if (widget.reportType == ReportType.items || widget.reportType == ReportType.ingresos || widget.reportType == ReportType.gastos || widget.reportType == ReportType.alertas || widget.reportType == ReportType.clientes) {
      if (widget.initialItemsStartDate != null && widget.initialItemsEndDate != null) {
        _itemsStartDate = widget.initialItemsStartDate;
        _itemsEndDate = widget.initialItemsEndDate;
        final reportName = widget.reportType == ReportType.items ? "Items" : (widget.reportType == ReportType.ingresos ? "Ingresos" : (widget.reportType == ReportType.gastos ? "Gastos" : (widget.reportType == ReportType.clientes ? "Clientes" : "Alertas")));
        print('📅 $reportName 보고서 초기 날짜 범위 설정: ${DateFormat('yyyy-MM-dd').format(_itemsStartDate!)} ~ ${DateFormat('yyyy-MM-dd').format(_itemsEndDate!)}');
      } else {
        final now = DateTime.now();
        _itemsStartDate = now;
        _itemsEndDate = now;
        if (widget.reportType == ReportType.clientes) {
          print('📅 Clientes 보고서 날짜 범위 설정 (오늘): ${DateFormat('yyyy-MM-dd').format(_itemsStartDate!)} ~ ${DateFormat('yyyy-MM-dd').format(_itemsEndDate!)}');
        }
      }
    }
    // Movidos 보고서의 경우 기간·체크박스 초기값
    // Ventas 및 FVentas 보고서의 경우 초기 날짜 범위 설정
    if (widget.reportType == ReportType.ventas || widget.reportType == ReportType.fventas) {
      final now = DateTime.now();
      if (widget.initialDate != null) {
        _ventasStartDate = widget.initialDate;
        _ventasEndDate = widget.initialDate;
        final reportName = widget.reportType == ReportType.ventas ? "Ventas" : "FVentas";
        print('📅 $reportName 보고서 초기 날짜 범위 설정: ${DateFormat('yyyy-MM-dd').format(_ventasStartDate!)} ~ ${DateFormat('yyyy-MM-dd').format(_ventasEndDate!)}');
      } else {
        // initialDate가 없으면 오늘 날짜로 설정
        _ventasStartDate = now;
        _ventasEndDate = now;
        final reportName = widget.reportType == ReportType.ventas ? "Ventas" : "FVentas";
        print('📅 $reportName 보고서 날짜 범위 설정 (오늘): ${DateFormat('yyyy-MM-dd').format(_ventasStartDate!)} ~ ${DateFormat('yyyy-MM-dd').format(_ventasEndDate!)}');
      }
      // 초기 descontado 필터 설정 (ventas만)
      if (widget.reportType == ReportType.ventas && widget.initialVentasDescontado != null) {
        _ventasDescontado = widget.initialVentasDescontado!;
        print('📅 Ventas 보고서 초기 descontado 필터 설정: $_ventasDescontado');
      }
    }
    // Gastos 보고서의 경우 저장된 칼럼 너비 로드
    if (widget.reportType == ReportType.gastos) {
      GastosColumnWidthStorage.load().then((loaded) {
        if (loaded != null && mounted) {
          setState(() {
            _gastosColumnWidths = loaded;
          });
        }
      });
    }

    // 초기 상태 저장
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🟦🟦🟦 [report_screen.dart:280] addPostFrameCallback 실행');
      print('   → 라인: 280');
      if (widget.reportType == ReportType.ventas) {
        print('   → _ventasUnit: $_ventasUnit');
      }
      debugPrint('🟦🟦🟦 [report_screen.dart:280] addPostFrameCallback 실행');
      debugPrint('   → 라인: 280');
      if (widget.reportType == ReportType.ventas) {
        debugPrint('   → _ventasUnit: $_ventasUnit');
      }
      _notifyStateChanged();
      // Clientes 보고서 초기화 시 OverlayEntry 닫기 (이전에 열린 overlay가 남아있을 수 있음)
      // PostFrameCallback 내에서 실행하여 context가 준비된 후에 실행되도록 함
      _closeClienteDetailOverlay();
    });
    print('🟦🟦🟦 [report_screen.dart:286] initState 완료 직전 - _loadData() 호출');
    print('   → 라인: 286');
    if (widget.reportType == ReportType.ventas) {
      print('   → _ventasUnit: $_ventasUnit');
    }
    debugPrint('🟦🟦🟦 [report_screen.dart:286] initState 완료 직전 - _loadData() 호출');
    debugPrint('   → 라인: 286');
    if (widget.reportType == ReportType.ventas) {
      debugPrint('   → _ventasUnit: $_ventasUnit');
    }
    _loadConnectedDatabaseName();
    _loadData();
    print('🟦🟦🟦 [report_screen.dart:287] initState 완료');
    print('   → 라인: 287');
    if (widget.reportType == ReportType.ventas) {
      print('   → _ventasUnit: $_ventasUnit');
    }
    debugPrint('🟦🟦🟦 [report_screen.dart:287] initState 완료');
    debugPrint('   → 라인: 287');
    if (widget.reportType == ReportType.ventas) {
      debugPrint('   → _ventasUnit: $_ventasUnit');
    }
  }

  /// alertas에서 다른 보고서로 이동할 때 filteringWord를 초기화하는 헬퍼 함수
  @override
  String? _getInitialFilteringWordForNavigation(ReportType currentReportType, ReportType targetReportType) {
    final isFromAlertas = currentReportType == ReportType.alertas;
    final isToAlertas = targetReportType == ReportType.alertas;
    final shouldClearFilteringWord = isFromAlertas && !isToAlertas;
    
    debugPrint('🔍 [_getInitialFilteringWordForNavigation]');
    debugPrint('   → 현재 reportType: $currentReportType');
    debugPrint('   → 이동할 reportType: $targetReportType');
    debugPrint('   → isFromAlertas: $isFromAlertas');
    debugPrint('   → isToAlertas: $isToAlertas');
    debugPrint('   → shouldClearFilteringWord: $shouldClearFilteringWord');
    debugPrint('   → 현재 initialFilteringWord: ${widget.initialFilteringWord}');
    debugPrint('   → 반환할 initialFilteringWord: ${shouldClearFilteringWord ? null : widget.initialFilteringWord}');
    
    return shouldClearFilteringWord ? null : widget.initialFilteringWord;
  }

  @override
  void didUpdateWidget(ReportScreenLegacy oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Ventas 보고서에서 initialVentasDescontado가 변경된 경우 처리
    if (widget.reportType == ReportType.ventas && 
        oldWidget.initialVentasDescontado != widget.initialVentasDescontado) {
      if (widget.initialVentasDescontado != null) {
        _ventasDescontado = widget.initialVentasDescontado!;
        print('📅 Ventas 보고서 descontado 필터 변경 감지: $_ventasDescontado');
        _loadData(); // 데이터 다시 로드
        return;
      }
    }
    
    // reportType이 변경되었을 때 데이터 다시 로드
    if (oldWidget.reportType != widget.reportType) {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🔄 [didUpdateWidget] ReportType 변경 감지');
      debugPrint('   → 파일: report_screen.dart');
      debugPrint('   → 라인: ${262}');
      debugPrint('   → oldWidget.reportType: ${oldWidget.reportType}');
      debugPrint('   → widget.reportType: ${widget.reportType}');
      debugPrint('   → filteringWord 초기값: "${_filteringWordController.text}"');
      debugPrint('   → filteringWord 길이: ${_filteringWordController.text.length}');
      
      // 상태 초기화
      _data = null;
      _errorMessage = null;
      _isLoading = true;
      
      // alertas에서 다른 보고서로 이동할 때만 filteringWord 초기화 (기간은 유지)
      final isFromAlertas = oldWidget.reportType == ReportType.alertas;
      final isToAlertas = widget.reportType == ReportType.alertas;
      
      debugPrint('   → isFromAlertas: $isFromAlertas');
      debugPrint('   → isToAlertas: $isToAlertas');
      debugPrint('   → 조건 확인: isFromAlertas && !isToAlertas = ${isFromAlertas && !isToAlertas}');
      debugPrint('   → 조건 확인: !isFromAlertas && !isToAlertas = ${!isFromAlertas && !isToAlertas}');
      
      if (isFromAlertas && !isToAlertas) {
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('🔄 [Alertas → 다른 보고서] filteringWord 초기화 시작');
        debugPrint('   → 초기화 전 filteringWord: "${_filteringWordController.text}"');
        debugPrint('   → 초기화 전 filteringWord 길이: ${_filteringWordController.text.length}');
        debugPrint('   → _filteringWordController.clear() 호출');
        
        _filteringWordController.clear();
        
        // clear() 호출 후 즉시 확인
        WidgetsBinding.instance.addPostFrameCallback((_) {
          debugPrint('   → [PostFrameCallback] 초기화 후 filteringWord: "${_filteringWordController.text}"');
          debugPrint('   → [PostFrameCallback] 초기화 후 filteringWord 길이: ${_filteringWordController.text.length}');
          debugPrint('   → [PostFrameCallback] filteringWord가 비어있는지: ${_filteringWordController.text.isEmpty}');
        });
        
        debugPrint('   → 초기화 직후 filteringWord: "${_filteringWordController.text}"');
        debugPrint('   → 초기화 직후 filteringWord 길이: ${_filteringWordController.text.length}');
        
        // alertas 관련 상태도 초기화
        debugPrint('   → alertas 관련 상태 초기화');
        debugPrint('      → _alertasVCancelado: $_alertasVCancelado → false');
        debugPrint('      → _alertasJefe: $_alertasJefe → false');
        debugPrint('      → _alertasWeb: $_alertasWeb → false');
        
        _alertasVCancelado = false;
        _alertasJefe = false;
        _alertasWeb = false;
        
        debugPrint('🔄 [Alertas → 다른 보고서] filteringWord 초기화 완료');
        debugPrint('═══════════════════════════════════════════════════════');
      } else if (!isFromAlertas && !isToAlertas) {
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('🔄 [다른 보고서 → 다른 보고서] filteringWord 초기화 시작');
        debugPrint('   → 초기화 전 filteringWord: "${_filteringWordController.text}"');
        debugPrint('   → 초기화 전 filteringWord 길이: ${_filteringWordController.text.length}');
        debugPrint('   → _filteringWordController.clear() 호출');
        
        // alertas가 아닌 다른 보고서에서 다른 보고서로 이동할 때는 filteringWord 초기화
        _filteringWordController.clear();
        
        // clear() 호출 후 즉시 확인
        WidgetsBinding.instance.addPostFrameCallback((_) {
          debugPrint('   → [PostFrameCallback] 초기화 후 filteringWord: "${_filteringWordController.text}"');
          debugPrint('   → [PostFrameCallback] 초기화 후 filteringWord 길이: ${_filteringWordController.text.length}');
          debugPrint('   → [PostFrameCallback] filteringWord가 비어있는지: ${_filteringWordController.text.isEmpty}');
        });
        
        debugPrint('   → 초기화 직후 filteringWord: "${_filteringWordController.text}"');
        debugPrint('   → 초기화 직후 filteringWord 길이: ${_filteringWordController.text.length}');
        debugPrint('🔄 [다른 보고서 → 다른 보고서] filteringWord 초기화 완료');
        debugPrint('═══════════════════════════════════════════════════════');
      } else {
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('🔄 [Alertas 유지 또는 Alertas로 이동] filteringWord 유지');
        debugPrint('   → filteringWord: "${_filteringWordController.text}"');
        debugPrint('   → filteringWord 길이: ${_filteringWordController.text.length}');
        debugPrint('═══════════════════════════════════════════════════════');
      }
      // alertas로 이동하거나 alertas 내에서 변경될 때는 filteringWord 유지
      
      _selectedSucursal = null;
      
      // 보고서 타입별 상태 초기화
      if (widget.reportType == ReportType.codigos || widget.reportType == ReportType.todocodigos) {
        _codigosNextIdCodigo = null;
        _codigosHasMore = false;
        _codigosSortColumn = 'codigo';
        _codigosSortAscending = true;
      } else if (widget.reportType == ReportType.stocks) {
        _stocksNextMaxUtime = null;
        _stocksHasMore = false;
        _stocksSortColumn = 'codigo';
        _stocksSortAscending = true;
      } else if (widget.reportType == ReportType.clientes) {
        _clientesOffset = 0;
        _clientesHasMore = false;
        _clientesIsLoadingMore = false;
        _clientesSortColumn = null;
        _clientesSortAscending = false;
        // Clientes 보고서로 전환 시 OverlayEntry 닫기
        _closeClienteDetailOverlay();
      } else {
        // 다른 보고서로 전환 시에도 OverlayEntry 닫기
        _closeClienteDetailOverlay();
      }
      
      // Items, Ingresos, Gastos, Alertas 및 Clientes 보고서의 경우 기본 날짜 설정
      // alertas에서 다른 보고서로 이동할 때는 날짜 유지 (초기화하지 않음)
      if (widget.reportType == ReportType.items || widget.reportType == ReportType.ingresos || widget.reportType == ReportType.gastos || widget.reportType == ReportType.alertas || widget.reportType == ReportType.clientes) {
        // alertas에서 다른 보고서로 이동할 때는 날짜 유지
        if (isFromAlertas && !isToAlertas) {
          print('🔄 Alertas에서 다른 보고서로 이동 - 날짜 유지: $_itemsStartDate ~ $_itemsEndDate');
          // 날짜는 그대로 유지 (초기화하지 않음)
        } else if (widget.initialItemsStartDate != null && widget.initialItemsEndDate != null) {
          _itemsStartDate = widget.initialItemsStartDate;
          _itemsEndDate = widget.initialItemsEndDate;
        } else {
          final now = DateTime.now();
          _itemsStartDate = now;
          _itemsEndDate = now;
        }
      }
      
      // Ventas 및 FVentas 보고서의 경우 초기 날짜 범위 설정
      if (widget.reportType == ReportType.ventas || widget.reportType == ReportType.fventas) {
        final now = DateTime.now();
        if (widget.initialDate != null) {
          _ventasStartDate = widget.initialDate;
          _ventasEndDate = widget.initialDate;
        } else if (oldWidget.reportType != ReportType.ventas && oldWidget.reportType != ReportType.fventas) {
          _ventasStartDate = now;
          _ventasEndDate = now;
        }
        // 초기 descontado 필터 설정 (ventas만, reportType 변경 시 또는 initialVentasDescontado 변경 시)
        if (widget.reportType == ReportType.ventas && (oldWidget.reportType != ReportType.ventas || oldWidget.initialVentasDescontado != widget.initialVentasDescontado)) {
          if (widget.initialVentasDescontado != null) {
            _ventasDescontado = widget.initialVentasDescontado!;
            print('📅 Ventas 보고서 descontado 필터 업데이트: $_ventasDescontado');
          } else {
            _ventasDescontado = false;
          }
        }
      } else if ((oldWidget.reportType == ReportType.ventas || oldWidget.reportType == ReportType.fventas) && widget.reportType != ReportType.ventas && widget.reportType != ReportType.fventas) {
        _ventasStartDate = null;
        _ventasEndDate = null;
        _ventasDescontado = false;
      }
      
      // 데이터 다시 로드
      _loadData();
    }
  }
  
  // filteringWord 변경 감지 핸들러 (즉시 반응하지 않음)
  String _lastFilteringWord = '';
  Timer? _filteringWordDebounceTimer;
  
  /// filteringWord 변경 감지 (debounced) - 0.1초보다 빠른 입력은 묶어서 처리
  void _onFilteringWordChangedDebounced() {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [_onFilteringWordChangedDebounced] filteringWord 변경 감지');
    debugPrint('   → 파일: report_screen.dart');
    debugPrint('   → 라인: ${400}');
    debugPrint('   → 현재 filteringWord: "${_filteringWordController.text}"');
    debugPrint('   → 현재 filteringWord 길이: ${_filteringWordController.text.length}');
    debugPrint('   → 이전 filteringWord: "$_lastFilteringWord"');
    debugPrint('   → reportType: ${widget.reportType}');
    
    // 이전 타이머 취소
    _filteringWordDebounceTimer?.cancel();
    
    // debounce를 위해 타이머 사용 (100ms 후 실행)
    _filteringWordDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) {
        debugPrint('   → [Debounce Timer] mounted가 false - 취소');
        return;
      }
      final finalWord = _filteringWordController.text.trim();
      debugPrint('   → [Debounce Timer] finalWord: "$finalWord"');
      debugPrint('   → [Debounce Timer] _lastFilteringWord: "$_lastFilteringWord"');
      debugPrint('   → [Debounce Timer] 변경사항 있음: ${finalWord != _lastFilteringWord}');
      
      if (finalWord == _lastFilteringWord) {
        debugPrint('   → [Debounce Timer] 변경사항 없음 - 취소');
        return; // 변경사항이 없으면 취소
      }
      
      // 프레임 완료 후 상태 업데이트를 보장하여 mouse_tracker assertion 오류 방지
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final currentWord = _filteringWordController.text.trim();
        // 한글 입력 시 조합 중인 문자(composing)가 있을 수 있으므로,
        // finalWord와 currentWord가 다르더라도 처리 (debounce 타이머가 이미 지연되었으므로)
        // 단, finalWord가 _lastFilteringWord와 같으면 이미 처리된 것이므로 스킵
        if (currentWord == _lastFilteringWord) {
          debugPrint('   → [PostFrameCallback] 이미 처리된 값 - 스킵');
          return;
        }
        
        _lastFilteringWord = currentWord;
        
        // Alertas 보고서의 경우 VCancelado, Jefe 버튼 상태 동기화
        // WEB 버튼은 filteringWord와 무관하므로 동기화하지 않음
        // setState를 debounce 후에만 호출하여 키보드 이벤트 충돌 방지
        if (widget.reportType == ReportType.alertas) {
          final lowerWord = currentWord.toLowerCase();
          final newVCancelado = lowerWord == 'vcancelado';
          final newJefe = lowerWord == 'jefe';
          // WEB은 filteringWord와 무관하므로 동기화하지 않음
          if (_alertasVCancelado != newVCancelado || _alertasJefe != newJefe) {
            setState(() {
              _alertasVCancelado = newVCancelado;
              _alertasJefe = newJefe;
            });
          }
        }
        
        // 상태 변경 콜백 호출
        _notifyStateChanged();
        // codigos, todocodigos, stocks 또는 clientes 보고서인 경우 데이터 재로드
        if (widget.reportType == ReportType.codigos || 
            widget.reportType == ReportType.todocodigos || 
            widget.reportType == ReportType.stocks ||
            widget.reportType == ReportType.clientes) {
          _reloadDataWithFilters();
        }
      });
    });
  }
  
  // 상태 변경 콜백 호출
  @override
  void _notifyStateChanged() {
    if (widget.onStateChanged != null) {
      String? sortColumn;
      bool? sortAscending;
      
      if (widget.reportType == ReportType.stocks) {
        sortColumn = _stocksSortColumn;
        sortAscending = _stocksSortAscending;
      } else if (widget.reportType == ReportType.codigos || widget.reportType == ReportType.todocodigos) {
        sortColumn = _codigosSortColumn;
        sortAscending = _codigosSortAscending;
      } else {
        sortColumn = _sortColumn;
        sortAscending = _sortAscending;
      }
      
      widget.onStateChanged!(
        _filteringWordController.text.trim().isEmpty ? null : _filteringWordController.text.trim(),
        sortColumn,
        sortAscending,
      );
    }
  }
  
  // 필터 및 정렬 기준으로 데이터 재로드
  @override
  Future<void> _reloadDataWithFilters() async {
    // 성능 최적화: 필터 변경 시 합계 계산 캐시 무효화
    ReportTotalRowBuilder.clearCache();
    
    // 페이지네이션 상태 초기화
    if (widget.reportType == ReportType.codigos || widget.reportType == ReportType.todocodigos) {
      _codigosNextIdCodigo = null;
      _codigosHasMore = false;
    } else if (widget.reportType == ReportType.stocks) {
      _stocksNextMaxUtime = null;
      _stocksHasMore = false;
    } else if (widget.reportType == ReportType.clientes) {
      _clientesOffset = 0;
      _clientesHasMore = false;
      _clientesIsLoadingMore = false;
    }
    
    await _loadData();
  }

  @override
  void dispose() {
    _filteringWordDebounceTimer?.cancel(); // debounce 타이머 취소
    _databaseService.dispose(); // HTTP 클라이언트 연결 풀 정리
    _filteringWordController.dispose();
    _scrollController.dispose();
    _horizontalScrollController.dispose(); // 수평 스크롤 컨트롤러 정리
    // Codigos 편집 컨트롤러들 정리
    for (var controller in _codigoEditControllers.values) {
      controller.dispose();
    }
    _codigoEditControllers.clear();
    // Clientes 모달리스 대화상자 정리
    _closeClienteDetailOverlay();
    super.dispose();
  }

  /// 모달리스 Cliente 상세 정보 대화상자 닫기
  @override
  void _closeClienteDetailOverlay() {
    debugPrint('📋 [_closeClienteDetailOverlay] 대화상자 닫기');
    if (_clienteDetailOverlayEntry != null) {
      _clienteDetailOverlayEntry!.remove();
      _clienteDetailOverlayEntry = null;
      _currentClienteDetailData = null;
      _currentClienteRowData = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🟢🟢🟢 [report_screen.dart:3131] build 메서드 호출 시작');
    print('   → 라인: 3131');
    if (widget.reportType == ReportType.ventas) {
      print('   → _ventasUnit: $_ventasUnit');
      print('   → _ventasUnit 타입: ${_ventasUnit.runtimeType}');
      print('   → _ventasUnit == "day": ${_ventasUnit == "day"}');
      print('   → _ventasUnit == "month": ${_ventasUnit == "month"}');
      print('   → _ventasUnit == "year": ${_ventasUnit == "year"}');
      print('   → _ventasUnit == "vcode": ${_ventasUnit == "vcode"}');
      print('   → 호출 스택 (처음 5줄):');
      print('      ${StackTrace.current.toString().split("\n").take(5).join("\n      ")}');
    }
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [ReportScreen.build] 호출됨');
    debugPrint('   → reportType: ${widget.reportType}');
    debugPrint('   → Platform.isWindows: ${Platform.isWindows}');
    debugPrint('   → Platform.isMacOS: ${Platform.isMacOS}');
    debugPrint('   → Platform.isLinux: ${Platform.isLinux}');
    debugPrint('   → defaultTargetPlatform: $defaultTargetPlatform');
    debugPrint('   → useFullWidth: ${widget.useFullWidth}');
    debugPrint('   → _isLoading: $_isLoading');
    debugPrint('   → _data: ${_data != null ? "있음 (키: ${_data!.keys.toList()})" : "null"}');
    debugPrint('   → _errorMessage: $_errorMessage');
    if (widget.reportType == ReportType.ventas) {
      debugPrint('   → [Ventas] _ventasUnit: $_ventasUnit');
      debugPrint('   → [Ventas] _ventasUnit 타입: ${_ventasUnit.runtimeType}');
      debugPrint('   → [Ventas] _ventasUnit == "day": ${_ventasUnit == "day"}');
      debugPrint('   → [Ventas] _ventasUnit == "month": ${_ventasUnit == "month"}');
      debugPrint('   → [Ventas] _ventasUnit == "year": ${_ventasUnit == "year"}');
      debugPrint('   → [Ventas] _ventasUnit == "vcode": ${_ventasUnit == "vcode"}');
      debugPrint('   → 호출 스택 (처음 5줄):');
      debugPrint('      ${StackTrace.current.toString().split("\n").take(5).join("\n      ")}');
    }
    debugPrint('═══════════════════════════════════════════════════════');
    
    final l10n = AppLocalizations.of(context)!;
    final reportTitle = _getReportTitle();
    final reportIcon = _getReportIcon();
    final reportColor = _getReportColor();

    return LayoutBuilder(
      builder: (context, constraints) {
        debugPrint('   → LayoutBuilder: constraints.maxWidth=${constraints.maxWidth}, constraints.maxHeight=${constraints.maxHeight}');
        
        // ============================================================
        // 📱 모바일 화면 구성 정보 가져오기
        // ============================================================
        // MobileLayoutHelper를 사용하여 핸드폰의 수직/수평 화면 구성을 집중적으로 처리
        // 대형 화면(태블릿, 데스크톱)에는 영향을 미치지 않도록 설계됨
        final layoutInfo = MobileLayoutHelper.getLayoutInfo(context);
        
        // 기존 호환성을 위한 변수들 (하위 호환성 유지)
        final isLargeScreen = layoutInfo.isLargeScreen;
        final orientation = layoutInfo.orientation;
        final platformType = layoutInfo.platformType;
        final isMobile = layoutInfo.isMobilePlatform;
        final isMobilePortrait = layoutInfo.isMobilePhonePortrait;
        final isMobilePhone = layoutInfo.isMobilePhone;
        
        debugPrint('   → isLargeScreen: $isLargeScreen');
        debugPrint('   → orientation: ${layoutInfo.orientation}');
        debugPrint('   → platformType: ${layoutInfo.platformType}');
        debugPrint('   → isMobile: $isMobile');
        debugPrint('   → isMobilePhone: $isMobilePhone');
        debugPrint('   → isMobilePhonePortrait: ${layoutInfo.isMobilePhonePortrait}');
        debugPrint('   → isMobilePhoneLandscape: ${layoutInfo.isMobilePhoneLandscape}');
        
        // ============================================================
        // 📱 핸드폰 AppBar 다중 줄 구성 결정
        // ============================================================
        // 핸드폰의 경우: 넓은 화면(가로 모드)이면 1줄, 좁은 화면(세로 모드)이면 2줄 또는 3줄
        // 데스크톱/태블릿의 경우: 기존 로직 유지 (대형 화면 보호)
        // 주의: isMobilePhone을 사용하여 태블릿을 제외한 핸드폰만 대상으로 함
        final needsMultiLineAppBar = isMobilePhone
            ? layoutInfo.isMobilePhonePortrait && (
                widget.reportType == ReportType.ventas ||
                widget.reportType == ReportType.items ||
                widget.reportType == ReportType.ingresos ||
                widget.reportType == ReportType.gastos ||
                widget.reportType == ReportType.alertas ||
                widget.reportType == ReportType.fventas
              )
            : !isLargeScreen && (
                widget.reportType == ReportType.ventas ||
                widget.reportType == ReportType.items ||
                widget.reportType == ReportType.ingresos ||
                widget.reportType == ReportType.gastos ||
                widget.reportType == ReportType.alertas ||
                widget.reportType == ReportType.fventas
              );
        
        // ============================================================
        // 📱 AppBar 줄 수 결정 로직
        // ============================================================
        // 각 보고서 타입별로 핸드폰 화면 크기에 따라 AppBar 줄 수 결정:
        // - 핸드폰 세로 모드 (좁은 화면): 컨트롤이 많으면 3줄, 적으면 2줄
        // - 핸드폰 가로 모드 (넓은 화면): 1줄 또는 2줄
        // - 태블릿/데스크톱: 1줄 (대형 화면 보호)
        // 주의: isMobilePhone을 사용하여 태블릿을 제외한 핸드폰만 대상으로 함
        
        // 3줄 AppBar가 필요한 보고서 타입들 (컨트롤이 많아서 공간 확보 필요)
        final needsThreeLineAppBar = isMobilePhone && layoutInfo.isMobilePhonePortrait && (
          widget.reportType == ReportType.ventas ||      // Unit 버튼, 체크박스 3개, 날짜 버튼 2개, sucursal 등
          widget.reportType == ReportType.clientes ||    // Responsable Ins, Provincias, 체크박스 2개, 필터링 단어, 날짜 선택기 2개
          widget.reportType == ReportType.alertas ||     // VCancelado, Jefe, WEB 버튼, 날짜 선택기, sucursal, 필터링 단어
          widget.reportType == ReportType.stocks ||      // Tipo, Temporada 콤보박스, 필터링 단어 (필요시 확장)
          widget.reportType == ReportType.codigos ||     // Tipo, Temporada 콤보박스, 필터링 단어 (필요시 확장)
          widget.reportType == ReportType.todocodigos    // Tipo, Temporada 콤보박스, 필터링 단어 (필요시 확장)
        );
        
        // 2줄 AppBar가 필요한 경우:
        // - 3줄이 필요하지 않은 보고서 중에서 멀티라인이 필요한 경우
        // - 핸드폰 가로 모드에서 ventas 보고서 (가로 모드에서는 공간이 넓어서 2줄로 충분)
        final needsTwoLineAppBar = (needsMultiLineAppBar && !needsThreeLineAppBar) || 
                                    (layoutInfo.isMobilePhoneLandscape && widget.reportType == ReportType.ventas);
        
        // ============================================================
        // 📱 AppBar 구성 디버깅 정보 출력
        // ============================================================
        debugPrint('═══════════════════════════════════════════════════════════');
        debugPrint('📱 [AppBar 구성] AppBar 줄 수 결정 로직 실행');
        debugPrint('   → reportType: ${widget.reportType}');
        debugPrint('   → isMobilePhone: $isMobilePhone');
        debugPrint('   → isMobilePhonePortrait: ${layoutInfo.isMobilePhonePortrait}');
        debugPrint('   → isMobilePhoneLandscape: ${layoutInfo.isMobilePhoneLandscape}');
        debugPrint('   → isLargeScreen: $isLargeScreen');
        debugPrint('   → needsMultiLineAppBar: $needsMultiLineAppBar');
        debugPrint('   → needsThreeLineAppBar: $needsThreeLineAppBar');
        debugPrint('   → needsTwoLineAppBar: $needsTwoLineAppBar');
        debugPrint('   → 최종 toolbarHeight: ${needsThreeLineAppBar ? kToolbarHeight * 3 : (needsTwoLineAppBar ? kToolbarHeight * 2 : null)}');
        debugPrint('═══════════════════════════════════════════════════════════');

    // useFullWidth가 true이면 Scaffold를 반환하지 않고 AppBar와 body를 포함한 위젯 반환
    if (widget.useFullWidth) {
      debugPrint('   → useFullWidth=true: Column 반환 (AppBar + Expanded body)');
      final appBar = _buildAppBar(context, reportTitle, reportIcon, reportColor, isLargeScreen, isMobilePortrait, needsTwoLineAppBar, needsThreeLineAppBar);
      return Column(
        children: [
          PreferredSize(
            preferredSize: Size.fromHeight(appBar.preferredSize.height),
            child: appBar,
          ),
          Expanded(
            child: _buildBody(context, l10n, reportColor),
          ),
        ],
      );
    }

    debugPrint('   → useFullWidth=false: Scaffold 반환');
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
            toolbarHeight: needsThreeLineAppBar ? kToolbarHeight * 3 : (needsTwoLineAppBar ? kToolbarHeight * 2 : null),
        title: widget.reportType == ReportType.stocks
            ? LayoutBuilder(
                builder: (context, constraints) {
                  // ============================================================
                  // 📱 Stocks 보고서 AppBar - 모바일 화면 구성 처리
                  // ============================================================
                  // MobileLayoutHelper를 사용하여 핸드폰의 수직/수평 화면 구성을 처리
                  // 대형 화면에는 영향을 미치지 않도록 주의
                  final layoutInfo = MobileLayoutHelper.getLayoutInfo(context);
                  final isLargeScreen = layoutInfo.isLargeScreen;
                  final isMobilePortrait = layoutInfo.isMobilePhonePortrait;
                  
                  // 핸드폰 세로 모드: 3줄로 배치 (컨트롤이 많아서 공간 확보 필요)
                  // 핸드폰 가로 모드: 1줄로 배치 (가로 모드에서는 공간이 넓어서 충분)
                  // 태블릿/데스크톱: 1줄로 배치 (대형 화면 보호)
                  if (isMobilePortrait) {
                    debugPrint('═══════════════════════════════════════════════════════════');
                    debugPrint('📱 [Stocks AppBar] 핸드폰 세로 모드 - 3줄 구성');
                    debugPrint('   → _tiposList.length: ${_tiposList.length}');
                    debugPrint('   → _temporadasList.length: ${_temporadasList.length}');
                    debugPrint('═══════════════════════════════════════════════════════════');
                    
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 첫 번째 줄: 아이콘, 제목
                        Builder(
                          builder: (rowContext) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              final renderObject = rowContext.findRenderObject();
                              if (renderObject != null && renderObject is RenderBox) {
                                debugPrint('   📱 [Stocks AppBar] 첫 번째 Row 렌더링 크기:');
                                debugPrint('      → width: ${renderObject.size.width}');
                                debugPrint('      → height: ${renderObject.size.height}');
                              }
                            });
                            return Row(
                              children: [
                                Icon(reportIcon, color: Colors.white),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    reportTitle,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                const Spacer(),
                                // 메뉴 버튼
                                PopupMenuButton<ReportType>(
                                  icon: const Icon(Icons.more_vert, color: Colors.white, size: 18),
                                  tooltip: 'Menú',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  iconSize: 18,
                                  onSelected: (ReportType reportType) {
                                    debugPrint('🔍 [Stocks AppBar] PopupMenuButton onSelected: $reportType');
                                    _switchToReport(reportType);
                                  },
                                  itemBuilder: (BuildContext context) {
                                    debugPrint('🔍 [Stocks AppBar] PopupMenuButton itemBuilder 호출됨!');
                                    final items = _buildReportMenuItems();
                                    debugPrint('🔍 [Stocks AppBar] PopupMenuButton 메뉴 아이템 개수: ${items.length}');
                                    for (int i = 0; i < items.length; i++) {
                                      debugPrint('🔍 [Stocks AppBar] PopupMenuButton 아이템 #$i: ${items[i].runtimeType}');
                                    }
                                    return items;
                                  },
                                ),
                                // 공유 버튼
                                if (_data != null)
                                  IconButton(
                                    icon: const Icon(Icons.share, color: Colors.white, size: 18),
                                    tooltip: 'Compartir como PDF',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    iconSize: 18,
                                    onPressed: () {
                                      debugPrint('🔍 [Stocks AppBar] 공유 버튼 클릭됨');
                                      _shareReport();
                                    },
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        // 두 번째 줄: Tipo, Temporada 콤보박스
                        Builder(
                          builder: (rowContext) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              final renderObject = rowContext.findRenderObject();
                              if (renderObject != null && renderObject is RenderBox) {
                                debugPrint('   📱 [Stocks AppBar] 두 번째 Row 렌더링 크기:');
                                debugPrint('      → width: ${renderObject.size.width}');
                                debugPrint('      → height: ${renderObject.size.height}');
                              }
                            });
                            return Row(
                              children: [
                                if (_tiposList.length > 1 || _temporadasList.length > 1) ...[
                                  if (_tiposList.length > 1) ...[
                                    Flexible(
                                      child: _buildTipoSelector(),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  if (_temporadasList.length > 1) ...[
                                    Flexible(
                                      child: _buildTemporadaSelector(),
                                    ),
                                  ],
                                ],
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        // 세 번째 줄: 필터링 단어 필드
                        Builder(
                          builder: (rowContext) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              final renderObject = rowContext.findRenderObject();
                              if (renderObject != null && renderObject is RenderBox) {
                                debugPrint('   📱 [Stocks AppBar] 세 번째 Row 렌더링 크기:');
                                debugPrint('      → width: ${renderObject.size.width}');
                                debugPrint('      → height: ${renderObject.size.height}');
                              }
                            });
                            return Row(
                              children: [
                                Expanded(
                                  child: _buildFilteringWordFieldInAppBar(),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    );
                  }
                  
                  // ============================================================
                  // 📱 넓은 화면 (가로 모드 또는 태블릿/데스크톱): 1줄로 배치
                  // ============================================================
                  // 핸드폰 가로 모드, 태블릿, 데스크톱 모두 1줄 레이아웃 사용
                  // 대형 화면에는 모바일 전용 로직이 적용되지 않음
                  return Row(
                    children: [
                      Icon(reportIcon, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(reportTitle),
                      const SizedBox(width: 16),
                      // Tipo와 Temporada 콤보박스 (filteringWord 왼쪽)
                      if (_tiposList.length > 1 || _temporadasList.length > 1) ...[
                        if (_tiposList.length > 1) ...[
                          _buildTipoSelector(),
                          const SizedBox(width: 8),
                        ],
                        if (_temporadasList.length > 1) ...[
                          _buildTemporadaSelector(),
                          const SizedBox(width: 8),
                        ],
                      ],
                      Expanded(
                        child: _buildFilteringWordFieldInAppBar(),
                      ),
                    ],
                  );
                },
              )
            : (widget.reportType == ReportType.items || widget.reportType == ReportType.ingresos || widget.reportType == ReportType.gastos || widget.reportType == ReportType.alertas || widget.reportType == ReportType.fventas || widget.reportType == ReportType.clientes)
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      // ============================================================
                      // 📱 Items/Ingresos/Gastos/Alertas/Fventas/Clientes 보고서 AppBar
                      // ============================================================
                      // MobileLayoutHelper를 사용하여 핸드폰의 수직/수평 화면 구성을 처리
                      final layoutInfo = MobileLayoutHelper.getLayoutInfo(context);
                      final isMobilePortrait = layoutInfo.isMobilePhonePortrait;
                      
                      // 핸드폰 세로 모드: 2줄로 배치 (컨트롤이 많아서 공간 확보 필요)
                      // 핸드폰 가로 모드, 태블릿, 데스크톱: 1줄로 배치 (대형 화면 보호)
                      if (isMobilePortrait) {
                        // Clientes 보고서의 경우 특별한 레이아웃 (3줄 구성)
                        if (widget.reportType == ReportType.clientes) {
                          debugPrint('═══════════════════════════════════════════════════════════');
                          debugPrint('🔍 [Clientes AppBar] AppBar 빌드 시작 - 3줄 구성');
                          debugPrint('   → reportType: ${widget.reportType}');
                          debugPrint('   → _itemsStartDate: $_itemsStartDate');
                          debugPrint('   → _itemsEndDate: $_itemsEndDate');
                          debugPrint('═══════════════════════════════════════════════════════════');
                          
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 첫 번째 줄: 아이콘, 제목, 메뉴 버튼, 공유 버튼
                              Builder(
                                builder: (rowContext) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    final renderObject = rowContext.findRenderObject();
                                    if (renderObject != null && renderObject is RenderBox) {
                                      debugPrint('   📱 [Clientes AppBar] 첫 번째 Row 렌더링 크기:');
                                      debugPrint('      → width: ${renderObject.size.width}');
                                      debugPrint('      → height: ${renderObject.size.height}');
                                    }
                                  });
                                  return Row(
                                    children: [
                                      Icon(reportIcon, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          reportTitle,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                      const Spacer(),
                                      // 메뉴 버튼
                                      PopupMenuButton<ReportType>(
                                        icon: const Icon(Icons.more_vert, color: Colors.white, size: 18),
                                        tooltip: 'Menú',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        iconSize: 18,
                                        onSelected: (ReportType reportType) {
                                          _switchToReport(reportType);
                                        },
                                        itemBuilder: (BuildContext context) {
                                          debugPrint('🔍 [PopupMenuButton] itemBuilder 호출됨!');
                                          final items = _buildReportMenuItems();
                                          debugPrint('🔍 [PopupMenuButton] 메뉴 아이템 개수: ${items.length}');
                                          for (int i = 0; i < items.length; i++) {
                                            debugPrint('🔍 [PopupMenuButton] 아이템 #$i: ${items[i].runtimeType}');
                                          }
                                          return items;
                                        },
                                      ),
                                      // 공유 버튼
                                      if (_data != null)
                                        IconButton(
                                          icon: const Icon(Icons.share, color: Colors.white, size: 18),
                                          tooltip: 'Compartir como PDF',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          iconSize: 18,
                                          onPressed: () => _shareReport(),
                                        ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 4),
                              // 두 번째 줄: Responsable Ins, Provincias 콤보박스, 체크박스들
                              Builder(
                                builder: (rowContext) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    final renderObject = rowContext.findRenderObject();
                                    if (renderObject != null && renderObject is RenderBox) {
                                      debugPrint('   📱 [Clientes AppBar] 두 번째 Row 렌더링 크기:');
                                      debugPrint('      → width: ${renderObject.size.width}');
                                      debugPrint('      → height: ${renderObject.size.height}');
                                    }
                                  });
                                  return Row(
                                    children: [
                                      // Responsable Ins 콤보박스
                                      Flexible(
                                        child: _buildClientesResponsableInsSelector(),
                                      ),
                                      const SizedBox(width: 8),
                                      // Provincias 콤보박스
                                      Flexible(
                                        child: _buildClientesProvinciaSelector(),
                                      ),
                                      const SizedBox(width: 8),
                                      // Deudores 체크박스
                                      _buildClientesDeudoresCheckbox(),
                                      const SizedBox(width: 8),
                                      // Reservadores 체크박스
                                      _buildClientesReservadoresCheckbox(),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 4),
                              // 세 번째 줄: FilteringWord 필드, 날짜 선택기
                              Builder(
                                builder: (rowContext) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    final renderObject = rowContext.findRenderObject();
                                    if (renderObject != null && renderObject is RenderBox) {
                                      debugPrint('   📱 [Clientes AppBar] 세 번째 Row 렌더링 크기:');
                                      debugPrint('      → width: ${renderObject.size.width}');
                                      debugPrint('      → height: ${renderObject.size.height}');
                                    }
                                  });
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: _buildFilteringWordFieldInAppBar(),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 4),
                              // 네 번째 줄: 달력 2개
                              Builder(
                                builder: (context) {
                                  debugPrint('═══════════════════════════════════════════════════════════');
                                  debugPrint('🔍 [Clientes AppBar] Builder 호출됨');
                                  debugPrint('   → _itemsStartDate: $_itemsStartDate');
                                  debugPrint('   → _itemsEndDate: $_itemsEndDate');
                                  
                                  try {
                                    final mediaQuery = MediaQuery.of(context);
                                    debugPrint('   → MediaQuery.size: ${mediaQuery.size}');
                                    debugPrint('   → MediaQuery.orientation: ${mediaQuery.orientation}');
                                  } catch (e) {
                                    debugPrint('   ⚠️ MediaQuery.of(context) 오류: $e');
                                  }
                                  
                                  debugPrint('═══════════════════════════════════════════════════════════');
                                  
                                  return ItemsDateRangeSelector(
                                    reportType: widget.reportType,
                                    startDate: _itemsStartDate,
                                    endDate: _itemsEndDate,
                                    onDateRangeChanged: (startDate, endDate) {
                                      debugPrint('📅 [Items Report] 날짜 범위 변경 이벤트:');
                                      debugPrint('   → 변경 전: startDate=$_itemsStartDate, endDate=$_itemsEndDate');
                                      debugPrint('   → 변경 후: startDate=$startDate, endDate=$endDate');
                                      setState(() {
                                        _itemsStartDate = startDate;
                                        _itemsEndDate = endDate;
                                      });
                                      if (widget.onItemsDateRangeChanged != null) {
                                        widget.onItemsDateRangeChanged!(startDate, endDate);
                                      }
                                      debugPrint('   → _loadData() 호출하여 데이터 다시 로드');
                                      _loadData();
                                    },
                                  );
                                },
                              ),
                            ],
                          );
                        }
                        // Alertas 보고서의 경우 특별한 레이아웃 (3줄 구성)
                        if (widget.reportType == ReportType.alertas) {
                          debugPrint('═══════════════════════════════════════════════════════════');
                          debugPrint('🔍 [Alertas AppBar] AppBar 빌드 시작 - 3줄 구성');
                          debugPrint('   → reportType: ${widget.reportType}');
                          debugPrint('═══════════════════════════════════════════════════════════');
                          
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 첫 번째 줄: 아이콘, 제목, 메뉴 버튼, 공유 버튼
                              Builder(
                                builder: (rowContext) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    final renderObject = rowContext.findRenderObject();
                                    if (renderObject != null && renderObject is RenderBox) {
                                      debugPrint('   📱 [Alertas AppBar] 첫 번째 Row 렌더링 크기:');
                                      debugPrint('      → width: ${renderObject.size.width}');
                                      debugPrint('      → height: ${renderObject.size.height}');
                                    }
                                  });
                                  return Row(
                                    children: [
                                      Icon(reportIcon, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          reportTitle,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                      const Spacer(),
                                      // 메뉴 버튼
                                      PopupMenuButton<ReportType>(
                                        icon: const Icon(Icons.more_vert, color: Colors.white, size: 18),
                                        tooltip: 'Menú',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        iconSize: 18,
                                        onSelected: (ReportType reportType) {
                                          _switchToReport(reportType);
                                        },
                                        itemBuilder: (BuildContext context) {
                                          debugPrint('🔍 [PopupMenuButton] itemBuilder 호출됨!');
                                          final items = _buildReportMenuItems();
                                          debugPrint('🔍 [PopupMenuButton] 메뉴 아이템 개수: ${items.length}');
                                          for (int i = 0; i < items.length; i++) {
                                            debugPrint('🔍 [PopupMenuButton] 아이템 #$i: ${items[i].runtimeType}');
                                          }
                                          return items;
                                        },
                                      ),
                                      // 공유 버튼
                                      if (_data != null)
                                        IconButton(
                                          icon: const Icon(Icons.share, color: Colors.white, size: 18),
                                          tooltip: 'Compartir como PDF',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          iconSize: 18,
                                          onPressed: () => _shareReport(),
                                        ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 4),
                              // 두 번째 줄: VCancelado, Jefe, WEB 버튼
                              Builder(
                                builder: (rowContext) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    final renderObject = rowContext.findRenderObject();
                                    if (renderObject != null && renderObject is RenderBox) {
                                      debugPrint('   📱 [Alertas AppBar] 두 번째 Row 렌더링 크기:');
                                      debugPrint('      → width: ${renderObject.size.width}');
                                      debugPrint('      → height: ${renderObject.size.height}');
                                    }
                                  });
                                  return Row(
                                    children: [
                                      // VCancelado 버튼
                                      Flexible(
                                        child: _buildAlertasFilterButton('VCancelado', _alertasVCancelado, () {
                                          setState(() {
                                            _alertasVCancelado = !_alertasVCancelado;
                                            _alertasJefe = false;
                                            _alertasWeb = false;
                                            if (_alertasVCancelado) {
                                              _filteringWordController.text = 'VCancelado';
                                            } else {
                                              _filteringWordController.text = '';
                                            }
                                          });
                                          _loadData();
                                        }),
                                      ),
                                      const SizedBox(width: 4),
                                      // Jefe 버튼
                                      Flexible(
                                        child: _buildAlertasFilterButton('Jefe', _alertasJefe, () {
                                          setState(() {
                                            _alertasJefe = !_alertasJefe;
                                            _alertasVCancelado = false;
                                            _alertasWeb = false;
                                            if (_alertasJefe) {
                                              _filteringWordController.text = 'Jefe';
                                            } else {
                                              _filteringWordController.text = '';
                                            }
                                          });
                                          _loadData();
                                        }),
                                      ),
                                      const SizedBox(width: 4),
                                      // WEB 버튼
                                      Flexible(
                                        child: _buildAlertasFilterButton('WEB', _alertasWeb, () {
                                          setState(() {
                                            _alertasWeb = !_alertasWeb;
                                            _alertasVCancelado = false;
                                            _alertasJefe = false;
                                            if (_alertasWeb) {
                                              _filteringWordController.text = 'WEB';
                                            } else {
                                              _filteringWordController.text = '';
                                            }
                                          });
                                          _loadData();
                                        }),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 4),
                              // 세 번째 줄: 날짜 선택기, Sucursal 선택기, 필터링 단어 필드
                              Builder(
                                builder: (rowContext) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    final renderObject = rowContext.findRenderObject();
                                    if (renderObject != null && renderObject is RenderBox) {
                                      debugPrint('   📱 [Alertas AppBar] 세 번째 Row 렌더링 크기:');
                                      debugPrint('      → width: ${renderObject.size.width}');
                                      debugPrint('      → height: ${renderObject.size.height}');
                                    }
                                  });
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: ItemsDateRangeSelector(
                                          reportType: widget.reportType,
                                          startDate: _itemsStartDate,
                                          endDate: _itemsEndDate,
                                          onDateRangeChanged: (startDate, endDate) {
                                            debugPrint('📅 [Items Report] 날짜 범위 변경 이벤트:');
                                            debugPrint('   → 변경 전: startDate=$_itemsStartDate, endDate=$_itemsEndDate');
                                            debugPrint('   → 변경 후: startDate=$startDate, endDate=$endDate');
                                            setState(() {
                                              _itemsStartDate = startDate;
                                              _itemsEndDate = endDate;
                                            });
                                            if (widget.onItemsDateRangeChanged != null) {
                                              widget.onItemsDateRangeChanged!(startDate, endDate);
                                            }
                                            debugPrint('   → _loadData() 호출하여 데이터 다시 로드');
                                            _loadData();
                                          },
                                        ),
                                      ),
                                      if (_availableSucursales != null && _availableSucursales!.length > 1) ...[
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: _buildSucursalSelector(),
                                        ),
                                      ],
                                      if (widget.reportType == ReportType.ingresos) ...[
                                        const SizedBox(width: 8),
                                        _buildIngresosMovidosCheckbox(),
                                      ],
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildFilteringWordFieldInAppBar(),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          );
                        }
                        // 다른 보고서는 기존 레이아웃 유지
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 첫 번째 줄: 아이콘, 제목, 날짜 버튼 2개
                            Row(
                              children: [
                                Icon(reportIcon, color: Colors.white),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    reportTitle,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: SizedBox(
                                    width: 90,
                                    child: _buildSingleDateButton(
                                      label: 'Desde',
                                      date: widget.reportType == ReportType.fventas ? _ventasStartDate : _itemsStartDate,
                                      reportColor: _getReportColor(),
                                      onDateSelected: (date) {
                                        setState(() {
                                          if (widget.reportType == ReportType.fventas) {
                                            _ventasStartDate = date;
                                          } else {
                                            _itemsStartDate = date;
                                          }
                                        });
                                        if (widget.onItemsDateRangeChanged != null && widget.reportType != ReportType.fventas) {
                                          widget.onItemsDateRangeChanged!(
                                            widget.reportType == ReportType.fventas ? _ventasStartDate! : _itemsStartDate!,
                                            widget.reportType == ReportType.fventas ? (_ventasEndDate ?? _ventasStartDate!) : (_itemsEndDate ?? _itemsStartDate!)
                                          );
                                        }
                                        _loadData();
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: SizedBox(
                                    width: 90,
                                    child: _buildSingleDateButton(
                                      label: 'Hasta',
                                      date: widget.reportType == ReportType.fventas ? _ventasEndDate : _itemsEndDate,
                                      reportColor: _getReportColor(),
                                      onDateSelected: (date) {
                                        setState(() {
                                          if (widget.reportType == ReportType.fventas) {
                                            _ventasEndDate = date;
                                          } else {
                                            _itemsEndDate = date;
                                          }
                                        });
                                        if (widget.onItemsDateRangeChanged != null && widget.reportType != ReportType.fventas) {
                                          widget.onItemsDateRangeChanged!(
                                            widget.reportType == ReportType.fventas ? (_ventasStartDate ?? _ventasEndDate!) : (_itemsStartDate ?? _itemsEndDate!),
                                            widget.reportType == ReportType.fventas ? _ventasEndDate! : _itemsEndDate!
                                          );
                                        }
                                        _loadData();
                                      },
                                    ),
                                  ),
                                ),
                                if (_availableSucursales != null && _availableSucursales!.length > 1) ...[
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: _buildSucursalSelector(),
                                  ),
                                ],
                                if (widget.reportType == ReportType.ingresos) ...[
                                  const SizedBox(width: 8),
                                  _buildIngresosMovidosCheckbox(),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            // 두 번째 줄: 필터링 단어 필드, 메뉴 버튼, 공유 버튼
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFilteringWordFieldInAppBar(),
                                ),
                                const SizedBox(width: 8),
                                // 메뉴 버튼
                                PopupMenuButton<ReportType>(
                                  icon: const Icon(Icons.more_vert, color: Colors.white, size: 18),
                                  tooltip: 'Menú',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  iconSize: 18,
                                  onSelected: (ReportType reportType) {
                                    _switchToReport(reportType);
                                  },
                                  itemBuilder: (BuildContext context) {
                                    debugPrint('🔍 [PopupMenuButton] itemBuilder 호출됨!');
                                    final items = _buildReportMenuItems();
                                    debugPrint('🔍 [PopupMenuButton] 메뉴 아이템 개수: ${items.length}');
                                    for (int i = 0; i < items.length; i++) {
                                      debugPrint('🔍 [PopupMenuButton] 아이템 #$i: ${items[i].runtimeType}');
                                    }
                                    return items;
                                  },
                                ),
                                // PDF 공유 버튼
                                if (_data != null) ...[
                                  const SizedBox(width: 2),
                                  IconButton(
                                    icon: const Icon(Icons.share, color: Colors.white, size: 18),
                                    tooltip: 'Compartir como PDF',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    iconSize: 18,
                                    onPressed: () => _shareReport(),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        );
                      }
                      
                      // 넓은 화면: 1줄로 배치
                      return Row(
                        children: [
                          Icon(reportIcon, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(reportTitle),
                          const SizedBox(width: 16),
                          // 큰 화면 또는 수평 모드: 시작일과 종료일 선택기 2개
                          SizedBox(
                            width: isLargeScreen ? 150 : 90,
                            child: _buildSingleDateButton(
                              label: 'Desde',
                              date: widget.reportType == ReportType.fventas ? _ventasStartDate : _itemsStartDate,
                              reportColor: _getReportColor(),
                              onDateSelected: (date) {
                                setState(() {
                                  if (widget.reportType == ReportType.fventas) {
                                    _ventasStartDate = date;
                                  } else {
                                    _itemsStartDate = date;
                                  }
                                });
                                if (widget.onItemsDateRangeChanged != null && widget.reportType != ReportType.fventas) {
                                  widget.onItemsDateRangeChanged!(
                                    widget.reportType == ReportType.fventas ? _ventasStartDate! : _itemsStartDate!,
                                    widget.reportType == ReportType.fventas ? (_ventasEndDate ?? _ventasStartDate!) : (_itemsEndDate ?? _itemsStartDate!)
                                  );
                                }
                                _loadData();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: isLargeScreen ? 150 : 90,
                            child: _buildSingleDateButton(
                              label: 'Hasta',
                              date: widget.reportType == ReportType.fventas ? _ventasEndDate : _itemsEndDate,
                              reportColor: _getReportColor(),
                              onDateSelected: (date) {
                                setState(() {
                                  if (widget.reportType == ReportType.fventas) {
                                    _ventasEndDate = date;
                                  } else {
                                    _itemsEndDate = date;
                                  }
                                });
                                if (widget.onItemsDateRangeChanged != null && widget.reportType != ReportType.fventas) {
                                  widget.onItemsDateRangeChanged!(
                                    widget.reportType == ReportType.fventas ? (_ventasStartDate ?? _ventasEndDate!) : (_itemsStartDate ?? _itemsEndDate!),
                                    widget.reportType == ReportType.fventas ? _ventasEndDate! : _itemsEndDate!
                                  );
                                }
                                _loadData();
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          // 지점 선택 UI (sucursal이 2개 이상일 때만 표시)
                          if (_availableSucursales != null && _availableSucursales!.length > 1) ...[
                              _buildSucursalSelector(),
                              const SizedBox(width: 16),
                          ],
                          if (widget.reportType == ReportType.ingresos) ...[
                              _buildIngresosMovidosCheckbox(),
                              const SizedBox(width: 16),
                          ],
                          // Clientes 보고서의 경우 필터들 추가
                          if (widget.reportType == ReportType.clientes) ...[
                            _buildClientesResponsableInsSelector(),
                            const SizedBox(width: 8),
                            _buildClientesProvinciaSelector(),
                            const SizedBox(width: 8),
                            _buildClientesDeudoresCheckbox(),
                            const SizedBox(width: 8),
                            _buildClientesReservadoresCheckbox(),
                            const SizedBox(width: 8),
                          ],
                          // Alertas 보고서의 경우 VCancelado 및 Jefe 버튼 추가
                          if (widget.reportType == ReportType.alertas) ...[
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _alertasVCancelado = !_alertasVCancelado;
                                  _alertasJefe = false; // 다른 버튼 비활성화
                                  if (_alertasVCancelado) {
                                    // VCancelado 버튼이 활성화되면 filteringWord에 "VCancelado" 입력
                                    _filteringWordController.text = 'VCancelado';
                                  } else {
                                    // VCancelado 버튼이 비활성화되면 filteringWord 초기화
                                    _filteringWordController.text = '';
                                  }
                                });
                                _loadData();
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: _alertasVCancelado 
                                    ? Colors.white.withOpacity(0.3) 
                                    : Colors.transparent,
                              ),
                              child: Text(
                                'VCancelado',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: _alertasVCancelado ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _alertasJefe = !_alertasJefe;
                                  _alertasVCancelado = false; // 다른 버튼 비활성화
                                  if (_alertasJefe) {
                                    // Jefe 버튼이 활성화되면 filteringWord에 "jefe" 입력
                                    _filteringWordController.text = 'jefe';
                                  } else {
                                    // Jefe 버튼이 비활성화되면 filteringWord 초기화
                                    _filteringWordController.text = '';
                                  }
                                });
                                _loadData();
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: _alertasJefe 
                                    ? Colors.white.withOpacity(0.3) 
                                    : Colors.transparent,
                              ),
                              child: Text(
                                'Jefe',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: _alertasJefe ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: _buildFilteringWordFieldInAppBar(),
                          ),
                        ],
                      );
                    },
                  )
                : widget.reportType == ReportType.ventas
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          // 디버깅: Ventas AppBar title 렌더링 시작
                          debugPrint('═══════════════════════════════════════════════════════');
                          debugPrint('📅 [Ventas AppBar Title] LayoutBuilder builder 호출');
                          debugPrint('   → 파일: report_screen.dart');
                          debugPrint('   → 라인: ~3102');
                          debugPrint('   → constraints.maxWidth: ${constraints.maxWidth}');
                          
                          // ============================================================
                          // 📱 Ventas 보고서 AppBar - 모바일 화면 구성 처리
                          // ============================================================
                          // MobileLayoutHelper를 사용하여 핸드폰의 수직/수평 화면 구성을 집중적으로 처리
                          // 대형 화면에는 영향을 미치지 않도록 주의
                          final layoutInfo = MobileLayoutHelper.getLayoutInfo(context);
                          final isLargeScreen = layoutInfo.isLargeScreen;
                          final isMobilePortrait = layoutInfo.isMobilePhonePortrait;
                          final isMobilePhoneLandscape = layoutInfo.isMobilePhoneLandscape;
                          
                          debugPrint('   → isLargeScreen: $isLargeScreen');
                          debugPrint('   → orientation: ${layoutInfo.orientation}');
                          debugPrint('   → platformType: ${layoutInfo.platformType}');
                          debugPrint('   → isMobilePhone: ${layoutInfo.isMobilePhone}');
                          debugPrint('   → isMobilePhonePortrait: $isMobilePortrait');
                          debugPrint('   → isMobilePhoneLandscape: $isMobilePhoneLandscape');
                          
                          // ============================================================
                          // 📱 핸드폰 세로 모드: 3줄로 배치
                          // ============================================================
                          // Ventas 보고서는 컨트롤이 많아서 핸드폰 세로 모드에서는 3줄이 필요함
                          // 태블릿/데스크톱에는 영향을 미치지 않음 (대형 화면 보호)
                          if (isMobilePortrait) {
                            debugPrint('   → isMobilePortrait = true → 핸드폰 세로 모드 레이아웃 사용');
                            final mediaQuery = MediaQuery.of(context);
                            debugPrint('   📱 [핸드폰 세로 모드 디버깅] 화면 크기 정보:');
                            debugPrint('      → MediaQuery.size: ${mediaQuery.size}');
                            debugPrint('      → MediaQuery.padding: ${mediaQuery.padding}');
                            debugPrint('      → constraints.maxWidth: ${constraints.maxWidth}');
                            debugPrint('      → constraints.maxHeight: ${constraints.maxHeight}');
                            debugPrint('      → 사용 가능한 너비: ${constraints.maxWidth}');
                            
                            return Builder(
                              builder: (context) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  final renderObject = context.findRenderObject();
                                  if (renderObject != null && renderObject is RenderBox) {
                                    debugPrint('   📱 [핸드폰 세로 모드] Column 실제 렌더링 크기:');
                                    debugPrint('      → width: ${renderObject.size.width}');
                                    debugPrint('      → height: ${renderObject.size.height}');
                                    debugPrint('      → constraints: ${renderObject.constraints}');
                                  }
                                });
                                
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 첫 번째 줄: Unit 선택 콤보, filteringWord, 메뉴 버튼, 공유 버튼
                                    Builder(
                                      builder: (rowContext) {
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          final renderObject = rowContext.findRenderObject();
                                          if (renderObject != null && renderObject is RenderBox) {
                                            debugPrint('   📱 [핸드폰 세로 모드] 첫 번째 Row 렌더링 크기:');
                                            debugPrint('      → width: ${renderObject.size.width}');
                                            debugPrint('      → height: ${renderObject.size.height}');
                                            debugPrint('      → constraints: ${renderObject.constraints}');
                                            if (renderObject is RenderFlex) {
                                              debugPrint('      → children 개수: ${renderObject.childCount}');
                                              RenderBox? child = renderObject.firstChild;
                                              int index = 0;
                                              while (child != null) {
                                                debugPrint('         → child #$index: width=${child.size.width}, height=${child.size.height}');
                                                final parentData = child.parentData;
                                                if (parentData is FlexParentData) {
                                                  child = parentData.nextSibling;
                                                } else {
                                                  break;
                                                }
                                                index++;
                                              }
                                            }
                                          }
                                        });
                                        
                                        return Row(
                                          children: [
                                    Flexible(
                                      flex: 2,
                                      child: _buildVentasUnitButtonsInAppBar(),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      flex: 3,
                                      child: _buildFilteringWordFieldInAppBar(),
                                    ),
                                    const SizedBox(width: 4),
                                    // 메뉴 버튼
                                    PopupMenuButton<ReportType>(
                                      icon: const Icon(Icons.more_vert, color: Colors.white, size: 18),
                                      tooltip: 'Menú',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      iconSize: 18,
                                      onSelected: (ReportType reportType) {
                                        _switchToReport(reportType);
                                      },
                                      itemBuilder: (BuildContext context) {
                    debugPrint('🔍 [PopupMenuButton] itemBuilder 호출됨!');
                    final items = _buildReportMenuItems();
                    debugPrint('🔍 [PopupMenuButton] 메뉴 아이템 개수: ${items.length}');
                    for (int i = 0; i < items.length; i++) {
                      debugPrint('🔍 [PopupMenuButton] 아이템 #$i: ${items[i].runtimeType}');
                    }
                    return items;
                  },
                                    ),
                                    // PDF 공유 버튼
                                    if (_data != null) ...[
                                      const SizedBox(width: 2),
                                      IconButton(
                                        icon: const Icon(Icons.share, color: Colors.white, size: 18),
                                        tooltip: 'Compartir como PDF',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        iconSize: 18,
                                        onPressed: () => _shareReport(),
                                      ),
                                    ],
                                  ],
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 4),
                                    // 두 번째 줄: Descontado, Reservado, Crédito 체크박스
                                    Builder(
                                      builder: (rowContext) {
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          final renderObject = rowContext.findRenderObject();
                                          if (renderObject != null && renderObject is RenderBox) {
                                            debugPrint('   📱 [핸드폰 세로 모드] 두 번째 Row 렌더링 크기:');
                                            debugPrint('      → width: ${renderObject.size.width}');
                                            debugPrint('      → height: ${renderObject.size.height}');
                                            debugPrint('      → constraints: ${renderObject.constraints}');
                                            if (renderObject is RenderFlex) {
                                              debugPrint('      → children 개수: ${renderObject.childCount}');
                                            }
                                          }
                                        });
                                        
                                        // ============================================================
                                        // 📱 핸드폰 세로 모드 전용: 하나의 콤보박스로 4개 필터 통합
                                        // ============================================================
                                        // ⚠️ 중요: 이 코드는 isMobilePortrait 조건문 안에만 있으므로
                                        // 대형 화면(데스크톱/태블릿)에는 절대 영향을 주지 않습니다.
                                        // 대형 화면은 아래의 isDesktopOrTablet 조건문에서 처리됩니다.
                                        return Row(
                                          children: [
                                            Expanded(
                                              child: _buildVentasFiltersSingleComboBox(),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 4),
                                    // 세 번째 줄: 달력 버튼 2개, sucursal 선택 콤보
                                    Builder(
                                      builder: (rowContext) {
                                        return Row(
                                          children: [
                                    Flexible(
                                      child: SizedBox(
                                        width: 90,
                                        child: _buildSingleDateButton(
                                          label: 'Desde',
                                          date: _ventasStartDate,
                                          reportColor: _getReportColor(),
                                          unit: _ventasUnit,
                                          onDateSelected: (date) {
                                            setState(() {
                                              _ventasStartDate = date;
                                              // month: 첫째 달력만 변경. 종료일은 유지. 새 시작이 종료보다 늦을 때만 해당 월 말일로 맞춤
                                              if (_ventasUnit == 'month' && (_ventasEndDate == null || date.isAfter(_ventasEndDate!))) {
                                                _ventasEndDate = DateTime(date.year, date.month + 1, 0);
                                              }
                                            });
                                            _loadData();
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: SizedBox(
                                        width: 90,
                                        child: _buildSingleDateButton(
                                          label: 'Hasta',
                                          date: _ventasEndDate,
                                          reportColor: _getReportColor(),
                                          unit: _ventasUnit,
                                          onDateSelected: (date) {
                                            setState(() {
                                              _ventasEndDate = date;
                                              if (_ventasUnit == 'month') {
                                                _ventasStartDate = DateTime(date.year, date.month, 1);
                                              }
                                            });
                                            _loadData();
                                          },
                                        ),
                                      ),
                                    ),
                                    if (_availableSucursales != null && _availableSucursales!.length > 1) ...[
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: _buildSucursalSelector(),
                                      ),
                                    ],
                                    if (widget.reportType == ReportType.ingresos) ...[
                                      const SizedBox(width: 8),
                                      _buildIngresosMovidosCheckbox(),
                                    ],
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                          
                          // 넓은 화면: 1줄로 배치 (데스크톱/태블릿은 변경하지 않음, 핸드폰 넓은 화면만 변경)
                          final isDesktopOrTablet = platformType == PlatformType.desktop || PlatformUtils.isIPad(context);
                          
                          // 디버깅: macOS/Windows 대형 화면에서 달력 버튼 표시 확인
                          debugPrint('═══════════════════════════════════════════════════════');
                          debugPrint('📅 [Ventas AppBar] 달력 버튼 표시 디버깅');
                          debugPrint('   → 파일: report_screen.dart');
                          debugPrint('   → 라인: ~3330');
                          debugPrint('   → platformType: $platformType');
                          debugPrint('   → PlatformType.desktop: ${PlatformType.desktop}');
                          debugPrint('   → PlatformUtils.isIPad(context): ${PlatformUtils.isIPad(context)}');
                          debugPrint('   → isDesktopOrTablet: $isDesktopOrTablet');
                          debugPrint('   → constraints.maxWidth: ${constraints.maxWidth}');
                          debugPrint('   → isLargeScreen: $isLargeScreen');
                          debugPrint('   → orientation: $orientation');
                          debugPrint('   → isMobile: $isMobile');
                          debugPrint('   → isMobilePortrait: $isMobilePortrait');
                          debugPrint('   → _ventasStartDate: $_ventasStartDate');
                          debugPrint('   → _ventasEndDate: $_ventasEndDate');
                          debugPrint('   → _ventasUnit: $_ventasUnit');
                          
                          // 데스크톱/태블릿: 기존대로 체크박스 사용
                          if (isDesktopOrTablet) {
                            debugPrint('   ✅ isDesktopOrTablet = true → 달력 버튼 2개 포함 Row 반환');
                            final desdeButton = SizedBox(
                              width: 90,
                              child: _buildSingleDateButton(
                                label: 'Desde',
                                date: _ventasStartDate,
                                reportColor: _getReportColor(),
                                unit: _ventasUnit,
                                onDateSelected: (date) {
                                  setState(() {
                                    _ventasStartDate = date;
                                    // month: 첫째 달력만 변경. 종료일은 유지. 새 시작이 종료보다 늦을 때만 해당 월 말일로 맞춤
                                    if (_ventasUnit == 'month' && (_ventasEndDate == null || date.isAfter(_ventasEndDate!))) {
                                      _ventasEndDate = DateTime(date.year, date.month + 1, 0);
                                    }
                                  });
                                  _loadData();
                                },
                              ),
                            );
                            final hastaButton = SizedBox(
                              width: 90,
                              child: _buildSingleDateButton(
                                label: 'Hasta',
                                date: _ventasEndDate,
                                reportColor: _getReportColor(),
                                unit: _ventasUnit,
                                onDateSelected: (date) {
                                  setState(() {
                                    _ventasEndDate = date;
                                    if (_ventasUnit == 'month') {
                                      _ventasStartDate = DateTime(date.year, date.month, 1);
                                    }
                                  });
                                  _loadData();
                                },
                              ),
                            );
                            
                            debugPrint('   → Desde 버튼 생성 완료');
                            debugPrint('   → Hasta 버튼 생성 완료');
                            
                            final unitButtons = _buildVentasUnitButtonsInAppBar();
                            final checkboxesRow = Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: _ventasDescontado,
                                  onChanged: (value) {
                                    setState(() {
                                      _ventasDescontado = value ?? false;
                                    });
                                    _loadData();
                                  },
                                  checkColor: Colors.white,
                                  fillColor: WidgetStateProperty.resolveWith<Color>(
                                    (Set<WidgetState> states) {
                                      if (states.contains(WidgetState.selected)) {
                                        return Colors.white.withOpacity(0.3);
                                      }
                                      return Colors.transparent;
                                    },
                                  ),
                                  side: const BorderSide(color: Colors.white, width: 1.5),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                const SizedBox(width: 2),
                                const Text(
                                  'Descontado',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Checkbox(
                                  value: _ventasReservado,
                                  onChanged: (value) {
                                    setState(() {
                                      _ventasReservado = value ?? false;
                                    });
                                    _loadData();
                                  },
                                  checkColor: Colors.white,
                                  fillColor: WidgetStateProperty.resolveWith<Color>(
                                    (Set<WidgetState> states) {
                                      if (states.contains(WidgetState.selected)) {
                                        return Colors.white.withOpacity(0.3);
                                      }
                                      return Colors.transparent;
                                    },
                                  ),
                                  side: const BorderSide(color: Colors.white, width: 1.5),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                const SizedBox(width: 2),
                                const Text(
                                  'Reservado',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Checkbox(
                                  value: _ventasCredito,
                                  onChanged: (value) {
                                    setState(() {
                                      _ventasCredito = value ?? false;
                                    });
                                    _loadData();
                                  },
                                  checkColor: Colors.white,
                                  fillColor: WidgetStateProperty.resolveWith<Color>(
                                    (Set<WidgetState> states) {
                                      if (states.contains(WidgetState.selected)) {
                                        return Colors.white.withOpacity(0.3);
                                      }
                                      return Colors.transparent;
                                    },
                                  ),
                                  side: const BorderSide(color: Colors.white, width: 1.5),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                const SizedBox(width: 2),
                                const Text(
                                  'Crédito',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                            
                            final filteringField = _buildFilteringWordFieldInAppBar();
                            
                            debugPrint('   → Row children 구성:');
                            debugPrint('      - unitButtons: 생성됨');
                            debugPrint('      - desdeButton: 생성됨 (width: 90)');
                            debugPrint('      - hastaButton: 생성됨 (width: 90)');
                            debugPrint('      - checkboxesRow: 생성됨');
                            debugPrint('      - filteringField: 생성됨');
                            
                            // Sucursal 선택 콤보 미리 빌드
                            final sucursalSelectorWidget = _buildSucursalSelectorWithDebug('큰 화면 - AppBar title (isDesktopOrTablet - 첫 번째 위치)');
                            debugPrint('🔍 [Row children 구성 - 첫 번째 위치] sucursalSelectorWidget: ${sucursalSelectorWidget != null ? sucursalSelectorWidget.runtimeType : "null"}');
                            
                            // Row children 리스트 구성
                            final rowChildren = <Widget>[
                              // Unit 선택 콤보
                              unitButtons,
                              const SizedBox(width: 8),
                              // 달력 버튼 2개
                              desdeButton,
                              const SizedBox(width: 4),
                              hastaButton,
                              const SizedBox(width: 8),
                            ];
                            
                            // Sucursal 선택 콤보 추가
                            if (sucursalSelectorWidget != null) {
                              debugPrint('🔍 [Row children 구성 - 첫 번째 위치] sucursalSelectorWidget 추가됨');
                              rowChildren.add(sucursalSelectorWidget);
                              rowChildren.add(const SizedBox(width: 8));
                            } else {
                              debugPrint('🔍 [Row children 구성 - 첫 번째 위치] sucursalSelectorWidget가 null이므로 추가 안 함');
                            }
                            
                            debugPrint('🔍 [Row children 구성 - 첫 번째 위치] 최종 children 개수: ${rowChildren.length}');
                            
                            return Builder(
                              builder: (context) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  final renderObject = context.findRenderObject();
                                  if (renderObject != null && renderObject is RenderBox) {
                                    debugPrint('   → Row 실제 렌더링 크기:');
                                    debugPrint('      - width: ${renderObject.size.width}');
                                    debugPrint('      - height: ${renderObject.size.height}');
                                    if (renderObject is RenderFlex) {
                                      debugPrint('      - children 개수: ${renderObject.childCount}');
                                    }
                                  }
                                });
                                
                                return Row(
                                  children: [
                                    ...rowChildren,
                                    // Descontado, Reservado, Crédito 체크박스
                                    checkboxesRow,
                                    const SizedBox(width: 8),
                                    // filteringWord
                                    Expanded(
                                      child: filteringField,
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                          
                          // ============================================================
                          // 📱 핸드폰 가로 모드: 2줄로 배치
                          // ============================================================
                          // 핸드폰 가로 모드에서는 공간이 넓어지지만 여전히 제한적이므로 2줄로 배치
                          // 태블릿/데스크톱에는 영향을 미치지 않음 (대형 화면 보호)
                          // layoutInfo에서 이미 계산된 isMobilePhoneLandscape 사용
                          if (isMobilePhoneLandscape) {
                            debugPrint('   → 모바일 폰 가로 모드 (iPhone/Android): 2줄 Column 사용');
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 첫 번째 줄: Unit 선택 콤보, 달력 버튼 2개, Sucursal 선택 콤보
                                Row(
                                  children: [
                                    Flexible(
                                      child: _buildVentasUnitButtonsInAppBar(),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: SizedBox(
                                        width: 90,
                                        child: _buildSingleDateButton(
                                          label: 'Desde',
                                          date: _ventasStartDate,
                                          reportColor: _getReportColor(),
                                          unit: _ventasUnit,
                                          onDateSelected: (date) {
                                            setState(() {
                                              _ventasStartDate = date;
                                              // month: 첫째 달력만 변경. 종료일은 유지. 새 시작이 종료보다 늦을 때만 해당 월 말일로 맞춤
                                              if (_ventasUnit == 'month' && (_ventasEndDate == null || date.isAfter(_ventasEndDate!))) {
                                                _ventasEndDate = DateTime(date.year, date.month + 1, 0);
                                              }
                                            });
                                            _loadData();
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: SizedBox(
                                        width: 90,
                                        child: _buildSingleDateButton(
                                          label: 'Hasta',
                                          date: _ventasEndDate,
                                          reportColor: _getReportColor(),
                                          unit: _ventasUnit,
                                          onDateSelected: (date) {
                                            setState(() {
                                              _ventasEndDate = date;
                                              if (_ventasUnit == 'month') {
                                                _ventasStartDate = DateTime(date.year, date.month, 1);
                                              }
                                            });
                                            _loadData();
                                          },
                                        ),
                                      ),
                                    ),
                                    if (_availableSucursales != null && _availableSucursales!.length > 1) ...[
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: _buildSucursalSelector(),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // 두 번째 줄: Descontado, Reservado, Crédito 콤보박스, filteringWord
                                Row(
                                  children: [
                                    Flexible(
                                      child: _buildVentasFilterComboBox('Descontado', _ventasDescontado, (value) {
                                        setState(() {
                                          _ventasDescontado = value;
                                        });
                                        _loadData();
                                      }),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: _buildVentasFilterComboBox('Reservado', _ventasReservado, (value) {
                                        setState(() {
                                          _ventasReservado = value;
                                        });
                                        _loadData();
                                      }),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: _buildVentasFilterComboBox('Crédito', _ventasCredito, (value) {
                                        setState(() {
                                          _ventasCredito = value;
                                        });
                                        _loadData();
                                      }),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: _buildVentasFilterComboBox('Movidos', _ventasMovidos, (value) {
                                        debugPrint('═══════════════════════════════════════════════════════');
                                        debugPrint('🔍 [Ventas AppBar] Movidos 콤보박스 변경');
                                        debugPrint('   → 이전 값: $_ventasMovidos');
                                        debugPrint('   → 새 값: $value');
                                        debugPrint('   → setState 호출 전');
                                        setState(() {
                                          _ventasMovidos = value;
                                        });
                                        debugPrint('   → setState 호출 후: _ventasMovidos = $_ventasMovidos');
                                        debugPrint('   → _loadData() 호출 시작');
                                        _loadData();
                                        debugPrint('   → _loadData() 호출 완료');
                                        debugPrint('═══════════════════════════════════════════════════════');
                                      }),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildFilteringWordFieldInAppBar(),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }
                          
                          return Row(
                            children: [
                              // Unit 선택 콤보
                              _buildVentasUnitButtonsInAppBar(),
                              const SizedBox(width: 8),
                              // 달력 버튼 2개
                              SizedBox(
                                width: 90,
                                child: _buildSingleDateButton(
                                  label: 'Desde',
                                  date: _ventasStartDate,
                                  reportColor: _getReportColor(),
                                  unit: _ventasUnit,
                                  onDateSelected: (date) {
                                    setState(() {
                                      _ventasStartDate = date;
                                      // month: 첫째 달력만 변경. 종료일은 유지. 새 시작이 종료보다 늦을 때만 해당 월 말일로 맞춤
                                      if (_ventasUnit == 'month' && (_ventasEndDate == null || date.isAfter(_ventasEndDate!))) {
                                        _ventasEndDate = DateTime(date.year, date.month + 1, 0);
                                      }
                                    });
                                    _loadData();
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              SizedBox(
                                width: 90,
                                child: _buildSingleDateButton(
                                  label: 'Hasta',
                                  date: _ventasEndDate,
                                  reportColor: _getReportColor(),
                                  unit: _ventasUnit,
                                  onDateSelected: (date) {
                                    setState(() {
                                      _ventasEndDate = date;
                                      if (_ventasUnit == 'month') {
                                        _ventasStartDate = DateTime(date.year, date.month, 1);
                                      }
                                    });
                                    _loadData();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Sucursal 선택 콤보
                              if (_availableSucursales != null && _availableSucursales!.length > 1) ...[
                                _buildSucursalSelector(),
                                const SizedBox(width: 8),
                              ],
                              // Descontado, Reservado, Crédito 콤보박스
                              _buildVentasFilterComboBox('Descontado', _ventasDescontado, (value) {
                                setState(() {
                                  _ventasDescontado = value;
                                });
                                _loadData();
                              }),
                              const SizedBox(width: 4),
                              _buildVentasFilterComboBox('Reservado', _ventasReservado, (value) {
                                setState(() {
                                  _ventasReservado = value;
                                });
                                _loadData();
                              }),
                              const SizedBox(width: 4),
                              _buildVentasFilterComboBox('Crédito', _ventasCredito, (value) {
                                setState(() {
                                  _ventasCredito = value;
                                });
                                _loadData();
                              }),
                              const SizedBox(width: 4),
                              _buildVentasFilterComboBox('Movidos', _ventasMovidos, (value) {
                                debugPrint('═══════════════════════════════════════════════════════');
                                debugPrint('🔍 [Ventas AppBar] Movidos 콤보박스 변경');
                                debugPrint('   → 이전 값: $_ventasMovidos');
                                debugPrint('   → 새 값: $value');
                                debugPrint('   → setState 호출 전');
                                setState(() {
                                  _ventasMovidos = value;
                                });
                                debugPrint('   → setState 호출 후: _ventasMovidos = $_ventasMovidos');
                                debugPrint('   → _loadData() 호출 시작');
                                _loadData();
                                debugPrint('   → _loadData() 호출 완료');
                                debugPrint('═══════════════════════════════════════════════════════');
                              }),
                              const SizedBox(width: 8),
                              // filteringWord
                              Expanded(
                                child: _buildFilteringWordFieldInAppBar(),
                              ),
                            ],
                          );
                        },
                      )
                    : widget.reportType == ReportType.ventas
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          // ============================================================
                          // 📱 Ventas 보고서 AppBar Actions - 모바일 화면 구성 처리
                          // ============================================================
                          // MobileLayoutHelper를 사용하여 핸드폰의 수직/수평 화면 구성을 처리
                          final layoutInfo = MobileLayoutHelper.getLayoutInfo(context);
                          final isMobilePortrait = layoutInfo.isMobilePhonePortrait;
                          
                          // 핸드폰 세로 모드: 3줄로 배치 (컨트롤이 많아서 공간 확보 필요)
                          // 핸드폰 가로 모드, 태블릿, 데스크톱: 1줄로 배치 (대형 화면 보호)
                          if (isMobilePortrait) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 첫 번째 줄: Unit 선택 콤보, filteringWord, 메뉴 버튼, 공유 버튼
                                Row(
                                  children: [
                                    Flexible(
                                      flex: 2,
                                      child: _buildVentasUnitButtonsInAppBar(),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      flex: 3,
                                      child: _buildFilteringWordFieldInAppBar(),
                                    ),
                                    const SizedBox(width: 4),
                                    // 메뉴 버튼
                                    PopupMenuButton<ReportType>(
                                      icon: const Icon(Icons.more_vert, color: Colors.white, size: 18),
                                      tooltip: 'Menú',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      iconSize: 18,
                                      onSelected: (ReportType reportType) {
                                        _switchToReport(reportType);
                                      },
                                      itemBuilder: (BuildContext context) {
                    debugPrint('🔍 [PopupMenuButton] itemBuilder 호출됨!');
                    final items = _buildReportMenuItems();
                    debugPrint('🔍 [PopupMenuButton] 메뉴 아이템 개수: ${items.length}');
                    for (int i = 0; i < items.length; i++) {
                      debugPrint('🔍 [PopupMenuButton] 아이템 #$i: ${items[i].runtimeType}');
                    }
                    return items;
                  },
                                    ),
                                    // PDF 공유 버튼
                                    if (_data != null) ...[
                                      const SizedBox(width: 2),
                                      IconButton(
                                        icon: const Icon(Icons.share, color: Colors.white, size: 18),
                                        tooltip: 'Compartir como PDF',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        iconSize: 18,
                                        onPressed: () => _shareReport(),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // 두 번째 줄: Descontado, Reservado, Crédito 체크박스
                                Builder(
                                  builder: (rowContext) {
                                    return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                    Checkbox(
                                      value: _ventasDescontado,
                                      onChanged: (value) {
                                        setState(() {
                                          _ventasDescontado = value ?? false;
                                        });
                                        _loadData();
                                      },
                                      checkColor: Colors.white,
                                      fillColor: WidgetStateProperty.resolveWith<Color>(
                                        (Set<WidgetState> states) {
                                          if (states.contains(WidgetState.selected)) {
                                            return Colors.white.withOpacity(0.3);
                                          }
                                          return Colors.transparent;
                                        },
                                      ),
                                      side: const BorderSide(color: Colors.white, width: 1.5),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    const SizedBox(width: 2),
                                    const Text(
                                      'Descontado',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Checkbox(
                                      value: _ventasReservado,
                                      onChanged: (value) {
                                        setState(() {
                                          _ventasReservado = value ?? false;
                                        });
                                        _loadData();
                                      },
                                      checkColor: Colors.white,
                                      fillColor: WidgetStateProperty.resolveWith<Color>(
                                        (Set<WidgetState> states) {
                                          if (states.contains(WidgetState.selected)) {
                                            return Colors.white.withOpacity(0.3);
                                          }
                                          return Colors.transparent;
                                        },
                                      ),
                                      side: const BorderSide(color: Colors.white, width: 1.5),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    const SizedBox(width: 2),
                                    const Text(
                                      'Reservado',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Checkbox(
                                      value: _ventasCredito,
                                      onChanged: (value) {
                                        setState(() {
                                          _ventasCredito = value ?? false;
                                        });
                                        _loadData();
                                      },
                                      checkColor: Colors.white,
                                      fillColor: WidgetStateProperty.resolveWith<Color>(
                                        (Set<WidgetState> states) {
                                          if (states.contains(WidgetState.selected)) {
                                            return Colors.white.withOpacity(0.3);
                                          }
                                          return Colors.transparent;
                                        },
                                      ),
                                      side: const BorderSide(color: Colors.white, width: 1.5),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    const SizedBox(width: 2),
                                    const Text(
                                      'Crédito',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      ),
                                          ],
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 4),
                                    // 세 번째 줄: 달력 버튼 2개, sucursal 선택 콤보
                                    Builder(
                                      builder: (rowContext) {
                                        return Row(
                                          children: [
                                    Flexible(
                                      child: SizedBox(
                                        width: 90,
                                        child: _buildSingleDateButton(
                                          label: 'Desde',
                                          date: _ventasStartDate,
                                          reportColor: _getReportColor(),
                                          unit: _ventasUnit,
                                          onDateSelected: (date) {
                                            setState(() {
                                              _ventasStartDate = date;
                                              // month: 첫째 달력만 변경. 종료일은 유지. 새 시작이 종료보다 늦을 때만 해당 월 말일로 맞춤
                                              if (_ventasUnit == 'month' && (_ventasEndDate == null || date.isAfter(_ventasEndDate!))) {
                                                _ventasEndDate = DateTime(date.year, date.month + 1, 0);
                                              }
                                            });
                                            _loadData();
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: SizedBox(
                                        width: 90,
                                        child: _buildSingleDateButton(
                                          label: 'Hasta',
                                          date: _ventasEndDate,
                                          reportColor: _getReportColor(),
                                          unit: _ventasUnit,
                                          onDateSelected: (date) {
                                            setState(() {
                                              _ventasEndDate = date;
                                              if (_ventasUnit == 'month') {
                                                _ventasStartDate = DateTime(date.year, date.month, 1);
                                              }
                                            });
                                            _loadData();
                                          },
                                        ),
                                      ),
                                    ),
                                    if (_availableSucursales != null && _availableSucursales!.length > 1) ...[
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: _buildSucursalSelector(),
                                      ),
                                    ],
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                );
                          }
                          
                          // 넓은 화면: 1줄로 배치 (데스크톱/태블릿은 변경하지 않음, 핸드폰 넓은 화면만 변경)
                          final isDesktopOrTablet = platformType == PlatformType.desktop || PlatformUtils.isIPad(context);
                          
                          // 데스크톱/태블릿: 기존대로 체크박스 사용
                          if (isDesktopOrTablet) {
                            return Row(
                              children: [
                                // Unit 선택 콤보
                                _buildVentasUnitButtonsInAppBar(),
                                const SizedBox(width: 8),
                                // Descontado, Reservado, Crédito 체크박스
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Checkbox(
                                      value: _ventasDescontado,
                                      onChanged: (value) {
                                        setState(() {
                                          _ventasDescontado = value ?? false;
                                        });
                                        _loadData();
                                      },
                                      checkColor: Colors.white,
                                      fillColor: WidgetStateProperty.resolveWith<Color>(
                                        (Set<WidgetState> states) {
                                          if (states.contains(WidgetState.selected)) {
                                            return Colors.white.withOpacity(0.3);
                                          }
                                          return Colors.transparent;
                                        },
                                      ),
                                      side: const BorderSide(color: Colors.white, width: 1.5),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    const SizedBox(width: 2),
                                    const Text(
                                      'Descontado',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Checkbox(
                                      value: _ventasReservado,
                                      onChanged: (value) {
                                        setState(() {
                                          _ventasReservado = value ?? false;
                                        });
                                        _loadData();
                                      },
                                      checkColor: Colors.white,
                                      fillColor: WidgetStateProperty.resolveWith<Color>(
                                        (Set<WidgetState> states) {
                                          if (states.contains(WidgetState.selected)) {
                                            return Colors.white.withOpacity(0.3);
                                          }
                                          return Colors.transparent;
                                        },
                                      ),
                                      side: const BorderSide(color: Colors.white, width: 1.5),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    const SizedBox(width: 2),
                                    const Text(
                                      'Reservado',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Checkbox(
                                      value: _ventasCredito,
                                      onChanged: (value) {
                                        setState(() {
                                          _ventasCredito = value ?? false;
                                        });
                                        _loadData();
                                      },
                                      checkColor: Colors.white,
                                      fillColor: WidgetStateProperty.resolveWith<Color>(
                                        (Set<WidgetState> states) {
                                          if (states.contains(WidgetState.selected)) {
                                            return Colors.white.withOpacity(0.3);
                                          }
                                          return Colors.transparent;
                                        },
                                      ),
                                      side: const BorderSide(color: Colors.white, width: 1.5),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    const SizedBox(width: 2),
                                    const Text(
                                      'Crédito',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                // filteringWord
                                Expanded(
                                  child: _buildFilteringWordFieldInAppBar(),
                                ),
                              ],
                            );
                          }
                          
                          // 모바일 폰 가로 모드 체크 (iPhone, Android phone)
                          final isTablet2 = PlatformUtils.isIPad(context) || 
                                            (platformType == PlatformType.mobile && isLargeScreen);
                          final isMobilePhone2 = isMobile && !isTablet2;
                          final isMobilePhoneLandscape2 = isMobilePhone2 && orientation == Orientation.landscape;
                          
                          // 모바일 폰 가로 모드: 2줄로 배치 (컨트롤이 많아서 오버랩 방지)
                          if (isMobilePhoneLandscape2) {
                            debugPrint('   → 모바일 폰 가로 모드 (iPhone/Android, 두 번째 위치): 2줄 Column 사용');
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 첫 번째 줄: Unit 선택 콤보, 달력 버튼 2개, Sucursal 선택 콤보
                                Row(
                                  children: [
                                    Flexible(
                                      child: _buildVentasUnitButtonsInAppBar(),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: SizedBox(
                                        width: 90,
                                        child: _buildSingleDateButton(
                                          label: 'Desde',
                                          date: _ventasStartDate,
                                          reportColor: _getReportColor(),
                                          unit: _ventasUnit,
                                          onDateSelected: (date) {
                                            setState(() {
                                              _ventasStartDate = date;
                                              // month: 첫째 달력만 변경. 종료일은 유지. 새 시작이 종료보다 늦을 때만 해당 월 말일로 맞춤
                                              if (_ventasUnit == 'month' && (_ventasEndDate == null || date.isAfter(_ventasEndDate!))) {
                                                _ventasEndDate = DateTime(date.year, date.month + 1, 0);
                                              }
                                            });
                                            _loadData();
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: SizedBox(
                                        width: 90,
                                        child: _buildSingleDateButton(
                                          label: 'Hasta',
                                          date: _ventasEndDate,
                                          reportColor: _getReportColor(),
                                          unit: _ventasUnit,
                                          onDateSelected: (date) {
                                            setState(() {
                                              _ventasEndDate = date;
                                              if (_ventasUnit == 'month') {
                                                _ventasStartDate = DateTime(date.year, date.month, 1);
                                              }
                                            });
                                            _loadData();
                                          },
                                        ),
                                      ),
                                    ),
                                    if (_availableSucursales != null && _availableSucursales!.length > 1) ...[
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: _buildSucursalSelector(),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // 두 번째 줄: Descontado, Reservado, Crédito 콤보박스, filteringWord
                                Row(
                                  children: [
                                    Flexible(
                                      child: _buildVentasFilterComboBox('Descontado', _ventasDescontado, (value) {
                                        setState(() {
                                          _ventasDescontado = value;
                                        });
                                        _loadData();
                                      }),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: _buildVentasFilterComboBox('Reservado', _ventasReservado, (value) {
                                        setState(() {
                                          _ventasReservado = value;
                                        });
                                        _loadData();
                                      }),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: _buildVentasFilterComboBox('Crédito', _ventasCredito, (value) {
                                        setState(() {
                                          _ventasCredito = value;
                                        });
                                        _loadData();
                                      }),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: _buildVentasFilterComboBox('Movidos', _ventasMovidos, (value) {
                                        debugPrint('═══════════════════════════════════════════════════════');
                                        debugPrint('🔍 [Ventas AppBar] Movidos 콤보박스 변경');
                                        debugPrint('   → 이전 값: $_ventasMovidos');
                                        debugPrint('   → 새 값: $value');
                                        debugPrint('   → setState 호출 전');
                                        setState(() {
                                          _ventasMovidos = value;
                                        });
                                        debugPrint('   → setState 호출 후: _ventasMovidos = $_ventasMovidos');
                                        debugPrint('   → _loadData() 호출 시작');
                                        _loadData();
                                        debugPrint('   → _loadData() 호출 완료');
                                        debugPrint('═══════════════════════════════════════════════════════');
                                      }),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildFilteringWordFieldInAppBar(),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }
                          
                          return Row(
                            children: [
                              // Unit 선택 콤보
                              _buildVentasUnitButtonsInAppBar(),
                              const SizedBox(width: 8),
                              // 달력 버튼 2개
                              SizedBox(
                                width: 90,
                                child: _buildSingleDateButton(
                                  label: 'Desde',
                                  date: _ventasStartDate,
                                  reportColor: _getReportColor(),
                                  unit: _ventasUnit,
                                  onDateSelected: (date) {
                                    setState(() {
                                      _ventasStartDate = date;
                                      // month: 첫째 달력만 변경. 종료일은 유지. 새 시작이 종료보다 늦을 때만 해당 월 말일로 맞춤
                                      if (_ventasUnit == 'month' && (_ventasEndDate == null || date.isAfter(_ventasEndDate!))) {
                                        _ventasEndDate = DateTime(date.year, date.month + 1, 0);
                                      }
                                    });
                                    _loadData();
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              SizedBox(
                                width: 90,
                                child: _buildSingleDateButton(
                                  label: 'Hasta',
                                  date: _ventasEndDate,
                                  reportColor: _getReportColor(),
                                  unit: _ventasUnit,
                                  onDateSelected: (date) {
                                    setState(() {
                                      _ventasEndDate = date;
                                      if (_ventasUnit == 'month') {
                                        _ventasStartDate = DateTime(date.year, date.month, 1);
                                      }
                                    });
                                    _loadData();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Sucursal 선택 콤보
                              if (_availableSucursales != null && _availableSucursales!.length > 1) ...[
                                _buildSucursalSelector(),
                                const SizedBox(width: 8),
                              ],
                              // Descontado, Reservado, Crédito 콤보박스
                              _buildVentasFilterComboBox('Descontado', _ventasDescontado, (value) {
                                setState(() {
                                  _ventasDescontado = value;
                                });
                                _loadData();
                              }),
                              const SizedBox(width: 4),
                              _buildVentasFilterComboBox('Reservado', _ventasReservado, (value) {
                                setState(() {
                                  _ventasReservado = value;
                                });
                                _loadData();
                              }),
                              const SizedBox(width: 4),
                              _buildVentasFilterComboBox('Crédito', _ventasCredito, (value) {
                                setState(() {
                                  _ventasCredito = value;
                                });
                                _loadData();
                              }),
                              const SizedBox(width: 4),
                              _buildVentasFilterComboBox('Movidos', _ventasMovidos, (value) {
                                debugPrint('═══════════════════════════════════════════════════════');
                                debugPrint('🔍 [Ventas AppBar] Movidos 콤보박스 변경');
                                debugPrint('   → 이전 값: $_ventasMovidos');
                                debugPrint('   → 새 값: $value');
                                debugPrint('   → setState 호출 전');
                                setState(() {
                                  _ventasMovidos = value;
                                });
                                debugPrint('   → setState 호출 후: _ventasMovidos = $_ventasMovidos');
                                debugPrint('   → _loadData() 호출 시작');
                                _loadData();
                                debugPrint('   → _loadData() 호출 완료');
                                debugPrint('═══════════════════════════════════════════════════════');
                              }),
                              const SizedBox(width: 8),
                              // filteringWord
                              Expanded(
                                child: _buildFilteringWordFieldInAppBar(),
                              ),
                            ],
                          );
                        },
                      )
                    : (widget.reportType == ReportType.codigos || widget.reportType == ReportType.todocodigos)
                        ? LayoutBuilder(
                            builder: (context, constraints) {
                              // ============================================================
                              // 📱 Codigos/Todocodigos 보고서 AppBar - 모바일 화면 구성 처리
                              // ============================================================
                              // MobileLayoutHelper를 사용하여 핸드폰의 수직/수평 화면 구성을 처리
                              final layoutInfo = MobileLayoutHelper.getLayoutInfo(context);
                              final isMobilePortrait = layoutInfo.isMobilePhonePortrait;
                              
                              // 핸드폰 세로 모드: 3줄로 배치 (컨트롤이 많아서 공간 확보 필요)
                              // 핸드폰 가로 모드, 태블릿, 데스크톱: 1줄로 배치 (대형 화면 보호)
                              if (isMobilePortrait) {
                                debugPrint('═══════════════════════════════════════════════════════════');
                                debugPrint('📱 [Codigos/Todocodigos AppBar] 핸드폰 세로 모드 - 3줄 구성');
                                debugPrint('   → reportType: ${widget.reportType}');
                                debugPrint('   → _tiposList.length: ${_tiposList.length}');
                                debugPrint('   → _temporadasList.length: ${_temporadasList.length}');
                                debugPrint('═══════════════════════════════════════════════════════════');
                                
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 첫 번째 줄: 아이콘, 제목
                                    Builder(
                                      builder: (rowContext) {
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          final renderObject = rowContext.findRenderObject();
                                          if (renderObject != null && renderObject is RenderBox) {
                                            debugPrint('   📱 [Codigos/Todocodigos AppBar] 첫 번째 Row 렌더링 크기:');
                                            debugPrint('      → width: ${renderObject.size.width}');
                                            debugPrint('      → height: ${renderObject.size.height}');
                                          }
                                        });
                                        return Row(
                                          children: [
                                            Icon(reportIcon, color: Colors.white),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                reportTitle,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 16),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 4),
                                    // 두 번째 줄: Tipo, Temporada 콤보박스
                                    Builder(
                                      builder: (rowContext) {
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          final renderObject = rowContext.findRenderObject();
                                          if (renderObject != null && renderObject is RenderBox) {
                                            debugPrint('   📱 [Codigos/Todocodigos AppBar] 두 번째 Row 렌더링 크기:');
                                            debugPrint('      → width: ${renderObject.size.width}');
                                            debugPrint('      → height: ${renderObject.size.height}');
                                          }
                                        });
                                        return Row(
                                          children: [
                                            if (_tiposList.length > 1 || _temporadasList.length > 1) ...[
                                              if (_tiposList.length > 1) ...[
                                                Flexible(
                                                  child: _buildTipoSelector(),
                                                ),
                                                const SizedBox(width: 8),
                                              ],
                                              if (_temporadasList.length > 1) ...[
                                                Flexible(
                                                  child: _buildTemporadaSelector(),
                                                ),
                                              ],
                                            ],
                                          ],
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 4),
                                    // 세 번째 줄: Solo borrados 체크박스, 필터링 단어 필드
                                    Builder(
                                      builder: (rowContext) {
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          final renderObject = rowContext.findRenderObject();
                                          if (renderObject != null && renderObject is RenderBox) {
                                            debugPrint('   📱 [Codigos/Todocodigos AppBar] 세 번째 Row 렌더링 크기:');
                                            debugPrint('      → width: ${renderObject.size.width}');
                                            debugPrint('      → height: ${renderObject.size.height}');
                                          }
                                        });
                                        return Row(
                                          children: [
                                            _buildCodigosSoloBorradosCheckbox(),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: _buildFilteringWordFieldInAppBar(),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                );
                              }
                              
                              // ============================================================
                              // 📱 넓은 화면 (가로 모드 또는 태블릿/데스크톱): 1줄로 배치
                              // ============================================================
                              // 핸드폰 가로 모드, 태블릿, 데스크톱 모두 1줄 레이아웃 사용
                              // 대형 화면에는 모바일 전용 로직이 적용되지 않음
                              return Row(
                                children: [
                                  Icon(reportIcon, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(reportTitle),
                                  const SizedBox(width: 16),
                                  // Tipo와 Temporada 콤보박스 (filteringWord 왼쪽)
                                  if (_tiposList.length > 1 || _temporadasList.length > 1) ...[
                                    if (_tiposList.length > 1) ...[
                                      _buildTipoSelector(),
                                      const SizedBox(width: 8),
                                    ],
                                    if (_temporadasList.length > 1) ...[
                                      _buildTemporadaSelector(),
                                      const SizedBox(width: 8),
                                    ],
                                  ],
                                  _buildCodigosSoloBorradosCheckbox(),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildFilteringWordFieldInAppBar(),
                                  ),
                                ],
                              );
                            },
                          )
                    : widget.reportType == ReportType.stocks
                        ? LayoutBuilder(
                            builder: (context, constraints) {
                              final isLargeScreen = constraints.maxWidth > 800;
                              return Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  Icon(reportIcon, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(reportTitle),
                                  if (isLargeScreen && _data != null) ...[
                                    const SizedBox(width: 16),
                                    _buildStocksViewTypeInAppBar(),
                                  ],
                                  const SizedBox(width: 16),
                                  // Tipo와 Temporada 콤보박스 (filteringWord 왼쪽)
                                  Builder(
                                    builder: (context) {
                                      debugPrint('═══════════════════════════════════════════════════════');
                                      debugPrint('🔍 [Stocks AppBar] Tipo/Temporada 콤보박스 표시 조건 확인');
                                      debugPrint('   → _tiposList.length: ${_tiposList.length}');
                                      debugPrint('   → _temporadasList.length: ${_temporadasList.length}');
                                      debugPrint('   → _tiposList: $_tiposList');
                                      debugPrint('   → _temporadasList: $_temporadasList');
                                      debugPrint('   → 표시 조건: _tiposList.length > 1 || _temporadasList.length > 1');
                                      debugPrint('   → 결과: ${_tiposList.length > 1 || _temporadasList.length > 1}');
                                      debugPrint('═══════════════════════════════════════════════════════');
                                      
                                      // 길이가 1 이상이면 표시 (1개여도 선택할 수 있도록)
                                      if (_tiposList.isNotEmpty || _temporadasList.isNotEmpty) {
                                        return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (_tiposList.isNotEmpty) ...[
                                              _buildTipoSelector(),
                                              const SizedBox(width: 8),
                                            ],
                                            if (_temporadasList.isNotEmpty) ...[
                                              _buildTemporadaSelector(),
                                              const SizedBox(width: 8),
                                            ],
                                          ],
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                  Expanded(
                                    child: _buildFilteringWordFieldInAppBar(),
                                  ),
                                ],
                              );
                            },
                          )
                        : Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                              Icon(reportIcon, color: Colors.white),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(reportTitle),
                                  ],
                                ),
                              ),
                            ],
                          ),
        backgroundColor: reportColor,
        actions: () {
          // ============================================================
          // 📱 AppBar Actions - 모바일 화면 구성 처리
          // ============================================================
          // MobileLayoutHelper를 사용하여 핸드폰의 수직/수평 화면 구성을 처리
          // 대형 화면에는 영향을 미치지 않도록 주의
          final layoutInfo = MobileLayoutHelper.getLayoutInfo(context);
          final isMobilePhoneLandscape = layoutInfo.isMobilePhoneLandscape;
          
          // 디버깅: 핸드폰 가로 모드일 때만 디버그 정보 출력
          if (isMobilePhoneLandscape && widget.reportType == ReportType.ventas) {
            debugPrint('═══════════════════════════════════════════════════════');
            debugPrint('📱 [모바일 폰 가로 모드 디버깅] Ventas AppBar Actions');
            debugPrint('   → 파일: report_screen.dart');
            debugPrint('   → 라인: ~4247');
            debugPrint('   → needsThreeLineAppBar: $needsThreeLineAppBar');
            debugPrint('   → isMobilePhoneLandscape: $isMobilePhoneLandscape');
            debugPrint('   → _data: $_data');
            debugPrint('   → _data != null: ${_data != null}');
            debugPrint('   → orientation: $orientation');
            debugPrint('   → platformType: $platformType');
            debugPrint('   → MediaQuery.size: ${MediaQuery.of(context).size}');
          }
          
          return (needsThreeLineAppBar || needsTwoLineAppBar)
              ? <Widget>[] // 좁은 화면에서는 title에 이미 메뉴 버튼과 공유 버튼이 있으므로 actions 비활성화
              : <Widget>[
                  // 보고서 선택 드롭다운 메뉴
                  PopupMenuButton<ReportType>(
                  icon: const Icon(Icons.assessment, color: Colors.white),
                  tooltip: 'Reportes',
                  onOpened: () {
                    debugPrint('🔍 [PopupMenuButton] 메뉴가 열렸습니다!');
                  },
                  onSelected: (ReportType reportType) {
                    debugPrint('🔍 [메뉴] onSelected 호출됨: reportType=$reportType, 현재 reportType=${widget.reportType}');
                    // 빌드 날짜 항목은 무시 (alertas와 같은 value를 사용하지만, 메뉴의 마지막 항목)
                    // alertas 보고서에서 alertas를 선택한 경우, 빌드 날짜 항목일 가능성이 높음
                    // 빌드 날짜 항목은 항상 마지막에 위치하므로, alertas 보고서에서 alertas를 선택하면 무시
                    if (reportType == ReportType.alertas && widget.reportType == ReportType.alertas) {
                      // alertas 보고서에서 alertas를 선택한 경우, 빌드 날짜 항목일 가능성이 높음
                      // 메뉴 아이템 리스트를 확인하여 마지막 항목인지 확인
                      final menuItems = _buildReportMenuItems();
                      if (menuItems.isNotEmpty) {
                        final lastMenuItem = menuItems.last;
                        if (lastMenuItem is PopupMenuItem<ReportType>) {
                          final lastItemValue = lastMenuItem.value;
                          // 마지막 항목이 alertas이고, 그 앞에 alertas 메뉴 아이템이 있으면 빌드 날짜 항목
                          if (lastItemValue == ReportType.alertas) {
                            // alertas 메뉴 아이템이 몇 개인지 확인
                            final alertasMenuItems = menuItems.where((item) => 
                              item is PopupMenuItem<ReportType> && 
                              item.value == ReportType.alertas
                            ).toList();
                            // alertas 메뉴 아이템이 2개 이상이면, 마지막 항목은 빌드 날짜 항목
                            if (alertasMenuItems.length >= 2) {
                              debugPrint('🔍 [메뉴] 빌드 날짜 항목 선택됨 - 무시 (alertas 메뉴 아이템이 ${alertasMenuItems.length}개)');
                              return; // if: 빌드 날짜 항목 - 무시
                            }
                          }
                        }
                      }
                      debugPrint('🔍 [메뉴] alertas 보고서에서 alertas 선택됨 - 빌드 날짜 항목일 가능성, 무시');
                      return; // if: alertas 보고서에서 alertas 선택 - 무시
                    } // if (reportType == ReportType.alertas && widget.reportType == ReportType.alertas) 끝
                    _switchToReport(reportType);
                  },
                  itemBuilder: (BuildContext context) {
                    debugPrint('🔍 [PopupMenuButton] itemBuilder 호출됨!');
                    final items = _buildReportMenuItems();
                    debugPrint('🔍 [PopupMenuButton] 메뉴 아이템 개수: ${items.length}');
                    for (int i = 0; i < items.length; i++) {
                      debugPrint('🔍 [PopupMenuButton] 아이템 #$i: ${items[i].runtimeType}');
                    }
                    return items;
                  },
                ),
                // PDF 공유 / Exportación 버튼
                if (_data != null)
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    tooltip: 'Compartir como PDF',
                    onPressed: () => _shareReport(),
                  ),
                ];
        }(),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: reportColor),
                  const SizedBox(height: 16),
                  Text(l10n.loadingData),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.errorOccurred,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.retry),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: reportColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : _data == null || _data!.isEmpty
                  ? Center(
                      child: Text(l10n.noData),
                    )
                  : Builder(
                      builder: (context) {
                        // ============================================================
                        // 📱 Body - 모바일 화면 구성 처리
                        // ============================================================
                        // MobileLayoutHelper를 사용하여 핸드폰의 수직/수평 화면 구성을 처리
                        // 대형 화면에는 영향을 미치지 않도록 주의
                        final layoutInfo = MobileLayoutHelper.getLayoutInfo(context);
                        final isMobilePortrait = layoutInfo.isMobilePhonePortrait;
                        
                        // 디버깅: 핸드폰 세로 모드일 때만 디버그 정보 출력
                        if (isMobilePortrait && widget.reportType == ReportType.ventas) {
                          debugPrint('═══════════════════════════════════════════════════════');
                          debugPrint('📱 [핸드폰 세로 모드] Body 디버깅');
                          debugPrint('   → 파일: report_screen.dart');
                          debugPrint('   → 라인: ~4659');
                          debugPrint('   → MediaQuery.size: ${layoutInfo.screenSize}');
                          debugPrint('   → MediaQuery.padding: ${MediaQuery.of(context).padding}');
                          debugPrint('   → orientation: ${layoutInfo.orientation}');
                          debugPrint('   → platformType: ${layoutInfo.platformType}');
                          debugPrint('   → isMobile: ${layoutInfo.isMobilePlatform}');
                          debugPrint('   → isMobilePortrait: $isMobilePortrait');
                          debugPrint('   → useFullWidth: ${widget.useFullWidth}');
                          debugPrint('   → reportType: ${widget.reportType}');
                        }
                        
                        // useFullWidth가 true이면 전체 너비 사용 (resumen del dia에서 사용)
                        if (widget.useFullWidth) {
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final isLargeScreen = constraints.maxWidth >= 800;
                              
                              if (isMobilePortrait && widget.reportType == ReportType.ventas) {
                                debugPrint('   📱 [핸드폰 세로 모드] useFullWidth LayoutBuilder:');
                                debugPrint('      → constraints.maxWidth: ${constraints.maxWidth}');
                                debugPrint('      → constraints.maxHeight: ${constraints.maxHeight}');
                                debugPrint('      → isLargeScreen: $isLargeScreen');
                              }
                              
                              return Builder(
                                builder: (context) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    final renderObject = context.findRenderObject();
                                    if (renderObject != null && renderObject is RenderBox) {
                                      debugPrint('   📱 [핸드폰 세로 모드] useFullWidth Column 렌더링 크기:');
                                      debugPrint('      → width: ${renderObject.size.width}');
                                      debugPrint('      → height: ${renderObject.size.height}');
                                    }
                                  });
                                  
                                  return Column(
                                    children: [
                                      // 작은 화면에서만 날짜 범위 선택 UI 표시 (큰 화면은 AppBar에 있음)
                                      if (!isLargeScreen && (widget.reportType == ReportType.items || widget.reportType == ReportType.ingresos || widget.reportType == ReportType.gastos || widget.reportType == ReportType.alertas || widget.reportType == ReportType.clientes))
                                        _buildItemsFilterSection(),
                                      // 스톡 보고서의 vista 타입 표시
                                      if (widget.reportType == ReportType.stocks && _data != null)
                                        _buildStocksViewType(),
                                      Expanded(
                                        child: Builder(
                                          builder: (expandedContext) {
                                            WidgetsBinding.instance.addPostFrameCallback((_) {
                                              final renderObject = expandedContext.findRenderObject();
                                              if (renderObject != null && renderObject is RenderBox) {
                                                debugPrint('   📱 [핸드폰 세로 모드] Expanded (RefreshIndicator) 렌더링 크기:');
                                                debugPrint('      → width: ${renderObject.size.width}');
                                                debugPrint('      → height: ${renderObject.size.height}');
                                                debugPrint('      → constraints: ${renderObject.constraints}');
                                                // 스크롤 가능 여부 확인
                                                RenderObject? ancestor = renderObject.parent;
                                                RenderViewport? viewport;
                                                while (ancestor != null) {
                                                  if (ancestor is RenderViewport) {
                                                    viewport = ancestor;
                                                    break;
                                                  }
                                                  ancestor = ancestor.parent;
                                                }
                                                if (viewport != null) {
                                                  debugPrint('      → ✅ 스크롤 가능 (RenderViewport 발견)');
                                                  debugPrint('         → viewport.size: ${viewport.size}');
                                                  debugPrint('         → viewport.offset: ${viewport.offset}');
                                                } else {
                                                  debugPrint('      → ⚠️ 스크롤 불가능 (RenderViewport 없음)');
                                                }
                                              }
                                            });
                                            
                                            return RefreshIndicator(
                                              onRefresh: () => _loadData(),
                                              child: Builder(
                                                builder: (refreshContext) {
                                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                                    final renderObject = refreshContext.findRenderObject();
                                                    if (renderObject != null && renderObject is RenderBox) {
                                                      debugPrint('   📱 [핸드폰 세로 모드] RefreshIndicator child 렌더링 크기:');
                                                      debugPrint('      → width: ${renderObject.size.width}');
                                                      debugPrint('      → height: ${renderObject.size.height}');
                                                      debugPrint('      → constraints: ${renderObject.constraints}');
                                                      // 스크롤 가능 여부 확인
                                                      RenderObject? ancestor = renderObject.parent;
                                                      RenderViewport? viewport;
                                                      while (ancestor != null) {
                                                        if (ancestor is RenderViewport) {
                                                          viewport = ancestor;
                                                          break;
                                                        }
                                                        ancestor = ancestor.parent;
                                                      }
                                                      if (viewport != null) {
                                                        debugPrint('      → ✅ 스크롤 가능 (RenderViewport 발견)');
                                                      } else {
                                                        debugPrint('      → ⚠️ 스크롤 불가능 (RenderViewport 없음)');
                                                      }
                                                    }
                                                  });
                                                  
                                                  return _buildReportContent();
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        }
                        
                        // Alertas 보고서는 전체 화면 너비 사용
                        if (widget.reportType == ReportType.alertas) {
                          return Column(
                            children: [
                              Expanded(
                                child: RefreshIndicator(
                                  onRefresh: () => _loadData(),
                                  child: _buildReportContent(),
                                ),
                              ),
                            ],
                          );
                        }
                        
                        final maxWidth = PlatformUtils.getMaxWidth(
                          context,
                          mobileMaxWidth: double.infinity,
                          tabletMaxWidth: 1400,
                          desktopMaxWidth: 1800,
                        );
                        
                        // 모바일 폰 체크 (상위 스코프의 변수 사용)
                        final currentPlatformType = PlatformUtils.getPlatformType(context);
                        final currentIsMobile = currentPlatformType == PlatformType.mobile;
                        final currentIsTablet = PlatformUtils.isIPad(context) || 
                                         (currentPlatformType == PlatformType.mobile && MediaQuery.of(context).size.width >= 800);
                        final currentIsMobilePhone = currentIsMobile && !currentIsTablet;
                        
                        return ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: Column(
                            children: [
                              // Items 및 Ingresos 보고서의 날짜 범위 선택 UI 및 필터링 (모바일 폰에서는 표시하지 않음)
                              if ((widget.reportType == ReportType.items || widget.reportType == ReportType.ingresos) && !currentIsMobilePhone)
                                _buildItemsFilterSection(),
                              // 스톡 보고서의 vista 타입 표시
                              if (widget.reportType == ReportType.stocks && _data != null)
                                _buildStocksViewType(),
                              Expanded(
                                child: RefreshIndicator(
                                  onRefresh: () => _loadData(),
                                  child: _buildReportContent(),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          );
        },
    );
  }

  // AppBar 빌드 메서드 (useFullWidth가 true일 때 사용)
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    String reportTitle,
    IconData reportIcon,
    Color reportColor,
    bool isLargeScreen,
    bool isMobilePortrait,
    bool needsTwoLineAppBar,
    bool needsThreeLineAppBar,
  ) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: needsThreeLineAppBar ? kToolbarHeight * 3 : (needsTwoLineAppBar ? kToolbarHeight * 2 : null),
      leading: widget.useFullWidth && !isLargeScreen && widget.onMenuPressed != null
          ? IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: widget.onMenuPressed,
              tooltip: 'Menú',
            )
          : null,
      title: widget.reportType == ReportType.stocks
          ? LayoutBuilder(
              builder: (context, constraints) {
                // ============================================================
                // 📱 Stocks 보고서 AppBar (useFullWidth) - 모바일 화면 구성 처리
                // ============================================================
                // MobileLayoutHelper를 사용하여 핸드폰의 수직/수평 화면 구성을 처리
                final layoutInfo = MobileLayoutHelper.getLayoutInfo(context);
                final isMobilePortrait = layoutInfo.isMobilePhonePortrait;
                
                // 핸드폰 세로 모드: 2줄로 배치 (컨트롤이 많아서 공간 확보 필요)
                // 핸드폰 가로 모드, 태블릿, 데스크톱: 1줄로 배치 (대형 화면 보호)
                if (isMobilePortrait) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 첫 번째 줄: 아이콘, 제목
                      Row(
                        children: [
                          Icon(reportIcon, color: Colors.white),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              reportTitle,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // 두 번째 줄: Tipo, Temporada 콤보박스, Solo borrados, 필터링 단어 필드
                      Row(
                        children: [
                          if (_tiposList.length > 1 || _temporadasList.length > 1) ...[
                            if (_tiposList.length > 1) ...[
                              _buildTipoSelector(),
                              const SizedBox(width: 8),
                            ],
                            if (_temporadasList.length > 1) ...[
                              _buildTemporadaSelector(),
                              const SizedBox(width: 8),
                            ],
                          ],
                          _buildCodigosSoloBorradosCheckbox(),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFilteringWordFieldInAppBar(),
                          ),
                        ],
                      ),
                    ],
                  );
                }
                
                // 넓은 화면: 1줄로 배치
                return Row(
                  children: [
                    Icon(reportIcon, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(reportTitle),
                    const SizedBox(width: 16),
                    // Tipo와 Temporada 콤보박스 (filteringWord 왼쪽)
                    if (_tiposList.length > 1 || _temporadasList.length > 1) ...[
                      if (_tiposList.length > 1) ...[
                        _buildTipoSelector(),
                        const SizedBox(width: 8),
                      ],
                      if (_temporadasList.length > 1) ...[
                        _buildTemporadaSelector(),
                        const SizedBox(width: 8),
                      ],
                    ],
                    _buildCodigosSoloBorradosCheckbox(),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilteringWordFieldInAppBar(),
                    ),
                  ],
                );
              },
            )
          : (widget.reportType == ReportType.items || widget.reportType == ReportType.ingresos || widget.reportType == ReportType.gastos || widget.reportType == ReportType.alertas || widget.reportType == ReportType.fventas || widget.reportType == ReportType.clientes)
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    // ============================================================
                    // 📱 Items/Ingresos/Gastos/Alertas/Fventas/Clientes 보고서 AppBar (useFullWidth)
                    // ============================================================
                    // MobileLayoutHelper를 사용하여 핸드폰의 수직/수평 화면 구성을 처리
                    final layoutInfo = MobileLayoutHelper.getLayoutInfo(context);
                    final isMobilePortrait = layoutInfo.isMobilePhonePortrait;
                    
                    // 핸드폰 세로 모드: 2줄로 배치 (컨트롤이 많아서 공간 확보 필요)
                    // 핸드폰 가로 모드, 태블릿, 데스크톱: 1줄로 배치 (대형 화면 보호)
                    if (isMobilePortrait) {
                      // Clientes 보고서의 경우 특별한 레이아웃
                      if (widget.reportType == ReportType.clientes) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 첫 번째 줄: 아이콘, 제목, 필터들, 메뉴 버튼, 공유 버튼
                            Row(
                              children: [
                                Icon(reportIcon, color: Colors.white),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    reportTitle,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Responsable Ins 콤보박스
                                _buildClientesResponsableInsSelector(),
                                const SizedBox(width: 8),
                                // Provincias 콤보박스
                                _buildClientesProvinciaSelector(),
                                const SizedBox(width: 8),
                                // Deudores 체크박스
                                _buildClientesDeudoresCheckbox(),
                                const SizedBox(width: 8),
                                // Reservadores 체크박스
                                _buildClientesReservadoresCheckbox(),
                                const SizedBox(width: 8),
                                // FilteringWord 필드
                                Expanded(
                                  child: _buildFilteringWordFieldInAppBar(),
                                ),
                                const SizedBox(width: 8),
                                // 메뉴 버튼
                                PopupMenuButton<ReportType>(
                                  icon: const Icon(Icons.more_vert, color: Colors.white, size: 18),
                                  tooltip: 'Menú',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  iconSize: 18,
                                  onSelected: (ReportType reportType) {
                                    _switchToReport(reportType);
                                  },
                                  itemBuilder: (BuildContext context) {
                    debugPrint('🔍 [PopupMenuButton] itemBuilder 호출됨!');
                    final items = _buildReportMenuItems();
                    debugPrint('🔍 [PopupMenuButton] 메뉴 아이템 개수: ${items.length}');
                    for (int i = 0; i < items.length; i++) {
                      debugPrint('🔍 [PopupMenuButton] 아이템 #$i: ${items[i].runtimeType}');
                    }
                    return items;
                  },
                                ),
                                // 공유 버튼
                                if (_data != null)
                                  IconButton(
                                    icon: const Icon(Icons.share, color: Colors.white, size: 18),
                                    tooltip: 'Compartir como PDF',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    iconSize: 18,
                                    onPressed: () => _shareReport(),
                                  ),
                              ],
                            ),
                            // 두 번째 줄: 달력 2개
                            LayoutBuilder(
                              builder: (context, constraints) {
                                debugPrint('═══════════════════════════════════════════════════════════');
                                debugPrint('🔍 [Clientes AppBar - 넓은 화면] 두 번째 줄 LayoutBuilder 호출됨');
                                debugPrint('   → constraints.maxWidth: ${constraints.maxWidth}');
                                debugPrint('   → constraints.maxHeight: ${constraints.maxHeight}');
                                debugPrint('   → constraints.isTight: ${constraints.isTight}');
                                debugPrint('   → constraints.isNormalized: ${constraints.isNormalized}');
                                debugPrint('═══════════════════════════════════════════════════════════');

                                if (constraints.maxWidth.isInfinite) {
                                  debugPrint('⚠️ [Clientes AppBar - 넓은 화면] constraints.maxWidth가 무한대입니다!');
                                  return const SizedBox.shrink();
                                }

                                return Row(
                                  children: [
                                    SizedBox(
                                      width: constraints.maxWidth,
                                      child: ItemsDateRangeSelector(
                                        reportType: widget.reportType,
                                        startDate: _itemsStartDate,
                                        endDate: _itemsEndDate,
                                        onDateRangeChanged: (startDate, endDate) {
                                          setState(() {
                                            _itemsStartDate = startDate;
                                            _itemsEndDate = endDate;
                                          });
                                          if (widget.onItemsDateRangeChanged != null) {
                                            widget.onItemsDateRangeChanged!(startDate, endDate);
                                          }
                                          _loadData();
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        );
                      }
                      // Alertas 보고서의 경우 특별한 레이아웃
                      if (widget.reportType == ReportType.alertas) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 첫 번째 줄: 아이콘, 제목, VCancelado 버튼, Jefe 버튼, 메뉴 버튼, 공유 버튼
                            Row(
                              children: [
                                Icon(reportIcon, color: Colors.white),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    reportTitle,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // VCancelado 버튼
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _alertasVCancelado = !_alertasVCancelado;
                                      _alertasJefe = false; // 다른 버튼 비활성화
                                      if (_alertasVCancelado) {
                                        // VCancelado 버튼이 활성화되면 filteringWord에 "VCancelado" 입력
                                        _filteringWordController.text = 'VCancelado';
                                      } else {
                                        // VCancelado 버튼이 비활성화되면 filteringWord 초기화
                                        _filteringWordController.text = '';
                                      }
                                    });
                                    _loadData();
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    backgroundColor: _alertasVCancelado 
                                        ? Colors.white.withOpacity(0.3) 
                                        : Colors.transparent,
                                  ),
                                  child: Text(
                                    'VCancelado',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: _alertasVCancelado ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                // Jefe 버튼
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _alertasJefe = !_alertasJefe;
                                      _alertasVCancelado = false; // 다른 버튼 비활성화
                                      if (_alertasJefe) {
                                        // Jefe 버튼이 활성화되면 filteringWord에 "jefe" 입력
                                        _filteringWordController.text = 'jefe';
                                      } else {
                                        // Jefe 버튼이 비활성화되면 filteringWord 초기화
                                        _filteringWordController.text = '';
                                      }
                                    });
                                    _loadData();
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    backgroundColor: _alertasJefe 
                                        ? Colors.white.withOpacity(0.3) 
                                        : Colors.transparent,
                                  ),
                                  child: Text(
                                    'Jefe',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: _alertasJefe ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                // 메뉴 버튼
                                PopupMenuButton<ReportType>(
                                  icon: const Icon(Icons.more_vert, color: Colors.white, size: 18),
                                  tooltip: 'Menú',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  iconSize: 18,
                                  onSelected: (ReportType reportType) {
                                    _switchToReport(reportType);
                                  },
                                  itemBuilder: (BuildContext context) {
                    debugPrint('🔍 [PopupMenuButton] itemBuilder 호출됨!');
                    final items = _buildReportMenuItems();
                    debugPrint('🔍 [PopupMenuButton] 메뉴 아이템 개수: ${items.length}');
                    for (int i = 0; i < items.length; i++) {
                      debugPrint('🔍 [PopupMenuButton] 아이템 #$i: ${items[i].runtimeType}');
                    }
                    return items;
                  },
                                ),
                                // 공유 버튼
                                if (_data != null)
                                  IconButton(
                                    icon: const Icon(Icons.share, color: Colors.white, size: 18),
                                    tooltip: 'Compartir como PDF',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    iconSize: 18,
                                    onPressed: () => _shareReport(),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // 두 번째 줄: 날짜 선택기, 버튼들, Sucursal 선택기, 필터링 단어 필드
                            LayoutBuilder(
                              builder: (context, constraints) {
                                debugPrint('═══════════════════════════════════════════════════════════');
                                debugPrint('🔍 [Clientes AppBar - 넓은 화면] 두 번째 줄 LayoutBuilder 호출됨 (다른 보고서)');
                                debugPrint('   → constraints.maxWidth: ${constraints.maxWidth}');
                                debugPrint('   → constraints.maxHeight: ${constraints.maxHeight}');
                                debugPrint('   → constraints.isTight: ${constraints.isTight}');
                                debugPrint('   → constraints.isNormalized: ${constraints.isNormalized}');
                                debugPrint('═══════════════════════════════════════════════════════════');

                                if (constraints.maxWidth.isInfinite) {
                                  debugPrint('⚠️ [Clientes AppBar - 넓은 화면] constraints.maxWidth가 무한대입니다!');
                                  return const SizedBox.shrink();
                                }

                                return Row(
                                  children: [
                                    Expanded(
                                      child: ItemsDateRangeSelector(
                                        reportType: widget.reportType,
                                        startDate: _itemsStartDate,
                                        endDate: _itemsEndDate,
                                        onDateRangeChanged: (startDate, endDate) {
                                          setState(() {
                                            _itemsStartDate = startDate;
                                            _itemsEndDate = endDate;
                                          });
                                          if (widget.onItemsDateRangeChanged != null) {
                                            widget.onItemsDateRangeChanged!(startDate, endDate);
                                          }
                                          _loadData();
                                        },
                                      ),
                                    ),
                                    // Alertas 보고서의 경우 VCancelado, Jefe, WEB 버튼 추가
                                    if (widget.reportType == ReportType.alertas) ...[
                                      const SizedBox(width: 8),
                                      _buildAlertasFilterButton('VCancelado', _alertasVCancelado, () {
                                        setState(() {
                                          _alertasVCancelado = !_alertasVCancelado;
                                          _alertasJefe = false;
                                          _alertasWeb = false;
                                          if (_alertasVCancelado) {
                                            _filteringWordController.text = 'VCancelado';
                                          } else {
                                            _filteringWordController.text = '';
                                          }
                                        });
                                        _loadData();
                                      }),
                                      const SizedBox(width: 4),
                                      _buildAlertasFilterButton('Jefe', _alertasJefe, () {
                                        setState(() {
                                          _alertasJefe = !_alertasJefe;
                                          _alertasVCancelado = false;
                                          _alertasWeb = false;
                                          if (_alertasJefe) {
                                            _filteringWordController.text = 'Jefe';
                                          } else {
                                            _filteringWordController.text = '';
                                          }
                                        });
                                        _loadData();
                                      }),
                                      const SizedBox(width: 4),
                                      _buildAlertasFilterButton('WEB', _alertasWeb, () {
                                        setState(() {
                                          _alertasWeb = !_alertasWeb;
                                          _alertasVCancelado = false;
                                          _alertasJefe = false;
                                          // WEB 버튼은 filteringWord를 설정하지 않음
                                          if (!_alertasWeb) {
                                            _filteringWordController.text = '';
                                          }
                                        });
                                        _loadData();
                                      }),
                                    ],
                                    if (_availableSucursales != null && _availableSucursales!.length > 1) ...[
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: _buildSucursalSelector(),
                                      ),
                                    ],
                                    if (widget.reportType == ReportType.ingresos) ...[
                                      const SizedBox(width: 8),
                                      _buildIngresosMovidosCheckbox(),
                                    ],
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildFilteringWordFieldInAppBar(),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        );
                      }
                      // 다른 보고서는 기존 레이아웃 유지
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 첫 번째 줄: 아이콘, 제목
                          Row(
                            children: [
                              Icon(reportIcon, color: Colors.white),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  reportTitle,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // 두 번째 줄: 날짜 선택기, Sucursal 선택기, 필터링 단어 필드
                          Row(
                            children: [
                              Flexible(
                                child: ItemsDateRangeSelector(
                                  reportType: widget.reportType,
                                  startDate: widget.reportType == ReportType.fventas ? _ventasStartDate : _itemsStartDate,
                                  endDate: widget.reportType == ReportType.fventas ? _ventasEndDate : _itemsEndDate,
                                  unit: widget.reportType == ReportType.fventas ? _ventasUnit : null, // fventas 보고서의 경우 unit 전달
                                  onDateRangeChanged: (startDate, endDate) {
                                    debugPrint('═══════════════════════════════════════════════════════');
                                    debugPrint('📅 [FVentas] 날짜 범위 변경 이벤트 시작');
                                    debugPrint('   → reportType: ${widget.reportType}');
                                    debugPrint('   → startDate: $startDate');
                                    debugPrint('   → endDate: $endDate');
                                    debugPrint('   → 현재 _ventasStartDate: $_ventasStartDate');
                                    debugPrint('   → 현재 _ventasEndDate: $_ventasEndDate');
                                    debugPrint('   → horizontalScrollController: ${_horizontalScrollController != null}');
                                    
                                    try {
                                      setState(() {
                                        if (widget.reportType == ReportType.fventas) {
                                          _ventasStartDate = startDate;
                                          _ventasEndDate = endDate;
                                          debugPrint('📅 FVentas 날짜 범위 변경: ${DateFormat('yyyy-MM-dd').format(startDate)} ~ ${DateFormat('yyyy-MM-dd').format(endDate)}');
                                        } else {
                                          _itemsStartDate = startDate;
                                          _itemsEndDate = endDate;
                                        }
                                      });
                                      
                                      if (widget.onItemsDateRangeChanged != null && widget.reportType != ReportType.fventas) {
                                        widget.onItemsDateRangeChanged!(startDate, endDate);
                                      }
                                      
                                      debugPrint('   → _loadData() 호출 전');
                                      _loadData();
                                      debugPrint('   → _loadData() 호출 완료');
                                    } catch (e, stackTrace) {
                                      debugPrint('❌ [FVentas] 날짜 범위 변경 중 오류 발생: $e');
                                      debugPrint('❌ [FVentas] 스택 트레이스: $stackTrace');
                                    }
                                    debugPrint('═══════════════════════════════════════════════════════');
                                  },
                                ),
                              ),
                              if (_availableSucursales != null && _availableSucursales!.length > 1) ...[
                                const SizedBox(width: 8),
                                Flexible(
                                  child: _buildSucursalSelector(),
                                ),
                              ],
                              if (widget.reportType == ReportType.ingresos) ...[
                                const SizedBox(width: 8),
                                _buildIngresosMovidosCheckbox(),
                              ],
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildFilteringWordFieldInAppBar(),
                              ),
                            ],
                          ),
                        ],
                      );
                    }
                    
                    // 넓은 화면: Clientes 보고서 - 1줄로 배치 (달력 2개는 filteringWord 왼편에)
                    if (widget.reportType == ReportType.clientes) {
                      return LayoutBuilder(
                        builder: (context, rowConstraints) {
                          debugPrint('═══════════════════════════════════════════════════════════');
                          debugPrint('🔍 [Clientes AppBar - 넓은 화면] Row LayoutBuilder 호출됨');
                          debugPrint('   → rowConstraints.maxWidth: ${rowConstraints.maxWidth}');
                          debugPrint('   → rowConstraints.maxHeight: ${rowConstraints.maxHeight}');
                          debugPrint('   → rowConstraints.isTight: ${rowConstraints.isTight}');
                          debugPrint('   → rowConstraints.isNormalized: ${rowConstraints.isNormalized}');
                          debugPrint('   → isLargeScreen: $isLargeScreen');
                          debugPrint('═══════════════════════════════════════════════════════════');

                          if (rowConstraints.maxWidth.isInfinite) {
                            debugPrint('⚠️ [Clientes AppBar - 넓은 화면] rowConstraints.maxWidth가 무한대입니다!');
                            return const SizedBox.shrink();
                          }

                          return SizedBox(
                            width: rowConstraints.maxWidth,
                            child: Row(
                              children: [
                                Icon(reportIcon, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(reportTitle),
                                const SizedBox(width: 16),
                                // 날짜 버튼 2개 (filteringWord 왼편에)
                                SizedBox(
                                  width: isLargeScreen ? 150 : 90,
                                  child: _buildSingleDateButton(
                                    label: 'Desde',
                                    date: _itemsStartDate,
                                    reportColor: _getReportColor(),
                                    onDateSelected: (date) {
                                      debugPrint('📅 [Clientes AppBar] Desde 버튼 클릭: $date');
                                      setState(() {
                                        _itemsStartDate = date;
                                      });
                                      if (widget.onItemsDateRangeChanged != null) {
                                        widget.onItemsDateRangeChanged!(_itemsStartDate!, _itemsEndDate ?? _itemsStartDate!);
                                      }
                                      _loadData();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: isLargeScreen ? 150 : 90,
                                  child: _buildSingleDateButton(
                                    label: 'Hasta',
                                    date: _itemsEndDate,
                                    reportColor: _getReportColor(),
                                    onDateSelected: (date) {
                                      debugPrint('📅 [Clientes AppBar] Hasta 버튼 클릭: $date');
                                      setState(() {
                                        _itemsEndDate = date;
                                      });
                                      if (widget.onItemsDateRangeChanged != null) {
                                        widget.onItemsDateRangeChanged!(_itemsStartDate ?? _itemsEndDate!, _itemsEndDate!);
                                      }
                                      _loadData();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Clientes 필터들
                                _buildClientesResponsableInsSelector(),
                                const SizedBox(width: 8),
                                _buildClientesProvinciaSelector(),
                                const SizedBox(width: 8),
                                _buildClientesDeudoresCheckbox(),
                                const SizedBox(width: 8),
                                _buildClientesReservadoresCheckbox(),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildFilteringWordFieldInAppBar(),
                                ),
                                const SizedBox(width: 8),
                                // 메뉴 버튼
                                Builder(
                                  builder: (context) {
                                    debugPrint('🔍 [Clientes AppBar] PopupMenuButton 빌드 시작');
                                    return PopupMenuButton<ReportType>(
                                      icon: const Icon(Icons.more_vert, color: Colors.white, size: 18),
                                      tooltip: 'Menú',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      iconSize: 18,
                                      onSelected: (ReportType reportType) {
                                        debugPrint('🔍 [Clientes AppBar] PopupMenuButton onSelected: $reportType');
                                        _switchToReport(reportType);
                                      },
                                      itemBuilder: (BuildContext context) {
                                        debugPrint('🔍 [Clientes AppBar] PopupMenuButton itemBuilder 호출됨!');
                                        final items = _buildReportMenuItems();
                                        debugPrint('🔍 [Clientes AppBar] PopupMenuButton 메뉴 아이템 개수: ${items.length}');
                                        for (int i = 0; i < items.length; i++) {
                                          debugPrint('🔍 [Clientes AppBar] PopupMenuButton 아이템 #$i: ${items[i].runtimeType}');
                                        }
                                        return items;
                                      },
                                    );
                                  },
                                ),
                                // 공유 버튼
                                if (_data != null)
                                  Builder(
                                    builder: (context) {
                                      debugPrint('🔍 [Clientes AppBar] 공유 버튼 빌드 시작');
                                      return IconButton(
                                        icon: const Icon(Icons.share, color: Colors.white, size: 18),
                                        tooltip: 'Compartir como PDF',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        iconSize: 18,
                                        onPressed: () {
                                          debugPrint('🔍 [Clientes AppBar] 공유 버튼 클릭됨');
                                          _shareReport();
                                        },
                                      );
                                    },
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    }
                    
                    // 다른 보고서들: 기존 로직 유지 (alertas 포함)
                    return LayoutBuilder(
                      builder: (context, rowConstraints) {
                        debugPrint('═══════════════════════════════════════════════════════════');
                        debugPrint('🔍 [${widget.reportType} AppBar - 넓은 화면] Row LayoutBuilder 호출됨');
                        debugPrint('   → rowConstraints.maxWidth: ${rowConstraints.maxWidth}');
                        debugPrint('   → rowConstraints.maxHeight: ${rowConstraints.maxHeight}');
                        debugPrint('   → rowConstraints.isTight: ${rowConstraints.isTight}');
                        debugPrint('   → rowConstraints.isNormalized: ${rowConstraints.isNormalized}');
                        debugPrint('   → isLargeScreen: $isLargeScreen');
                        debugPrint('   → reportType: ${widget.reportType}');
                        debugPrint('═══════════════════════════════════════════════════════════');

                        if (rowConstraints.maxWidth.isInfinite) {
                          debugPrint('⚠️ [${widget.reportType} AppBar - 넓은 화면] rowConstraints.maxWidth가 무한대입니다!');
                          return const SizedBox.shrink();
                        }

                        return SizedBox(
                          width: rowConstraints.maxWidth,
                          child: Row(
                            children: [
                              Icon(reportIcon, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(reportTitle),
                              const SizedBox(width: 16),
                              // 큰 화면 또는 수평 모드: 시작일과 종료일 선택기 2개
                              SizedBox(
                                width: isLargeScreen ? 150 : 90,
                                child: _buildSingleDateButton(
                                  label: 'Desde',
                                  date: widget.reportType == ReportType.fventas ? _ventasStartDate : _itemsStartDate,
                                  reportColor: _getReportColor(),
                                  onDateSelected: (date) {
                                    debugPrint('📅 [${widget.reportType} AppBar] Desde 버튼 클릭: $date');
                                    setState(() {
                                      if (widget.reportType == ReportType.fventas) {
                                        _ventasStartDate = date;
                                      } else {
                                        _itemsStartDate = date;
                                      }
                                    });
                                    if (widget.onItemsDateRangeChanged != null && widget.reportType != ReportType.fventas) {
                                      widget.onItemsDateRangeChanged!(
                                        widget.reportType == ReportType.fventas ? _ventasStartDate! : _itemsStartDate!,
                                        widget.reportType == ReportType.fventas ? (_ventasEndDate ?? _ventasStartDate!) : (_itemsEndDate ?? _itemsStartDate!)
                                      );
                                    }
                                    _loadData();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: isLargeScreen ? 150 : 90,
                                child: _buildSingleDateButton(
                                  label: 'Hasta',
                                  date: widget.reportType == ReportType.fventas ? _ventasEndDate : _itemsEndDate,
                                  reportColor: _getReportColor(),
                                  onDateSelected: (date) {
                                    debugPrint('📅 [${widget.reportType} AppBar] Hasta 버튼 클릭: $date');
                                    setState(() {
                                      if (widget.reportType == ReportType.fventas) {
                                        _ventasEndDate = date;
                                      } else {
                                        _itemsEndDate = date;
                                      }
                                    });
                                    if (widget.onItemsDateRangeChanged != null && widget.reportType != ReportType.fventas) {
                                      widget.onItemsDateRangeChanged!(
                                        widget.reportType == ReportType.fventas ? (_ventasStartDate ?? _ventasEndDate!) : (_itemsStartDate ?? _itemsEndDate!),
                                        widget.reportType == ReportType.fventas ? _ventasEndDate! : _itemsEndDate!
                                      );
                                    }
                                    _loadData();
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              // 지점 선택 UI (sucursal이 2개 이상일 때만 표시)
                              if (_availableSucursales != null && _availableSucursales!.length > 1) ...[
                                  _buildSucursalSelector(),
                                  const SizedBox(width: 16),
                              ],
                              if (widget.reportType == ReportType.ingresos) ...[
                                  _buildIngresosMovidosCheckbox(),
                                  const SizedBox(width: 16),
                              ],
                              // Alertas 보고서의 경우 VCancelado 및 Jefe 버튼 추가
                              if (widget.reportType == ReportType.alertas) ...[
                                TextButton(
                                  onPressed: () {
                                    debugPrint('🔍 [Alertas AppBar] VCancelado 버튼 클릭됨');
                                    setState(() {
                                      _alertasVCancelado = !_alertasVCancelado;
                                      _alertasJefe = false; // 다른 버튼 비활성화
                                      if (_alertasVCancelado) {
                                        // VCancelado 버튼이 활성화되면 filteringWord에 "VCancelado" 입력
                                        _filteringWordController.text = 'VCancelado';
                                      } else {
                                        // VCancelado 버튼이 비활성화되면 filteringWord 초기화
                                        _filteringWordController.text = '';
                                      }
                                    });
                                    _loadData();
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    backgroundColor: _alertasVCancelado 
                                        ? Colors.white.withOpacity(0.3) 
                                        : Colors.transparent,
                                  ),
                                  child: Text(
                                    'VCancelado',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: _alertasVCancelado ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                TextButton(
                                  onPressed: () {
                                    debugPrint('🔍 [Alertas AppBar] Jefe 버튼 클릭됨');
                                    setState(() {
                                      _alertasJefe = !_alertasJefe;
                                      _alertasVCancelado = false; // 다른 버튼 비활성화
                                      if (_alertasJefe) {
                                        // Jefe 버튼이 활성화되면 filteringWord에 "jefe" 입력
                                        _filteringWordController.text = 'jefe';
                                      } else {
                                        // Jefe 버튼이 비활성화되면 filteringWord 초기화
                                        _filteringWordController.text = '';
                                      }
                                    });
                                    _loadData();
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    backgroundColor: _alertasJefe 
                                        ? Colors.white.withOpacity(0.3) 
                                        : Colors.transparent,
                                  ),
                                  child: Text(
                                    'Jefe',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: _alertasJefe ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: _buildFilteringWordFieldInAppBar(),
                              ),
                              const SizedBox(width: 8),
                              // 메뉴 버튼
                              PopupMenuButton<ReportType>(
                                icon: const Icon(Icons.more_vert, color: Colors.white, size: 18),
                                tooltip: 'Menú',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                iconSize: 18,
                                onSelected: (ReportType reportType) {
                                  debugPrint('🔍 [${widget.reportType} AppBar] PopupMenuButton onSelected: $reportType');
                                  _switchToReport(reportType);
                                },
                                itemBuilder: (BuildContext context) {
                                  debugPrint('🔍 [${widget.reportType} AppBar] PopupMenuButton itemBuilder 호출됨!');
                                  final items = _buildReportMenuItems();
                                  debugPrint('🔍 [${widget.reportType} AppBar] PopupMenuButton 메뉴 아이템 개수: ${items.length}');
                                  for (int i = 0; i < items.length; i++) {
                                    debugPrint('🔍 [${widget.reportType} AppBar] PopupMenuButton 아이템 #$i: ${items[i].runtimeType}');
                                  }
                                  return items;
                                },
                              ),
                              // 공유 버튼
                              if (_data != null)
                                IconButton(
                                  icon: const Icon(Icons.share, color: Colors.white, size: 18),
                                  tooltip: 'Compartir como PDF',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  iconSize: 18,
                                  onPressed: () {
                                    debugPrint('🔍 [${widget.reportType} AppBar] 공유 버튼 클릭됨');
                                    _shareReport();
                                  },
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                )
              : widget.reportType == ReportType.ventas
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        // ============================================================
                        // 📱 Ventas 보고서 AppBar (useFullWidth) - 모바일 화면 구성 처리
                        // ============================================================
                        // MobileLayoutHelper를 사용하여 핸드폰의 수직/수평 화면 구성을 처리
                        final layoutInfo = MobileLayoutHelper.getLayoutInfo(context);
                        final isMobilePortrait = layoutInfo.isMobilePhonePortrait;
                        
                        // 핸드폰 세로 모드: 2줄로 배치 (컨트롤이 많아서 공간 확보 필요)
                        // 핸드폰 가로 모드, 태블릿, 데스크톱: 1줄로 배치 (대형 화면 보호)
                        if (isMobilePortrait) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 첫 번째 줄: 아이콘, 제목, Unit 버튼들
                              Row(
                                children: [
                                  Icon(reportIcon, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      reportTitle,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: _buildVentasUnitButtonsInAppBar(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // 두 번째 줄: 날짜 선택기, Sucursal 선택기, Descontado 체크박스, 필터링 단어 필드
                              Row(
                                children: [
                                  Flexible(
                                    child: _buildCompactDateRangeButton(_getReportColor()),
                                  ),
                                  if (_availableSucursales != null && _availableSucursales!.length > 1) ...[
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: _buildSucursalSelector(),
                                    ),
                                  ],
                                  const SizedBox(width: 8),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Checkbox(
                                        value: _ventasDescontado,
                                        onChanged: (value) {
                                          setState(() {
                                            _ventasDescontado = value ?? false;
                                          });
                                          _loadData();
                                        },
                                        checkColor: Colors.white,
                                        fillColor: WidgetStateProperty.resolveWith<Color>(
                                          (Set<WidgetState> states) {
                                            if (states.contains(WidgetState.selected)) {
                                              return Colors.white.withOpacity(0.3);
                                            }
                                            return Colors.transparent;
                                          },
                                        ),
                                        side: const BorderSide(color: Colors.white, width: 1.5),
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      const SizedBox(width: 2),
                                      const Text(
                                        'Descontado',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Checkbox(
                                        value: _ventasReservado,
                                        onChanged: (value) {
                                          setState(() {
                                            _ventasReservado = value ?? false;
                                          });
                                          _loadData();
                                        },
                                        checkColor: Colors.white,
                                        fillColor: WidgetStateProperty.resolveWith<Color>(
                                          (Set<WidgetState> states) {
                                            if (states.contains(WidgetState.selected)) {
                                              return Colors.white.withOpacity(0.3);
                                            }
                                            return Colors.transparent;
                                          },
                                        ),
                                        side: const BorderSide(color: Colors.white, width: 1.5),
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      const SizedBox(width: 2),
                                      const Text(
                                        'Reservado',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Checkbox(
                                        value: _ventasCredito,
                                        onChanged: (value) {
                                          setState(() {
                                            _ventasCredito = value ?? false;
                                          });
                                          _loadData();
                                        },
                                        checkColor: Colors.white,
                                        fillColor: WidgetStateProperty.resolveWith<Color>(
                                          (Set<WidgetState> states) {
                                            if (states.contains(WidgetState.selected)) {
                                              return Colors.white.withOpacity(0.3);
                                            }
                                            return Colors.transparent;
                                          },
                                        ),
                                        side: const BorderSide(color: Colors.white, width: 1.5),
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      const SizedBox(width: 2),
                                      const Text(
                                        'Crédito',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildFilteringWordFieldInAppBar(),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }
                        
                        // ============================================================
                        // 📱 넓은 화면 (태블릿/데스크톱): 1줄로 배치
                        // ============================================================
                        // 디버깅: _buildAppBar 내부 ventas title 렌더링
                        debugPrint('═══════════════════════════════════════════════════════');
                        debugPrint('📅 [_buildAppBar] Ventas AppBar title 렌더링');
                        debugPrint('   → 파일: report_screen.dart');
                        debugPrint('   → 라인: ~5098');
                        debugPrint('   → constraints.maxWidth: ${constraints.maxWidth}');
                        debugPrint('   → isLargeScreen: ${layoutInfo.isLargeScreen}');
                        debugPrint('   → orientation: ${layoutInfo.orientation}');
                        debugPrint('   → platformType: ${layoutInfo.platformType}');
                        debugPrint('   → isMobile: ${layoutInfo.isMobilePlatform}');
                        debugPrint('   → isMobilePortrait: $isMobilePortrait');
                        
                        final isDesktopOrTablet = layoutInfo.platformType == PlatformType.desktop || PlatformUtils.isIPad(context);
                        debugPrint('   → isDesktopOrTablet: $isDesktopOrTablet');
                        
                        if (isDesktopOrTablet) {
                          debugPrint('   ✅ isDesktopOrTablet = true → 달력 버튼 2개 포함 Row 반환');
                          
                          // Sucursal 선택 콤보 미리 빌드
                          final sucursalSelectorWidget = _buildSucursalSelectorWithDebug('큰 화면 - AppBar title (isDesktopOrTablet)');
                          debugPrint('🔍 [Row children 구성] sucursalSelectorWidget: ${sucursalSelectorWidget != null ? sucursalSelectorWidget.runtimeType : "null"}');
                          
                          // Row children 리스트 구성
                          final rowChildren = <Widget>[
                            // Unit 선택 콤보
                            _buildVentasUnitButtonsInAppBar(),
                            const SizedBox(width: 8),
                            // 달력 버튼 2개
                            SizedBox(
                              width: 90,
                              child: _buildSingleDateButton(
                                label: 'Desde',
                                date: _ventasStartDate,
                                reportColor: _getReportColor(),
                                unit: _ventasUnit,
                                onDateSelected: (date) {
                                  setState(() {
                                    _ventasStartDate = date;
                                    // month: 첫째 달력만 변경. 종료일은 유지. 새 시작이 종료보다 늦을 때만 해당 월 말일로 맞춤
                                    if (_ventasUnit == 'month' && (_ventasEndDate == null || date.isAfter(_ventasEndDate!))) {
                                      _ventasEndDate = DateTime(date.year, date.month + 1, 0);
                                    }
                                  });
                                  _loadData();
                                },
                              ),
                            ),
                            const SizedBox(width: 4),
                            SizedBox(
                              width: 90,
                              child: _buildSingleDateButton(
                                label: 'Hasta',
                                date: _ventasEndDate,
                                reportColor: _getReportColor(),
                                unit: _ventasUnit,
                                onDateSelected: (date) {
                                  setState(() {
                                    _ventasEndDate = date;
                                    if (_ventasUnit == 'month') {
                                      _ventasStartDate = DateTime(date.year, date.month, 1);
                                    }
                                  });
                                  _loadData();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                          ];
                          
                          // Sucursal 선택 콤보 추가
                          if (sucursalSelectorWidget != null) {
                            debugPrint('🔍 [Row children 구성] sucursalSelectorWidget 추가됨');
                            rowChildren.add(sucursalSelectorWidget);
                            rowChildren.add(const SizedBox(width: 8));
                          } else {
                            debugPrint('🔍 [Row children 구성] sucursalSelectorWidget가 null이므로 추가 안 함');
                          }
                          
                          debugPrint('🔍 [Row children 구성] 최종 children 개수: ${rowChildren.length}');
                          for (int i = 0; i < rowChildren.length; i++) {
                            debugPrint('   → children[$i]: ${rowChildren[i].runtimeType}');
                          }
                          
                          return Builder(
                            builder: (context) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                final renderObject = context.findRenderObject();
                                if (renderObject != null && renderObject is RenderBox) {
                                  debugPrint('🔍 [Row 렌더링] 실제 크기: width=${renderObject.size.width}, height=${renderObject.size.height}');
                                  if (renderObject is RenderFlex) {
                                    debugPrint('🔍 [Row 렌더링] children 개수: ${renderObject.childCount}');
                                    RenderBox? child = renderObject.firstChild;
                                    int index = 0;
                                    while (child != null) {
                                      debugPrint('   → child[$index]: width=${child.size.width}, height=${child.size.height}, type=${child.runtimeType}');
                                      
                                      // child[6]이 콤보박스인 경우 상세 정보 출력
                                      if (index == 6 && sucursalSelectorWidget != null) {
                                        debugPrint('   🔍 [콤보박스 디버깅] child[6] 상세 정보:');
                                        debugPrint('      - 실제 렌더링 크기: ${child.size.width} x ${child.size.height}');
                                        debugPrint('      - RenderBox 타입: ${child.runtimeType}');
                                        debugPrint('      - 부모 RenderBox 크기: ${renderObject.size.width} x ${renderObject.size.height}');
                                        debugPrint('      - 부모 RenderBox 타입: ${renderObject.runtimeType}');
                                        
                                        // 콤보박스의 실제 위치 확인
                                        final offset = child.localToGlobal(Offset.zero);
                                        debugPrint('      - 콤보박스 화면 위치: x=${offset.dx}, y=${offset.dy}');
                                        
                                        // 콤보박스가 화면 밖에 있는지 확인
                                        final screenSize = MediaQuery.of(context).size;
                                        debugPrint('      - 화면 크기: ${screenSize.width} x ${screenSize.height}');
                                        debugPrint('      - 콤보박스가 화면 안에 있는지: ${offset.dx >= 0 && offset.dx < screenSize.width && offset.dy >= 0 && offset.dy < screenSize.height}');
                                      }
                                      
                                      final parentData = child.parentData;
                                      if (parentData is FlexParentData) {
                                        child = parentData.nextSibling;
                                      } else {
                                        break;
                                      }
                                      index++;
                                    }
                                  }
                                }
                              });
                              
                              return Row(
                                children: [
                                  ...rowChildren,
                                  // Descontado, Reservado, Crédito 체크박스
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Checkbox(
                                  value: _ventasDescontado,
                                  onChanged: (value) {
                                    setState(() {
                                      _ventasDescontado = value ?? false;
                                    });
                                    _loadData();
                                  },
                                  checkColor: Colors.white,
                                  fillColor: WidgetStateProperty.resolveWith<Color>(
                                    (Set<WidgetState> states) {
                                      if (states.contains(WidgetState.selected)) {
                                        return Colors.white.withOpacity(0.3);
                                      }
                                      return Colors.transparent;
                                    },
                                  ),
                                  side: const BorderSide(color: Colors.white, width: 1.5),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                const SizedBox(width: 2),
                                const Text(
                                  'Descontado',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Checkbox(
                                  value: _ventasReservado,
                                  onChanged: (value) {
                                    setState(() {
                                      _ventasReservado = value ?? false;
                                    });
                                    _loadData();
                                  },
                                  checkColor: Colors.white,
                                  fillColor: WidgetStateProperty.resolveWith<Color>(
                                    (Set<WidgetState> states) {
                                      if (states.contains(WidgetState.selected)) {
                                        return Colors.white.withOpacity(0.3);
                                      }
                                      return Colors.transparent;
                                    },
                                  ),
                                  side: const BorderSide(color: Colors.white, width: 1.5),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                const SizedBox(width: 2),
                                const Text(
                                  'Reservado',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Checkbox(
                                  value: _ventasCredito,
                                  onChanged: (value) {
                                    setState(() {
                                      _ventasCredito = value ?? false;
                                    });
                                    _loadData();
                                  },
                                  checkColor: Colors.white,
                                  fillColor: WidgetStateProperty.resolveWith<Color>(
                                    (Set<WidgetState> states) {
                                      if (states.contains(WidgetState.selected)) {
                                        return Colors.white.withOpacity(0.3);
                                      }
                                      return Colors.transparent;
                                    },
                                  ),
                                  side: const BorderSide(color: Colors.white, width: 1.5),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                const SizedBox(width: 2),
                                const Text(
                                  'Crédito',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Checkbox(
                                  value: _ventasMovidos,
                                  onChanged: (value) {
                                    debugPrint('🔍 [Ventas AppBar] Movidos 체크박스 클릭: $value');
                                    setState(() {
                                      _ventasMovidos = value ?? false;
                                    });
                                    _loadData();
                                  },
                                  checkColor: Colors.white,
                                  fillColor: WidgetStateProperty.resolveWith<Color>(
                                    (Set<WidgetState> states) {
                                      if (states.contains(WidgetState.selected)) {
                                        return Colors.white.withOpacity(0.3);
                                      }
                                      return Colors.transparent;
                                    },
                                  ),
                                  side: const BorderSide(color: Colors.white, width: 1.5),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                const SizedBox(width: 2),
                                const Text(
                                  'Movidos',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            // filteringWord
                            Expanded(
                              child: _buildFilteringWordFieldInAppBar(),
                            ),
                          ],
                        );
                              },
                            );
                        } else {
                          debugPrint('   ⚠️ isDesktopOrTablet = false → 핸드폰 넓은 화면 레이아웃 사용');
                          return Row(
                            children: [
                              // Unit 선택 콤보
                              _buildVentasUnitButtonsInAppBar(),
                              const SizedBox(width: 8),
                              // Descontado, Reservado, Crédito, Movidos 체크박스
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    value: _ventasDescontado,
                                    onChanged: (value) {
                                      setState(() {
                                        _ventasDescontado = value ?? false;
                                      });
                                      _loadData();
                                    },
                                    checkColor: Colors.white,
                                    fillColor: WidgetStateProperty.resolveWith<Color>(
                                      (Set<WidgetState> states) {
                                        if (states.contains(WidgetState.selected)) {
                                          return Colors.white.withOpacity(0.3);
                                        }
                                        return Colors.transparent;
                                      },
                                    ),
                                    side: const BorderSide(color: Colors.white, width: 1.5),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  const SizedBox(width: 2),
                                  const Text(
                                    'Descontado',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Checkbox(
                                    value: _ventasReservado,
                                    onChanged: (value) {
                                      setState(() {
                                        _ventasReservado = value ?? false;
                                      });
                                      _loadData();
                                    },
                                    checkColor: Colors.white,
                                    fillColor: WidgetStateProperty.resolveWith<Color>(
                                      (Set<WidgetState> states) {
                                        if (states.contains(WidgetState.selected)) {
                                          return Colors.white.withOpacity(0.3);
                                        }
                                        return Colors.transparent;
                                      },
                                    ),
                                    side: const BorderSide(color: Colors.white, width: 1.5),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  const SizedBox(width: 2),
                                  const Text(
                                    'Reservado',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Checkbox(
                                    value: _ventasCredito,
                                    onChanged: (value) {
                                      setState(() {
                                        _ventasCredito = value ?? false;
                                      });
                                      _loadData();
                                    },
                                    checkColor: Colors.white,
                                    fillColor: WidgetStateProperty.resolveWith<Color>(
                                      (Set<WidgetState> states) {
                                        if (states.contains(WidgetState.selected)) {
                                          return Colors.white.withOpacity(0.3);
                                        }
                                        return Colors.transparent;
                                      },
                                    ),
                                    side: const BorderSide(color: Colors.white, width: 1.5),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  const SizedBox(width: 2),
                                  const Text(
                                    'Crédito',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Checkbox(
                                    value: _ventasMovidos,
                                    onChanged: (value) {
                                      debugPrint('🔍 [Ventas AppBar] Movidos 체크박스 클릭: $value');
                                      setState(() {
                                        _ventasMovidos = value ?? false;
                                      });
                                      _loadData();
                                    },
                                    checkColor: Colors.white,
                                    fillColor: WidgetStateProperty.resolveWith<Color>(
                                      (Set<WidgetState> states) {
                                        if (states.contains(WidgetState.selected)) {
                                          return Colors.white.withOpacity(0.3);
                                        }
                                        return Colors.transparent;
                                      },
                                    ),
                                    side: const BorderSide(color: Colors.white, width: 1.5),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  const SizedBox(width: 2),
                                  const Text(
                                    'Movidos',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildFilteringWordFieldInAppBar(),
                              ),
                            ],
                          );
                        }
                      },
                    )
                  : (widget.reportType == ReportType.codigos || widget.reportType == ReportType.todocodigos)
                      ? LayoutBuilder(
                          builder: (context, constraints) {
                            // ============================================================
                            // 📱 Codigos/Todocodigos 보고서 AppBar (useFullWidth) - 모바일 화면 구성 처리
                            // ============================================================
                            // MobileLayoutHelper를 사용하여 핸드폰의 수직/수평 화면 구성을 처리
                            final layoutInfo = MobileLayoutHelper.getLayoutInfo(context);
                            final isMobilePortrait = layoutInfo.isMobilePhonePortrait;
                            
                            // 핸드폰 세로 모드: 3줄로 배치 (컨트롤이 많아서 공간 확보 필요)
                            // 핸드폰 가로 모드, 태블릿, 데스크톱: 1줄로 배치 (대형 화면 보호)
                            if (isMobilePortrait) {
                              debugPrint('═══════════════════════════════════════════════════════════');
                              debugPrint('📱 [Codigos/Todocodigos AppBar (useFullWidth)] 핸드폰 세로 모드 - 3줄 구성');
                              debugPrint('   → reportType: ${widget.reportType}');
                              debugPrint('   → _tiposList.length: ${_tiposList.length}');
                              debugPrint('   → _temporadasList.length: ${_temporadasList.length}');
                              debugPrint('═══════════════════════════════════════════════════════════');
                              
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 첫 번째 줄: 아이콘, 제목
                                  Builder(
                                    builder: (rowContext) {
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        final renderObject = rowContext.findRenderObject();
                                        if (renderObject != null && renderObject is RenderBox) {
                                          debugPrint('   📱 [Codigos/Todocodigos AppBar (useFullWidth)] 첫 번째 Row 렌더링 크기:');
                                          debugPrint('      → width: ${renderObject.size.width}');
                                          debugPrint('      → height: ${renderObject.size.height}');
                                        }
                                      });
                                      return Row(
                                        children: [
                                          Icon(reportIcon, color: Colors.white),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              reportTitle,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 16),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 4),
                                  // 두 번째 줄: Tipo, Temporada 콤보박스
                                  Builder(
                                    builder: (rowContext) {
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        final renderObject = rowContext.findRenderObject();
                                        if (renderObject != null && renderObject is RenderBox) {
                                          debugPrint('   📱 [Codigos/Todocodigos AppBar (useFullWidth)] 두 번째 Row 렌더링 크기:');
                                          debugPrint('      → width: ${renderObject.size.width}');
                                          debugPrint('      → height: ${renderObject.size.height}');
                                        }
                                      });
                                      return Row(
                                        children: [
                                          if (_tiposList.length > 1 || _temporadasList.length > 1) ...[
                                            if (_tiposList.length > 1) ...[
                                              Flexible(
                                                child: _buildTipoSelector(),
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                            if (_temporadasList.length > 1) ...[
                                              Flexible(
                                                child: _buildTemporadaSelector(),
                                              ),
                                            ],
                                          ],
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 4),
                                  // 세 번째 줄: Solo borrados, 필터링 단어 필드
                                  Builder(
                                    builder: (rowContext) {
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        final renderObject = rowContext.findRenderObject();
                                        if (renderObject != null && renderObject is RenderBox) {
                                          debugPrint('   📱 [Codigos/Todocodigos AppBar (useFullWidth)] 세 번째 Row 렌더링 크기:');
                                          debugPrint('      → width: ${renderObject.size.width}');
                                          debugPrint('      → height: ${renderObject.size.height}');
                                        }
                                      });
                                      return Row(
                                        children: [
                                          _buildCodigosSoloBorradosCheckbox(),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _buildFilteringWordFieldInAppBar(),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              );
                            }
                            
                            // 넓은 화면: 1줄로 배치
                            return Row(
                              children: [
                                Icon(reportIcon, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(reportTitle),
                                const SizedBox(width: 16),
                                // Tipo와 Temporada 콤보박스 (filteringWord 왼쪽)
                                if (_tiposList.length > 1 || _temporadasList.length > 1) ...[
                                  if (_tiposList.length > 1) ...[
                                    _buildTipoSelector(),
                                    const SizedBox(width: 8),
                                  ],
                                  if (_temporadasList.length > 1) ...[
                                    _buildTemporadaSelector(),
                                    const SizedBox(width: 8),
                                  ],
                                ],
                                _buildCodigosSoloBorradosCheckbox(),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildFilteringWordFieldInAppBar(),
                                ),
                              ],
                            );
                          },
                        )
                      : widget.reportType == ReportType.stocks
                          ? LayoutBuilder(
                              builder: (context, constraints) {
                                final isLargeScreen = constraints.maxWidth > 800;
                                return Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                    Icon(reportIcon, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(reportTitle),
                                    if (isLargeScreen && _data != null) ...[
                                      const SizedBox(width: 16),
                                      _buildStocksViewTypeInAppBar(),
                                    ],
                                    const SizedBox(width: 16),
                                    // Tipo와 Temporada 콤보박스 (filteringWord 왼쪽)
                                    Builder(
                                      builder: (context) {
                                        debugPrint('═══════════════════════════════════════════════════════');
                                        debugPrint('🔍 [Stocks AppBar - useFullWidth] Tipo/Temporada 콤보박스 표시 조건 확인');
                                        debugPrint('   → _tiposList.length: ${_tiposList.length}');
                                        debugPrint('   → _temporadasList.length: ${_temporadasList.length}');
                                        debugPrint('   → _tiposList: $_tiposList');
                                        debugPrint('   → _temporadasList: $_temporadasList');
                                        debugPrint('═══════════════════════════════════════════════════════');
                                        
                                        // 길이가 1 이상이면 표시 (1개여도 선택할 수 있도록)
                                        if (_tiposList.isNotEmpty || _temporadasList.isNotEmpty) {
                                          return Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (_tiposList.isNotEmpty) ...[
                                                _buildTipoSelector(),
                                                const SizedBox(width: 8),
                                              ],
                                              if (_temporadasList.isNotEmpty) ...[
                                                _buildTemporadaSelector(),
                                                const SizedBox(width: 8),
                                              ],
                                            ],
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                    Expanded(
                                      child: _buildFilteringWordFieldInAppBar(),
                                    ),
                                  ],
                                );
                              },
                            )
                          : Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                Icon(reportIcon, color: Colors.white),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(reportTitle),
                                    ],
                                  ),
                                ),
                              ],
                            ),
      backgroundColor: reportColor,
      actions: () {
        // 디버깅: actions 설정 로직 확인
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('🔍 [AppBar Actions] 설정 로직 확인');
        debugPrint('   → reportType: ${widget.reportType}');
        debugPrint('   → isLargeScreen: $isLargeScreen');
        debugPrint('   → needsThreeLineAppBar: $needsThreeLineAppBar');
        debugPrint('   → needsTwoLineAppBar: $needsTwoLineAppBar');
        debugPrint('   → useFullWidth: ${widget.useFullWidth}');
        
        // 대형 화면에서 title 내부에 메뉴 버튼과 공유 버튼이 있는 보고서들
        // ventas는 title에 공유 버튼이 없으므로 actions에 표시되도록 제외
        final hasButtonsInTitle = isLargeScreen && (
          widget.reportType == ReportType.items ||
          widget.reportType == ReportType.ingresos ||
          widget.reportType == ReportType.gastos ||
          widget.reportType == ReportType.fventas ||
          widget.reportType == ReportType.alertas ||
          widget.reportType == ReportType.clientes ||
          widget.reportType == ReportType.stocks ||
          widget.reportType == ReportType.codigos ||
          widget.reportType == ReportType.todocodigos
        );
        
        debugPrint('   → hasButtonsInTitle: $hasButtonsInTitle');
        
        // 좁은 화면 또는 대형 화면에서 title에 버튼이 있는 경우 actions 비활성화
        final shouldDisableActions = needsThreeLineAppBar || 
                                     needsTwoLineAppBar || 
                                     hasButtonsInTitle;
        
        debugPrint('   → shouldDisableActions: $shouldDisableActions');
        debugPrint('═══════════════════════════════════════════════════════');
        
        if (shouldDisableActions) {
          return <Widget>[]; // title에 이미 메뉴 버튼과 공유 버튼이 있으므로 actions 비활성화
        }
        
        return <Widget>[
          // 보고서 선택 드롭다운 메뉴
          PopupMenuButton<ReportType>(
            icon: const Icon(Icons.assessment, color: Colors.white),
            tooltip: 'Reportes',
            onSelected: (ReportType reportType) {
              debugPrint('🔍 [AppBar Actions] PopupMenuButton onSelected: $reportType');
              _switchToReport(reportType);
            },
            itemBuilder: (BuildContext context) {
              debugPrint('🔍 [AppBar Actions] PopupMenuButton itemBuilder 호출됨!');
              final items = _buildReportMenuItems();
              debugPrint('🔍 [AppBar Actions] PopupMenuButton 메뉴 아이템 개수: ${items.length}');
              return items;
            },
          ),
          // 공유 버튼 (macOS/Windows: Excel, 기타: PDF)
          if (_data != null)
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              tooltip: Platform.isMacOS || Platform.isWindows 
                  ? 'Compartir como Excel' 
                  : 'Compartir como PDF',
              onPressed: () {
                debugPrint('🔍 [AppBar Actions] 공유 버튼 클릭됨');
                _shareReport();
              },
            ),
        ];
      }(),
    );
  }

  // Body 빌드 메서드 (useFullWidth가 true일 때 사용)
  Widget _buildBody(BuildContext context, AppLocalizations l10n, Color reportColor) {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [_buildBody] 호출됨');
    debugPrint('   → reportType: ${widget.reportType}');
    debugPrint('   → Platform.isWindows: ${Platform.isWindows}');
    debugPrint('   → _isLoading: $_isLoading');
    debugPrint('   → _data: ${_data != null ? "있음 (키: ${_data!.keys.toList()})" : "null"}');
    debugPrint('   → _errorMessage: $_errorMessage');
    debugPrint('═══════════════════════════════════════════════════════');
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: reportColor),
            const SizedBox(height: 16),
            Text(l10n.loadingData),
          ],
        ),
      );
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.errorOccurred,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: reportColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    
    if (_data == null || _data!.isEmpty) {
      return Center(child: Text(l10n.noData));
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth >= 800;
        
        // Stocks 화면 디버깅
        if (widget.reportType == ReportType.stocks) {
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('📱 [Stocks] LayoutBuilder 빌드');
          debugPrint('   → constraints.maxWidth: ${constraints.maxWidth}');
          debugPrint('   → constraints.maxHeight: ${constraints.maxHeight}');
          debugPrint('   → isLargeScreen: $isLargeScreen');
          debugPrint('   → MediaQuery size: ${MediaQuery.of(context).size}');
          debugPrint('═══════════════════════════════════════════════════════');
        }
        
        return Column(
          children: [
            // 작은 화면에서만 날짜 범위 선택 UI 표시 (큰 화면은 AppBar에 있음)
            if (!isLargeScreen && (widget.reportType == ReportType.items || widget.reportType == ReportType.ingresos || widget.reportType == ReportType.gastos || widget.reportType == ReportType.alertas || widget.reportType == ReportType.clientes))
              _buildItemsFilterSection(),
            // 스톡 보고서의 vista 타입 표시
            if (widget.reportType == ReportType.stocks && _data != null)
              _buildStocksViewType(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadData(),
                child: _buildReportContent(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReportContent() {
    print('🟡🟡🟡 [report_screen.dart:8080] _buildReportContent 메서드 호출 시작');
    print('   → 라인: 8080');
    if (widget.reportType == ReportType.ventas) {
      print('   → _ventasUnit: $_ventasUnit');
      print('   → _ventasUnit 타입: ${_ventasUnit.runtimeType}');
      print('   → _ventasUnit == "day": ${_ventasUnit == "day"}');
      print('   → _ventasUnit == "month": ${_ventasUnit == "month"}');
      print('   → _ventasUnit == "year": ${_ventasUnit == "year"}');
      print('   → _ventasUnit == "vcode": ${_ventasUnit == "vcode"}');
      print('   → 호출 스택 (처음 5줄):');
      print('      ${StackTrace.current.toString().split("\n").take(5).join("\n      ")}');
    }
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [_buildReportContent] 호출됨');
    debugPrint('   → reportType: ${widget.reportType}');
    debugPrint('   → Platform.isWindows: ${Platform.isWindows}');
    debugPrint('   → _data: ${_data != null ? "있음" : "null"}');
    if (widget.reportType == ReportType.ventas) {
      debugPrint('   → [Ventas] _ventasUnit: $_ventasUnit');
      debugPrint('   → [Ventas] _ventasUnit 타입: ${_ventasUnit.runtimeType}');
      debugPrint('   → [Ventas] _ventasUnit == "day": ${_ventasUnit == "day"}');
      debugPrint('   → [Ventas] _ventasUnit == "month": ${_ventasUnit == "month"}');
      debugPrint('   → [Ventas] _ventasUnit == "year": ${_ventasUnit == "year"}');
      debugPrint('   → [Ventas] _ventasUnit == "vcode": ${_ventasUnit == "vcode"}');
      debugPrint('   → 호출 스택 (처음 5줄):');
      debugPrint('      ${StackTrace.current.toString().split("\n").take(5).join("\n      ")}');
    }
    
    if (_data == null) {
      debugPrint('   ⚠️ _data가 null임 - "No hay datos" 반환');
      debugPrint('═══════════════════════════════════════════════════════');
      return const Center(child: Text('No hay datos'));
    }
    
    debugPrint('   → _data 키: ${_data!.keys.toList()}');
    
    // Alertas 보고서 디버깅
    if (widget.reportType == ReportType.alertas) {
      debugPrint('   → [Alertas] _data 타입: ${_data.runtimeType}');
      debugPrint('   → [Alertas] _data 키: ${_data!.keys.toList()}');
      if (_data!.containsKey('data')) {
        debugPrint('   → [Alertas] data 키 존재: true');
        debugPrint('   → [Alertas] data 타입: ${_data!['data'].runtimeType}');
        if (_data!['data'] is List) {
          final dataList = _data!['data'] as List;
          debugPrint('   → [Alertas] data 리스트 길이: ${dataList.length}');
          if (dataList.isNotEmpty) {
            debugPrint('   → [Alertas] 첫 번째 항목: ${dataList.first}');
            if (dataList.first is Map) {
              debugPrint('   → [Alertas] 첫 번째 항목 키: ${(dataList.first as Map).keys.toList()}');
            }
          } else {
            debugPrint('   ⚠️ [Alertas] data 리스트가 비어있음!');
          }
        } else {
          debugPrint('   ⚠️ [Alertas] data가 List가 아님: ${_data!['data'].runtimeType}');
        }
      } else {
        debugPrint('   ⚠️ [Alertas] data 키가 없음');
      }
    }
    
    if (widget.reportType == ReportType.ventas) {
      debugPrint('   → [Ventas] _data 타입: ${_data.runtimeType}');
      if (_data!.containsKey('data') && _data!['data'] is List) {
        debugPrint('   → [Ventas] data 리스트 길이: ${(_data!['data'] as List).length}');
      } else {
        debugPrint('   ⚠️ [Ventas] data 키가 없거나 List가 아님');
      }
    }
    debugPrint('═══════════════════════════════════════════════════════');

    // 데이터 구조 분석 및 적절한 위젯 반환
    final data = _data!;
    
    // Stocks 보고서의 경우 특별 처리
    if (widget.reportType == ReportType.stocks) {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('📱 [Stocks] _buildReportContent에서 Stocks 처리 시작');
      debugPrint('   → data.containsKey("data"): ${data.containsKey("data")}');
      if (data.containsKey('data')) {
        debugPrint('   → data["data"] 타입: ${data['data'].runtimeType}');
        if (data['data'] is List) {
          final stocksList = data['data'] as List;
          debugPrint('   → data["data"] 길이: ${stocksList.length}');
          if (stocksList.isNotEmpty) {
            debugPrint('   → 첫 번째 항목: ${stocksList.first}');
            if (stocksList.first is Map) {
              debugPrint('   → 첫 번째 항목 키: ${(stocksList.first as Map).keys.toList()}');
            }
          }
        } else {
          debugPrint('   ⚠️ data["data"]가 List가 아님: ${data['data'].runtimeType}');
        }
      } else {
        debugPrint('   ⚠️ data에 "data" 키가 없음');
      }
      debugPrint('   → MediaQuery size: ${MediaQuery.of(context).size}');
      debugPrint('═══════════════════════════════════════════════════════');
      
      if (data.containsKey('data') && data['data'] is List) {
        // 성능 최적화: RepaintBoundary로 감싸서 불필요한 리페인트 방지
        return RepaintBoundary(
          child: _buildStocksContent(data),
        );
      } else {
        debugPrint('   ⚠️ Stocks 데이터 형식이 올바르지 않음 - 기본 위젯 반환');
        return const Center(child: Text('No hay datos disponibles'));
      }
    }
    
    // Codigos 및 Todo Codigos 보고서의 경우 특별 처리
    if ((widget.reportType == ReportType.codigos || widget.reportType == ReportType.todocodigos) && 
        data.containsKey('data') && 
        data['data'] is List) {
      // 성능 최적화: RepaintBoundary로 감싸서 불필요한 리페인트 방지
      return RepaintBoundary(
        child: _buildCodigosContent(data),
      );
    }
    
    // Gastos 보고서의 경우 특별 처리
    if (widget.reportType == ReportType.gastos) {
      // 새로운 구조: summary_by_rubro가 있고 data가 List인 경우
      if (data.containsKey('summary_by_rubro') && 
          data.containsKey('data') && 
          data['data'] is List) {
        print('📊 Gastos 새로운 구조 감지: summary_by_rubro + data(List)');
        final filteringWord = _filteringWordController.text.trim();
        // _getDisplayedData()를 사용하여 필터링/정렬 적용
        final displayedData = _getDisplayedData();
        // 성능 최적화: RepaintBoundary로 감싸서 불필요한 리페인트 방지
        final gastosDefaults = {
          for (final col in GastosBuilder.buildColumnDefs()) col.key: col.defaultWidth
        };
        final mergedGastosWidths = Map<String, double>.from(gastosDefaults)
          ..addAll(_gastosColumnWidths ?? {});
        return RepaintBoundary(
          child: GastosBuilder.buildContent(
            data: displayedData,
            context: context,
            scrollController: _scrollController,
            onSort: (column, ascending) {
              setState(() {
                _sortColumn = column;
                _sortAscending = ascending;
              });
            },
            sortColumn: _sortColumn,
            sortAscending: _sortAscending,
            filteringWord: filteringWord.isNotEmpty ? filteringWord : null,
            selectedRubroCode: _selectedRubroCode,
            isLoadingDetail: _isLoadingGastosDetail,
            horizontalScrollController: _horizontalScrollController,
            columnWidths: mergedGastosWidths,
            onColumnResize: (key, newWidth) {
              setState(() {
                _gastosColumnWidths ??= {};
                _gastosColumnWidths![key] = newWidth;
              });
              GastosColumnWidthStorage.save(_gastosColumnWidths!);
            },
            onRubroSelected: (rubroCode) {
              debugPrint('🔍 [ReportScreen] Rubro 선택 콜백 호출: $rubroCode');
              setState(() {
                _selectedRubroCode = rubroCode;
                debugPrint('🔍 [ReportScreen] _selectedRubroCode 업데이트: $_selectedRubroCode');
              });
              // 오른쪽 패널만 갱신하기 위해 별도 메서드 호출
              _loadGastosDetailOnly(rubroCode);
            },
          ),
        );
      }

      // 기존 구조: data가 Map이고 detail 키가 있는 경우
      if (data.containsKey('data') &&
          data['data'] is Map &&
          (data['data'] as Map).containsKey('detail')) {
        print('📊 Gastos 기존 구조 감지: data(Map) + detail');
        final filteringWord = _filteringWordController.text.trim();
        // _getDisplayedData()를 사용하여 필터링/정렬 적용
        final displayedData = _getDisplayedData();
        final gastosDefaults = {
          for (final col in GastosBuilder.buildColumnDefs()) col.key: col.defaultWidth
        };
        final mergedGastosWidths = Map<String, double>.from(gastosDefaults)
          ..addAll(_gastosColumnWidths ?? {});
        // 성능 최적화: RepaintBoundary로 감싸서 불필요한 리페인트 방지
        return RepaintBoundary(
          child: GastosBuilder.buildContent(
            data: displayedData,
            context: context,
            scrollController: _scrollController,
            onSort: (column, ascending) {
              setState(() {
                _sortColumn = column;
                _sortAscending = ascending;
              });
            },
            sortColumn: _sortColumn,
            sortAscending: _sortAscending,
            filteringWord: filteringWord.isNotEmpty ? filteringWord : null,
            selectedRubroCode: _selectedRubroCode,
            isLoadingDetail: _isLoadingGastosDetail,
            horizontalScrollController: _horizontalScrollController,
            columnWidths: mergedGastosWidths,
            onColumnResize: (key, newWidth) {
              setState(() {
                _gastosColumnWidths ??= {};
                _gastosColumnWidths![key] = newWidth;
              });
              GastosColumnWidthStorage.save(_gastosColumnWidths!);
            },
            onRubroSelected: (rubroCode) {
              debugPrint('🔍 [ReportScreen] Rubro 선택 콜백 호출: $rubroCode');
              setState(() {
                _selectedRubroCode = rubroCode;
                debugPrint('🔍 [ReportScreen] _selectedRubroCode 업데이트: $_selectedRubroCode');
              });
              // 오른쪽 패널만 갱신하기 위해 별도 메서드 호출
              _loadGastosDetailOnly(rubroCode);
            },
          ),
        );
      }
    }
    
    // Items 보고서의 경우 새로운 구조 처리 (summary_by_company, summary_by_category, products)
    if (widget.reportType == ReportType.items &&
        data.containsKey('data') && 
        data['data'] is Map &&
        (data['data'] as Map).containsKey('products') &&
        (data['data'] as Map)['products'] is List) {
      debugPrint('📊 Items 새로운 구조 감지: summary + data(Map) + products');
      final filteringWord = _filteringWordController.text.trim();
      
      // bcolorview 값에 따라 색상 결정
      Color itemsColor = Colors.blue;
      if (data.containsKey('filters') && data['filters'] is Map) {
        final filters = data['filters'] as Map<String, dynamic>;
        final bcolorview = filters['bcolorview'];
        itemsColor = ReportUtils.isBcolorviewEnabled(bcolorview) ? Colors.orange : Colors.lightBlue;
      } else if (data.containsKey('bcolorview')) {
        final bcolorview = data['bcolorview'];
        itemsColor = ReportUtils.isBcolorviewEnabled(bcolorview) ? Colors.orange : Colors.lightBlue;
      }
      
      final itemsDbKey = _connectedDatabaseName ?? '';
      if (_itemsColumnWidthsDbKey != itemsDbKey) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final loaded = await ReportColumnWidthStorage.load(itemsDbKey, ReportType.items);
          if (mounted) {
            setState(() {
              _itemsColumnWidthsDbKey = itemsDbKey;
              _itemsColumnWidths = loaded;
            });
          }
        });
      }
      final mergedItemsColumnWidths = Map<String, double>.from(_itemsColumnWidths ?? {});

      return RepaintBoundary(
        child: ItemsBuilder.buildContent(
          data: data,
          context: context,
          scrollController: _scrollController,
          onSort: (column, ascending) {
            setState(() {
              _sortColumn = column;
              _sortAscending = ascending;
            });
          },
          sortColumn: _sortColumn,
          sortAscending: _sortAscending,
          filteringWord: filteringWord.isNotEmpty ? filteringWord : null,
          displayedItemsCount: _displayedItemsCount,
          itemsPerPage: _itemsPerPage,
          horizontalScrollController: _horizontalScrollController,
          reportColor: itemsColor,
          selectedCategoryCode: _selectedCategoryCode,
          onCategorySelected: (categoryCode) {
            debugPrint('🔍 [ReportScreen] Category 선택 콜백 호출: $categoryCode');
            setState(() {
              _selectedCategoryCode = categoryCode;
              _selectedColorCode = null; // 카테고리 선택 시 색상 선택 해제
              debugPrint('🔍 [ReportScreen] _selectedCategoryCode 업데이트: $_selectedCategoryCode');
            });
          },
          selectedColorCode: _selectedColorCode,
          onColorSelected: (colorCode) {
            debugPrint('🔍 [ReportScreen] Items Color 선택 콜백 호출: $colorCode');
            setState(() {
              _selectedColorCode = colorCode;
              _selectedCategoryCode = null; // 색상 선택 시 카테고리 선택 해제
              debugPrint('🔍 [ReportScreen] _selectedColorCode 업데이트: $_selectedColorCode');
            });
            _reloadDataWithFilters();
          },
          columnWidths: mergedItemsColumnWidths.isEmpty ? null : mergedItemsColumnWidths,
          onColumnResize: (columnKey, newWidth) {
            setState(() {
              _itemsColumnWidths ??= {};
              _itemsColumnWidths![columnKey] = newWidth;
            });
            ReportColumnWidthStorage.save(itemsDbKey, ReportType.items, _itemsColumnWidths!);
          },
        ),
      );
    }
    
    // Ingresos 보고서의 경우 새로운 구조 처리 (summary_by_company, summary_by_category, products)
    if (widget.reportType == ReportType.ingresos &&
        data.containsKey('data') && 
        data['data'] is Map &&
        (data['data'] as Map).containsKey('products') &&
        (data['data'] as Map)['products'] is List) {
      debugPrint('📊 Ingresos 새로운 구조 감지: summary + data(Map) + products');
      final filteringWord = _filteringWordController.text.trim();
      
      // Ingresos 보고서 색상 (기본값: 녹색)
      Color ingresosColor = Colors.green;
      
      final ingresosDbKey = _connectedDatabaseName ?? '';
      if (_ingresosColumnWidthsDbKey != ingresosDbKey) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final loaded = await ReportColumnWidthStorage.load(ingresosDbKey, ReportType.ingresos);
          if (mounted) {
            setState(() {
              _ingresosColumnWidthsDbKey = ingresosDbKey;
              _ingresosColumnWidths = loaded;
            });
          }
        });
      }
      final mergedIngresosColumnWidths = Map<String, double>.from(_ingresosColumnWidths ?? {});

      return RepaintBoundary(
        child: IngresosBuilder.buildContent(
          data: data,
          context: context,
          scrollController: _scrollController,
          onSort: (column, ascending) {
            setState(() {
              _sortColumn = column;
              _sortAscending = ascending;
            });
          },
          sortColumn: _sortColumn,
          sortAscending: _sortAscending,
          filteringWord: filteringWord.isNotEmpty ? filteringWord : null,
          displayedItemsCount: _displayedItemsCount,
          itemsPerPage: _itemsPerPage,
          horizontalScrollController: _horizontalScrollController,
          selectedCategoryCode: _selectedIngresosCategoryCode,
          onCategorySelected: (categoryCode) {
            debugPrint('🔍 [ReportScreen] Ingresos Category 선택 콜백 호출: $categoryCode');
            setState(() {
              _selectedIngresosCategoryCode = categoryCode;
              _selectedIngresosCompanyCode = null;
              _selectedIngresosColorCode = null;
              debugPrint('🔍 [ReportScreen] _selectedIngresosCategoryCode 업데이트: $_selectedIngresosCategoryCode');
            });
            _reloadDataWithFilters();
          },
          selectedCompanyCode: _selectedIngresosCompanyCode,
          onCompanySelected: (companyCode) {
            debugPrint('🔍 [ReportScreen] Ingresos Company 선택 콜백 호출: $companyCode');
            setState(() {
              _selectedIngresosCompanyCode = companyCode;
              _selectedIngresosCategoryCode = null;
              _selectedIngresosColorCode = null;
              debugPrint('🔍 [ReportScreen] _selectedIngresosCompanyCode 업데이트: $_selectedIngresosCompanyCode');
            });
            _reloadDataWithFilters();
          },
          selectedColorCode: _selectedIngresosColorCode,
          onColorSelected: (colorCode) {
            debugPrint('🔍 [ReportScreen] Ingresos Color 선택 콜백 호출: $colorCode');
            setState(() {
              _selectedIngresosColorCode = colorCode;
              _selectedIngresosCategoryCode = null; // 색상 선택 시 카테고리 선택 해제
              _selectedIngresosCompanyCode = null; // 색상 선택 시 회사 선택 해제
              debugPrint('🔍 [ReportScreen] _selectedIngresosColorCode 업데이트: $_selectedIngresosColorCode');
            });
            // 색상 선택 시 API 재요청
            _reloadDataWithFilters();
          },
          reportColor: ingresosColor,
          columnWidths: mergedIngresosColumnWidths.isEmpty ? null : mergedIngresosColumnWidths,
          onColumnResize: (columnKey, newWidth) {
            setState(() {
              _ingresosColumnWidths ??= {};
              _ingresosColumnWidths![columnKey] = newWidth;
            });
            ReportColumnWidthStorage.save(ingresosDbKey, ReportType.ingresos, _ingresosColumnWidths!);
          },
        ),
      );
    }
    
    // 'data' 키가 있고 리스트인 경우
    if (data.containsKey('data') && data['data'] is List) {
      final dataList = data['data'] as List;
      
      // Alertas 보고서 디버깅
      if (widget.reportType == ReportType.alertas) {
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('🔍 [Alertas] dataList 생성 확인');
        debugPrint('   → data.containsKey("data"): ${data.containsKey("data")}');
        debugPrint('   → data["data"] 타입: ${data["data"].runtimeType}');
        debugPrint('   → data["data"] is List: ${data["data"] is List}');
        debugPrint('   → dataList.length: ${dataList.length}');
        if (dataList.isNotEmpty) {
          debugPrint('   → dataList.first 타입: ${dataList.first.runtimeType}');
          debugPrint('   → dataList.first: ${dataList.first}');
          if (dataList.first is Map) {
            debugPrint('   → dataList.first 키: ${(dataList.first as Map).keys.toList()}');
          }
        } else {
          debugPrint('   ⚠️ [Alertas] dataList가 비어있음!');
        }
        debugPrint('═══════════════════════════════════════════════════════');
      }
      
      if (dataList.isEmpty) {
        if (widget.reportType == ReportType.alertas) {
          debugPrint('⚠️ [Alertas] dataList가 비어있어서 "No hay datos disponibles" 반환');
        }
        return const Center(child: Text('No hay datos disponibles'));
      }
      
      // 첫 번째 항목이 맵이고 여러 키를 가지고 있으면 테이블로 표시
      if (dataList.isNotEmpty && dataList.first is Map) {
        // Items, Ingresos, Gastos, Alertas, Ventas 및 FVentas 보고서의 경우 filteringWord 필터 적용
        List<dynamic> filteredDataList = dataList;
        
        // Alertas 보고서 디버깅
        if (widget.reportType == ReportType.alertas) {
          debugPrint('🔍 [Alertas] filteredDataList 초기화');
          debugPrint('   → filteredDataList.length: ${filteredDataList.length}');
        }
        
        // fventas 데이터 디버깅
        if (widget.reportType == ReportType.fventas) {
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('🔍 [FVentas Report] 필터링 전 데이터 확인');
          debugPrint('   → dataList 타입: ${dataList.runtimeType}');
          debugPrint('   → dataList.length: ${dataList.length}');
          if (dataList.isNotEmpty) {
            debugPrint('   → 첫 번째 항목: ${dataList.first}');
            if (dataList.first is Map<String, dynamic>) {
              debugPrint('   → 첫 번째 항목 키: ${(dataList.first as Map<String, dynamic>).keys.toList()}');
            }
          }
          debugPrint('   → filteringWord: "${_filteringWordController.text.trim()}"');
          debugPrint('   → _selectedSucursal: $_selectedSucursal');
          debugPrint('═══════════════════════════════════════════════════════');
        }
        
        if (widget.reportType == ReportType.items || widget.reportType == ReportType.ingresos || widget.reportType == ReportType.gastos || widget.reportType == ReportType.alertas || widget.reportType == ReportType.ventas || widget.reportType == ReportType.fventas) {
          // Alertas 보고서의 경우 WEB 버튼이 활성화되면 progname과 evento 필터 모두 적용
          if (widget.reportType == ReportType.alertas && _alertasWeb) {
            final filteringWord = _filteringWordController.text.trim().toLowerCase();
            filteredDataList = dataList.where((item) {
              if (item is Map<String, dynamic>) {
                final progname = item['progname']?.toString().toLowerCase() ?? '';
                final evento = item['evento']?.toString().toLowerCase() ?? '';
                // progname에 'web'이 포함되어야 하고
                final hasWeb = progname.contains('web');
                // filteringWord가 비어있지 않으면 evento에도 포함되어야 함
                if (filteringWord.isNotEmpty) {
                  return hasWeb && evento.contains(filteringWord);
                } else {
                  return hasWeb;
                }
              }
              return false;
            }).toList();
          } else {
            // 일반 filteringWord 필터링
            final filteringWord = _filteringWordController.text.trim().toLowerCase();
            if (filteringWord.isNotEmpty) {
              filteredDataList = dataList.where((item) {
                if (item is Map<String, dynamic>) {
                  // Items 보고서: codigo1, desc1 사용
                  // Ingresos 보고서: codigo, descripcion 사용
                  // Gastos 보고서: codigo, descripcion, concepto 사용
                  // Alertas 보고서: codigo, descripcion, mensaje, tipo 사용
                  // Ventas 보고서: vcode, vendedor, clientenombre 등 주요 필드에서 검색
                  if (widget.reportType == ReportType.items) {
                    // codigo1 또는 desc1(제품 이름)에서 검색
                    final codigo1 = item['codigo1']?.toString().toLowerCase() ?? '';
                    final desc1 = item['desc1']?.toString().toLowerCase() ?? '';
                    return codigo1.contains(filteringWord) || desc1.contains(filteringWord);
                  } else if (widget.reportType == ReportType.ingresos) {
                    final codigo = item['codigo']?.toString().toLowerCase() ?? '';
                    final descripcion = item['descripcion']?.toString().toLowerCase() ?? '';
                    return codigo.contains(filteringWord) || descripcion.contains(filteringWord);
                  } else if (widget.reportType == ReportType.gastos) {
                    // gastos 필터링: tema 칼럼에서 대소문자 구분 없이 비교
                    final tema = item['tema']?.toString().toLowerCase() ?? '';
                    return tema.contains(filteringWord);
                  } else if (widget.reportType == ReportType.alertas) {
                    // alertas 필터링 로직: evento 필드에서 검색
                    final evento = item['evento']?.toString().toLowerCase() ?? '';
                    return evento.contains(filteringWord);
                  } else if (widget.reportType == ReportType.ventas) {
                    // Ventas 보고서 필터링
                    // vcode unit: clientenombre에서 검색
                    // day/month/year unit: fecha, sucursal 등에서 검색
                    if (item.containsKey('clientenombre')) {
                      // vcode unit
                      final clientenombre = item['clientenombre']?.toString().toLowerCase() ?? '';
                      return clientenombre.contains(filteringWord);
                    } else {
                      // day/month/year unit: fecha, sucursal 등에서 검색
                      final fecha = item['fecha']?.toString().toLowerCase() ?? '';
                      final sucursal = item['sucursal']?.toString().toLowerCase() ?? '';
                      final nencargado = item['nencargado']?.toString().toLowerCase() ?? '';
                      return fecha.contains(filteringWord) || 
                             sucursal.contains(filteringWord) ||
                             nencargado.contains(filteringWord);
                    }
                  } else if (widget.reportType == ReportType.fventas) {
                    // fventas 필터링: cuit, cliente, clientenombre, numfactura 필드에서 검색
                    final cuit = item['cuit']?.toString().toLowerCase() ?? '';
                    final cliente = item['cliente']?.toString().toLowerCase() ?? '';
                    final clientenombre = item['clientenombre']?.toString().toLowerCase() ?? '';
                    final numfactura = item['numfactura']?.toString().toLowerCase() ?? '';
                    return cuit.contains(filteringWord) || 
                           cliente.contains(filteringWord) ||
                           clientenombre.contains(filteringWord) ||
                           numfactura.contains(filteringWord);
                  }
                }
                return false;
              }).toList();
            }
          }
        }
        // Ventas 보고서의 경우 날짜 필터는 서버에서 처리되므로 클라이언트 측 필터링 제거
        // Ventas 보고서의 filteringWord 필터는 위에서 이미 적용됨 (clientenombre만 검색)
        // Ventas 보고서의 경우 sucursal 필터 적용
        if (widget.reportType == ReportType.ventas && _selectedSucursal != null) {
          filteredDataList = filteredDataList.where((item) {
            if (item is Map<String, dynamic> && item.containsKey('sucursal')) {
              final sucursal = item['sucursal']?.toString();
              return sucursal == _selectedSucursal;
            }
            return false;
          }).toList();
        }
        // Codigos 및 Todo Codigos 보고서의 경우 filteringWord 필터 적용
        if (widget.reportType == ReportType.codigos || widget.reportType == ReportType.todocodigos) {
          final filteringWord = _filteringWordController.text.trim().toLowerCase();
          if (filteringWord.isNotEmpty) {
            filteredDataList = filteredDataList.where((item) {
              if (item is Map<String, dynamic>) {
                final codigo = item['codigo']?.toString().toLowerCase() ?? '';
                final descripcion = item['descripcion']?.toString().toLowerCase() ?? '';
                return codigo.contains(filteringWord) || descripcion.contains(filteringWord);
              }
              return false;
            }).toList();
          }
        }
        // Alertas 보고서는 별도 처리 (화면을 나누지 않음)
        if (widget.reportType == ReportType.alertas) {
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('🔍 [Alertas] 데이터 처리 시작');
          debugPrint('   → dataList.length: ${dataList.length}');
          debugPrint('   → filteredDataList.length: ${filteredDataList.length}');
          debugPrint('   → _alertasVCancelado: $_alertasVCancelado');
          debugPrint('   → _alertasJefe: $_alertasJefe');
          debugPrint('   → _alertasWeb: $_alertasWeb');
          debugPrint('   → filteringWord: "${_filteringWordController.text.trim()}"');
          if (filteredDataList.isNotEmpty) {
            debugPrint('   → filteredDataList 첫 번째 항목: ${filteredDataList.first}');
            if (filteredDataList.first is Map) {
              debugPrint('   → filteredDataList 첫 번째 항목 키: ${(filteredDataList.first as Map).keys.toList()}');
            }
          } else {
            debugPrint('   ⚠️ [Alertas] filteredDataList가 비어있음!');
          }
          debugPrint('═══════════════════════════════════════════════════════');
          
          // Alertas 보고서는 항상 id_log 역순으로 정렬
          List<dynamic> sortedDataList = List.from(filteredDataList);
          debugPrint('🔍 [Alertas] 정렬 전 sortedDataList.length: ${sortedDataList.length}');
          sortedDataList.sort((a, b) {
            if (a is! Map<String, dynamic> || b is! Map<String, dynamic>) {
              return 0;
            }
            
            final aIdLog = a['id_log'];
            final bIdLog = b['id_log'];
            
            // null 처리
            if (aIdLog == null && bIdLog == null) return 0;
            if (aIdLog == null) return 1; // null은 뒤로
            if (bIdLog == null) return -1; // null은 뒤로
            
            // 숫자 비교 (역순: 큰 값이 앞으로)
            final aNum = ReportUtils.isNumeric(aIdLog) ? num.tryParse(aIdLog.toString().replaceAll(',', '')) : null;
            final bNum = ReportUtils.isNumeric(bIdLog) ? num.tryParse(bIdLog.toString().replaceAll(',', '')) : null;
            
            if (aNum != null && bNum != null) {
              return bNum.compareTo(aNum); // 역순 정렬
            }
            
            // 문자열 비교 (역순)
            final aStr = aIdLog.toString().toLowerCase();
            final bStr = bIdLog.toString().toLowerCase();
            return bStr.compareTo(aStr); // 역순 정렬
          });
          debugPrint('🔍 [Alertas] 정렬 후 sortedDataList.length: ${sortedDataList.length}');
          if (sortedDataList.isNotEmpty) {
            debugPrint('   → sortedDataList 첫 번째 항목: ${sortedDataList.first}');
            if (sortedDataList.first is Map) {
              debugPrint('   → sortedDataList 첫 번째 항목 키: ${(sortedDataList.first as Map).keys.toList()}');
            }
          } else {
            debugPrint('   ⚠️ [Alertas] sortedDataList가 비어있음!');
          }
          
          // Alertas 보고서 색상 결정
          Color alertasColor = Colors.orange; // alertas 보고서 기본 색상
          
          debugPrint('🔍 [Alertas] 테이블 빌드 시작');
          debugPrint('   → sortedDataList.length: ${sortedDataList.length}');
          debugPrint('   → _displayedItemsCount: $_displayedItemsCount');
          debugPrint('   → _itemsPerPage: $_itemsPerPage');
          debugPrint('   → _scrollController: ${_scrollController != null}');
          debugPrint('   → _horizontalScrollController: ${_horizontalScrollController != null}');
          debugPrint('   → reportColor: $alertasColor');
          
          // 테이블 위젯 생성 (화면을 나누지 않음) (성능 최적화: RepaintBoundary로 감싸서 불필요한 리페인트 방지)
          final tableWidget = ReportTableBuilder.buildTableFromList(
            sortedDataList,
            _displayedItemsCount,
            _itemsPerPage,
            _scrollController,
            widget.reportType,
            sortColumn: _sortColumn,
            sortAscending: _sortAscending,
            horizontalScrollController: _horizontalScrollController,
            reportColor: alertasColor,
            unit: null,
            onRowDoubleTap: null,
            onRowTap: null,
            onSort: (columnIndex, ascending) {
              debugPrint('🔍 [Alertas] onSort 콜백 호출: columnIndex=$columnIndex, ascending=$ascending');
              setState(() {
                final allKeys = sortedDataList.isNotEmpty 
                    ? (sortedDataList.first as Map<String, dynamic>).keys.toList()
                    : <String>[];
                debugPrint('   → allKeys: $allKeys');
                if (columnIndex >= 0 && columnIndex < allKeys.length) {
                  final key = allKeys[columnIndex];
                  debugPrint('   → 정렬 키: $key');
                  if (_sortColumn == key) {
                    _sortAscending = !_sortAscending;
                  } else {
                    _sortColumn = key;
                    _sortAscending = false;
                  }
                  _displayedItemsCount = _itemsPerPage;
                }
              });
            },
          );
          
          debugPrint('🔍 [Alertas] 테이블 위젯 생성 완료');
          debugPrint('   → tableWidget 타입: ${tableWidget.runtimeType}');
          debugPrint('   → tableWidget: ${tableWidget.toString()}');
          
          return RepaintBoundary(
            child: tableWidget,
          );
        }
        
        if (widget.reportType == ReportType.items || widget.reportType == ReportType.ingresos || widget.reportType == ReportType.gastos) {

          // Items, Ingresos, Gastos 보고서의 경우 정렬 적용
          List<dynamic> sortedDataList = List.from(filteredDataList);
          if (_sortColumn != null) {
            sortedDataList.sort((a, b) {
              if (a is! Map<String, dynamic> || b is! Map<String, dynamic>) {
                return 0;
              }
              
              final aValue = a[_sortColumn];
              final bValue = b[_sortColumn];
              
              // null 처리
              if (aValue == null && bValue == null) return 0;
              if (aValue == null) return _sortAscending ? -1 : 1;
              if (bValue == null) return _sortAscending ? 1 : -1;
              
              // 숫자 비교
              final aNum = ReportUtils.isNumeric(aValue) ? num.tryParse(aValue.toString().replaceAll(',', '')) : null;
              final bNum = ReportUtils.isNumeric(bValue) ? num.tryParse(bValue.toString().replaceAll(',', '')) : null;
              
              if (aNum != null && bNum != null) {
                final comparison = aNum.compareTo(bNum);
                return _sortAscending ? comparison : -comparison;
              }
              
              // 문자열 비교
              final aStr = aValue.toString().toLowerCase();
              final bStr = bValue.toString().toLowerCase();
              final comparison = aStr.compareTo(bStr);
              return _sortAscending ? comparison : -comparison;
            });
          }
          
          print('📊 Items 보고서 - sortedDataList.length: ${sortedDataList.length}, _displayedItemsCount: $_displayedItemsCount');
          
          // bcolorview 값에 따라 색상 결정
          Color itemsColor = Colors.blue; // 기본값 (items 보고서 기본 색상)
          if (_data != null) {
            if (_data!.containsKey('filters') && _data!['filters'] is Map) {
              final filters = _data!['filters'] as Map<String, dynamic>;
              final bcolorview = filters['bcolorview'];
              itemsColor = ReportUtils.isBcolorviewEnabled(bcolorview) ? Colors.orange : Colors.lightBlue;
            } else if (_data!.containsKey('bcolorview')) {
              final bcolorview = _data!['bcolorview'];
              itemsColor = ReportUtils.isBcolorviewEnabled(bcolorview) ? Colors.orange : Colors.lightBlue;
            }
          }
          
          // 화면 너비 확인 (좁은 화면인지 체크)
          final screenWidth = MediaQuery.of(context).size.width;
          final isWideScreen = screenWidth >= 800; // 800px 이상이면 큰 화면으로 간주
          
          // 테이블 위젯 생성 (성능 최적화: RepaintBoundary로 감싸서 불필요한 리페인트 방지)
          final tableWidget = RepaintBoundary(
            child: ReportTableBuilder.buildTableFromList(
                    sortedDataList,
                    _displayedItemsCount,
                    _itemsPerPage,
                    _scrollController,
                    widget.reportType,
                    sortColumn: _sortColumn,
                    sortAscending: _sortAscending,
                    horizontalScrollController: _horizontalScrollController,
                    reportColor: itemsColor,
                    unit: widget.reportType == ReportType.ventas ? _ventasUnit : null,
                    onRowDoubleTap: widget.reportType == ReportType.ventas ? _handleRowDoubleTap : null,
                    onRowTap: widget.reportType == ReportType.ventas && 
                              _ventasUnit != 'vcode' ? _handleRowTap : null, // day/month/year 단위에서는 단일 클릭으로 sucursal 필터링
                    onSort: (columnIndex, ascending) {
                      setState(() {
                        // 키 목록을 정렬된 데이터에서 가져오기 (report_table_builder와 동일한 순서 보장)
                      // Items 보고서: start_date, end_date, sucursal 제외
                      final allKeys = sortedDataList.isNotEmpty 
                          ? (sortedDataList.first as Map<String, dynamic>).keys.toList()
                          : <String>[];
                      final keys = (widget.reportType == ReportType.items || widget.reportType == ReportType.ingresos)
                          ? allKeys.where((key) => key != 'start_date' && key != 'end_date' && key != 'sucursal').toList()
                          : allKeys;
                      if (columnIndex >= 0 && columnIndex < keys.length) {
                        final key = keys[columnIndex];
                        if (_sortColumn == key) {
                          // 같은 칼럼을 클릭하면 정렬 방향 변경
                          _sortAscending = !_sortAscending;
                        } else {
                          // 다른 칼럼을 클릭하면 새 칼럼으로 정렬 (첫 클릭 시 내림차순)
                          _sortColumn = key;
                          _sortAscending = false;
                        }
                        // 정렬이 변경되면 처음부터 다시 표시
                        _displayedItemsCount = _itemsPerPage;
                      }
                    });
                  },
                ),
          );
          
          // 큰 화면일 때만 2/3, 1/3로 나눔 (Items, Ingresos, Gastos만)
          if (isWideScreen && (widget.reportType == ReportType.items || widget.reportType == ReportType.ingresos)) {
            return Row(
              children: [
                // 왼쪽 2/3: 서버에서 우선 응답 온 내용 (Items/Ingresos 보고서 내용)
                Flexible(
                  flex: 2,
                  fit: FlexFit.loose,
                  child: tableWidget,
                ),
                // 구분선
                Container(
                  width: 1,
                  color: Colors.grey[300],
                ),
                // 오른쪽 1/3: 비어있음 (나중에 사용 가능)
                Expanded(
                  flex: 1,
                  child: Container(
                    color: Colors.grey[50],
                    child: const Center(
                      child: Text(
                        'Right Panel',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            // 좁은 화면이거나 Gastos 보고서일 때는 전체 화면 사용
            return tableWidget;
          }
        }
        
        // Clientes 보고서의 경우 별도 처리 (서버에서 정렬하므로 클라이언트 측 정렬 불필요)
        if (widget.reportType == ReportType.clientes) {
          // 성능 최적화: RepaintBoundary로 감싸서 불필요한 리페인트 방지
          return RepaintBoundary(
            child: ReportTableBuilder.buildTableFromList(
              filteredDataList,
              _displayedItemsCount,
              _itemsPerPage,
              _scrollController,
              widget.reportType,
              sortColumn: _clientesSortColumn,
              sortAscending: _clientesSortAscending,
              horizontalScrollController: _horizontalScrollController,
              reportColor: _getReportColor(),
              unit: null,
              onRowDoubleTap: (rowData) => _handleClienteRowTap(rowData),
              // detail 화면이 이미 열려있으면 단일 클릭으로도 고객 정보 표시
              onRowTap: (rowData) {
                // detail 화면이 열려있을 때만 단일 클릭으로 동작
                if (_clienteDetailOverlayEntry != null) {
                  _handleClienteRowTap(rowData);
                }
              },
              onSort: (columnIndex, ascending) {
                setState(() {
                  // 키 목록을 필터링된 데이터에서 가져오기
                  final allKeys = filteredDataList.isNotEmpty 
                      ? (filteredDataList.first as Map<String, dynamic>).keys.toList()
                      : <String>[];
                  if (columnIndex >= 0 && columnIndex < allKeys.length) {
                    final key = allKeys[columnIndex];
                    if (_clientesSortColumn == key) {
                      // 같은 칼럼을 클릭하면 정렬 방향 변경
                      _clientesSortAscending = !_clientesSortAscending;
                    } else {
                      // 다른 칼럼을 클릭하면 새 칼럼으로 정렬 (첫 클릭 시 내림차순)
                      _clientesSortColumn = key;
                      _clientesSortAscending = false;
                    }
                    // 정렬이 변경되면 서버에서 다시 로드
                    _reloadDataWithFilters();
                  }
                });
              },
            ),
          );
        }
        
        // Ventas 보고서의 경우 정렬 적용
        List<dynamic> sortedDataList = List.from(filteredDataList);
        if (widget.reportType == ReportType.ventas && _sortColumn != null) {
          sortedDataList.sort((a, b) {
            if (a is! Map<String, dynamic> || b is! Map<String, dynamic>) {
              return 0;
            }
            
            final aValue = a[_sortColumn];
            final bValue = b[_sortColumn];
            
            // null 처리
            if (aValue == null && bValue == null) return 0;
            if (aValue == null) return _sortAscending ? -1 : 1;
            if (bValue == null) return _sortAscending ? 1 : -1;
            
            // 숫자 비교
            final aNum = ReportUtils.isNumeric(aValue) ? num.tryParse(aValue.toString().replaceAll(',', '')) : null;
            final bNum = ReportUtils.isNumeric(bValue) ? num.tryParse(bValue.toString().replaceAll(',', '')) : null;
            
            if (aNum != null && bNum != null) {
              final comparison = aNum.compareTo(bNum);
              return _sortAscending ? comparison : -comparison;
            }
            
            // 문자열 비교
            final aStr = aValue.toString().toLowerCase();
            final bStr = bValue.toString().toLowerCase();
            final comparison = aStr.compareTo(bStr);
            return _sortAscending ? comparison : -comparison;
          });
        }
        
        // fventas 데이터 디버깅 (buildTableFromList 호출 전)
        if (widget.reportType == ReportType.fventas) {
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('🔍 [FVentas Report] buildTableFromList 호출 전 데이터 확인');
          debugPrint('   → filteredDataList.length: ${filteredDataList.length}');
          debugPrint('   → sortedDataList.length: ${sortedDataList.length}');
          debugPrint('   → _displayedItemsCount: $_displayedItemsCount');
          debugPrint('   → _itemsPerPage: $_itemsPerPage');
          debugPrint('   → horizontalScrollController: ${_horizontalScrollController != null}');
          if (filteredDataList.isNotEmpty) {
            debugPrint('   → filteredDataList 첫 번째 항목: ${filteredDataList.first}');
          } else {
            debugPrint('   ⚠️ filteredDataList가 비어있습니다!');
          }
          debugPrint('═══════════════════════════════════════════════════════');
        }
        
        // 성능 최적화: RepaintBoundary로 감싸서 불필요한 리페인트 방지
        if (widget.reportType == ReportType.ventas) {
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('🔍 [report_screen.dart:8876] [Ventas] ReportTableBuilder.buildTableFromList 호출 전');
          debugPrint('   → 라인: 8876');
          debugPrint('   → [report_screen.dart:8879] Platform.isWindows: ${Platform.isWindows}');
          debugPrint('   → [report_screen.dart:8880] sortedDataList.length: ${sortedDataList.length}');
          debugPrint('   → [report_screen.dart:8881] _displayedItemsCount: $_displayedItemsCount');
          debugPrint('   → [report_screen.dart:8882] _ventasUnit: $_ventasUnit');
          debugPrint('   → [report_screen.dart:8883] _ventasUnit 타입: ${_ventasUnit.runtimeType}');
          debugPrint('   → [report_screen.dart:8884] _ventasUnit == "day": ${_ventasUnit == "day"}');
          debugPrint('   → [report_screen.dart:8885] _ventasUnit == "month": ${_ventasUnit == "month"}');
          debugPrint('   → [report_screen.dart:8886] _ventasUnit == "year": ${_ventasUnit == "year"}');
          debugPrint('   → [report_screen.dart:8887] _ventasUnit == "vcode": ${_ventasUnit == "vcode"}');
          debugPrint('   → [report_screen.dart:8888] widget.reportType == ReportType.ventas: ${widget.reportType == ReportType.ventas}');
          debugPrint('   → [report_screen.dart:8889] 전달할 unit 파라미터: ${widget.reportType == ReportType.ventas ? _ventasUnit : null}');
          debugPrint('   → _data != null: ${_data != null}');
          if (_data != null && _data!.containsKey('data') && _data!['data'] is List) {
            final dataList = _data!['data'] as List;
            debugPrint('   → _data["data"] 길이: ${dataList.length}');
            if (dataList.isNotEmpty && dataList.first is Map<String, dynamic>) {
              final firstItem = dataList.first as Map<String, dynamic>;
              debugPrint('   → _data["data"] 첫 번째 항목 keys: ${firstItem.keys.toList()}');
              debugPrint('   → _data["data"] 첫 번째 항목에 fecha 있음: ${firstItem.containsKey("fecha")}');
              debugPrint('   → _data["data"] 첫 번째 항목에 vcode 있음: ${firstItem.containsKey("vcode")}');
              debugPrint('   → _data["data"] 첫 번째 항목에 month 있음: ${firstItem.containsKey("month")}');
              debugPrint('   → _data["data"] 첫 번째 항목에 year 있음: ${firstItem.containsKey("year")}');
              
              // 데이터 구조와 _ventasUnit 일치 여부 확인
              final hasVcodeField = firstItem.containsKey('vcode');
              final hasFechaField = firstItem.containsKey('fecha');
              final hasMonthField = firstItem.containsKey('month');
              final hasYearField = firstItem.containsKey('year');
              final hasDayMonthYearKey = hasFechaField || hasMonthField || hasYearField;
              
              final isDataForDayMonthYear = !hasVcodeField && hasDayMonthYearKey;
              final isDataForVcode = hasVcodeField;
              
              final isUnitDayMonthYear = _ventasUnit == 'day' || _ventasUnit == 'month' || _ventasUnit == 'year';
              final isUnitVcode = _ventasUnit == 'vcode';
              
              final dataMatchesUnit = (isUnitDayMonthYear && isDataForDayMonthYear) || 
                                      (isUnitVcode && isDataForVcode);
              
              print('🟠🟠🟠 [report_screen.dart:9065] 데이터 구조 분석 결과');
              print('   → 라인: 9065');
              print('   → hasVcodeField: $hasVcodeField');
              print('   → hasFechaField: $hasFechaField');
              print('   → hasMonthField: $hasMonthField');
              print('   → hasYearField: $hasYearField');
              print('   → isDataForDayMonthYear: $isDataForDayMonthYear');
              print('   → isDataForVcode: $isDataForVcode');
              print('   → isUnitDayMonthYear: $isUnitDayMonthYear');
              print('   → isUnitVcode: $isUnitVcode');
              print('   → dataMatchesUnit: $dataMatchesUnit');
              print('   → _ventasUnit: $_ventasUnit');
              print('   → _isLoading: $_isLoading');
              debugPrint('   → 데이터 구조 분석:');
              debugPrint('      → hasVcodeField: $hasVcodeField');
              debugPrint('      → hasDayMonthYearKey: $hasDayMonthYearKey');
              debugPrint('      → isDataForDayMonthYear: $isDataForDayMonthYear');
              debugPrint('      → isDataForVcode: $isDataForVcode');
              debugPrint('   → _ventasUnit 분석:');
              debugPrint('      → isUnitDayMonthYear: $isUnitDayMonthYear');
              debugPrint('      → isUnitVcode: $isUnitVcode');
              debugPrint('   → 데이터와 _ventasUnit 일치 여부: $dataMatchesUnit');
              debugPrint('   → _isLoading: $_isLoading');
              
              if (!dataMatchesUnit && _isLoading) {
                debugPrint('   ⚠️ [report_screen.dart:9070] 경고: 데이터와 _ventasUnit이 일치하지 않지만 로딩 중입니다.');
                debugPrint('      → 라인: 9070');
                debugPrint('      → _ventasUnit: $_ventasUnit');
                debugPrint('      → 데이터 구조: ${isDataForDayMonthYear ? "day/month/year" : (isDataForVcode ? "vcode" : "unknown")}');
              }
            }
          }
          debugPrint('   → _sortColumn: $_sortColumn');
          debugPrint('   → _sortAscending: $_sortAscending');
          debugPrint('   → _horizontalScrollController: ${_horizontalScrollController != null}');
          debugPrint('   → _scrollController: ${_scrollController != null}');
          if (sortedDataList.isNotEmpty) {
            debugPrint('   → sortedDataList 첫 번째 항목: ${sortedDataList.first}');
            if (sortedDataList.first is Map<String, dynamic>) {
              final firstItem = sortedDataList.first as Map<String, dynamic>;
              debugPrint('   → sortedDataList 첫 번째 항목 keys: ${firstItem.keys.toList()}');
            }
          }
          debugPrint('═══════════════════════════════════════════════════════');
        }
        
        // Ventas 보고서의 경우 데이터와 _ventasUnit 일치 여부 확인
        print('🟠🟠🟠 [report_screen.dart:9044] unitToPass 결정 로직 시작');
        print('   → 라인: 9044');
        print('   → _ventasUnit: $_ventasUnit');
        print('   → _ventasUnit 타입: ${_ventasUnit.runtimeType}');
        print('   → _isLoading: $_isLoading');
        print('   → _data != null: ${_data != null}');
        debugPrint('🟠🟠🟠 [report_screen.dart:9044] unitToPass 결정 로직 시작');
        debugPrint('   → 라인: 9044');
        debugPrint('   → _ventasUnit: $_ventasUnit');
        debugPrint('   → _ventasUnit 타입: ${_ventasUnit.runtimeType}');
        debugPrint('   → _isLoading: $_isLoading');
        debugPrint('   → _data != null: ${_data != null}');
        String? unitToPass = widget.reportType == ReportType.ventas ? _ventasUnit : null;
        print('🟠🟠🟠 [report_screen.dart:9045] unitToPass 초기값 설정: $unitToPass');
        debugPrint('🔍 [report_screen.dart:8981] unitToPass 초기값 설정: $unitToPass');
        if (widget.reportType == ReportType.ventas && _data != null && _data!.containsKey('data') && _data!['data'] is List) {
          final dataList = _data!['data'] as List;
          print('🟠🟠🟠 [report_screen.dart:9047] dataList 확인');
          print('   → 라인: 9047');
          print('   → dataList.length: ${dataList.length}');
          print('   → dataList.isNotEmpty: ${dataList.isNotEmpty}');
          debugPrint('🟠🟠🟠 [report_screen.dart:9047] dataList 확인');
          debugPrint('   → 라인: 9047');
          debugPrint('   → dataList.length: ${dataList.length}');
          debugPrint('   → dataList.isNotEmpty: ${dataList.isNotEmpty}');
          if (dataList.isNotEmpty && dataList.first is Map<String, dynamic>) {
            final firstItem = dataList.first as Map<String, dynamic>;
            print('🟠🟠🟠 [report_screen.dart:9049] firstItem 분석 시작');
            print('   → 라인: 9049');
            print('   → firstItem.keys: ${firstItem.keys.toList()}');
            debugPrint('🟠🟠🟠 [report_screen.dart:9049] firstItem 분석 시작');
            debugPrint('   → 라인: 9049');
            debugPrint('   → firstItem.keys: ${firstItem.keys.toList()}');
            final hasVcodeField = firstItem.containsKey('vcode');
            final hasFechaField = firstItem.containsKey('fecha');
            final hasMonthField = firstItem.containsKey('month');
            final hasYearField = firstItem.containsKey('year');
            final hasDayMonthYearKey = hasFechaField || hasMonthField || hasYearField;
            
            final isDataForDayMonthYear = !hasVcodeField && hasDayMonthYearKey;
            final isDataForVcode = hasVcodeField;
            
            final isUnitDayMonthYear = _ventasUnit == 'day' || _ventasUnit == 'month' || _ventasUnit == 'year';
            final isUnitVcode = _ventasUnit == 'vcode';
            
            final dataMatchesUnit = (isUnitDayMonthYear && isDataForDayMonthYear) || 
                                    (isUnitVcode && isDataForVcode);
            
            print('🟠🟠🟠 [report_screen.dart:9065] 데이터 구조 분석 결과');
            print('   → 라인: 9065');
            print('   → hasVcodeField: $hasVcodeField');
            print('   → hasFechaField: $hasFechaField');
            print('   → hasMonthField: $hasMonthField');
            print('   → hasYearField: $hasYearField');
            print('   → isDataForDayMonthYear: $isDataForDayMonthYear');
            print('   → isDataForVcode: $isDataForVcode');
            print('   → isUnitDayMonthYear: $isUnitDayMonthYear');
            print('   → isUnitVcode: $isUnitVcode');
            print('   → dataMatchesUnit: $dataMatchesUnit');
            print('   → _ventasUnit: $_ventasUnit');
            print('   → _isLoading: $_isLoading');
            debugPrint('   → [report_screen.dart:8984] 데이터 구조 분석 시작');
            debugPrint('      → hasVcodeField: $hasVcodeField');
            debugPrint('      → hasFechaField: $hasFechaField');
            debugPrint('      → hasMonthField: $hasMonthField');
            debugPrint('      → hasYearField: $hasYearField');
            debugPrint('      → isDataForDayMonthYear: $isDataForDayMonthYear');
            debugPrint('      → isDataForVcode: $isDataForVcode');
            debugPrint('      → isUnitDayMonthYear: $isUnitDayMonthYear');
            debugPrint('      → isUnitVcode: $isUnitVcode');
            debugPrint('      → dataMatchesUnit: $dataMatchesUnit');
            
            if (!dataMatchesUnit && !_isLoading) {
              // 중요: _ventasUnit과 데이터 구조가 일치하지 않을 때, _ventasUnit을 우선적으로 사용
              // 이는 사용자가 버튼을 클릭했지만 아직 API 응답이 도착하지 않은 경우를 처리하기 위함
              print('🟠🟠🟠 [report_screen.dart:9183] 데이터와 _ventasUnit 불일치 감지 - _ventasUnit 우선 사용');
              print('   → 라인: 9183');
              print('   → _ventasUnit: $_ventasUnit');
              print('   → 데이터 구조: ${isDataForDayMonthYear ? "day/month/year" : (isDataForVcode ? "vcode" : "unknown")}');
              print('   → _isLoading: $_isLoading');
              print('   → unitToPass를 _ventasUnit으로 강제 설정: $_ventasUnit');
              debugPrint('   ⚠️ [report_screen.dart:9183] 데이터와 _ventasUnit 불일치 감지 - _ventasUnit 우선 사용');
              debugPrint('      → 라인: 9183');
              debugPrint('      → _ventasUnit: $_ventasUnit');
              debugPrint('      → 데이터 구조: ${isDataForDayMonthYear ? "day/month/year" : (isDataForVcode ? "vcode" : "unknown")}');
              debugPrint('      → _isLoading: $_isLoading');
              debugPrint('      → unitToPass를 _ventasUnit으로 강제 설정: $_ventasUnit');
              // _ventasUnit을 우선적으로 사용 (사용자가 선택한 값)
              unitToPass = _ventasUnit;
            } else if (!dataMatchesUnit && _isLoading) {
              // 로딩 중일 때도 _ventasUnit 사용
              print('🟠🟠🟠 [report_screen.dart:9198] 로딩 중 - _ventasUnit 사용');
              print('   → 라인: 9198');
              print('   → _ventasUnit: $_ventasUnit');
              print('   → unitToPass를 _ventasUnit으로 설정: $_ventasUnit');
              debugPrint('   ⚠️ [report_screen.dart:9198] 로딩 중 - _ventasUnit 사용');
              debugPrint('      → 라인: 9198');
              debugPrint('      → _ventasUnit: $_ventasUnit');
              debugPrint('      → unitToPass를 _ventasUnit으로 설정: $_ventasUnit');
              unitToPass = _ventasUnit;
            } else {
              print('🟠🟠🟠 [report_screen.dart:9217] 데이터와 _ventasUnit 일치 - unitToPass 유지');
              print('   → 라인: 9217');
              print('   → unitToPass: $unitToPass');
              print('   → dataMatchesUnit: $dataMatchesUnit');
              print('   → _isLoading: $_isLoading');
              debugPrint('🟠🟠🟠 [report_screen.dart:9217] 데이터와 _ventasUnit 일치 - unitToPass 유지');
              debugPrint('   → 라인: 9217');
              debugPrint('   → unitToPass: $unitToPass');
              debugPrint('   → dataMatchesUnit: $dataMatchesUnit');
              debugPrint('   → _isLoading: $_isLoading');
            }
          }
        }
        print('🟠🟠🟠 [report_screen.dart:9105] unitToPass 결정 로직 완료');
        print('   → 라인: 9105');
        print('   → 최종 unitToPass: $unitToPass');
        print('   → _ventasUnit: $_ventasUnit');
        debugPrint('🟠🟠🟠 [report_screen.dart:9105] unitToPass 결정 로직 완료');
        debugPrint('   → 라인: 9105');
        debugPrint('   → 최종 unitToPass: $unitToPass');
        debugPrint('   → _ventasUnit: $_ventasUnit');
        
        print('🟣🟣🟣 [report_screen.dart:9028] buildTableFromList 호출 직전');
        print('   → 라인: 9028');
        print('   → unitToPass: $unitToPass');
        print('   → unitToPass 타입: ${unitToPass.runtimeType}');
        print('   → unitToPass == "day": ${unitToPass == "day"}');
        print('   → unitToPass == "month": ${unitToPass == "month"}');
        print('   → unitToPass == "year": ${unitToPass == "year"}');
        print('   → 현재 _ventasUnit: $_ventasUnit');
        print('   → _isLoading: $_isLoading');
        print('   → _data != null: ${_data != null}');
        print('   → 호출 스택 (처음 5줄):');
        print('      ${StackTrace.current.toString().split("\n").take(5).join("\n      ")}');
        debugPrint('🔍 [report_screen.dart:9028] buildTableFromList 호출 직전');
        debugPrint('   → 라인: 9028');
        debugPrint('   → unitToPass: $unitToPass');
        debugPrint('   → unitToPass 타입: ${unitToPass.runtimeType}');
        debugPrint('   → unitToPass == "day": ${unitToPass == "day"}');
        debugPrint('   → unitToPass == "month": ${unitToPass == "month"}');
        debugPrint('   → unitToPass == "year": ${unitToPass == "year"}');
        debugPrint('   → 현재 _ventasUnit: $_ventasUnit');
        debugPrint('   → _isLoading: $_isLoading');
        debugPrint('   → _data != null: ${_data != null}');
        debugPrint('   → 호출 스택 (처음 3줄):');
        debugPrint('      ${StackTrace.current.toString().split("\n").take(3).join("\n      ")}');
        debugPrint('   → [report_screen.dart:9035] ReportTableBuilder.buildTableFromList 호출 시작');
        debugPrint('   → [report_screen.dart:8982] ReportTableBuilder.buildTableFromList 호출 시작');
        
        return RepaintBoundary(
          child: ReportTableBuilder.buildTableFromList(
            widget.reportType == ReportType.ventas ? sortedDataList : filteredDataList,
            _displayedItemsCount,
            _itemsPerPage,
            _scrollController,
            widget.reportType,
            sortColumn: widget.reportType == ReportType.ventas ? _sortColumn : null,
            sortAscending: widget.reportType == ReportType.ventas ? _sortAscending : true,
            horizontalScrollController: _horizontalScrollController,
            reportColor: widget.reportType == ReportType.ventas ? Colors.purple : null,
            unit: unitToPass,
            onRowDoubleTap: widget.reportType == ReportType.ventas ? _handleRowDoubleTap : null,
            onRowTap: widget.reportType == ReportType.ventas && 
                      _ventasUnit != 'vcode' ? _handleRowTap : null, // day/month/year 단위에서는 단일 클릭으로 sucursal 필터링
            onSort: widget.reportType == ReportType.ventas
                ? (columnIndex, ascending) {
                    setState(() {
                      // 키 목록을 정렬된 데이터에서 가져오기 (report_table_builder와 동일한 순서 보장)
                      final allKeys = sortedDataList.isNotEmpty 
                          ? (sortedDataList.first as Map<String, dynamic>).keys.toList()
                          : <String>[];
                      // ventas 보고서는 특정 순서로 컬럼이 정렬되어 있으므로 report_table_builder에서 사용하는 순서를 따라야 함
                      // 하지만 여기서는 실제 데이터의 키 순서를 사용
                      final keys = allKeys;
                      if (columnIndex >= 0 && columnIndex < keys.length) {
                        final key = keys[columnIndex];
                        if (_sortColumn == key) {
                          // 같은 칼럼을 클릭하면 정렬 방향 변경
                          _sortAscending = !_sortAscending;
                        } else {
                          // 다른 칼럼을 클릭하면 새 칼럼으로 정렬 (첫 클릭 시 내림차순)
                          _sortColumn = key;
                          _sortAscending = false;
                        }
                        // 정렬이 변경되면 처음부터 다시 표시
                        _displayedItemsCount = _itemsPerPage;
                      }
                    });
                  }
                : null,
          ),
        );
      }
      
      // 카드 형태로 표시할 때도 대량 데이터 처리
      final displayedList = dataList.take(_displayedItemsCount).toList();
      final totalCount = dataList.length;
      final hasMore = _displayedItemsCount < totalCount;
      
      return Column(
        children: [
          // 카드 리스트
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.zero,
              children: [
                ...displayedList.map((item) => _buildDataCard(item)),
                if (hasMore)
                  Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: ElevatedButton.icon(
                      onPressed: _loadMoreItems,
                      icon: const Icon(Icons.expand_more),
                      label: Text('Cargar más (${totalCount - _displayedItemsCount} restantes)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getReportColor(),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }
    
    // 'data' 키가 있고 맵인 경우
    if (data.containsKey('data') && data['data'] is Map) {
      return ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDataMap(data['data'] as Map<String, dynamic>),
        ],
      );
    }
    
    // 'data' 키가 없고 직접 맵인 경우
    // 테이블 형태로 표시 가능한지 확인
    if (ReportTableBuilder.isTableData(data)) {
      return ListView(
        padding: EdgeInsets.zero,
        children: [
          ReportTableBuilder.buildTable(data, widget.reportType),
        ],
      );
    }
    
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildDataMap(data),
      ],
    );
      
    return const Center(child: Text('Formato de datos desconocido'));
  }

}


