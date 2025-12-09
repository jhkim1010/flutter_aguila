import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/platform_utils.dart';
import '../widgets/report_utils.dart';
import '../widgets/items_date_range_selector.dart';
import '../widgets/report_table_builder.dart';
import '../widgets/codigos_builder.dart';
import '../widgets/stocks_builder.dart';
import '../widgets/report_data_builder.dart';
import '../widgets/report_filters.dart';
import '../widgets/report_header_builders.dart';

export '../widgets/report_utils.dart' show ReportType;

class ReportScreen extends StatefulWidget {
  final String serverUrl;
  final ReportType reportType;
  final DateTime? initialDate; // ventas report용 초기 날짜
  final DateTime? initialItemsStartDate; // items report용 초기 시작 날짜
  final DateTime? initialItemsEndDate; // items report용 초기 종료 날짜
  final String? initialFilteringWord; // 초기 필터링 단어
  final String? initialSortColumn; // 초기 정렬 컬럼
  final bool? initialSortAscending; // 초기 정렬 방향
  final Function(String?, String?, bool?)? onStateChanged; // 상태 변경 콜백 (filteringWord, sortColumn, sortAscending)
  final Function(DateTime?, DateTime?)? onItemsDateRangeChanged; // items 보고서 날짜 범위 변경 콜백
  final bool useFullWidth; // 전체 너비 사용 여부 (resumen del dia에서 사용 시 true)

  const ReportScreen({
    super.key,
    required this.serverUrl,
    required this.reportType,
    this.initialDate,
    this.initialItemsStartDate,
    this.initialItemsEndDate,
    this.initialFilteringWord,
    this.initialSortColumn,
    this.initialSortAscending,
    this.onStateChanged,
    this.onItemsDateRangeChanged,
    this.useFullWidth = false,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late final DatabaseService _databaseService;
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _filteringWordController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController(); // 수평 스크롤 컨트롤러
  int _displayedItemsCount = 100; // 처음 표시할 항목 수
  static const int _itemsPerPage = 100; // 한 번에 추가로 표시할 항목 수
  
  // 정렬 및 필터 상태
  String? _sortColumn;
  bool _sortAscending = true;
  Map<String, String> _columnFilters = {}; // 컬럼별 필터 값
  String? _selectedSucursal; // 선택된 sucursal 필터 (null이면 "모두")
  
  // Items 보고서용 날짜 범위
  DateTime? _itemsStartDate;
  DateTime? _itemsEndDate;
  // Ventas 보고서용 날짜 범위
  DateTime? _ventasStartDate;
  DateTime? _ventasEndDate;
  
  // Codigos 보고서용 상태
  Map<String, dynamic>? _selectedCodigo; // 선택된 codigo
  final Map<String, TextEditingController> _codigoEditControllers = {}; // 편집용 컨트롤러들
  bool _isEditingCodigo = false; // 편집 모드 여부
  bool _isLoadingMoreCodigos = false; // 추가 codigos 로딩 중 여부
  String? _codigosNextIdCodigo; // 다음 페이지의 id_codigo
  bool _codigosHasMore = false; // 더 많은 페이지가 있는지 여부
  String? _codigosSortColumn = 'codigo'; // Codigos 정렬 칼럼 (기본값: codigo)
  bool _codigosSortAscending = true; // Codigos 정렬 방향 (true: 오름차순, false: 내림차순)
  
  // Stocks 보고서용 페이지네이션 상태
  String? _stocksNextMaxUtime; // 다음 페이지의 max_utime
  bool _stocksHasMore = false; // 더 많은 페이지가 있는지 여부
  bool _isLoadingMoreStocks = false; // 추가 stocks 로딩 중 여부
  String? _stocksSortColumn = 'codigo'; // Stocks 정렬 칼럼 (기본값: codigo)
  bool _stocksSortAscending = true; // Stocks 정렬 방향 (true: 오름차순, false: 내림차순)

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService(serverUrl: widget.serverUrl);
    // 스크롤 리스너 추가 (무한 스크롤)
    _scrollController.addListener(_onScroll);
    // filteringWord 변경 감지 리스너 추가
    _filteringWordController.addListener(_onFilteringWordChanged);
    
    // 초기 필터링 단어 설정
    if (widget.initialFilteringWord != null && widget.initialFilteringWord!.isNotEmpty) {
      _filteringWordController.text = widget.initialFilteringWord!;
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
    
    // Items 및 Ingresos 보고서의 경우 기본 날짜 설정 (오늘 날짜 또는 초기값)
    if (widget.reportType == ReportType.items || widget.reportType == ReportType.ingresos) {
      if (widget.initialItemsStartDate != null && widget.initialItemsEndDate != null) {
        _itemsStartDate = widget.initialItemsStartDate;
        _itemsEndDate = widget.initialItemsEndDate;
        print('📅 ${widget.reportType == ReportType.items ? "Items" : "Ingresos"} 보고서 초기 날짜 범위 설정: ${DateFormat('yyyy-MM-dd').format(_itemsStartDate!)} ~ ${DateFormat('yyyy-MM-dd').format(_itemsEndDate!)}');
      } else {
        final now = DateTime.now();
        _itemsStartDate = now;
        _itemsEndDate = now;
      }
    }
    // Ventas 보고서의 경우 초기 날짜 범위 설정
    if (widget.reportType == ReportType.ventas) {
      final now = DateTime.now();
      if (widget.initialDate != null) {
        _ventasStartDate = widget.initialDate;
        _ventasEndDate = widget.initialDate;
        print('📅 Ventas 보고서 초기 날짜 범위 설정: ${DateFormat('yyyy-MM-dd').format(_ventasStartDate!)} ~ ${DateFormat('yyyy-MM-dd').format(_ventasEndDate!)}');
      } else {
        // initialDate가 없으면 오늘 날짜로 설정
        _ventasStartDate = now;
        _ventasEndDate = now;
        print('📅 Ventas 보고서 날짜 범위 설정 (오늘): ${DateFormat('yyyy-MM-dd').format(_ventasStartDate!)} ~ ${DateFormat('yyyy-MM-dd').format(_ventasEndDate!)}');
      }
    }
    // 초기 상태 저장
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyStateChanged();
    });
    _loadData();
  }

  @override
  void didUpdateWidget(ReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // reportType이 변경되었을 때 데이터 다시 로드
    if (oldWidget.reportType != widget.reportType) {
      print('🔄 ReportType 변경 감지: ${oldWidget.reportType} → ${widget.reportType}');
      // 상태 초기화
      _data = null;
      _errorMessage = null;
      _isLoading = true;
      _filteringWordController.clear();
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
      }
      
      // Items 및 Ingresos 보고서의 경우 기본 날짜 설정 (오늘 날짜 또는 초기값)
      if (widget.reportType == ReportType.items || widget.reportType == ReportType.ingresos) {
        if (widget.initialItemsStartDate != null && widget.initialItemsEndDate != null) {
          _itemsStartDate = widget.initialItemsStartDate;
          _itemsEndDate = widget.initialItemsEndDate;
        } else {
          final now = DateTime.now();
          _itemsStartDate = now;
          _itemsEndDate = now;
        }
      }
      
      // Ventas 보고서의 경우 초기 날짜 범위 설정
      if (widget.reportType == ReportType.ventas) {
        final now = DateTime.now();
        if (widget.initialDate != null) {
          _ventasStartDate = widget.initialDate;
          _ventasEndDate = widget.initialDate;
        } else if (oldWidget.reportType != ReportType.ventas) {
          _ventasStartDate = now;
          _ventasEndDate = now;
        }
      } else if (oldWidget.reportType == ReportType.ventas && widget.reportType != ReportType.ventas) {
        _ventasStartDate = null;
        _ventasEndDate = null;
      }
      
      // 데이터 다시 로드
      _loadData();
    }
  }
  
  // filteringWord 변경 감지 핸들러
  String _lastFilteringWord = '';
  void _onFilteringWordChanged() {
    final currentWord = _filteringWordController.text.trim();
    // debounce를 위해 타이머 사용 (500ms 후 실행)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && currentWord == _filteringWordController.text.trim() && 
          currentWord != _lastFilteringWord) {
        _lastFilteringWord = currentWord;
        // 상태 변경 콜백 호출
        _notifyStateChanged();
        // codigos, todocodigos 또는 stocks 보고서인 경우에만 데이터 재로드
        if (widget.reportType == ReportType.codigos || 
            widget.reportType == ReportType.todocodigos || 
            widget.reportType == ReportType.stocks) {
          _reloadDataWithFilters();
        }
      }
    });
  }
  
  // 상태 변경 콜백 호출
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
  Future<void> _reloadDataWithFilters() async {
    // 페이지네이션 상태 초기화
    if (widget.reportType == ReportType.codigos || widget.reportType == ReportType.todocodigos) {
      _codigosNextIdCodigo = null;
      _codigosHasMore = false;
    } else if (widget.reportType == ReportType.stocks) {
      _stocksNextMaxUtime = null;
      _stocksHasMore = false;
    }
    
    await _loadData();
  }

  @override
  void dispose() {
    _filteringWordController.dispose();
    _scrollController.dispose();
    _horizontalScrollController.dispose(); // 수평 스크롤 컨트롤러 정리
    // Codigos 편집 컨트롤러들 정리
    for (var controller in _codigoEditControllers.values) {
      controller.dispose();
    }
    _codigoEditControllers.clear();
    super.dispose();
  }

  Future<void> _loadData({String? filteringWord}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic> data;
      
      switch (widget.reportType) {
        case ReportType.stocks:
          // 첫 페이지만 먼저 받아서 표시
          final currentFilteringWord = filteringWord ?? _filteringWordController.text.trim();
          data = await _databaseService.getStocksReport(
            filteringWord: currentFilteringWord.isNotEmpty ? currentFilteringWord : null,
            sortColumn: _stocksSortColumn,
            sortAscending: _stocksSortAscending,
          );
          
          // 디버깅: 응답 데이터 구조 확인
          print('📊 Stocks 응답 데이터 구조:');
          print('   - data 키 존재: ${data.containsKey('data')}');
          if (data.containsKey('data')) {
            final dataList = data['data'];
            print('   - data 타입: ${dataList.runtimeType}');
            if (dataList is List) {
              print('   - data 배열 길이: ${dataList.length}');
            }
          }
          print('   - filters 키 존재: ${data.containsKey('filters')}');
          print('   - summary 키 존재: ${data.containsKey('summary')}');
          print('   - pagination 키 존재: ${data.containsKey('pagination')}');
          
          // 페이지네이션 정보 저장
          if (data.containsKey('pagination') && data['pagination'] is Map) {
            final pagination = data['pagination'] as Map<String, dynamic>;
            _stocksHasMore = pagination['hasMore'] == true;
            _stocksNextMaxUtime = pagination['nextMaxUtime']?.toString();
            print('   - 페이지네이션: hasMore=$_stocksHasMore, nextMaxUtime=$_stocksNextMaxUtime');
          } else {
            print('   ⚠️ 페이지네이션 정보 없음');
          }
          break;
        case ReportType.items:
          // items 보고서는 항상 날짜 범위가 필요함 (기본값: 오늘부터 오늘까지)
          final now = DateTime.now();
          final startDate = _itemsStartDate ?? now;
          final endDate = _itemsEndDate ?? now;
          final currentFilteringWord = filteringWord ?? _filteringWordController.text.trim();
          
          final filters = <String, dynamic>{
            'fecha_inicio': DateFormat('yyyy-MM-dd').format(startDate),
            'fecha_fin': DateFormat('yyyy-MM-dd').format(endDate),
          };
          data = await _databaseService.getItemsReport(
            filteringWord: currentFilteringWord.isNotEmpty ? currentFilteringWord : null,
            filters: filters,
          );
          break;
        case ReportType.clientes:
          data = await _databaseService.getClientesReport();
          break;
        case ReportType.gastos:
          data = await _databaseService.getGastosReport();
          break;
        case ReportType.ventas:
          // 날짜 범위 필터 사용 (기본값: 오늘부터 오늘까지)
          final now = DateTime.now();
          final startDate = _ventasStartDate ?? now;
          final endDate = _ventasEndDate ?? now;
          final currentFilteringWord = filteringWord ?? _filteringWordController.text.trim();
          
          final filters = <String, dynamic>{
            'fecha_inicio': DateFormat('yyyy-MM-dd').format(startDate),
            'fecha_fin': DateFormat('yyyy-MM-dd').format(endDate),
          };
          print('📅 Ventas 보고서 요청 - 날짜 필터: ${filters['fecha_inicio']} ~ ${filters['fecha_fin']}, filteringWord: $currentFilteringWord');
          data = await _databaseService.getVentasReport(
            filteringWord: currentFilteringWord.isNotEmpty ? currentFilteringWord : null,
            filters: filters,
          );
          break;
        case ReportType.alertas:
          data = await _databaseService.getAlertasReport();
          break;
        case ReportType.ingresos:
          // ingresos 보고서는 날짜 범위 필터 사용 (기본값: 오늘부터 오늘까지)
          final now = DateTime.now();
          final startDate = _itemsStartDate ?? now;
          final endDate = _itemsEndDate ?? now;
          final currentFilteringWord = filteringWord ?? _filteringWordController.text.trim();
          
          final filters = <String, dynamic>{
            'fecha_inicio': DateFormat('yyyy-MM-dd').format(startDate),
            'fecha_fin': DateFormat('yyyy-MM-dd').format(endDate),
          };
          data = await _databaseService.getIngresosReport(
            filteringWord: currentFilteringWord.isNotEmpty ? currentFilteringWord : null,
            filters: filters,
          );
          break;
        case ReportType.codigos:
          // 첫 페이지만 먼저 받아서 표시
          final currentFilteringWord = filteringWord ?? _filteringWordController.text.trim();
          print('🔍 Codigos 요청 - filteringWord: "$currentFilteringWord"');
          data = await _databaseService.getCodigos(
            filteringWord: currentFilteringWord.isNotEmpty ? currentFilteringWord : null,
            sortColumn: _codigosSortColumn,
            sortAscending: _codigosSortAscending,
          );
          // 페이지네이션 정보 저장
          // pagination.id_codigo가 있으면 다음 페이지가 있다고 판단
          if (data.containsKey('pagination') && data['pagination'] is Map) {
            final pagination = data['pagination'] as Map<String, dynamic>;
            // pagination.id_codigo가 있으면 다음 페이지가 있음
            if (pagination.containsKey('id_codigo') && pagination['id_codigo'] != null) {
              _codigosNextIdCodigo = pagination['id_codigo']?.toString();
              _codigosHasMore = true;
              print('📄 다음 페이지 id_codigo: $_codigosNextIdCodigo');
            } else {
              _codigosNextIdCodigo = null;
              _codigosHasMore = false;
              print('ℹ️ 마지막 페이지입니다.');
            }
          } else {
            _codigosNextIdCodigo = null;
            _codigosHasMore = false;
          }
          
          // id_codigo가 포함되어 있는지 확인
          if (data.containsKey('data') && data['data'] is List) {
            final dataList = data['data'] as List;
            if (dataList.isNotEmpty) {
              final firstItem = dataList[0] as Map<String, dynamic>;
              print('📋 첫 번째 Codigo 항목 확인:');
              print('   - codigo: ${firstItem['codigo']}');
              print('   - id_codigo: ${firstItem['id_codigo']}');
              if (firstItem.containsKey('id_codigo')) {
                print('✅ id_codigo 필드가 서버 응답에 포함되어 있습니다!');
              } else {
                print('⚠️ id_codigo 필드가 서버 응답에 없습니다.');
              }
            }
          }
          break;
        case ReportType.todocodigos:
          // Todo Codigos - todocodigos 엔드포인트 사용
          print('🔍 Todo Codigos 요청');
          final currentFilteringWord = filteringWord ?? _filteringWordController.text.trim();
          data = await _databaseService.getTodocodigos(
            filteringWord: currentFilteringWord.isNotEmpty ? currentFilteringWord : null,
            sortColumn: _codigosSortColumn,
            sortAscending: _codigosSortAscending,
          );
          // 페이지네이션 정보 저장
          if (data.containsKey('pagination') && data['pagination'] is Map) {
            final pagination = data['pagination'] as Map<String, dynamic>;
            if (pagination.containsKey('id_todocodigo') && pagination['id_todocodigo'] != null) {
              _codigosNextIdCodigo = pagination['id_todocodigo']?.toString();
              _codigosHasMore = true;
              print('📄 다음 페이지 id_todocodigo: $_codigosNextIdCodigo');
            } else {
              _codigosNextIdCodigo = null;
              _codigosHasMore = false;
              print('ℹ️ 마지막 페이지입니다.');
            }
          } else {
            _codigosNextIdCodigo = null;
            _codigosHasMore = false;
          }
          break;
      }

      setState(() {
        _data = data;
        _isLoading = false;
        // 데이터가 로드되면 처음 100개만 표시
        if (data.containsKey('data') && data['data'] is List) {
          final dataList = data['data'] as List;
          _displayedItemsCount = dataList.length > _itemsPerPage ? _itemsPerPage : dataList.length;
        } else {
          _displayedItemsCount = 100;
        }
      });
    } catch (e) {
        String errorMessage = 'Ocurrió un error desconocido.';
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = e.toString();
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = errorMessage;
        });
      }
    }
  }

  // Codigos 다음 페이지 로드 (스크롤 기반)
  Future<void> _loadNextCodigosPage() async {
    if (widget.reportType != ReportType.codigos && widget.reportType != ReportType.todocodigos) return;
    if (!_codigosHasMore || _codigosNextIdCodigo == null) return;
    if (_isLoadingMoreCodigos) return; // 이미 로딩 중이면 중복 요청 방지
    
    setState(() {
      _isLoadingMoreCodigos = true;
    });
    
    try {
      final filteringWord = _filteringWordController.text.trim();
      Map<String, dynamic> response;
      
      if (widget.reportType == ReportType.todocodigos) {
        print('📄 다음 Todocodigos 페이지 로드 중... (id_todocodigo=$_codigosNextIdCodigo)');
        response = await _databaseService.getTodocodigos(
          idTodocodigo: _codigosNextIdCodigo,
          filteringWord: filteringWord.isNotEmpty ? filteringWord : null,
          sortColumn: _codigosSortColumn,
          sortAscending: _codigosSortAscending,
        );
      } else {
        print('📄 다음 Codigos 페이지 로드 중... (id_codigo=$_codigosNextIdCodigo)');
        response = await _databaseService.getCodigos(
          idCodigo: _codigosNextIdCodigo,
          filteringWord: filteringWord.isNotEmpty ? filteringWord : null,
          sortColumn: _codigosSortColumn,
          sortAscending: _codigosSortAscending,
        );
      }
      
      // 새 데이터 추가
      if (response.containsKey('data') && response['data'] is List) {
        final newData = response['data'] as List;
        if (newData.isNotEmpty && _data != null && _data!.containsKey('data')) {
          final currentData = _data!['data'] as List;
          setState(() {
            _data = {
              ..._data!,
              'data': [...currentData, ...newData],
            };
          });
          print('✅ 다음 페이지 로드됨: ${newData.length}개 항목 (총 ${currentData.length + newData.length}개)');
        }
      }
      
      // 페이지네이션 정보 업데이트
      if (response.containsKey('pagination') && response['pagination'] is Map) {
        final pagination = response['pagination'] as Map<String, dynamic>;
        
        if (widget.reportType == ReportType.todocodigos) {
          // Todocodigos: pagination.id_todocodigo 사용
          if (pagination.containsKey('id_todocodigo') && pagination['id_todocodigo'] != null) {
            _codigosNextIdCodigo = pagination['id_todocodigo']?.toString();
            _codigosHasMore = true;
            print('📄 다음 페이지 id_todocodigo: $_codigosNextIdCodigo');
          } else {
            _codigosNextIdCodigo = null;
            _codigosHasMore = false;
            print('ℹ️ 모든 Todocodigos 페이지 로드 완료');
          }
        } else {
          // Codigos: pagination.id_codigo 사용
          if (pagination.containsKey('id_codigo') && pagination['id_codigo'] != null) {
            _codigosNextIdCodigo = pagination['id_codigo']?.toString();
            _codigosHasMore = true;
            print('📄 다음 페이지 id_codigo: $_codigosNextIdCodigo');
          } else {
            _codigosNextIdCodigo = null;
            _codigosHasMore = false;
            print('ℹ️ 모든 Codigos 페이지 로드 완료');
          }
        }
      } else {
        _codigosNextIdCodigo = null;
        _codigosHasMore = false;
      }
    } catch (e) {
      print('❌ 다음 페이지 로드 실패: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMoreCodigos = false;
        });
      }
    }
  }

  // Stocks 다음 페이지 로드 (스크롤 기반)
  Future<void> _loadNextStocksPage() async {
    if (widget.reportType != ReportType.stocks) return;
    if (!_stocksHasMore || _stocksNextMaxUtime == null) return;
    if (_isLoadingMoreStocks) return; // 이미 로딩 중이면 중복 요청 방지
    
    setState(() {
      _isLoadingMoreStocks = true;
    });
    
    try {
      print('📄 다음 Stocks 페이지 로드 중... (max_utime=$_stocksNextMaxUtime)');
      final filteringWord = _filteringWordController.text.trim();
      final response = await _databaseService.getStocksReport(
        maxUtime: _stocksNextMaxUtime,
        filteringWord: filteringWord.isNotEmpty ? filteringWord : null,
        sortColumn: _stocksSortColumn,
        sortAscending: _stocksSortAscending,
      );
      
      // 새 데이터 추가
      if (response.containsKey('data') && response['data'] is List) {
        final newData = response['data'] as List;
        if (newData.isNotEmpty && _data != null && _data!.containsKey('data')) {
          final currentData = _data!['data'] as List;
          // filters와 summary 정보도 유지
          setState(() {
            _data = {
              ..._data!,
              'data': [...currentData, ...newData],
            };
          });
          print('✅ 다음 페이지 로드됨: ${newData.length}개 항목 (총 ${currentData.length + newData.length}개)');
        }
      }
      
      // 페이지네이션 정보 업데이트
      if (response.containsKey('pagination') && response['pagination'] is Map) {
        final pagination = response['pagination'] as Map<String, dynamic>;
        _stocksHasMore = pagination['hasMore'] == true;
        _stocksNextMaxUtime = pagination['nextMaxUtime']?.toString();
        
        if (!_stocksHasMore) {
          print('ℹ️ 모든 Stocks 페이지 로드 완료');
        }
      } else {
        _stocksHasMore = false;
      }
    } catch (e) {
      print('❌ 다음 페이지 로드 실패: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMoreStocks = false;
        });
      }
    }
  }

  // 스크롤 이벤트 처리 (무한 스크롤)
  void _onScroll() {
    if (widget.reportType == ReportType.codigos || widget.reportType == ReportType.todocodigos) {
      // Codigos의 경우 스크롤이 80% 이상 내려갔을 때 다음 페이지 로드
      if (_scrollController.hasClients && 
          _scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
        _loadNextCodigosPage();
      }
    } else if (widget.reportType == ReportType.stocks) {
      // Stocks의 경우 스크롤이 80% 이상 내려갔을 때 다음 페이지 로드
      if (_scrollController.hasClients && 
          _scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
        _loadNextStocksPage();
      }
    } else {
      // 다른 보고서의 경우 기존 로직 사용
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreItems();
      }
    }
  }

  // 더 많은 항목 로드
  void _loadMoreItems() {
    if (_data == null) return;
    
    if (_data!.containsKey('data') && _data!['data'] is List) {
      final dataList = _data!['data'] as List;
      if (_displayedItemsCount < dataList.length) {
        setState(() {
          _displayedItemsCount = (_displayedItemsCount + _itemsPerPage).clamp(0, dataList.length);
        });
      }
    }
  }

  String _getReportTitle() => ReportUtils.getReportTitle(widget.reportType);
  IconData _getReportIcon() => ReportUtils.getReportIcon(widget.reportType);
  Color _getReportColor() => ReportUtils.getReportColor(widget.reportType);

  // Items 보고서용 데이터 개수 표시
  Widget _buildItemsDataCount() {
    return ReportHeaderBuilders.buildItemsDataCount(_data);
  }

  // Items 보고서용 필터 섹션 (데이터 개수 + 날짜 범위 + 필터링)
  Widget _buildItemsFilterSection() {
    return ReportHeaderBuilders.buildItemsFilterSection(
      data: _data,
      filteringWordController: _filteringWordController,
      startDate: _itemsStartDate,
      endDate: _itemsEndDate,
      onDateRangeChanged: (startDate, endDate) {
        setState(() {
          _itemsStartDate = startDate;
          _itemsEndDate = endDate;
        });
        // 날짜 범위 변경 콜백 호출
        if (widget.onItemsDateRangeChanged != null) {
          widget.onItemsDateRangeChanged!(startDate, endDate);
        }
        _loadData();
      },
      reportType: widget.reportType,
    );
  }

  // Items 보고서용 필터 섹션 (이전 버전 - 제거 예정)
  Widget _buildItemsFilterSectionOld() {
    // 필터링된 데이터 개수 계산
    int totalCount = 0;
    int filteredCount = 0;
    
    if (_data != null && _data!.containsKey('data') && _data!['data'] is List) {
      final dataList = _data!['data'] as List;
      totalCount = dataList.length;
      
      // filteringWord 필터 적용
      final filteringWord = _filteringWordController.text.trim().toLowerCase();
      if (filteringWord.isNotEmpty) {
        filteredCount = dataList.where((item) {
          if (item is Map<String, dynamic>) {
            final codigo1 = item['codigo1']?.toString().toLowerCase() ?? '';
            final desc1 = item['desc1']?.toString().toLowerCase() ?? '';
            return codigo1.contains(filteringWord) || desc1.contains(filteringWord);
          }
          return false;
        }).length;
      } else {
        filteredCount = totalCount;
      }
    }

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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: itemsColor.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: itemsColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 날짜 범위 선택
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
                // 날짜 범위 변경 콜백 호출
                if (widget.onItemsDateRangeChanged != null) {
                  widget.onItemsDateRangeChanged!(startDate, endDate);
                }
                _loadData();
              },
            ),
          ),
          const SizedBox(width: 12),
          // 데이터 개수 표시 (옆)
          Text(
            'Total: $filteredCount${filteredCount != totalCount ? ' / $totalCount' : ''}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reportTitle = _getReportTitle();
    final reportIcon = _getReportIcon();
    final reportColor = _getReportColor();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: widget.reportType == ReportType.stocks
            ? Row(
                children: [
                  Icon(reportIcon, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(reportTitle),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFilteringWordFieldInAppBar(),
                  ),
                ],
              )
            : (widget.reportType == ReportType.items || widget.reportType == ReportType.ingresos)
                ? Row(
                    children: [
                      Icon(reportIcon, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(reportTitle),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildFilteringWordFieldInAppBar(),
                      ),
                    ],
                  )
                : widget.reportType == ReportType.ventas
                    ? Row(
                        children: [
                          Icon(reportIcon, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildVentasHeader(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildFilteringWordFieldInAppBar(),
                          ),
                        ],
                      )
                    : (widget.reportType == ReportType.codigos || widget.reportType == ReportType.todocodigos)
                        ? Row(
                            children: [
                              Icon(reportIcon, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(reportTitle),
                              const SizedBox(width: 16),
                          Expanded(
                            child: _buildFilteringWordFieldInAppBar(),
                          ),
                        ],
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
                        // useFullWidth가 true이면 전체 너비 사용 (resumen del dia에서 사용)
                        if (widget.useFullWidth) {
                          return Column(
                            children: [
                              // Items 및 Ingresos 보고서의 날짜 범위 선택 UI 및 필터링
                              if (widget.reportType == ReportType.items || widget.reportType == ReportType.ingresos)
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
                        }
                        
                        final maxWidth = PlatformUtils.getMaxWidth(
                          context,
                          mobileMaxWidth: double.infinity,
                          tabletMaxWidth: 1400,
                          desktopMaxWidth: 1800,
                        );
                        
                        return Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxWidth),
                            child: Column(
                              children: [
                                // Items 및 Ingresos 보고서의 날짜 범위 선택 UI 및 필터링
                                if (widget.reportType == ReportType.items || widget.reportType == ReportType.ingresos)
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
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _buildReportContent() {
    if (_data == null) {
      return const Center(child: Text('No hay datos'));
    }

    // 데이터 구조 분석 및 적절한 위젯 반환
    final data = _data!;
    
    // Stocks 보고서의 경우 특별 처리
    if (widget.reportType == ReportType.stocks && 
        data.containsKey('data') && 
        data['data'] is List) {
      return _buildStocksContent(data);
    }
    
    // Codigos 및 Todo Codigos 보고서의 경우 특별 처리
    if ((widget.reportType == ReportType.codigos || widget.reportType == ReportType.todocodigos) && 
        data.containsKey('data') && 
        data['data'] is List) {
      return _buildCodigosContent(data);
    }
    
    // 'data' 키가 있고 리스트인 경우
    if (data.containsKey('data') && data['data'] is List) {
      final dataList = data['data'] as List;
      if (dataList.isEmpty) {
        return const Center(child: Text('No hay datos disponibles'));
      }
      
      // 첫 번째 항목이 맵이고 여러 키를 가지고 있으면 테이블로 표시
      if (dataList.isNotEmpty && dataList.first is Map) {
        // Items, Ingresos 및 Ventas 보고서의 경우 filteringWord 필터 적용
        List<dynamic> filteredDataList = dataList;
        if (widget.reportType == ReportType.items || widget.reportType == ReportType.ingresos || widget.reportType == ReportType.ventas) {
          final filteringWord = _filteringWordController.text.trim().toLowerCase();
          if (filteringWord.isNotEmpty) {
            filteredDataList = dataList.where((item) {
              if (item is Map<String, dynamic>) {
                // Items 보고서: codigo1, desc1 사용
                // Ingresos 보고서: codigo, descripcion 사용
                // Ventas 보고서: vcode, vendedor, clientenombre 등 주요 필드에서 검색
                if (widget.reportType == ReportType.items) {
                  final codigo1 = item['codigo1']?.toString().toLowerCase() ?? '';
                  final desc1 = item['desc1']?.toString().toLowerCase() ?? '';
                  return codigo1.contains(filteringWord) || desc1.contains(filteringWord);
                } else if (widget.reportType == ReportType.ingresos) {
                  final codigo = item['codigo']?.toString().toLowerCase() ?? '';
                  final descripcion = item['descripcion']?.toString().toLowerCase() ?? '';
                  return codigo.contains(filteringWord) || descripcion.contains(filteringWord);
                } else if (widget.reportType == ReportType.ventas) {
                  final vcode = item['vcode']?.toString().toLowerCase() ?? '';
                  final vendedor = item['vendedor']?.toString().toLowerCase() ?? '';
                  final clientenombre = item['clientenombre']?.toString().toLowerCase() ?? '';
                  return vcode.contains(filteringWord) || vendedor.contains(filteringWord) || clientenombre.contains(filteringWord);
                }
              }
              return false;
            }).toList();
          }
        }
        // Ventas 보고서의 경우 날짜 필터는 서버에서 처리되므로 클라이언트 측 필터링 제거
        // Ventas 보고서의 경우 filteringWord 필터 적용
        if (widget.reportType == ReportType.ventas) {
          final filteringWord = _filteringWordController.text.trim().toLowerCase();
          if (filteringWord.isNotEmpty) {
            filteredDataList = filteredDataList.where((item) {
              if (item is Map<String, dynamic>) {
                // ventas report의 주요 필드에서 검색
                final codigo = item['codigo']?.toString().toLowerCase() ?? 
                              item['codigo1']?.toString().toLowerCase() ?? '';
                final descripcion = item['descripcion']?.toString().toLowerCase() ?? 
                                  item['desc1']?.toString().toLowerCase() ?? '';
                final cliente = item['cliente']?.toString().toLowerCase() ?? '';
                final total = item['total']?.toString().toLowerCase() ?? '';
                
                return codigo.contains(filteringWord) || 
                       descripcion.contains(filteringWord) ||
                       cliente.contains(filteringWord) ||
                       total.contains(filteringWord);
              }
              return false;
            }).toList();
          }
        }
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
        if (widget.reportType == ReportType.items || widget.reportType == ReportType.ingresos) {

          // Items 및 Ingresos 보고서의 경우 정렬 적용
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
          
          // Items 보고서는 왼쪽과 오른쪽으로 절반씩 나눔
          return Row(
            children: [
              // 왼쪽 부분: Items 보고서 내용 (내용에 맞게 크기 조정)
              Flexible(
                flex: 1,
                fit: FlexFit.loose,
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
              ),
              // 구분선
              Container(
                width: 1,
                color: Colors.grey[300],
              ),
              // 오른쪽 절반: 비어있음 (나중에 사용 가능)
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
        }
        
        return ReportTableBuilder.buildTableFromList(
          filteredDataList,
          _displayedItemsCount,
          _itemsPerPage,
          _scrollController,
          widget.reportType,
          horizontalScrollController: _horizontalScrollController,
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
                ...displayedList.map((item) => _buildDataCard(item)).toList(),
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
    if (data is Map<String, dynamic>) {
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
    }
    
    return const Center(child: Text('Formato de datos desconocido'));
  }

  // Stocks 보고서의 vista 타입 표시 (Body용)
  Widget _buildStocksViewType() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 800;
        // 대형 화면에서는 AppBar에 표시되므로 여기서는 숨김
        if (isLargeScreen) {
          return const SizedBox.shrink();
        }
        // bcolorview 값에 따라 색상 결정
        Color stocksColor = Colors.orange; // 기본값
        if (_data != null) {
          if (_data!.containsKey('filters') && _data!['filters'] is Map) {
            final filters = _data!['filters'] as Map<String, dynamic>;
            final bcolorview = filters['bcolorview'];
            stocksColor = ReportUtils.isBcolorviewEnabled(bcolorview) ? Colors.orange : Colors.lightBlue;
          } else if (_data!.containsKey('bcolorview')) {
            final bcolorview = _data!['bcolorview'];
            stocksColor = ReportUtils.isBcolorviewEnabled(bcolorview) ? Colors.orange : Colors.lightBlue;
          }
        }
        return StocksBuilder.buildViewType(
          data: _data,
          selectedSucursal: _selectedSucursal,
          onSucursalChanged: (value) {
            setState(() {
              _selectedSucursal = value;
            });
          },
          reportColor: stocksColor,
        );
      },
    );
  }

  // Stocks 보고서의 vista 타입 표시 (AppBar용 - 컴팩트 버전)
  Widget _buildStocksViewTypeInAppBar() {
    if (_data == null || !_data!.containsKey('filters')) {
      return const SizedBox.shrink();
    }
    
    final filters = _data!['filters'] as Map<String, dynamic>?;
    if (filters == null || !filters.containsKey('bcolorview')) {
      return const SizedBox.shrink();
    }
    
    final bcolorview = filters['bcolorview'];
    final isBcolorviewEnabled = ReportUtils.isBcolorviewEnabled(bcolorview);
    final viewType = isBcolorviewEnabled ? 'Vista Resumida' : 'VistaD';
    
    // Vista Detallada일 때만 sucursal 필터 표시
    final bool showSucursalFilter = !isBcolorviewEnabled;
    List<String>? sucursales;
    
    if (showSucursalFilter && _data!.containsKey('data') && _data!['data'] is List) {
      final dataList = _data!['data'] as List;
      final sucursalSet = <String>{};
      
      for (var item in dataList) {
        if (item is Map<String, dynamic> && item.containsKey('sucursal')) {
          final sucursal = item['sucursal']?.toString();
          if (sucursal != null && sucursal.isNotEmpty) {
            sucursalSet.add(sucursal);
          }
        }
      }
      
      sucursales = sucursalSet.toList()..sort((a, b) {
        final aNum = int.tryParse(a) ?? 0;
        final bNum = int.tryParse(b) ?? 0;
        return aNum.compareTo(bNum);
      });
    }
    
    // bcolorview 값에 따라 색상 결정
    Color reportColor = Colors.orange; // 기본값
    if (filters != null && filters.containsKey('bcolorview')) {
      final bcolorviewValue = filters['bcolorview'];
      reportColor = ReportUtils.isBcolorviewEnabled(bcolorviewValue) ? Colors.orange : Colors.lightBlue;
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isBcolorviewEnabled ? Icons.view_compact : Icons.view_list,
          color: Colors.white,
          size: 18,
        ),
        const SizedBox(width: 6),
        Text(
          viewType,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        // Sucursal이 2개 이상일 때만 콤보박스 표시
        if (showSucursalFilter && sucursales != null && sucursales.length > 1)
          ...[
            const SizedBox(width: 12),
            Container(
              constraints: const BoxConstraints(minWidth: 80, maxWidth: 120),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: DropdownButton<String?>(
                value: _selectedSucursal,
                hint: const Text('모두', style: TextStyle(fontSize: 12, color: Colors.white)),
                underline: const SizedBox(),
                isDense: true,
                dropdownColor: reportColor,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
                style: const TextStyle(fontSize: 12, color: Colors.white),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('모두', style: TextStyle(fontSize: 12, color: Colors.white)),
                  ),
                  ...sucursales.map((sucursal) {
                    return DropdownMenuItem<String?>(
                      value: sucursal,
                      child: Text(sucursal, style: const TextStyle(fontSize: 12, color: Colors.white)),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSucursal = value;
                  });
                },
              ),
            ),
          ],
      ],
    );
  }

  // Stocks 보고서 전용 콘텐츠 빌드
  Widget _buildStocksContent(Map<String, dynamic> data) {
    // bcolorview 값에 따라 색상 결정
    Color stocksColor;
    if (data.containsKey('filters') && data['filters'] is Map) {
      final filters = data['filters'] as Map<String, dynamic>;
      final bcolorview = filters['bcolorview'];
      // bcolorview가 활성화되면 오렌지색, 비활성화되면 하늘색
      stocksColor = ReportUtils.isBcolorviewEnabled(bcolorview) ? Colors.orange : Colors.lightBlue;
    } else if (data.containsKey('bcolorview')) {
      final bcolorview = data['bcolorview'];
      stocksColor = ReportUtils.isBcolorviewEnabled(bcolorview) ? Colors.orange : Colors.lightBlue;
    } else {
      // 기본값은 오렌지색
      stocksColor = Colors.orange;
    }
    
    // 헤더 위젯 생성
    final headerWidget = StocksBuilder.buildHeader(
      reportType: ReportType.stocks,
      sortColumn: _stocksSortColumn,
      sortAscending: _stocksSortAscending,
      onSort: (column, ascending) {
        setState(() {
          if (_stocksSortColumn == column) {
            _stocksSortAscending = ascending;
          } else {
            _stocksSortColumn = column;
            _stocksSortAscending = false; // 첫 클릭 시 내림차순
          }
        });
        _notifyStateChanged();
        _reloadDataWithFilters();
      },
      reportColor: stocksColor,
    );
    
    return StocksBuilder.buildContent(
      data: data,
      context: context,
      scrollController: _scrollController,
      isLoadingMore: _isLoadingMoreStocks,
      reportColor: stocksColor,
      headerWidget: headerWidget,
    );
  }

  // Stocks 보고서 전용 콘텐츠 빌드 (이전 버전 - 제거 예정)
  Widget _buildStocksContentOld(Map<String, dynamic> data) {
    final dataList = data['data'] as List;
    if (dataList.isEmpty) {
      return const Center(child: Text('No data available'));
    }
    
    // 서버에서 이미 필터링된 데이터를 사용
    final filteredDataList = dataList;

    return Column(
      children: [
        // 백그라운드 로딩 인디케이터
        if (_isLoadingMoreStocks)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.blue.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _getReportColor(),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '추가 데이터 로딩 중...',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getReportColor(),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: Builder(
            builder: (context) {
              // 실제 컨텐츠 너비 계산 (stocks_builder.dart와 동일)
              final totalWidth = 1940.0 + 144.0 + 32.0; // 실제 컨텐츠 너비 = 2116
              final screenWidth = MediaQuery.of(context).size.width;
              final needsHorizontalScroll = totalWidth > screenWidth;
              
              final content = Column(
                children: [
                  // 칼럼 헤더
                  _buildStocksHeader(),
                  // 데이터 리스트
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.vertical,
                      shrinkWrap: false,
                      physics: const AlwaysScrollableScrollPhysics(), // 세로 스크롤 활성화
                      itemCount: filteredDataList.length,
                      itemBuilder: (context, index) {
                        final stock = filteredDataList[index] as Map<String, dynamic>;
        
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 150,
                                child: Text(
                                  stock['codigo']?.toString() ?? 
                                  stock['tcode']?.toString() ?? 
                                  'N/A',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 300,
                                child: Text(
                                  stock['descripcion']?.toString() ?? 
                                  stock['tdesc']?.toString() ?? 
                                  'N/A',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (stock['stockreal'] != null || stock['stockreal3'] != null)
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    stock['stockreal']?.toString() ?? 
                                    stock['stockreal3']?.toString() ?? 
                                    'N/A',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              if (stock['pre1'] != null)
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    stock['pre1']?.toString() ?? 'N/A',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
              
              if (needsHorizontalScroll) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: totalWidth,
                    child: content,
                  ),
                );
              } else {
                return SizedBox(
                  width: screenWidth,
                  child: content,
                );
              }
            },
          ),
        ),
      ],
    );
  }

  // Stocks 테이블 빌드 (bcolorview에 따라 다른 필드 사용)
  Widget _buildStocksTable(List<dynamic> dataList, bool isResumida) {
    if (dataList.isEmpty) {
      return const Center(child: Text('No hay datos'));
    }
    
    // filteringWord 필터 적용 (codigo와 descripcion에서 검색)
    List<dynamic> filteredList = dataList;
    final filteringWord = _filteringWordController.text.trim().toLowerCase();
    if (filteringWord.isNotEmpty) {
      filteredList = dataList.where((item) {
        if (item is Map<String, dynamic>) {
          final codigo = item['codigo']?.toString().toLowerCase() ?? '';
          final descripcion = item['descripcion']?.toString().toLowerCase() ?? '';
          return codigo.contains(filteringWord) || descripcion.contains(filteringWord);
        }
        return false;
      }).toList();
    }
    
    // Sucursal 필터 적용
    if (!isResumida && _selectedSucursal != null) {
      filteredList = filteredList.where((item) {
        if (item is Map<String, dynamic> && item.containsKey('sucursal')) {
          final sucursal = item['sucursal']?.toString();
          return sucursal == _selectedSucursal;
        }
        return false;
      }).toList();
    }
    
    // 정렬 적용
    List<dynamic> sortedList = List.from(filteredList);
    if (_sortColumn != null) {
      sortedList.sort((a, b) {
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
    
    // 대량 데이터 처리
    final displayedList = sortedList.take(_displayedItemsCount).toList();
    final totalCount = sortedList.length;
    final hasMore = _displayedItemsCount < totalCount;
    
    // 첫 번째 항목의 키를 컬럼으로 사용
    final firstItem = displayedList.isNotEmpty 
        ? displayedList.first as Map<String, dynamic>
        : dataList.first as Map<String, dynamic>;
    
    // 필드명을 스페인어로 매핑
    final fieldNames = ReportUtils.getStocksFieldNames(isResumida);
    
    // 칼럼 순서 재정렬: fecha 칼럼과 precio 칼럼들을 뒤로 이동 (Vista Detallada일 때만)
    List<String> orderedKeys = firstItem.keys.toList();
    if (!isResumida) {
      final precioKeys = ['pre1', 'pre2', 'pre3', 'pre4', 'pre5'];
      final fechaKeys = ['first_date', 'last_date'];
      final otherKeys = orderedKeys.where((key) => !precioKeys.contains(key) && !fechaKeys.contains(key)).toList();
      final fechaKeysInData = orderedKeys.where((key) => fechaKeys.contains(key)).toList();
      final precioKeysInData = orderedKeys.where((key) => precioKeys.contains(key)).toList();
      orderedKeys = [...otherKeys, ...fechaKeysInData, ...precioKeysInData];
    }
    
    // 표시할 컬럼 선택 (정렬 기능 추가)
    final columns = orderedKeys.map((key) {
      final displayName = fieldNames[key] ?? key.toString();
      final isSorted = _sortColumn == key;
      return DataColumn(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (isSorted)
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: _getReportColor(),
              ),
          ],
        ),
        onSort: (columnIndex, ascending) {
          setState(() {
            if (_sortColumn == key) {
              // 같은 칼럼을 클릭하면 정렬 방향 변경
              _sortAscending = !_sortAscending;
            } else {
              // 다른 칼럼을 클릭하면 새 칼럼으로 정렬 (첫 클릭 시 내림차순)
              _sortColumn = key;
              _sortAscending = false; // 첫 클릭 시 내림차순
            }
            // 정렬이 변경되면 처음부터 다시 표시
            _displayedItemsCount = _itemsPerPage;
          });
        },
      );
    }).toList();
    
    return Expanded(
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 8,
              dataRowMinHeight: 5,
              dataRowMaxHeight: 5,
              headingRowColor: MaterialStateProperty.all(
                _getReportColor().withOpacity(0.1),
              ),
              sortColumnIndex: _sortColumn != null ? orderedKeys.indexOf(_sortColumn!) : null,
              sortAscending: _sortAscending,
              columns: columns,
              rows: [
                ...displayedList.map((item) {
                  if (item is Map<String, dynamic>) {
                    return DataRow(
                      cells: orderedKeys.map((key) {
                        final value = item[key];
                        // Codigo 칼럼은 문자로 표시 (숫자 포맷팅 제외)
                        final isCodigoColumn = key == 'codigo' || key == 'tcode';
                        final formattedValue = isCodigoColumn 
                            ? (value?.toString() ?? 'N/A')
                            : ReportUtils.formatValue(value);
                        final isNumeric = isCodigoColumn ? false : ReportUtils.isNumeric(value);
                        return DataCell(
                          Align(
                            alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
                            child: Text(
                              formattedValue,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }
                  final formattedValue = ReportUtils.formatValue(item);
                  final isNumeric = ReportUtils.isNumeric(item);
                  return DataRow(
                    cells: [
                      DataCell(
                        Align(
                          alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
                          child: Text(
                            formattedValue,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                // 합계 행 추가
                _buildTotalRow(orderedKeys, sortedList, isResumida),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 합계 행 빌드
  DataRow _buildTotalRow(List<String> orderedKeys, List<dynamic> dataList, bool isResumida) {
    // 각 칼럼별 합계 계산
    final totals = <String, num>{};
    
    for (var key in orderedKeys) {
      final isCodigoColumn = key == 'codigo' || key == 'tcode' || key == 'codigo1' || key == 'id_codigo1';
      if (isCodigoColumn) continue; // 문자 칼럼은 합계 계산 제외
      
      num sum = 0;
      for (var item in dataList) {
        if (item is Map<String, dynamic> && item.containsKey(key)) {
          final value = item[key];
          if (ReportUtils.isNumeric(value)) {
            final numValue = num.tryParse(value.toString().replaceAll(',', '').replaceAll('\$', '').trim());
            if (numValue != null) {
              sum += numValue;
            }
          }
        }
      }
      totals[key] = sum;
    }
    
    return DataRow(
      color: MaterialStateProperty.all(_getReportColor().withOpacity(0.1)),
      cells: orderedKeys.map((key) {
        final isCodigoColumn = key == 'codigo' || key == 'tcode' || key == 'codigo1' || key == 'id_codigo1';
        if (isCodigoColumn) {
          return DataCell(
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Total',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }
        
        final total = totals[key] ?? 0;
        return DataCell(
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              ReportUtils.formatValue(total),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 컬럼 필터 UI 빌드
  List<Widget> _buildColumnFilters(List<String> columnKeys, Map<String, String> fieldNames) {
    // 제외할 필드 목록
    final excludedFields = ['pre3', 'pre4', 'pre5', 'id_codigo1', 'ref_id_todocodigo', 'cntoffset', 'cntoffset3', 'first_date'];
    
    return columnKeys
        .where((key) => !excludedFields.contains(key))
        .map((key) {
      final displayName = fieldNames[key] ?? key.toString();
      final filterValue = _columnFilters[key] ?? '';
      
      return SizedBox(
        width: 150,
        child: TextField(
          controller: TextEditingController(text: filterValue)
            ..selection = TextSelection.collapsed(offset: filterValue.length),
          decoration: InputDecoration(
            labelText: displayName,
            hintText: 'Filtrar...',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            suffixIcon: filterValue.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () {
                      setState(() {
                        _columnFilters.remove(key);
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                : null,
          ),
          style: const TextStyle(fontSize: 12),
          onChanged: (value) {
            setState(() {
              if (value.isEmpty) {
                _columnFilters.remove(key);
              } else {
                _columnFilters[key] = value;
              }
              // 필터 변경 시 처음부터 다시 표시
              _displayedItemsCount = _itemsPerPage;
            });
          },
        ),
      );
    }).toList();
  }

  // 필터 적용
  List<dynamic> _applyFilters(List<dynamic> dataList) {
    if (_columnFilters.isEmpty) {
      return dataList;
    }
    
    return dataList.where((item) {
      if (item is! Map<String, dynamic>) return true;
      
      for (var entry in _columnFilters.entries) {
        final columnKey = entry.key;
        final filterValue = entry.value.toLowerCase();
        
        if (!item.containsKey(columnKey)) continue;
        
        final cellValue = item[columnKey];
        final cellValueStr = ReportUtils.formatValue(cellValue).toLowerCase();
        
        if (!cellValueStr.contains(filterValue)) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  // 정렬 적용
  List<dynamic> _applySort(List<dynamic> dataList) {
    if (_sortColumn == null || dataList.isEmpty) {
      return dataList;
    }
    
    final sortedList = List<dynamic>.from(dataList);
    
    sortedList.sort((a, b) {
      if (a is! Map<String, dynamic> || b is! Map<String, dynamic>) {
        return 0;
      }
      
      final aValue = a[_sortColumn];
      final bValue = b[_sortColumn];
      
      // null 처리
      if (aValue == null && bValue == null) return 0;
      if (aValue == null) return 1;
      if (bValue == null) return -1;
      
      // 숫자 비교
      if (aValue is num && bValue is num) {
        final comparison = aValue.compareTo(bValue);
        return _sortAscending ? comparison : -comparison;
      }
      
      // 문자열 비교
      final aStr = ReportUtils.formatValue(aValue).toLowerCase();
      final bStr = ReportUtils.formatValue(bValue).toLowerCase();
      final comparison = aStr.compareTo(bStr);
      return _sortAscending ? comparison : -comparison;
    });
    
    return sortedList;
  }

  // Stocks 필드명 매핑 (스페인어)

  // Ventas report 헤더 (날짜 범위 및 sucursal 선택)
  Widget _buildVentasHeader() {
    return ReportHeaderBuilders.buildVentasHeader(
      context: context,
      data: _data,
      startDate: _ventasStartDate,
      endDate: _ventasEndDate,
      selectedSucursal: _selectedSucursal,
      onDateRangeChanged: (startDate, endDate) {
        setState(() {
          _ventasStartDate = startDate;
          _ventasEndDate = endDate;
        });
        _loadData();
      },
      onSucursalChanged: (value) {
        setState(() {
          _selectedSucursal = value;
        });
      },
      reportColor: _getReportColor(),
      reportType: widget.reportType,
    );
  }

  // Ventas report 헤더 (이전 버전 - 제거 예정, 사용되지 않음)
  // 전체 함수가 주석 처리되어 있음 - 필요시 삭제 가능
  /*
  Widget _buildVentasHeaderOld() {
    // 데이터에서 sucursal 목록 추출
    List<String>? sucursales;
    if (_data != null && _data!.containsKey('data') && _data!['data'] is List) {
      final dataList = _data!['data'] as List;
      final sucursalSet = <String>{};
      
      for (var item in dataList) {
        if (item is Map<String, dynamic> && item.containsKey('sucursal')) {
          final sucursal = item['sucursal']?.toString();
          if (sucursal != null && sucursal.isNotEmpty) {
            sucursalSet.add(sucursal);
          }
        }
      }
      
      if (sucursalSet.isNotEmpty) {
        sucursales = sucursalSet.toList()..sort((a, b) {
          final aNum = int.tryParse(a) ?? 0;
          final bNum = int.tryParse(b) ?? 0;
          return aNum.compareTo(bNum);
        });
      }
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sucursal이 1개 이상일 때만 콤보박스 표시
        if (sucursales != null && sucursales.length > 1) ...[
          const SizedBox(width: 8),
          Container(
            constraints: const BoxConstraints(minWidth: 80),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButton<String?>(
              value: _selectedSucursal,
              hint: const Text('모두', style: TextStyle(fontSize: 11)),
              underline: const SizedBox(),
              isDense: true,
              icon: Icon(Icons.arrow_drop_down, color: _getReportColor(), size: 18),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('모두', style: TextStyle(fontSize: 11)),
                ),
                ...sucursales.map((sucursal) {
                  return DropdownMenuItem<String?>(
                    value: sucursal,
                    child: Text(sucursal, style: const TextStyle(fontSize: 11)),
                  );
                }).toList(),
              ],
              onChanged: (String? value) {
                setState(() {
                  _selectedSucursal = value;
                });
              },
            ),
          ),
        ],
      ],
    );
  }
  */

  // Filtering word 입력 필드 (AppBar용)
  Widget _buildFilteringWordFieldInAppBar() {
    return ReportFilters.buildFilteringWordField(
        controller: _filteringWordController,
      onSubmitted: (value) {
        // codigos, todocodigos 또는 stocks 보고서인 경우 서버에 요청
        if (widget.reportType == ReportType.codigos || 
            widget.reportType == ReportType.todocodigos || 
            widget.reportType == ReportType.stocks) {
          _reloadDataWithFilters();
        }
      },
      onClear: () {
                    setState(() {
                      _filteringWordController.clear();
                    });
                  },
    );
  }

  Widget _buildTableFromList(List<dynamic> dataList) {
    if (dataList.isEmpty) {
      return const Center(child: Text('No hay datos'));
    }
    
    // 대량 데이터 처리: 처음 100개만 표시하고 나머지는 스크롤 시 로드
    final displayedList = dataList.take(_displayedItemsCount).toList();
    final totalCount = dataList.length;
    final hasMore = _displayedItemsCount < totalCount;
    
    // 첫 번째 항목의 키를 컬럼으로 사용
    final firstItem = displayedList.first as Map<String, dynamic>;
    final columns = firstItem.keys.map((key) {
      return DataColumn(
        label: Text(
          key.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }).toList();
    
    return Column(
      children: [
        // 테이블 (가상 스크롤 사용)
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 8,
                dataRowMinHeight: 5,
                dataRowMaxHeight: 5,
                headingRowColor: MaterialStateProperty.all(
                  _getReportColor().withOpacity(0.1),
                ),
                columns: columns,
                rows: [
                  ...displayedList.map((item) {
                    if (item is Map<String, dynamic>) {
                      return DataRow(
                        cells: firstItem.keys.map((key) {
                          final value = item[key];
                          final formattedValue = ReportUtils.formatValue(value);
                          final isNumeric = ReportUtils.isNumeric(value);
                          return DataCell(
                            Align(
                              alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
                              child: Text(
                                formattedValue,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }
                    final formattedValue = ReportUtils.formatValue(item);
                    final isNumeric = ReportUtils.isNumeric(item);
                    return DataRow(
                      cells: [
                        DataCell(
                          Align(
                            alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
                            child: Text(
                              formattedValue,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  // 합계 행 추가
                  _buildTotalRowForTable(firstItem.keys.toList(), dataList),
                ],
              ),
            ),
          ),
        ),
        // 더 보기 버튼 또는 로딩 인디케이터
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
    );
  }

  // 테이블용 합계 행 빌드
  DataRow _buildTotalRowForTable(List<String> keys, List<dynamic> dataList) {
    // 각 칼럼별 합계 계산
    final totals = <String, num>{};
    
    for (var key in keys) {
      final isCodigoColumn = key == 'codigo' || key == 'codigo1' || key == 'tcode' || key == 'id_codigo1';
      if (isCodigoColumn) continue; // 문자 칼럼은 합계 계산 제외
      
      num sum = 0;
      for (var item in dataList) {
        if (item is Map<String, dynamic> && item.containsKey(key)) {
          final value = item[key];
          if (ReportUtils.isNumeric(value)) {
            final numValue = num.tryParse(value.toString().replaceAll(',', '').replaceAll('\$', '').trim());
            if (numValue != null) {
              sum += numValue;
            }
          }
        }
      }
      totals[key] = sum;
    }
    
    return DataRow(
      color: MaterialStateProperty.all(_getReportColor().withOpacity(0.1)),
      cells: keys.map((key) {
        final isCodigoColumn = key == 'codigo' || key == 'codigo1' || key == 'tcode' || key == 'id_codigo1';
        if (isCodigoColumn) {
          return DataCell(
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Total',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }
        
        final total = totals[key] ?? 0;
        return DataCell(
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              ReportUtils.formatValue(total),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDataCard(dynamic item) {
    return ReportDataBuilder.buildDataCard(item);
  }

  Widget _buildDataCardOld(dynamic item) {
    if (item is Map<String, dynamic>) {
      return Container(
        padding: EdgeInsets.zero,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!, width: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: item.entries.map((entry) {
            return Padding(
              padding: EdgeInsets.zero,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      entry.key.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      ReportUtils.formatValue(entry.value),
                      textAlign: ReportUtils.isNumeric(entry.value) ? TextAlign.right : TextAlign.left,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    }
    return Container(
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 0.5),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        dense: true,
        title: Text(
          item.toString(),
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildDataMap(Map<String, dynamic> data) {
    // 테이블 형태로 표시할 수 있는 데이터인지 확인
    if (ReportTableBuilder.isTableData(data)) {
      return ReportTableBuilder.buildTable(data, widget.reportType);
    }

    // 카드 없이 직접 표시
    return ReportDataBuilder.buildDataMap(data);
  }

  Widget _buildValueWidget(dynamic value) {
    return ReportDataBuilder.buildValueWidget(value);
  }

  Widget _buildValueWidgetOld(dynamic value) {
    if (value is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: (value as Map<String, dynamic>).entries.map((entry) {
          final formattedValue = ReportUtils.formatValue(entry.value);
          final isNumeric = ReportUtils.isNumeric(entry.value);
          return Padding(
            padding: EdgeInsets.zero,
            child: Text(
              '${entry.key}: $formattedValue',
              textAlign: isNumeric ? TextAlign.right : TextAlign.left,
              style: const TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
      );
    } else if (value is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: value.asMap().entries.map((entry) {
          final formattedValue = ReportUtils.formatValue(entry.value);
          final isNumeric = ReportUtils.isNumeric(entry.value);
          return Padding(
            padding: EdgeInsets.zero,
            child: Text(
              '${entry.key + 1}. $formattedValue',
              textAlign: isNumeric ? TextAlign.right : TextAlign.left,
              style: const TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
      );
    }
    final formattedValue = ReportUtils.formatValue(value);
    final isNumeric = ReportUtils.isNumeric(value);
    return Text(
      formattedValue,
      textAlign: isNumeric ? TextAlign.right : TextAlign.left,
      style: const TextStyle(fontSize: 14),
    );
  }

  // Codigos 보고서 콘텐츠 빌드
  Widget _buildCodigosContent(Map<String, dynamic> data) {
    final dataList = data['data'] as List;
    if (dataList.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    // 첫 번째 항목에서 모든 칼럼 키 추출
    final firstItem = dataList[0] as Map<String, dynamic>;
    final columnKeys = widget.reportType == ReportType.todocodigos
        ? ['id_todocodigo', 'tcodigo', 'tdesc', 'tpre1', 'tpre2', 'tpre3', 'tpre4', 'tpre5', 'utime', 'borrado', 'ip', 'mac']
            .where((key) => firstItem.containsKey(key))
            .toList()
        : firstItem.keys
            .where((key) => key != 'id_woocommerce' && key != 'id_woocommerce_producto')
            .toList();
    
    // 칼럼별 너비 설정
    final columnWidths = <String, double>{
      'codigo': 150,
      'descripcion': 300,
      'pre1': 100,
      'pre2': 100,
      'pre3': 100,
      'pre4': 100,
      'pre5': 100,
      'preorg': 100,
      'tcodigo': 120,
      'tdesc': 300,
      'tpre1': 100,
      'tpre2': 100,
      'tpre3': 100,
      'tpre4': 100,
      'tpre5': 100,
      'utime': 150,
      'borrado': 80,
      'ip': 120,
      'mac': 150,
      'b_sincronizar_x_web': 120,
      'id_woocommerce': 120,
      'id_woocommerce_producto': 150,
      'id_codigo': 100,
      'id_todocodigo': 120,
    };
    
    // 칼럼별 표시 이름 설정
    final columnDisplayNames = <String, String>{
      'codigo': 'Codigo',
      'descripcion': 'Descripción',
      'pre1': 'Precio 1',
      'pre2': 'Precio 2',
      'pre3': 'Precio 3',
      'pre4': 'Precio 4',
      'pre5': 'Precio 5',
      'preorg': 'Precio Org',
      'tcodigo': 'T Codigo',
      'tdesc': 'T Desc',
      'tpre1': 'T Precio 1',
      'tpre2': 'T Precio 2',
      'tpre3': 'T Precio 3',
      'tpre4': 'T Precio 4',
      'tpre5': 'T Precio 5',
      'utime': 'Utime',
      'borrado': 'Borrado',
      'ip': 'IP',
      'mac': 'MAC',
      'b_sincronizar_x_web': 'Sincronizar Web',
      'id_woocommerce': 'ID WooCommerce',
      'id_woocommerce_producto': 'ID WooCommerce Producto',
      'id_codigo': 'ID Codigo',
      'id_todocodigo': 'ID Todo Codigo',
    };
    
    // 기본 너비가 없는 칼럼은 100으로 설정
    for (var key in columnKeys) {
      if (!columnWidths.containsKey(key)) {
        columnWidths[key] = 100.0;
      }
      if (!columnDisplayNames.containsKey(key)) {
        columnDisplayNames[key] = key;
      }
    }

    // 헤더 위젯 생성
    final headerWidget = CodigosBuilder.buildHeader(
      reportType: widget.reportType,
      sortColumn: _codigosSortColumn,
      sortAscending: _codigosSortAscending,
      onSort: (column, ascending) {
        setState(() {
          if (_codigosSortColumn == column) {
            _codigosSortAscending = ascending;
          } else {
            _codigosSortColumn = column;
            _codigosSortAscending = false; // 첫 클릭 시 내림차순
          }
        });
        _notifyStateChanged();
        _reloadDataWithFilters();
      },
      reportColor: _getReportColor(),
      columnKeys: columnKeys,
      columnWidths: columnWidths,
      columnDisplayNames: columnDisplayNames,
    );

    return Row(
      children: [
        Expanded(
          flex: _selectedCodigo != null ? 1 : 1,
          child: CodigosBuilder.buildContent(
            data: data,
            context: context,
            scrollController: _scrollController,
            selectedCodigo: _selectedCodigo,
            onCodigoSelected: (codigo) {
              setState(() {
                _selectedCodigo = Map<String, dynamic>.from(codigo);
                _isEditingCodigo = false;
                _initializeCodigoEditControllers();
              });
            },
            isLoadingMore: _isLoadingMoreCodigos,
            reportColor: _getReportColor(),
            columnKeys: columnKeys,
            columnWidths: columnWidths,
            headerWidget: headerWidget,
          ),
        ),
        // 오른쪽: 선택된 Codigo 편집 UI
        if (_selectedCodigo != null)
          Expanded(
            flex: 1,
            child: _buildCodigoEditPanel(),
          ),
      ],
    );
  }

  // Codigos 칼럼 헤더 빌드
  Widget _buildCodigosHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[400]!,
            width: 2,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildSortableHeader('codigo', 'Codigo', 150),
          const SizedBox(width: 12),
          _buildSortableHeader('descripcion', 'Descripción', 300),
          const SizedBox(width: 12),
          _buildSortableHeader('pre1', 'Precio 1', 100),
          const SizedBox(width: 12),
          _buildSortableHeader('pre2', 'Precio 2', 100),
        ],
      ),
    );
  }
  
  // Stocks 칼럼 헤더 빌드
  Widget _buildStocksHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getReportColor().withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[400]!,
            width: 2,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildSortableHeader('codigo', 'Codigo', 150),
            const SizedBox(width: 12),
            _buildSortableHeader('descripcion', 'Descripción', 300),
            const SizedBox(width: 12),
            _buildSortableHeader('stockreal', 'Stock', 100),
            const SizedBox(width: 12),
            _buildSortableHeader('pre1', 'Precio 1', 100),
          ],
        ),
      ),
    );
  }
  
  // 정렬 가능한 헤더 위젯 빌드 (Codigos용)
  Widget _buildSortableHeader(String columnKey, String displayName, double width) {
    final isSorted = ((widget.reportType == ReportType.codigos || widget.reportType == ReportType.todocodigos) && _codigosSortColumn == columnKey) ||
                     (widget.reportType == ReportType.stocks && _stocksSortColumn == columnKey);
    final isAscending = (widget.reportType == ReportType.codigos || widget.reportType == ReportType.todocodigos)
        ? _codigosSortAscending 
        : _stocksSortAscending;
    
    return InkWell(
      onTap: () {
        setState(() {
          if (widget.reportType == ReportType.codigos || widget.reportType == ReportType.todocodigos) {
            if (_codigosSortColumn == columnKey) {
              // 같은 칼럼을 클릭하면 정렬 방향 변경
              _codigosSortAscending = !_codigosSortAscending;
            } else {
              // 다른 칼럼을 클릭하면 새 칼럼으로 정렬 (첫 클릭 시 내림차순)
              _codigosSortColumn = columnKey;
              _codigosSortAscending = false;
            }
          } else if (widget.reportType == ReportType.stocks) {
            if (_stocksSortColumn == columnKey) {
              // 같은 칼럼을 클릭하면 정렬 방향 변경
              _stocksSortAscending = !_stocksSortAscending;
            } else {
              // 다른 칼럼을 클릭하면 새 칼럼으로 정렬 (첫 클릭 시 내림차순)
              _stocksSortColumn = columnKey;
              _stocksSortAscending = false;
            }
          }
        });
        _notifyStateChanged();
        // 데이터 재로드
        _reloadDataWithFilters();
      },
      child: SizedBox(
        width: width,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSorted ? Colors.teal[700] : Colors.black87,
              ),
            ),
            if (isSorted)
              Icon(
                isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: Colors.teal[700],
              ),
          ],
        ),
      ),
    );
  }

  // Codigo 편집 컨트롤러 초기화
  void _initializeCodigoEditControllers() {
    if (_selectedCodigo == null) return;

    // 선택된 codigo의 모든 키를 사용 (id_codigo 제외)
    final fields = _selectedCodigo!.keys.where((key) => key != 'id_codigo').toList();

    for (var field in fields) {
      if (!_codigoEditControllers.containsKey(field)) {
        _codigoEditControllers[field] = TextEditingController();
      }
      
      final value = _selectedCodigo![field];
      _codigoEditControllers[field]!.text = value?.toString() ?? '';
    }
  }

  // Codigo 편집 패널 빌드
  Widget _buildCodigoEditPanel() {
    if (_selectedCodigo == null) return const SizedBox.shrink();

    return CodigosBuilder.buildEditPanel(
      selectedCodigo: _selectedCodigo!,
      editControllers: _codigoEditControllers,
      isLoading: _isLoading,
      onClose: () {
        setState(() {
          _selectedCodigo = null;
          _isEditingCodigo = false;
        });
      },
      onSave: _saveCodigoChanges,
      reportColor: _getReportColor(),
      buildEditField: (fieldKey, label) {
        if (!_codigoEditControllers.containsKey(fieldKey)) {
          _codigoEditControllers[fieldKey] = TextEditingController();
        }
        
        return CodigosBuilder.buildEditField(
          fieldKey: fieldKey,
          label: label,
          controller: _codigoEditControllers[fieldKey]!,
          onChanged: (value) {
            setState(() {
              _isEditingCodigo = true;
            });
          },
        );
      },
    );
  }

  // Codigo 편집 필드 빌드
  Widget _buildCodigoEditField(String fieldKey, String label) {
    if (!_codigoEditControllers.containsKey(fieldKey)) {
      _codigoEditControllers[fieldKey] = TextEditingController();
    }
    
    final controller = _codigoEditControllers[fieldKey]!;

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        enabled: true,
      ),
      keyboardType: (fieldKey.startsWith('pre') || 
                     fieldKey == 'borrado' || 
                     fieldKey.startsWith('id_')) 
          ? TextInputType.number 
          : TextInputType.text,
      onChanged: (value) {
        setState(() {
          _isEditingCodigo = true;
        });
      },
    );
  }

  // Codigo 변경사항 저장
  Future<void> _saveCodigoChanges() async {
    if (_selectedCodigo == null) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await CodigosBuilder.saveCodigoChanges(
        databaseService: _databaseService,
        selectedCodigo: _selectedCodigo!,
        editControllers: _codigoEditControllers,
      );

      // 서버 응답 확인
      if (response.containsKey('error')) {
        throw Exception(response['error'] ?? 'Error al actualizar codigo');
      }

      // 로컬 데이터 업데이트
      final dataList = _data!['data'] as List;
      final index = dataList.indexWhere((item) => 
          item is Map<String, dynamic> && 
          item['codigo'] == _selectedCodigo!['codigo']);
      
      if (index != -1) {
        // 편집된 값들 수집
        final updatedData = <String, dynamic>{};
        for (var entry in _codigoEditControllers.entries) {
          final key = entry.key;
          final value = entry.value.text.trim();
          
          if (key.startsWith('pre') || key == 'borrado' || key.startsWith('id_')) {
            final numValue = num.tryParse(value);
            if (numValue != null) {
              updatedData[key] = numValue;
            } else if (value.isEmpty) {
              updatedData[key] = null;
            } else {
              updatedData[key] = value;
            }
          } else {
            updatedData[key] = value.isEmpty ? null : value;
          }
        }


        dataList[index] = {...dataList[index] as Map<String, dynamic>, ...updatedData};
        _selectedCodigo = Map<String, dynamic>.from(dataList[index] as Map<String, dynamic>);
        _initializeCodigoEditControllers();
      }

      setState(() {
        _isLoading = false;
        _isEditingCodigo = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✓ Actualizado'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

}

