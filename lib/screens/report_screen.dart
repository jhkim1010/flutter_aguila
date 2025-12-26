import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/platform_utils.dart';
import '../widgets/report_utils.dart';
import '../widgets/items_date_range_selector.dart';
import '../widgets/report_table_builder.dart';
import '../widgets/codigos_builder.dart';
import '../widgets/stocks_builder.dart';
import '../widgets/gastos_builder.dart';
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
  final VoidCallback? onMenuPressed; // 메뉴 버튼 콜백 (useFullWidth가 true일 때 좁은 화면에서 사용)

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
    this.onMenuPressed,
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
  List<String>? _availableSucursales; // 사용 가능한 sucursal 목록
  
  // Items 보고서용 날짜 범위
  DateTime? _itemsStartDate;
  DateTime? _itemsEndDate;
  // Ventas 보고서용 날짜 범위
  DateTime? _ventasStartDate;
  DateTime? _ventasEndDate;
  // Ventas 보고서용 그룹화 단위 ('vcode', 'day', 'month', 'year')
  String _ventasUnit = 'vcode'; // 기본값: 개별 vcode
  bool _ventasDescontado = false; // Ventas 보고서용 descontado 필터
  bool _ventasReservado = false; // Ventas 보고서용 reservado 필터
  bool _ventasCredito = false; // Ventas 보고서용 credito 필터
  
  // Codigos 보고서용 상태
  Map<String, dynamic>? _selectedCodigo; // 선택된 codigo
  final Map<String, TextEditingController> _codigoEditControllers = {}; // 편집용 컨트롤러들
  final Map<String, FocusNode> _codigoFocusNodes = {}; // 편집용 포커스 노드들
  bool _isEditingCodigo = false; // 편집 모드 여부
  String? _editedCodigoIdentifier; // 편집된 codigo 식별자 (색상 표시용)
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
  
  // Tipos와 Temporadas 관련 상태
  List<Map<String, dynamic>> _tiposList = [];
  List<Map<String, dynamic>> _temporadasList = [];
  int? _selectedTipoId;
  int? _selectedTemporadaId;

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
    
    // Stocks, Items, Ingresos, Codigos, Todocodigos 보고서의 경우 tipos/temporadas 로드
    if (widget.reportType == ReportType.stocks || 
        widget.reportType == ReportType.items || 
        widget.reportType == ReportType.ingresos || 
        widget.reportType == ReportType.codigos || 
        widget.reportType == ReportType.todocodigos) {
      _loadTiposAndTemporadas();
    }
    
    // Items, Ingresos, Gastos 및 Alertas 보고서의 경우 기본 날짜 설정 (오늘 날짜 또는 초기값)
    if (widget.reportType == ReportType.items || widget.reportType == ReportType.ingresos || widget.reportType == ReportType.gastos || widget.reportType == ReportType.alertas) {
      if (widget.initialItemsStartDate != null && widget.initialItemsEndDate != null) {
        _itemsStartDate = widget.initialItemsStartDate;
        _itemsEndDate = widget.initialItemsEndDate;
        final reportName = widget.reportType == ReportType.items ? "Items" : (widget.reportType == ReportType.ingresos ? "Ingresos" : "Gastos");
        print('📅 $reportName 보고서 초기 날짜 범위 설정: ${DateFormat('yyyy-MM-dd').format(_itemsStartDate!)} ~ ${DateFormat('yyyy-MM-dd').format(_itemsEndDate!)}');
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
      
      // Items, Ingresos, Gastos 및 Alertas 보고서의 경우 기본 날짜 설정 (오늘 날짜 또는 초기값)
      if (widget.reportType == ReportType.items || widget.reportType == ReportType.ingresos || widget.reportType == ReportType.gastos || widget.reportType == ReportType.alertas) {
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
      if (!mounted) return;
      if (currentWord != _filteringWordController.text.trim()) return;
      if (currentWord == _lastFilteringWord) return;
      
      // 프레임 완료 후 상태 업데이트를 보장하여 mouse_tracker assertion 오류 방지
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _lastFilteringWord = currentWord;
        // 상태 변경 콜백 호출
        _notifyStateChanged();
        // codigos, todocodigos 또는 stocks 보고서인 경우에만 데이터 재로드
        if (widget.reportType == ReportType.codigos || 
            widget.reportType == ReportType.todocodigos || 
            widget.reportType == ReportType.stocks) {
          _reloadDataWithFilters();
        }
      });
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
    _databaseService.dispose(); // HTTP 클라이언트 연결 풀 정리
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

  /// 화면에 표시되는 모든 데이터를 수집 (필터링/정렬 적용)
  Map<String, dynamic> _getDisplayedData() {
    if (_data == null) {
      return {};
    }

    final data = Map<String, dynamic>.from(_data!);
    
    // 데이터 리스트가 있는 경우 필터링/정렬 적용
    if (data.containsKey('data') && data['data'] is List) {
      List<dynamic> dataList = List.from(data['data'] as List);
      
      // 필터링 적용
      if (widget.reportType == ReportType.items || 
          widget.reportType == ReportType.ingresos || 
          widget.reportType == ReportType.gastos ||
          widget.reportType == ReportType.alertas ||
          widget.reportType == ReportType.ventas) {
        final filteringWord = _filteringWordController.text.trim().toLowerCase();
        if (filteringWord.isNotEmpty) {
          dataList = dataList.where((item) {
            if (item is Map<String, dynamic>) {
              if (widget.reportType == ReportType.items) {
                final codigo1 = item['codigo1']?.toString().toLowerCase() ?? '';
                final desc1 = item['desc1']?.toString().toLowerCase() ?? '';
                return codigo1.contains(filteringWord) || desc1.contains(filteringWord);
              } else if (widget.reportType == ReportType.ingresos) {
                final codigo = item['codigo']?.toString().toLowerCase() ?? '';
                final descripcion = item['descripcion']?.toString().toLowerCase() ?? '';
                return codigo.contains(filteringWord) || descripcion.contains(filteringWord);
              } else if (widget.reportType == ReportType.gastos) {
                // gastos 필터링 로직 추가 (필요한 필드에 따라 수정 가능)
                final codigo = item['codigo']?.toString().toLowerCase() ?? '';
                final descripcion = item['descripcion']?.toString().toLowerCase() ?? '';
                final concepto = item['concepto']?.toString().toLowerCase() ?? '';
                return codigo.contains(filteringWord) || descripcion.contains(filteringWord) || concepto.contains(filteringWord);
              } else if (widget.reportType == ReportType.alertas) {
                // alertas 필터링 로직: evento 필드에서 검색
                final evento = item['evento']?.toString().toLowerCase() ?? '';
                return evento.contains(filteringWord);
              } else if (widget.reportType == ReportType.ventas) {
                if (item.containsKey('clientenombre')) {
                  final clientenombre = item['clientenombre']?.toString().toLowerCase() ?? '';
                  return clientenombre.contains(filteringWord);
                } else {
                  final fecha = item['fecha']?.toString().toLowerCase() ?? '';
                  final sucursal = item['sucursal']?.toString().toLowerCase() ?? '';
                  final nencargado = item['nencargado']?.toString().toLowerCase() ?? '';
                  return fecha.contains(filteringWord) || 
                         sucursal.contains(filteringWord) ||
                         nencargado.contains(filteringWord);
                }
              }
            }
            return false;
          }).toList();
        }
      }
      
      // 모든 보고서의 sucursal 필터 적용
      if (_selectedSucursal != null) {
        dataList = dataList.where((item) {
          if (item is Map<String, dynamic> && item.containsKey('sucursal')) {
            final sucursal = item['sucursal']?.toString();
            return sucursal == _selectedSucursal;
          }
          return false;
        }).toList();
      }
      
      // Codigos 및 Todo Codigos 보고서의 필터링
      if (widget.reportType == ReportType.codigos || widget.reportType == ReportType.todocodigos) {
        final filteringWord = _filteringWordController.text.trim().toLowerCase();
        if (filteringWord.isNotEmpty) {
          dataList = dataList.where((item) {
            if (item is Map<String, dynamic>) {
              final codigo = item['codigo']?.toString().toLowerCase() ?? '';
              final descripcion = item['descripcion']?.toString().toLowerCase() ?? '';
              return codigo.contains(filteringWord) || descripcion.contains(filteringWord);
            }
            return false;
          }).toList();
        }
      }
      
      // Items, Ingresos, Gastos 및 Alertas 보고서의 정렬 적용
      if (widget.reportType == ReportType.items || widget.reportType == ReportType.ingresos || widget.reportType == ReportType.gastos || widget.reportType == ReportType.alertas) {
        if (_sortColumn != null) {
          dataList.sort((a, b) {
            if (a is! Map<String, dynamic> || b is! Map<String, dynamic>) {
              return 0;
            }
            
            final aValue = a[_sortColumn];
            final bValue = b[_sortColumn];
            
            if (aValue == null && bValue == null) return 0;
            if (aValue == null) return _sortAscending ? -1 : 1;
            if (bValue == null) return _sortAscending ? 1 : -1;
            
            final aNum = ReportUtils.isNumeric(aValue) ? num.tryParse(aValue.toString().replaceAll(',', '')) : null;
            final bNum = ReportUtils.isNumeric(bValue) ? num.tryParse(bValue.toString().replaceAll(',', '')) : null;
            
            if (aNum != null && bNum != null) {
              final comparison = aNum.compareTo(bNum);
              return _sortAscending ? comparison : -comparison;
            }
            
            final aStr = aValue.toString().toLowerCase();
            final bStr = bValue.toString().toLowerCase();
            final comparison = aStr.compareTo(bStr);
            return _sortAscending ? comparison : -comparison;
          });
        }
      }
      
      // 필터링/정렬된 데이터로 업데이트
      data['data'] = dataList;
    }
    
    // Gastos 보고서의 경우 data.detail에 필터링 적용
    if (widget.reportType == ReportType.gastos && 
        data.containsKey('data') && 
        data['data'] is Map &&
        (data['data'] as Map).containsKey('detail')) {
      final dataMap = data['data'] as Map<String, dynamic>;
      if (dataMap['detail'] is List) {
        List<dynamic> detailList = List.from(dataMap['detail'] as List);
        
        // sucursal 필터 적용
        if (_selectedSucursal != null) {
          detailList = detailList.where((item) {
            if (item is Map<String, dynamic> && item.containsKey('sucursal')) {
              final sucursal = item['sucursal']?.toString();
              return sucursal == _selectedSucursal;
            }
            return false;
          }).toList();
        }
        
        // 필터링된 detail로 업데이트
        dataMap['detail'] = detailList;
        data['data'] = dataMap;
      }
    }
    
    return data;
  }

  /// PDF로 변환하여 공유
  Future<void> _shareAsPdf() async {
    if (_data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay datos para compartir'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generando PDF...'),
                ],
              ),
            ),
          ),
        ),
      );

      // 날짜 범위 가져오기
      DateTime? startDate;
      DateTime? endDate;
      
      if (widget.reportType == ReportType.items || widget.reportType == ReportType.ingresos || widget.reportType == ReportType.gastos || widget.reportType == ReportType.alertas) {
        startDate = _itemsStartDate;
        endDate = _itemsEndDate;
      } else if (widget.reportType == ReportType.ventas) {
        startDate = _ventasStartDate;
        endDate = _ventasEndDate;
      }

      // 필터링 단어 가져오기
      final filteringWord = _filteringWordController.text.trim();
      final filterWord = filteringWord.isEmpty ? null : filteringWord;

      // 화면에 표시되는 모든 데이터 수집 (필터링/정렬 적용)
      final displayedData = _getDisplayedData();
      
      // 화면에 표시되는 컬럼 목록 가져오기
      List<String>? displayedColumns;
      if (displayedData.containsKey('data') && displayedData['data'] is List) {
        final dataList = displayedData['data'] as List;
        if (dataList.isNotEmpty) {
          displayedColumns = ReportTableBuilder.getDisplayedColumns(
            dataList,
            widget.reportType,
            unit: widget.reportType == ReportType.ventas ? _ventasUnit : null,
          );
          print('📋 PDF용 표시 컬럼: $displayedColumns');
        }
      }

      // PDF 생성
      final pdfFile = await PdfService.generateReportPdf(
        reportType: widget.reportType,
        data: displayedData,
        startDate: startDate,
        endDate: endDate,
        filteringWord: filterWord,
        displayedColumns: displayedColumns,
      );

      // 로딩 다이얼로그 닫기
      if (mounted) {
        Navigator.of(context).pop();
      }

      // 파일 존재 확인
      if (!await pdfFile.exists()) {
        throw Exception('PDF 파일이 생성되지 않았습니다: ${pdfFile.path}');
      }

      print('📄 PDF 파일 생성 완료: ${pdfFile.path}');
      print('📄 파일 크기: ${await pdfFile.length()} bytes');

      // PDF 미리보기 및 공유 다이얼로그 표시
      if (mounted) {
        await _showPdfPreviewDialog(pdfFile);
      }
    } catch (e, stackTrace) {
      // 로딩 다이얼로그 닫기
      if (mounted) {
        Navigator.of(context).pop();
      }

      // 상세한 에러 로깅
      print('❌ PDF 생성/공유 오류: $e');
      print('❌ Stack trace: $stackTrace');

      // 에러 메시지
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar/compartir PDF: $e'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// PDF 미리보기 및 공유 다이얼로그 표시
  Future<void> _showPdfPreviewDialog(File pdfFile) async {
    final reportTitle = ReportUtils.getReportTitle(widget.reportType);
    final fileName = pdfFile.path.split('/').last;
    final fileSize = await pdfFile.length();
    final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.picture_as_pdf, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'PDF 생성 완료',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '보고서: $reportTitle',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              '파일명: $fileName',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              '파일 크기: $fileSizeMB MB',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'PDF를 먼저 확인한 후 공유할 수 있습니다.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              await _openPdfFile(pdfFile);
            },
            icon: const Icon(Icons.preview, size: 20),
            label: const Text('PDF 보기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              await _sharePdfFile(pdfFile);
            },
            icon: const Icon(Icons.share, size: 20),
            label: const Text('공유'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// PDF 파일을 시스템 기본 뷰어로 열기
  Future<void> _openPdfFile(File pdfFile) async {
    try {
      if (Platform.isMacOS) {
        // macOS: Preview 앱으로 열기
        final result = await Process.run(
          'open',
          [pdfFile.path],
        );
        if (result.exitCode == 0) {
          print('✅ PDF 파일 열기 성공: ${pdfFile.path}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PDF가 열렸습니다'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('PDF 열기 실패: ${result.stderr}');
        }
      } else if (Platform.isWindows) {
        // Windows: 기본 PDF 뷰어로 열기
        await Process.run('start', [pdfFile.path], runInShell: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF가 열렸습니다'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (Platform.isLinux) {
        // Linux: xdg-open 사용
        await Process.run('xdg-open', [pdfFile.path]);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF가 열렸습니다'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ PDF 파일 열기 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF 열기 실패: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// PDF 파일 공유
  Future<void> _sharePdfFile(File pdfFile) async {
    try {
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: 'Reporte ${ReportUtils.getReportTitle(widget.reportType)}',
      );
      print('✅ PDF 공유 성공');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF 공유 완료'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (shareError) {
      print('❌ PDF 공유 실패: $shareError');
      
      // macOS에서 공유가 실패하면 데스크톱에 복사하고 Finder에서 열기
      if (Platform.isMacOS && mounted) {
        try {
          final homeDir = Platform.environment['HOME'] ?? '';
          final desktopPath = '$homeDir/Desktop';
          final desktopDir = Directory(desktopPath);
          
          if (await desktopDir.exists()) {
            final fileName = pdfFile.path.split('/').last;
            final desktopFile = File('$desktopPath/$fileName');
            
            await pdfFile.copy(desktopFile.path);
            print('✅ PDF 파일을 데스크톱에 복사: ${desktopFile.path}');
            
            final result = await Process.run(
              'open',
              ['-R', desktopFile.path],
            );
            
            if (result.exitCode == 0) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('PDF가 데스크톱에 저장되었습니다: $fileName'),
                    duration: const Duration(seconds: 4),
                    backgroundColor: Colors.green,
                  ),
                );
              }
              return;
            }
          }
        } catch (copyError) {
          print('❌ 데스크톱 복사 실패: $copyError');
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF 공유 실패: $shareError'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Tipos와 Temporadas 데이터 로드
  Future<void> _loadTiposAndTemporadas() async {
    try {
      final tipos = await _databaseService.getTipos();
      final temporadas = await _databaseService.getTemporadas();
      // 로그는 database_service에서 출력됨
      
      // 디버깅: 실제 데이터 구조 확인
      if (tipos.isNotEmpty) {
        print('🔍 Tipos 데이터 구조 확인:');
        print('   첫 번째 tipo 키: ${tipos.first.keys.toList()}');
        print('   첫 번째 tipo 값: ${tipos.first}');
      }
      if (temporadas.isNotEmpty) {
        print('🔍 Temporadas 데이터 구조 확인:');
        print('   첫 번째 temporada 키: ${temporadas.first.keys.toList()}');
        print('   첫 번째 temporada 값: ${temporadas.first}');
      }
      
      if (mounted) {
        setState(() {
          _tiposList = tipos;
          _temporadasList = temporadas;
          
          // 선택된 값이 새 리스트에 없으면 null로 초기화
          if (_selectedTipoId != null) {
            final tipoIds = tipos.map((tipo) {
              final id = tipo['id_tipo'] is int 
                  ? tipo['id_tipo'] 
                  : (tipo['id_tipo'] != null ? int.tryParse(tipo['id_tipo'].toString()) : null) ??
                    (tipo['id'] is int ? tipo['id'] : (tipo['id'] != null ? int.tryParse(tipo['id'].toString()) : null));
              return id;
            }).where((id) => id != null).cast<int>().toList();
            if (!tipoIds.contains(_selectedTipoId)) {
              _selectedTipoId = null;
            }
          }
          
          if (_selectedTemporadaId != null) {
            final temporadaIds = temporadas.map((temporada) {
              final id = temporada['id_temporada'] is int 
                  ? temporada['id_temporada'] 
                  : (temporada['id_temporada'] != null ? int.tryParse(temporada['id_temporada'].toString()) : null) ??
                    (temporada['id'] is int ? temporada['id'] : (temporada['id'] != null ? int.tryParse(temporada['id'].toString()) : null));
              return id;
            }).where((id) => id != null).cast<int>().toList();
            if (!temporadaIds.contains(_selectedTemporadaId)) {
              _selectedTemporadaId = null;
            }
          }
        });
      }
    } catch (e) {
      print('⚠️ Tipos/Temporadas 로드 실패: $e');
    }
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
          final filters = <String, dynamic>{};
          if (_selectedTipoId != null) {
            filters['tipo_id'] = _selectedTipoId;
          }
          if (_selectedTemporadaId != null) {
            filters['temporada_id'] = _selectedTemporadaId;
          }
          data = await _databaseService.getStocksReport(
            filteringWord: currentFilteringWord.isNotEmpty ? currentFilteringWord : null,
            sortColumn: _stocksSortColumn,
            sortAscending: _stocksSortAscending,
            filters: filters.isNotEmpty ? filters : null,
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
          if (_selectedTipoId != null) {
            filters['tipo_id'] = _selectedTipoId;
          }
          if (_selectedTemporadaId != null) {
            filters['temporada_id'] = _selectedTemporadaId;
          }
          data = await _databaseService.getItemsReport(
            filteringWord: currentFilteringWord.isNotEmpty ? currentFilteringWord : null,
            filters: filters,
          );
          break;
        case ReportType.clientes:
          data = await _databaseService.getClientesReport();
          break;
        case ReportType.gastos:
          // gastos 보고서는 날짜 범위 필터 사용 (기본값: 오늘부터 오늘까지)
          final now = DateTime.now();
          final startDate = _itemsStartDate ?? now;
          final endDate = _itemsEndDate ?? now;
          final currentFilteringWord = filteringWord ?? _filteringWordController.text.trim();
          
          final filters = <String, dynamic>{
            'fecha_inicio': DateFormat('yyyy-MM-dd').format(startDate),
            'fecha_fin': DateFormat('yyyy-MM-dd').format(endDate),
          };
          data = await _databaseService.getGastosReport(
            filteringWord: currentFilteringWord.isNotEmpty ? currentFilteringWord : null,
            filters: filters,
          );
          break;
        case ReportType.ventas:
          debugPrint('   → ReportType.ventas 케이스 실행');
          debugPrint('      - 현재 _ventasUnit: $_ventasUnit');
          
          // current_date 사용 (기본값: 오늘)
          final now = DateTime.now();
          var startDate = _ventasStartDate ?? now;
          var endDate = _ventasEndDate ?? now;
          final currentFilteringWord = filteringWord ?? _filteringWordController.text.trim();
          
          debugPrint('      - 초기 날짜 범위: startDate=$startDate, endDate=$endDate');
          debugPrint('      - 필터링 단어: $currentFilteringWord');
          
          // month unit일 때 날짜 범위를 정확히 설정
          if (_ventasUnit == 'month') {
            debugPrint('      - month unit 감지: 날짜 범위를 월 단위로 조정');
            // 시작 날짜: 해당 월의 1일
            startDate = DateTime(startDate.year, startDate.month, 1);
            // 종료 날짜: 해당 월의 마지막 날 (다음 달의 0일 = 이번 달의 마지막 날)
            endDate = DateTime(endDate.year, endDate.month + 1, 0);
            debugPrint('      - 조정된 날짜 범위: startDate=$startDate, endDate=$endDate');
          }
          // year unit일 때 날짜 범위를 정확히 설정
          else if (_ventasUnit == 'year') {
            debugPrint('      - year unit 감지: 날짜 범위를 연 단위로 조정');
            // 시작 날짜: 해당 연도의 1월 1일
            startDate = DateTime(startDate.year, 1, 1);
            // 종료 날짜: 해당 연도의 12월 31일
            endDate = DateTime(endDate.year, 12, 31);
            debugPrint('      - 조정된 날짜 범위: startDate=$startDate, endDate=$endDate');
          } else {
            debugPrint('      - vcode/day unit: 날짜 범위 유지');
          }
          
          // current_date는 startDate를 사용 (또는 endDate, 사용자 요구사항에 따라)
          final currentDate = DateFormat('yyyy-MM-dd').format(startDate);
          
          final filters = <String, dynamic>{
            'fecha_inicio': DateFormat('yyyy-MM-dd').format(startDate),
            'fecha_fin': DateFormat('yyyy-MM-dd').format(endDate),
          };
          
          // 체크박스 필터 추가
          if (_ventasDescontado) {
            filters['descontado'] = '1';
          }
          if (_ventasReservado) {
            filters['reservado'] = '1';
          }
          if (_ventasCredito) {
            filters['credito'] = '1';
          }
          
          debugPrint('      - API 요청 파라미터:');
          debugPrint('         * currentDate: $currentDate');
          debugPrint('         * fecha_inicio: ${filters['fecha_inicio']}');
          debugPrint('         * fecha_fin: ${filters['fecha_fin']}');
          debugPrint('         * filteringWord: $currentFilteringWord');
          debugPrint('         * unit: $_ventasUnit');
          debugPrint('         * descontado: $_ventasDescontado');
          debugPrint('         * reservado: $_ventasReservado');
          debugPrint('         * credito: $_ventasCredito');
          
          debugPrint('      → getVentasReport API 호출 시작');
          data = await _databaseService.getVentasReport(
            filteringWord: currentFilteringWord.isNotEmpty ? currentFilteringWord : null,
            currentDate: currentDate,
            unit: _ventasUnit,
            filters: filters,
          );
          debugPrint('      → getVentasReport API 호출 완료');
          debugPrint('      - 응답 데이터 타입: ${data.runtimeType}');
          debugPrint('      - 응답 데이터 키: ${data.keys.toList()}');
          if (data.containsKey('data') && data['data'] is List) {
            final dataList = data['data'] as List;
            debugPrint('      - 응답 데이터 개수: ${dataList.length}');
          }
          break;
        case ReportType.fventas:
          // current_date 사용 (기본값: 오늘)
          final now = DateTime.now();
          var startDate = _ventasStartDate ?? now;
          var endDate = _ventasEndDate ?? now;
          final currentFilteringWord = filteringWord ?? _filteringWordController.text.trim();
          
          // month unit일 때 날짜 범위를 정확히 설정
          if (_ventasUnit == 'month') {
            // 시작 날짜: 해당 월의 1일
            startDate = DateTime(startDate.year, startDate.month, 1);
            // 종료 날짜: 해당 월의 마지막 날 (다음 달의 0일 = 이번 달의 마지막 날)
            endDate = DateTime(endDate.year, endDate.month + 1, 0);
          }
          // year unit일 때 날짜 범위를 정확히 설정
          else if (_ventasUnit == 'year') {
            // 시작 날짜: 시작 연도의 1월 1일
            final startYear = startDate.year;
            startDate = DateTime(startYear, 1, 1);
            // 종료 날짜: 종료 연도의 12월 31일
            final endYear = endDate.year;
            endDate = DateTime(endYear, 12, 31);
            // 연도 범위가 여러 연도에 걸쳐 있으면, 각 연도별로 1월 1일~12월 31일 범위를 보장
            // (서버가 unit=year일 때 자동으로 연도별 그룹화하므로, fecha_inicio와 fecha_fin만 정확히 설정하면 됨)
          }
          
          // current_date는 startDate를 사용 (또는 endDate, 사용자 요구사항에 따라)
          final currentDate = DateFormat('yyyy-MM-dd').format(startDate);
          
          final filters = <String, dynamic>{
            'fecha_inicio': DateFormat('yyyy-MM-dd').format(startDate),
            'fecha_fin': DateFormat('yyyy-MM-dd').format(endDate),
          };
          print('📅 FVentas 보고서 요청 - current_date: $currentDate, 날짜 필터: ${filters['fecha_inicio']} ~ ${filters['fecha_fin']}, filteringWord: $currentFilteringWord, unit: $_ventasUnit');
          data = await _databaseService.getFVentasReport(
            filteringWord: currentFilteringWord.isNotEmpty ? currentFilteringWord : null,
            currentDate: currentDate,
            unit: _ventasUnit,
            filters: filters,
          );
          break;
        case ReportType.alertas:
          // alertas 보고서는 날짜 범위 필터 사용 (기본값: 오늘부터 오늘까지)
          final now = DateTime.now();
          final startDate = _itemsStartDate ?? now;
          final endDate = _itemsEndDate ?? now;
          final currentFilteringWord = filteringWord ?? _filteringWordController.text.trim();
          
          final filters = <String, dynamic>{
            'fecha_inicio': DateFormat('yyyy-MM-dd').format(startDate),
            'fecha_fin': DateFormat('yyyy-MM-dd').format(endDate),
          };
          data = await _databaseService.getAlertasReport(
            filteringWord: currentFilteringWord.isNotEmpty ? currentFilteringWord : null,
            filters: filters,
          );
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
          if (_selectedTipoId != null) {
            filters['tipo_id'] = _selectedTipoId;
          }
          if (_selectedTemporadaId != null) {
            filters['temporada_id'] = _selectedTemporadaId;
          }
          data = await _databaseService.getIngresosReport(
            filteringWord: currentFilteringWord.isNotEmpty ? currentFilteringWord : null,
            filters: filters,
          );
          break;
        case ReportType.codigos:
          // 첫 페이지만 먼저 받아서 표시
          final currentFilteringWord = filteringWord ?? _filteringWordController.text.trim();
          print('🔍 Codigos 요청 - filteringWord: "$currentFilteringWord"');
          final filters = <String, dynamic>{};
          if (_selectedTipoId != null) {
            filters['tipo_id'] = _selectedTipoId;
          }
          if (_selectedTemporadaId != null) {
            filters['temporada_id'] = _selectedTemporadaId;
          }
          data = await _databaseService.getCodigos(
            filteringWord: currentFilteringWord.isNotEmpty ? currentFilteringWord : null,
            sortColumn: _codigosSortColumn,
            sortAscending: _codigosSortAscending,
            filters: filters.isNotEmpty ? filters : null,
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
          final filters = <String, dynamic>{};
          if (_selectedTipoId != null) {
            filters['tipo_id'] = _selectedTipoId;
          }
          if (_selectedTemporadaId != null) {
            filters['temporada_id'] = _selectedTemporadaId;
          }
          data = await _databaseService.getTodocodigos(
            filteringWord: currentFilteringWord.isNotEmpty ? currentFilteringWord : null,
            sortColumn: _codigosSortColumn,
            sortAscending: _codigosSortAscending,
            filters: filters.isNotEmpty ? filters : null,
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

      // 데이터에서 sucursal 목록 추출
      List<String>? sucursales;
      if (data.containsKey('data')) {
        if (data['data'] is List) {
          final dataList = data['data'] as List;
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
        } else if (data['data'] is Map) {
          // gastos 보고서처럼 data가 Map인 경우
          final dataMap = data['data'] as Map<String, dynamic>;
          if (dataMap.containsKey('detail') && dataMap['detail'] is List) {
            final detailList = dataMap['detail'] as List;
            final sucursalSet = <String>{};
            for (var item in detailList) {
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
        }
      }

      debugPrint('   → 데이터 로딩 완료');
      debugPrint('   - 데이터 타입: ${data.runtimeType}');
      debugPrint('   - 데이터 키: ${data.keys.toList()}');
      if (data.containsKey('data') && data['data'] is List) {
        final dataList = data['data'] as List;
        debugPrint('   - 응답 데이터 개수: ${dataList.length}');
      }
      debugPrint('   - 사용 가능한 sucursales: $sucursales');

      setState(() {
        _data = data;
        _isLoading = false;
        _availableSucursales = sucursales;
        // sucursal이 1개 이하이면 필터 초기화
        if (sucursales == null || sucursales.length <= 1) {
          _selectedSucursal = null;
        }
        // 데이터가 로드되면 처음 100개만 표시
        if (data.containsKey('data')) {
          if (data['data'] is List) {
            final dataList = data['data'] as List;
            _displayedItemsCount = dataList.length > _itemsPerPage ? _itemsPerPage : dataList.length;
          } else if (data['data'] is Map) {
            final dataMap = data['data'] as Map<String, dynamic>;
            if (dataMap.containsKey('detail') && dataMap['detail'] is List) {
              final detailList = dataMap['detail'] as List;
              _displayedItemsCount = detailList.length > _itemsPerPage ? _itemsPerPage : detailList.length;
            } else {
              _displayedItemsCount = 100;
            }
          } else {
            _displayedItemsCount = 100;
          }
        } else {
          _displayedItemsCount = 100;
        }
        debugPrint('   → setState: _data 업데이트, _isLoading=false, _displayedItemsCount=$_displayedItemsCount');
      });
      
      debugPrint('📊 _loadData() 완료');
      debugPrint('═══════════════════════════════════════════════════════');
    } catch (e) {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('❌ _loadData() 오류 발생');
      debugPrint('   - 오류 타입: ${e.runtimeType}');
      debugPrint('   - 오류 메시지: $e');
      debugPrint('   - 스택 트레이스: ${StackTrace.current}');
      
        String errorMessage = 'Ocurrió un error desconocido.';
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = e.toString();
      }
      debugPrint('   - 처리된 오류 메시지: $errorMessage');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = errorMessage;
          debugPrint('   → setState: _isLoading=false, _errorMessage=$errorMessage');
        });
      }
      debugPrint('❌ _loadData() 오류 처리 완료');
      debugPrint('═══════════════════════════════════════════════════════');
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth >= 800;
        final orientation = MediaQuery.of(context).orientation;
        final isMobilePortrait = !isLargeScreen && orientation == Orientation.portrait;
        final platformType = PlatformUtils.getPlatformType(context);
        final isMobile = platformType == PlatformType.mobile;
        
        // 핸드폰의 경우: 넓은 화면(가로 모드)이면 1줄, 좁은 화면(세로 모드)이면 2줄
        // 데스크톱/태블릿의 경우: 기존 로직 유지
        final needsTwoLineAppBar = isMobile
            ? isMobilePortrait && (
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

    // useFullWidth가 true이면 Scaffold를 반환하지 않고 AppBar와 body를 포함한 위젯 반환
    if (widget.useFullWidth) {
      final appBar = _buildAppBar(context, reportTitle, reportIcon, reportColor, isLargeScreen, isMobilePortrait, needsTwoLineAppBar);
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

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
            toolbarHeight: needsTwoLineAppBar ? kToolbarHeight * 2 : null,
        title: widget.reportType == ReportType.stocks
            ? LayoutBuilder(
                builder: (context, constraints) {
                  final isLargeScreen = constraints.maxWidth >= 800;
                  final orientation = MediaQuery.of(context).orientation;
                  final platformType = PlatformUtils.getPlatformType(context);
                  final isMobile = platformType == PlatformType.mobile;
                  // 핸드폰의 경우: 세로 모드일 때만 2줄, 가로 모드일 때는 1줄
                  final isMobilePortrait = isMobile && !isLargeScreen && orientation == Orientation.portrait;
                  
                  // 핸드폰 세로 모드: 2줄로 배치
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
                        // 두 번째 줄: Tipo, Temporada 콤보박스, 필터링 단어 필드
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
                      Expanded(
                        child: _buildFilteringWordFieldInAppBar(),
                      ),
                    ],
                  );
                },
              )
            : (widget.reportType == ReportType.items || widget.reportType == ReportType.ingresos || widget.reportType == ReportType.gastos || widget.reportType == ReportType.alertas || widget.reportType == ReportType.fventas)
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      final isLargeScreen = constraints.maxWidth >= 800;
                      final orientation = MediaQuery.of(context).orientation;
                      final isMobilePortrait = !isLargeScreen && orientation == Orientation.portrait;
                      
                      // 좁은 화면: 2줄로 배치
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
                            // 두 번째 줄: 날짜 선택기, Sucursal 선택기, 필터링 단어 필드
                            Row(
                              children: [
                                Flexible(
                              child: ItemsDateRangeSelector(
                                reportType: widget.reportType,
                                    startDate: widget.reportType == ReportType.fventas ? _ventasStartDate : _itemsStartDate,
                                    endDate: widget.reportType == ReportType.fventas ? _ventasEndDate : _itemsEndDate,
                                onDateRangeChanged: (startDate, endDate) {
                                  setState(() {
                                        if (widget.reportType == ReportType.fventas) {
                                          _ventasStartDate = startDate;
                                          _ventasEndDate = endDate;
                                        } else {
                                    _itemsStartDate = startDate;
                                    _itemsEndDate = endDate;
                                        }
                                  });
                                      if (widget.onItemsDateRangeChanged != null && widget.reportType != ReportType.fventas) {
                                    widget.onItemsDateRangeChanged!(startDate, endDate);
                                  }
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
                          // 지점 선택 UI (큰 화면에서만, sucursal이 1개 이상일 때만 표시)
                          if (isLargeScreen && _availableSucursales != null && _availableSucursales!.length > 1) ...[
                              _buildSucursalSelector(),
                              const SizedBox(width: 16),
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
                          final isLargeScreen = constraints.maxWidth >= 800;
                          final orientation = MediaQuery.of(context).orientation;
                          final platformType = PlatformUtils.getPlatformType(context);
                          final isMobile = platformType == PlatformType.mobile;
                          // 핸드폰의 경우: 세로 모드일 때만 2줄, 가로 모드일 때는 1줄
                          final isMobilePortrait = isMobile && !isLargeScreen && orientation == Orientation.portrait;
                          
                          // 핸드폰 세로 모드: 2줄로 배치
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
                                          fillColor: MaterialStateProperty.resolveWith<Color>(
                                            (Set<MaterialState> states) {
                                              if (states.contains(MaterialState.selected)) {
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
                                          fillColor: MaterialStateProperty.resolveWith<Color>(
                                            (Set<MaterialState> states) {
                                              if (states.contains(MaterialState.selected)) {
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
                                          fillColor: MaterialStateProperty.resolveWith<Color>(
                                            (Set<MaterialState> states) {
                                              if (states.contains(MaterialState.selected)) {
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
                          
                          // 넓은 화면: 1줄로 배치
                          return Row(
                        children: [
                          Icon(reportIcon, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            reportTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                              const SizedBox(width: 16),
                              // Unit 버튼들
                              _buildVentasUnitButtonsInAppBar(),
                              const SizedBox(width: 16),
                              // 큰 화면 또는 수평 모드: 시작일과 종료일 선택기 2개
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: isLargeScreen ? 150 : 90,
                                    child: _buildSingleDateButton(
                                      label: 'Desde',
                                      date: _ventasStartDate,
                                      reportColor: _getReportColor(),
                                      unit: _ventasUnit,
                                  onDateSelected: (date) {
                                    setState(() {
                                      _ventasStartDate = date;
                                      // month unit일 때만 종료일 자동 조정 (year는 사용자가 직접 선택)
                                      if (_ventasUnit == 'month') {
                                        _ventasEndDate = DateTime(date.year, date.month + 1, 0);
                                      }
                                    });
                                    _loadData();
                                  },
                                    ),
                                  ),
                                ],
                              ),
                              // 큰 화면: 달력 간격을 unit 버튼 간격과 비슷하게 (4px)
                              const SizedBox(width: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: isLargeScreen ? 150 : 90,
                                    child: _buildSingleDateButton(
                                      label: 'Hasta',
                                      date: _ventasEndDate,
                                      reportColor: _getReportColor(),
                                      unit: _ventasUnit,
                                  onDateSelected: (date) {
                                    setState(() {
                                      _ventasEndDate = date;
                                      // month unit일 때만 시작일 자동 조정 (year는 사용자가 직접 선택)
                                      if (_ventasUnit == 'month') {
                                        _ventasStartDate = DateTime(date.year, date.month, 1);
                                      }
                                    });
                                    _loadData();
                                  },
                                    ),
                                  ),
                                ],
                              ),
                              // 큰 화면: descontado, reservado, credito 체크박스 추가
                              if (isLargeScreen) ...[
                                const SizedBox(width: 4),
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
                                      fillColor: MaterialStateProperty.resolveWith<Color>(
                                        (Set<MaterialState> states) {
                                          if (states.contains(MaterialState.selected)) {
                                            return Colors.white.withOpacity(0.3);
                                          }
                                          return Colors.transparent;
                                        },
                                      ),
                                      side: const BorderSide(color: Colors.white, width: 1.5),
                                    ),
                                    const SizedBox(width: 4),
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
                                      fillColor: MaterialStateProperty.resolveWith<Color>(
                                        (Set<MaterialState> states) {
                                          if (states.contains(MaterialState.selected)) {
                                            return Colors.white.withOpacity(0.3);
                                          }
                                          return Colors.transparent;
                                        },
                                      ),
                                      side: const BorderSide(color: Colors.white, width: 1.5),
                                    ),
                                    const SizedBox(width: 4),
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
                                      fillColor: MaterialStateProperty.resolveWith<Color>(
                                        (Set<MaterialState> states) {
                                          if (states.contains(MaterialState.selected)) {
                                            return Colors.white.withOpacity(0.3);
                                          }
                                          return Colors.transparent;
                                        },
                                      ),
                                      side: const BorderSide(color: Colors.white, width: 1.5),
                                    ),
                                    const SizedBox(width: 4),
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
                              ],
                              const SizedBox(width: 16),
                              // 지점 선택 UI (큰 화면에서만, sucursal이 1개 이상일 때만 표시)
                              if (isLargeScreen && _availableSucursales != null && _availableSucursales!.length > 1) ...[
                                _buildSucursalSelector(),
                                const SizedBox(width: 16),
                              ],
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
                              final isLargeScreen = constraints.maxWidth >= 800;
                              final orientation = MediaQuery.of(context).orientation;
                              final platformType = PlatformUtils.getPlatformType(context);
                              final isMobile = platformType == PlatformType.mobile;
                              // 핸드폰의 경우: 세로 모드일 때만 2줄, 가로 모드일 때는 1줄
                              final isMobilePortrait = isMobile && !isLargeScreen && orientation == Orientation.portrait;
                              
                              // 핸드폰 세로 모드: 2줄로 배치
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
                                    // 두 번째 줄: Tipo, Temporada 콤보박스, 필터링 단어 필드
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
        actions: [
          // 보고서 선택 드롭다운 메뉴
          PopupMenuButton<ReportType>(
            icon: const Icon(Icons.assessment, color: Colors.white),
            tooltip: 'Reportes',
            onSelected: (ReportType reportType) {
              if (reportType != widget.reportType) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportScreen(
                      serverUrl: widget.serverUrl,
                      reportType: reportType,
                      initialDate: widget.initialDate,
                      initialItemsStartDate: widget.initialItemsStartDate,
                      initialItemsEndDate: widget.initialItemsEndDate,
                      initialFilteringWord: widget.initialFilteringWord,
                      initialSortColumn: widget.initialSortColumn,
                      initialSortAscending: widget.initialSortAscending,
                      onStateChanged: widget.onStateChanged,
                      onItemsDateRangeChanged: widget.onItemsDateRangeChanged,
                      useFullWidth: widget.useFullWidth,
                    ),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => _buildReportMenuItems(),
          ),
          // PDF 공유 버튼
          if (_data != null)
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              tooltip: 'Compartir como PDF',
              onPressed: () => _shareAsPdf(),
            ),
        ],
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
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final isLargeScreen = constraints.maxWidth >= 800;
                              return Column(
                                children: [
                                  // 작은 화면에서만 날짜 범위 선택 UI 표시 (큰 화면은 AppBar에 있음)
                                  if (!isLargeScreen && (widget.reportType == ReportType.items || widget.reportType == ReportType.ingresos || widget.reportType == ReportType.gastos || widget.reportType == ReportType.alertas))
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
  ) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: needsTwoLineAppBar ? kToolbarHeight * 2 : null,
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
                final isLargeScreen = constraints.maxWidth >= 800;
                final orientation = MediaQuery.of(context).orientation;
                final platformType = PlatformUtils.getPlatformType(context);
                final isMobile = platformType == PlatformType.mobile;
                // 핸드폰의 경우: 세로 모드일 때만 2줄, 가로 모드일 때는 1줄
                final isMobilePortrait = isMobile && !isLargeScreen && orientation == Orientation.portrait;
                
                // 핸드폰 세로 모드: 2줄로 배치
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
                      // 두 번째 줄: Tipo, Temporada 콤보박스, 필터링 단어 필드
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
                    Expanded(
                      child: _buildFilteringWordFieldInAppBar(),
                    ),
                  ],
                );
              },
            )
          : (widget.reportType == ReportType.items || widget.reportType == ReportType.ingresos || widget.reportType == ReportType.gastos || widget.reportType == ReportType.alertas || widget.reportType == ReportType.fventas)
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    final isLargeScreen = constraints.maxWidth >= 800;
                    final orientation = MediaQuery.of(context).orientation;
                    final platformType = PlatformUtils.getPlatformType(context);
                    final isMobile = platformType == PlatformType.mobile;
                    // 핸드폰의 경우: 세로 모드일 때만 2줄, 가로 모드일 때는 1줄
                    final isMobilePortrait = isMobile && !isLargeScreen && orientation == Orientation.portrait;
                    
                    // 핸드폰 세로 모드: 2줄로 배치
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
                          // 두 번째 줄: 날짜 선택기, Sucursal 선택기, 필터링 단어 필드
                          Row(
                            children: [
                              Flexible(
                                child: ItemsDateRangeSelector(
                                  reportType: widget.reportType,
                                  startDate: widget.reportType == ReportType.fventas ? _ventasStartDate : _itemsStartDate,
                                  endDate: widget.reportType == ReportType.fventas ? _ventasEndDate : _itemsEndDate,
                                  onDateRangeChanged: (startDate, endDate) {
                                    setState(() {
                                      if (widget.reportType == ReportType.fventas) {
                                        _ventasStartDate = startDate;
                                        _ventasEndDate = endDate;
                                      } else {
                                        _itemsStartDate = startDate;
                                        _itemsEndDate = endDate;
                                      }
                                    });
                                    if (widget.onItemsDateRangeChanged != null && widget.reportType != ReportType.fventas) {
                                      widget.onItemsDateRangeChanged!(startDate, endDate);
                                    }
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
                        // 지점 선택 UI (큰 화면에서만, sucursal이 1개 이상일 때만 표시)
                        if (isLargeScreen && _availableSucursales != null && _availableSucursales!.length > 1) ...[
                          _buildSucursalSelector(),
                          const SizedBox(width: 16),
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
                        final isLargeScreen = constraints.maxWidth >= 800;
                        final orientation = MediaQuery.of(context).orientation;
                        final platformType = PlatformUtils.getPlatformType(context);
                        final isMobile = platformType == PlatformType.mobile;
                        // 핸드폰의 경우: 세로 모드일 때만 2줄, 가로 모드일 때는 1줄
                        final isMobilePortrait = isMobile && !isLargeScreen && orientation == Orientation.portrait;
                        
                        // 핸드폰 세로 모드: 2줄로 배치
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
                                        fillColor: MaterialStateProperty.resolveWith<Color>(
                                          (Set<MaterialState> states) {
                                            if (states.contains(MaterialState.selected)) {
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
                                        fillColor: MaterialStateProperty.resolveWith<Color>(
                                          (Set<MaterialState> states) {
                                            if (states.contains(MaterialState.selected)) {
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
                                        fillColor: MaterialStateProperty.resolveWith<Color>(
                                          (Set<MaterialState> states) {
                                            if (states.contains(MaterialState.selected)) {
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
                        
                        // 넓은 화면: 1줄로 배치
                        return Row(
                          children: [
                            Icon(reportIcon, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              reportTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Unit 버튼들
                            _buildVentasUnitButtonsInAppBar(),
                            const SizedBox(width: 16),
                            // 큰 화면 또는 수평 모드: 시작일과 종료일 선택기 2개
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: isLargeScreen ? 150 : 90,
                                  child: _buildSingleDateButton(
                                    label: 'Desde',
                                    date: _ventasStartDate,
                                    reportColor: _getReportColor(),
                                    unit: _ventasUnit,
                                    onDateSelected: (date) {
                                      setState(() {
                                        _ventasStartDate = date;
                                        // month unit일 때만 종료일 자동 조정 (year는 사용자가 직접 선택)
                                        if (_ventasUnit == 'month') {
                                          _ventasEndDate = DateTime(date.year, date.month + 1, 0);
                                        }
                                      });
                                      _loadData();
                                    },
                                  ),
                                ),
                              ],
                            ),
                            // 큰 화면: 달력 간격을 unit 버튼 간격과 비슷하게 (4px)
                            const SizedBox(width: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: isLargeScreen ? 150 : 90,
                                  child: _buildSingleDateButton(
                                    label: 'Hasta',
                                    date: _ventasEndDate,
                                    reportColor: _getReportColor(),
                                    unit: _ventasUnit,
                                    onDateSelected: (date) {
                                      setState(() {
                                        _ventasEndDate = date;
                                        // month unit일 때만 시작일 자동 조정 (year는 사용자가 직접 선택)
                                        if (_ventasUnit == 'month') {
                                          _ventasStartDate = DateTime(date.year, date.month, 1);
                                        }
                                      });
                                      _loadData();
                                    },
                                  ),
                                ),
                              ],
                            ),
                            // 큰 화면: descontado, reservado, credito 체크박스 추가
                            if (isLargeScreen) ...[
                              const SizedBox(width: 4),
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
                                    fillColor: MaterialStateProperty.resolveWith<Color>(
                                      (Set<MaterialState> states) {
                                        if (states.contains(MaterialState.selected)) {
                                          return Colors.white.withOpacity(0.3);
                                        }
                                        return Colors.transparent;
                                      },
                                    ),
                                    side: const BorderSide(color: Colors.white, width: 1.5),
                                  ),
                                  const SizedBox(width: 4),
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
                                    fillColor: MaterialStateProperty.resolveWith<Color>(
                                      (Set<MaterialState> states) {
                                        if (states.contains(MaterialState.selected)) {
                                          return Colors.white.withOpacity(0.3);
                                        }
                                        return Colors.transparent;
                                      },
                                    ),
                                    side: const BorderSide(color: Colors.white, width: 1.5),
                                  ),
                                  const SizedBox(width: 4),
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
                                    fillColor: MaterialStateProperty.resolveWith<Color>(
                                      (Set<MaterialState> states) {
                                        if (states.contains(MaterialState.selected)) {
                                          return Colors.white.withOpacity(0.3);
                                        }
                                        return Colors.transparent;
                                      },
                                    ),
                                    side: const BorderSide(color: Colors.white, width: 1.5),
                                  ),
                                  const SizedBox(width: 4),
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
                            ],
                            const SizedBox(width: 16),
                            // 지점 선택 UI (큰 화면에서만, sucursal이 1개 이상일 때만 표시)
                            if (isLargeScreen && _availableSucursales != null && _availableSucursales!.length > 1) ...[
                              _buildSucursalSelector(),
                              const SizedBox(width: 16),
                            ],
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
                            final isLargeScreen = constraints.maxWidth >= 800;
                            final orientation = MediaQuery.of(context).orientation;
                            final platformType = PlatformUtils.getPlatformType(context);
                            final isMobile = platformType == PlatformType.mobile;
                            // 핸드폰의 경우: 세로 모드일 때만 2줄, 가로 모드일 때는 1줄
                            final isMobilePortrait = isMobile && !isLargeScreen && orientation == Orientation.portrait;
                            
                            // 핸드폰 세로 모드: 2줄로 배치
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
                                  // 두 번째 줄: Tipo, Temporada 콤보박스, 필터링 단어 필드
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
      actions: [
        // 보고서 선택 드롭다운 메뉴
        PopupMenuButton<ReportType>(
          icon: const Icon(Icons.assessment, color: Colors.white),
          tooltip: 'Reportes',
          onSelected: (ReportType reportType) {
            if (reportType != widget.reportType) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportScreen(
                    serverUrl: widget.serverUrl,
                    reportType: reportType,
                    initialDate: widget.initialDate,
                    initialItemsStartDate: widget.initialItemsStartDate,
                    initialItemsEndDate: widget.initialItemsEndDate,
                    initialFilteringWord: widget.initialFilteringWord,
                    initialSortColumn: widget.initialSortColumn,
                    initialSortAscending: widget.initialSortAscending,
                    onStateChanged: widget.onStateChanged,
                    onItemsDateRangeChanged: widget.onItemsDateRangeChanged,
                    useFullWidth: widget.useFullWidth,
                  ),
                ),
              );
            }
          },
          itemBuilder: (BuildContext context) => _buildReportMenuItems(),
        ),
        // PDF 공유 버튼
        if (_data != null)
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            tooltip: 'Compartir como PDF',
            onPressed: () => _shareAsPdf(),
          ),
      ],
    );
  }

  // Body 빌드 메서드 (useFullWidth가 true일 때 사용)
  Widget _buildBody(BuildContext context, AppLocalizations l10n, Color reportColor) {
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
        return Column(
          children: [
            // 작은 화면에서만 날짜 범위 선택 UI 표시 (큰 화면은 AppBar에 있음)
            if (!isLargeScreen && (widget.reportType == ReportType.items || widget.reportType == ReportType.ingresos || widget.reportType == ReportType.gastos || widget.reportType == ReportType.alertas))
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
    
    // Gastos 보고서의 경우 특별 처리 (새로운 응답 구조)
    if (widget.reportType == ReportType.gastos && 
        data.containsKey('data') && 
        data['data'] is Map &&
        (data['data'] as Map).containsKey('detail')) {
      final filteringWord = _filteringWordController.text.trim();
      // _getDisplayedData()를 사용하여 필터링/정렬 적용
      final displayedData = _getDisplayedData();
      return GastosBuilder.buildContent(
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
      );
    }
    
    // 'data' 키가 있고 리스트인 경우
    if (data.containsKey('data') && data['data'] is List) {
      final dataList = data['data'] as List;
      if (dataList.isEmpty) {
        return const Center(child: Text('No hay datos disponibles'));
      }
      
      // 첫 번째 항목이 맵이고 여러 키를 가지고 있으면 테이블로 표시
      if (dataList.isNotEmpty && dataList.first is Map) {
        // Items, Ingresos, Gastos, Alertas 및 Ventas 보고서의 경우 filteringWord 필터 적용
        List<dynamic> filteredDataList = dataList;
        if (widget.reportType == ReportType.items || widget.reportType == ReportType.ingresos || widget.reportType == ReportType.gastos || widget.reportType == ReportType.alertas || widget.reportType == ReportType.ventas) {
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
                  final codigo1 = item['codigo1']?.toString().toLowerCase() ?? '';
                  final desc1 = item['desc1']?.toString().toLowerCase() ?? '';
                  return codigo1.contains(filteringWord) || desc1.contains(filteringWord);
                } else if (widget.reportType == ReportType.ingresos) {
                  final codigo = item['codigo']?.toString().toLowerCase() ?? '';
                  final descripcion = item['descripcion']?.toString().toLowerCase() ?? '';
                  return codigo.contains(filteringWord) || descripcion.contains(filteringWord);
                } else if (widget.reportType == ReportType.gastos) {
                  final codigo = item['codigo']?.toString().toLowerCase() ?? '';
                  final descripcion = item['descripcion']?.toString().toLowerCase() ?? '';
                  final concepto = item['concepto']?.toString().toLowerCase() ?? '';
                  return codigo.contains(filteringWord) || descripcion.contains(filteringWord) || concepto.contains(filteringWord);
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
                }
              }
              return false;
            }).toList();
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
          // Alertas 보고서의 경우 정렬 적용
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
          
          // Alertas 보고서 색상 결정
          Color alertasColor = Colors.orange; // alertas 보고서 기본 색상
          
          // 테이블 위젯 생성 (화면을 나누지 않음)
          return ReportTableBuilder.buildTableFromList(
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
              setState(() {
                final allKeys = sortedDataList.isNotEmpty 
                    ? (sortedDataList.first as Map<String, dynamic>).keys.toList()
                    : <String>[];
                if (columnIndex >= 0 && columnIndex < allKeys.length) {
                  final key = allKeys[columnIndex];
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
          
          // 테이블 위젯 생성
          final tableWidget = ReportTableBuilder.buildTableFromList(
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
                  onRowTap: null, // vcode 단위에서는 단일 클릭 비활성화 (더블 클릭만 사용)
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
        
        return ReportTableBuilder.buildTableFromList(
          widget.reportType == ReportType.ventas ? sortedDataList : filteredDataList,
          _displayedItemsCount,
          _itemsPerPage,
          _scrollController,
          widget.reportType,
          sortColumn: widget.reportType == ReportType.ventas ? _sortColumn : null,
          sortAscending: widget.reportType == ReportType.ventas ? _sortAscending : true,
          horizontalScrollController: _horizontalScrollController,
          reportColor: widget.reportType == ReportType.ventas ? Colors.purple : null,
          unit: widget.reportType == ReportType.ventas ? _ventasUnit : null,
          onRowDoubleTap: widget.reportType == ReportType.ventas ? _handleRowDoubleTap : null,
          onRowTap: null, // vcode 단위에서는 단일 클릭 비활성화 (더블 클릭만 사용)
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
                        
                        // 금액/숫자 관련 컬럼명 체크 (명시적으로 숫자로 처리)
                        final keyLower = key.toLowerCase();
                        final isAmountColumn = keyLower.contains('costo') || 
                                               keyLower.contains('importe') || 
                                               keyLower.contains('ingreso') || 
                                               keyLower.contains('precio') ||
                                               keyLower.contains('pre') ||
                                               keyLower.contains('venta') ||
                                               keyLower.contains('cantidad') ||
                                               keyLower.contains('count') ||
                                               keyLower.contains('total');
                        
                        final isNumeric = isCodigoColumn ? false : (ReportUtils.isNumeric(value) || isAmountColumn);
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
  /// Ventas 보고서의 컨트롤을 AppBar에 표시 (오른쪽)
  Widget _buildVentasControlsInAppBar() {
    final reportColor = _getReportColor();
    
    // 큰 화면(macOS, iPad)에서는 버튼 3개를 나란히 표시
    return Builder(
      builder: (context) {
        final platformType = PlatformUtils.getPlatformType(context);
        final size = MediaQuery.of(context).size;
        final isLargeScreen = (platformType == PlatformType.desktop || 
                              PlatformUtils.isIPad(context)) && 
                             size.width >= 800;
        
        if (isLargeScreen) {
          // 큰 화면: 버튼 4개를 나란히 표시 (VCode, Day, Month, Year)
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 50,
                child: _buildCompactUnitButton('VCode', 'vcode', reportColor),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 45,
                child: _buildCompactUnitButton('Day', 'day', reportColor),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 55,
                child: _buildCompactUnitButton('Month', 'month', reportColor),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 50,
                child: _buildCompactUnitButton('Year', 'year', reportColor),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                child: _buildCompactDateRangeButton(reportColor),
              ),
              const SizedBox(width: 8),
              // 지점 선택 UI (sucursal이 1개 이상일 때만 표시)
              if (_availableSucursales != null && _availableSucursales!.length > 1) ...[
                _buildSucursalSelector(),
                const SizedBox(width: 8),
              ],
              SizedBox(
                width: 300, // 큰 화면에서는 충분히 넓게
                child: _buildFilteringWordFieldInAppBar(),
              ),
            ],
          );
        } else {
          // 작은 화면: 드롭다운 사용
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCompactUnitDropdown(reportColor),
              const SizedBox(width: 4),
              SizedBox(
                width: 90,
                child: _buildCompactDateRangeButton(reportColor),
              ),
              // 지점 선택 UI (sucursal이 1개 이상일 때만 표시)
              if (_availableSucursales != null && _availableSucursales!.length > 1) ...[
                const SizedBox(width: 4),
                SizedBox(
                  width: 100,
                  child: _buildSucursalSelector(),
                ),
              ],
              const SizedBox(width: 4),
              SizedBox(
                width: 180, // 작은 화면에서도 충분한 크기
                child: _buildFilteringWordFieldInAppBar(),
              ),
            ],
          );
        }
      },
    );
  }

  /// Ventas 보고서의 Unit 버튼들을 AppBar에 표시 (타이틀 옆)
  Widget _buildVentasUnitButtonsInAppBar() {
    final reportColor = _getReportColor();
    
    return Builder(
      builder: (context) {
        final platformType = PlatformUtils.getPlatformType(context);
        final size = MediaQuery.of(context).size;
        final isLargeScreen = (platformType == PlatformType.desktop || 
                              PlatformUtils.isIPad(context)) && 
                             size.width >= 800;
        
        if (isLargeScreen) {
          // 큰 화면: 버튼 4개를 나란히 표시 (VCode, Day, Month, Year)
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 70,
                child: _buildCompactUnitButton('VCode', 'vcode', reportColor),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 65,
                child: _buildCompactUnitButton('Day', 'day', reportColor),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 75,
                child: _buildCompactUnitButton('Month', 'month', reportColor),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 70,
                child: _buildCompactUnitButton('Year', 'year', reportColor),
              ),
            ],
          );
        } else {
          // 작은 화면: 드롭다운 사용
          return _buildCompactUnitDropdown(reportColor);
        }
      },
    );
  }

  /// Ventas 보고서의 나머지 컨트롤을 AppBar에 표시 (날짜 범위, sucursal, 필터)
  Widget _buildVentasOtherControlsInAppBar() {
    final reportColor = _getReportColor();
    
    return Builder(
      builder: (context) {
        final platformType = PlatformUtils.getPlatformType(context);
        final size = MediaQuery.of(context).size;
        final isLargeScreen = (platformType == PlatformType.desktop || 
                              PlatformUtils.isIPad(context)) && 
                             size.width >= 800;
        
        if (isLargeScreen) {
          // 큰 화면: 날짜 범위, sucursal, 필터 입력 필드
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 90,
                child: _buildCompactDateRangeButton(reportColor),
              ),
              const SizedBox(width: 8),
              // 지점 선택 UI (sucursal이 1개 이상일 때만 표시)
              if (_availableSucursales != null && _availableSucursales!.length > 1) ...[
                _buildSucursalSelector(),
                const SizedBox(width: 8),
              ],
              SizedBox(
                width: 200,
                child: _buildFilteringWordFieldInAppBar(),
              ),
            ],
          );
        } else {
          // 작은 화면: 날짜 범위, sucursal, 필터 입력 필드
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 90,
                child: _buildCompactDateRangeButton(reportColor),
              ),
              // 지점 선택 UI (sucursal이 1개 이상일 때만 표시)
              if (_availableSucursales != null && _availableSucursales!.length > 1) ...[
                const SizedBox(width: 4),
                SizedBox(
                  width: 100,
                  child: _buildSucursalSelector(),
                ),
              ],
              const SizedBox(width: 4),
              SizedBox(
                width: 180, // 작은 화면에서도 충분한 크기
                child: _buildFilteringWordFieldInAppBar(),
              ),
            ],
          );
        }
      },
    );
  }

  /// 컴팩트한 Unit 버튼 (AppBar용)
  Widget _buildCompactUnitButton(String label, String value, Color reportColor) {
    final isSelected = _ventasUnit == value;
    debugPrint('🔵 _buildCompactUnitButton 호출: label=$label, value=$value, isSelected=$isSelected, 현재 _ventasUnit=$_ventasUnit');
    return SizedBox(
      height: 28,
      child: TextButton(
        onPressed: () {
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('🔵 Unit 버튼 클릭 이벤트 발생');
          debugPrint('   - 버튼 라벨: $label');
          debugPrint('   - 버튼 값: $value');
          debugPrint('   - 현재 선택된 unit: $_ventasUnit');
          debugPrint('   - 이전 상태: isSelected=$isSelected');
          debugPrint('   - 보고서 타입: ${widget.reportType}');
          debugPrint('   - 현재 날짜 범위: startDate=$_ventasStartDate, endDate=$_ventasEndDate');
          debugPrint('   - 필터링 단어: ${_filteringWordController.text}');
          debugPrint('   - 데이터 로딩 상태: isLoading=$_isLoading');
          debugPrint('   - 데이터 존재 여부: ${_data != null}');
          
        setState(() {
            final previousUnit = _ventasUnit;
          _ventasUnit = value;
            debugPrint('   → setState 실행: $_ventasUnit (이전: $previousUnit)');
        });
          
          debugPrint('   → _loadData() 호출 시작');
        _loadData();
          debugPrint('═══════════════════════════════════════════════════════');
      },
        style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: isSelected ? reportColor : Colors.white,
          foregroundColor: isSelected ? Colors.white : reportColor,
          shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
            side: BorderSide(
            color: isSelected ? reportColor : reportColor.withOpacity(0.3),
            width: 1,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : reportColor,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// 컴팩트한 Unit Dropdown (AppBar용)
  Widget _buildCompactUnitDropdown(Color reportColor) {
    String getUnitLabel(String unit) {
      switch (unit) {
        case 'vcode':
          return 'VCode';
        case 'day':
          return 'Day';
        case 'month':
          return 'Month';
        case 'year':
          return 'Year';
        default:
          return 'VCode';
      }
    }

    final validUnits = ['vcode', 'day', 'month', 'year'];
    final displayUnit = validUnits.contains(_ventasUnit) ? _ventasUnit : 'vcode';

    return Container(
      constraints: const BoxConstraints(minWidth: 60),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: reportColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: DropdownButton<String>(
        value: displayUnit,
        isDense: true,
        isExpanded: false,
        underline: const SizedBox.shrink(),
        icon: Icon(Icons.arrow_drop_down, color: reportColor, size: 18),
        style: TextStyle(
          color: reportColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        items: validUnits.map((String unit) {
          return DropdownMenuItem<String>(
            value: unit,
            child: Text(
              getUnitLabel(unit),
              style: TextStyle(
                color: reportColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
        onChanged: (String? newUnit) {
          if (newUnit != null) {
            setState(() {
              _ventasUnit = newUnit;
            });
            _loadData();
          }
        },
      ),
    );
  }

  /// 단일 날짜 선택 버튼 (AppBar용)
  Widget _buildSingleDateButton({
    required String label,
    required DateTime? date,
    required Color reportColor,
    required Function(DateTime) onDateSelected,
    String? unit, // ventas 보고서용 unit (vcode, day, month, year)
  }) {
    String dateText;
    IconData iconData;
    
    if (unit == 'year') {
      dateText = date != null ? DateFormat('yyyy').format(date) : label;
      iconData = Icons.event;
    } else if (unit == 'month') {
      dateText = date != null ? DateFormat('yyyy-MM').format(date) : label;
      iconData = Icons.calendar_view_month;
    } else {
      dateText = date != null ? DateFormat('yyyy-MM-dd').format(date) : label;
      iconData = Icons.calendar_today;
    }
    
    return InkWell(
      onTap: () async {
        DateTime? picked;
        
        if (unit == 'year') {
          // 연도 선택
          picked = await ReportHeaderBuilders.selectYearDialog(
            context,
            date ?? DateTime.now(),
            DateTime.now(),
            reportColor,
            widget.reportType,
            title: label,
          );
        } else if (unit == 'month') {
          // 월 선택
          picked = await ReportHeaderBuilders.selectYearMonthDialog(
            context,
            date ?? DateTime.now(),
            DateTime.now(),
            reportColor,
            widget.reportType,
            title: label,
          );
        } else {
          // 일반 날짜 선택 (vcode, day)
          picked = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
            locale: const Locale('es', 'ES'),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: reportColor,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black,
                  ),
                ),
                child: child!,
              );
            },
          );
        }
        
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: reportColor.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              iconData,
              color: reportColor,
              size: 14,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                dateText,
                style: TextStyle(
                  color: reportColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 컴팩트한 날짜 범위 버튼 (AppBar용)
  Widget _buildCompactDateRangeButton(Color reportColor) {
    String rangeText = 'Rango';
    DateFormat dateFormat;
    
    if (_ventasUnit == 'year') {
      dateFormat = DateFormat('yyyy');
    } else if (_ventasUnit == 'month') {
      dateFormat = DateFormat('yyyy-MM');
    } else {
      dateFormat = DateFormat('yyyy-MM-dd');
    }
    
    if (_ventasStartDate != null && _ventasEndDate != null) {
      if (_ventasUnit == 'year' || _ventasUnit == 'month') {
        rangeText = '${dateFormat.format(_ventasStartDate!)} - ${dateFormat.format(_ventasEndDate!)}';
      } else {
        rangeText = '${dateFormat.format(_ventasStartDate!)} ~ ${dateFormat.format(_ventasEndDate!)}';
      }
      // 텍스트가 너무 길면 줄임
      if (rangeText.length > 12) {
        rangeText = '${rangeText.substring(0, 10)}...';
      }
    }
    
    return InkWell(
      onTap: () => ReportHeaderBuilders.selectDateRange(
        context,
        _ventasStartDate,
        _ventasEndDate,
        _ventasUnit,
        reportColor,
        widget.reportType,
        (startDate, endDate) {
          setState(() {
            _ventasStartDate = startDate;
            _ventasEndDate = endDate;
          });
          _loadData();
        },
      ),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: reportColor.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _ventasUnit == 'year'
                  ? Icons.event
                  : _ventasUnit == 'month'
                      ? Icons.calendar_view_month
                      : Icons.date_range,
              color: reportColor,
              size: 14,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                rangeText,
                style: TextStyle(
                  color: reportColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVentasHeader() {
    return ReportHeaderBuilders.buildVentasHeader(
      context: context,
      data: _data,
      startDate: _ventasStartDate,
      endDate: _ventasEndDate,
      selectedSucursal: _selectedSucursal,
      unit: _ventasUnit,
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
      onUnitChanged: (value) {
        setState(() {
          _ventasUnit = value;
        });
        _loadData();
      },
      reportColor: _getReportColor(),
      reportType: widget.reportType,
      filteringWordController: _filteringWordController,
      onFilteringWordSubmitted: (value) {
        // filteringWord 변경 시 자동으로 필터링됨 (리스너에서 처리)
      },
      onFilteringWordClear: () {
        setState(() {
          _filteringWordController.clear();
        });
      },
    );
  }

  /// 행 더블 클릭 핸들러 - 세부 내역 보기
  void _handleRowDoubleTap(Map<String, dynamic> rowData) {
    print('🔵🔵🔵 더블 클릭 감지됨! 🔵🔵🔵');
    print('🔵 reportType: ${widget.reportType}, ventasUnit: $_ventasUnit');
    
    if (widget.reportType != ReportType.ventas) {
      print('❌ reportType이 ventas가 아닙니다: ${widget.reportType}');
      return;
    }
    
    // vcode 단위에서는 더블 클릭으로 vdetalle 상세 정보 보기
    if (_ventasUnit == 'vcode') {
      print('🔵 vcode 단위 더블 클릭 - vdetalle 요청');
      _handleVcodeRowTap(rowData);
      return;
    }
    
    print('🔍 더블 클릭 - 현재 unit: $_ventasUnit, rowData keys: ${rowData.keys.toList()}');
    print('🔍 rowData: $rowData');
    
    DateTime? selectedDate;
    String? newUnit;
    DateTime? newStartDate;
    DateTime? newEndDate;
    
    // 현재 unit에 따라 처리
    if (_ventasUnit == 'year') {
      print('🔵🔵🔵 YEAR 단위 더블 클릭 처리 시작! 🔵🔵🔵');
      // year 단위: 해당 연도의 month 단위로 변경
      // year 단위에서는 fecha 필드가 "YYYY" 형식이거나 'year' 필드가 있을 수 있음
      // year 필드가 "YYYY-MM-DD" 형식일 수도 있음
      dynamic yearValue;
      
      // 1. 'year' 필드 확인
      yearValue = rowData['year'] ?? rowData['Year'] ?? rowData['YEAR'];
      
      // year 필드가 "YYYY-MM-DD" 형식인 경우 "YYYY"만 추출
      if (yearValue != null) {
        final yearStr = yearValue.toString();
        if (yearStr.contains('-')) {
          // "YYYY-MM-DD" 또는 "YYYY-MM" 형식에서 연도 추출
          final parts = yearStr.split('-');
          if (parts.isNotEmpty) {
            yearValue = parts[0];
          }
        }
      }
      
      // 2. 'fecha' 필드 확인 (year 단위에서는 "YYYY" 형식)
      if (yearValue == null) {
        final fechaValue = rowData['fecha'] ?? rowData['Fecha'] ?? rowData['FECHA'];
        if (fechaValue != null) {
          final fechaStr = fechaValue.toString();
          // "YYYY" 형식인지 확인 (길이가 4이고 숫자만 포함)
          if (fechaStr.length == 4 && int.tryParse(fechaStr) != null) {
            yearValue = fechaStr;
          } else if (fechaStr.contains('-')) {
            // "YYYY-MM-DD" 형식에서 연도 추출
            final parts = fechaStr.split('-');
            if (parts.isNotEmpty) {
              yearValue = parts[0];
            }
          }
        }
      }
      
      // 3. 다른 필드에서 4자리 숫자 찾기
      if (yearValue == null) {
        yearValue = rowData.values.firstWhere(
          (v) {
            if (v == null) return false;
            final str = v.toString();
            // "YYYY" 형식이거나 "YYYY-MM-DD" 형식의 시작 부분이 4자리 숫자인지 확인
            if (str.length == 4 && int.tryParse(str) != null) {
              return true;
            }
            if (str.contains('-')) {
              final parts = str.split('-');
              if (parts.isNotEmpty && parts[0].length == 4 && int.tryParse(parts[0]) != null) {
                return true;
              }
            }
            return false;
          },
          orElse: () => null,
        );
        // 찾은 값이 날짜 형식이면 연도만 추출
        if (yearValue != null && yearValue.toString().contains('-')) {
          final parts = yearValue.toString().split('-');
          if (parts.isNotEmpty) {
            yearValue = parts[0];
          }
        }
      }
      
      print('🔍 year 단위 - yearValue: $yearValue, rowData keys: ${rowData.keys.toList()}');
      
      if (yearValue != null) {
        final yearStr = yearValue.toString();
        // 최종적으로 연도만 추출 (혹시 모를 경우를 대비)
        final year = yearStr.contains('-') 
            ? int.tryParse(yearStr.split('-')[0])
            : int.tryParse(yearStr);
            
        if (year != null && year >= 2000 && year <= DateTime.now().year) {
          newUnit = 'month';
          newStartDate = DateTime(year, 1, 1);
          newEndDate = DateTime(year, 12, 31);
          print('✅ year -> month: $year년 (${newStartDate} ~ ${newEndDate})');
        } else {
          print('❌ year 값이 유효하지 않습니다: $year (범위: 2000 ~ ${DateTime.now().year})');
        }
      } else {
        print('❌ year 값을 찾을 수 없습니다. rowData: $rowData');
      }
    } else if (_ventasUnit == 'month') {
      print('🔵🔵🔵 MONTH 단위 더블 클릭 처리 시작! 🔵🔵🔵');
      // month 단위: 해당 월의 day 단위로 변경
      // 다양한 필드명 시도
      dynamic monthValue = rowData['month'] ?? 
                        rowData['Month'] ?? 
                        rowData['MONTH'];
      
      // month 필드가 없으면 다른 필드에서 찾기
      if (monthValue == null) {
        monthValue = rowData.values.firstWhere(
          (v) => v != null && v.toString().contains('-') && v.toString().split('-').length >= 2,
          orElse: () => null,
        );
      }
      
      print('🔍 month 단위 - monthValue: $monthValue, rowData keys: ${rowData.keys.toList()}');
      print('🔍 rowData: $rowData');
      
      if (monthValue != null) {
        final monthStr = monthValue.toString();
        print('🔍 monthStr: $monthStr');
        
        // "YYYY-MM-DD" 또는 "YYYY-MM" 형식 파싱
        final parts = monthStr.split('-');
        print('🔍 parts: $parts, length: ${parts.length}');
        
        if (parts.length >= 2) {
          final year = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);
          print('🔍 파싱 결과 - year: $year, month: $month');
          
          if (year != null && month != null && month >= 1 && month <= 12) {
            newUnit = 'day';
            newStartDate = DateTime(year, month, 1);
            newEndDate = DateTime(year, month + 1, 0); // 해당 월의 마지막 날
            print('✅ month -> day: ${year}년 ${month}월 (${newStartDate} ~ ${newEndDate})');
          } else {
            print('❌ year 또는 month 값이 유효하지 않습니다: year=$year, month=$month');
          }
        } else {
          print('❌ monthStr을 파싱할 수 없습니다. parts.length=${parts.length}');
        }
      } else {
        print('❌ month 값을 찾을 수 없습니다. rowData: $rowData');
      }
    } else if (_ventasUnit == 'day') {
      // day 단위: 해당 날짜의 vcode 단위로 변경
      // 다양한 필드명 시도
      final fechaValue = rowData['fecha'] ?? 
                        rowData['Fecha'] ?? 
                        rowData['FECHA'] ??
                        rowData.values.firstWhere(
                          (v) => v != null && v.toString().split('-').length == 3,
                          orElse: () => null,
                        );
      
      print('🔍 day 단위 - fechaValue: $fechaValue');
      
      if (fechaValue != null) {
        final fechaStr = fechaValue.toString();
        // "YYYY-MM-DD" 형식 파싱
        final parts = fechaStr.split('-');
        if (parts.length >= 3) {
          final year = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);
          final day = int.tryParse(parts[2]);
          if (year != null && month != null && day != null) {
            newUnit = 'vcode';
            selectedDate = DateTime(year, month, day);
            newStartDate = selectedDate;
            newEndDate = selectedDate;
            print('✅ day -> vcode: ${year}년 ${month}월 ${day}일');
          }
        }
      }
    }
    
    // unit과 날짜 범위 변경
    if (newUnit != null && newStartDate != null && newEndDate != null) {
      print('✅ 변경 적용: unit=$newUnit, startDate=$newStartDate, endDate=$newEndDate');
      setState(() {
        _ventasUnit = newUnit!;
        _ventasStartDate = newStartDate;
        _ventasEndDate = newEndDate;
      });
      _loadData();
    } else {
      print('❌ 변경 실패: newUnit=$newUnit, newStartDate=$newStartDate, newEndDate=$newEndDate');
    }
  }

  /// vcode 행 탭 핸들러 - vdetalle 상세 정보 보기
  void _handleVcodeRowTap(Map<String, dynamic> rowData) async {
    if (widget.reportType != ReportType.ventas || _ventasUnit != 'vcode') return;
    
    print('🔍 vcode 행 탭 - rowData: $rowData');
    
    // id와 sucursal 추출 (서버에 id와 sucursal 파라미터로 전송)
    final vcodeId = rowData['id'] ?? rowData['vcode_id'] ?? rowData['Id'] ?? rowData['Vcode_id'];
    final sucursal = rowData['sucursal'] ?? rowData['Sucursal'];
    
    if (vcodeId == null || sucursal == null) {
      print('❌ id 또는 sucursal이 없습니다. id: $vcodeId, sucursal: $sucursal');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('id 또는 sucursal 정보를 찾을 수 없습니다.')),
      );
      return;
    }
    
    final vcodeIdInt = vcodeId is int ? vcodeId : int.tryParse(vcodeId.toString());
    final sucursalInt = sucursal is int ? sucursal : int.tryParse(sucursal.toString());
    
    if (vcodeIdInt == null || sucursalInt == null) {
      print('❌ id 또는 sucursal을 정수로 변환할 수 없습니다.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('id 또는 sucursal 형식이 올바르지 않습니다.')),
      );
      return;
    }
    
    print('✅ vdetalles 요청 - id: $vcodeIdInt, sucursal: $sucursalInt');
    
    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      // vdetalle 데이터 요청
      final vdetalleData = await _databaseService.getVdetalle(
        vcodeId: vcodeIdInt,
        sucursal: sucursalInt,
      );
      
      // 로딩 다이얼로그 닫기
      if (mounted) Navigator.of(context).pop();
      
      print('✅ vdetalle 응답: $vdetalleData');
      
      // vdetalle 카드 다이얼로그 표시
      if (mounted) {
        _showVdetalleDialog(vdetalleData, rowData);
      }
    } catch (e) {
      // 로딩 다이얼로그 닫기
      if (mounted) Navigator.of(context).pop();
      
      print('❌ vdetalle 요청 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('vdetalle 데이터를 가져오는 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  /// vdetalle 데이터를 카드 형태로 표시하는 다이얼로그
  void _showVdetalleDialog(Map<String, dynamic> vdetalleData, Map<String, dynamic> rowData) {
    showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final isWideScreen = screenWidth >= 800;
        // 좁은 화면일 때는 전체 화면 사용
        final dialogWidth = isWideScreen ? screenWidth * 2 / 3 : screenWidth;
        final dialogHeight = isWideScreen ? screenHeight * 0.9 : screenHeight;
        
        return Dialog(
          insetPadding: isWideScreen ? const EdgeInsets.all(16) : EdgeInsets.zero,
          child: Container(
            width: dialogWidth,
            height: dialogHeight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 헤더
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: isWideScreen
                        ? const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Detalle de Venta',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // 내용
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildVdetalleCards(vdetalleData, rowData, isWideScreen),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// vdetalle 데이터를 카드 형태로 구성
  Widget _buildVdetalleCards(Map<String, dynamic> vdetalleData, Map<String, dynamic> rowData, bool isWideScreen) {
    final leftCards = <Widget>[]; // 왼쪽: Información de Pago, Cliente, Cheque, Vtags
    final rightCards = <Widget>[]; // 오른쪽: Detalles, Online Ventas
    
    // 왼쪽 카드들
    // Vcodes 정보 카드 (결제 정보 및 기타 정보)
    if (vdetalleData.containsKey('vcodes') && vdetalleData['vcodes'] is Map) {
      final vcodes = vdetalleData['vcodes'] as Map<String, dynamic>;
      leftCards.add(_buildInfoCard('Información de Pago', {
        'Total Pago': ReportUtils.formatValue(vcodes['tpago']),
        'Efectivo': ReportUtils.formatValue(vcodes['tefectivo']),
        'Crédito': ReportUtils.formatValue(vcodes['tcredito']),
        'Banco': ReportUtils.formatValue(vcodes['tbanco']),
        'Reservado': ReportUtils.formatValue(vcodes['treservado']),
        'Favor': ReportUtils.formatValue(vcodes['tfavor']),
        'Núm. Caja': vcodes['d_num_caja']?.toString() ?? 'N/A',
        'Núm. Terminal': vcodes['d_num_terminal']?.toString() ?? 'N/A',
      }));
    }
    
    // Cliente 정보 카드
    if (vdetalleData.containsKey('cliente') && vdetalleData['cliente'] is Map) {
      final cliente = vdetalleData['cliente'] as Map<String, dynamic>;
      leftCards.add(_buildInfoCard('Información del Cliente', {
        'DNI': cliente['dni']?.toString() ?? 'N/A',
        'Nombre': cliente['nombre']?.toString() ?? 'N/A',
        'Dirección': cliente['direccion']?.toString() ?? 'N/A',
        'Localidad': cliente['localidad']?.toString() ?? 'N/A',
        'Provincia': cliente['provincia']?.toString() ?? 'N/A',
        'Vendedor': cliente['vendedor']?.toString() ?? 'N/A',
      }));
    }
    
    // Cheque (수표 정보) 카드
    if (vdetalleData.containsKey('cheque') && vdetalleData['cheque'] is List) {
      final cheques = vdetalleData['cheque'] as List;
      if (cheques.isNotEmpty) {
        leftCards.add(_buildChequesCard(cheques));
      }
    }
    
    // Vtags (결제 정보) 카드
    if (vdetalleData.containsKey('vtags') && vdetalleData['vtags'] is List) {
      final vtags = vdetalleData['vtags'] as List;
      if (vtags.isNotEmpty) {
        leftCards.add(_buildVtagsCard(vtags));
      }
    }
    
    // 오른쪽 카드들
    // Detalles (판매 상세 내역) 카드
    if (vdetalleData.containsKey('detalles') && vdetalleData['detalles'] is List) {
      final detalles = vdetalleData['detalles'] as List;
      if (detalles.isNotEmpty) {
        rightCards.add(_buildDetallesCard(detalles));
      }
    }
    
    // Online Ventas (온라인 판매 정보) 카드
    if (vdetalleData.containsKey('online_ventas') && vdetalleData['online_ventas'] is List) {
      final onlineVentas = vdetalleData['online_ventas'] as List;
      if (onlineVentas.isNotEmpty) {
        rightCards.add(_buildOnlineVentasCard(onlineVentas));
      }
    }
    
    // 왼쪽/오른쪽 레이아웃 구성
    // 좁은 화면일 때는 세로로 배치, 넓은 화면일 때는 좌우로 배치
    if (isWideScreen) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 왼쪽: 오른쪽의 1/2 너비 (즉, 전체의 1/3)
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: leftCards,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 오른쪽: 전체의 2/3
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: rightCards,
              ),
            ),
          ),
        ],
      );
    } else {
      // 좁은 화면: 세로로 배치
      final allCards = <Widget>[];
      for (int i = 0; i < leftCards.length; i++) {
        allCards.add(leftCards[i]);
        if (i < leftCards.length - 1 || rightCards.isNotEmpty) {
          allCards.add(const SizedBox(height: 16));
        }
      }
      for (int i = 0; i < rightCards.length; i++) {
        allCards.add(rightCards[i]);
        if (i < rightCards.length - 1) {
          allCards.add(const SizedBox(height: 16));
        }
      }
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: allCards,
        ),
      );
    }
  }
  
  /// Detalles 카드 (판매 상세 내역 테이블)
  Widget _buildDetallesCard(List<dynamic> detalles) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalles de Venta',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                headingRowColor: MaterialStateProperty.all(Colors.purple.withOpacity(0.1)),
                columns: const [
                  DataColumn(label: Text('Código', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Descripción', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Cantidad', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  DataColumn(label: Text('Precio Unit.', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  DataColumn(label: Text('Precio Total', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                ],
                rows: detalles.map((item) {
                  if (item is Map<String, dynamic>) {
                    return DataRow(
                      cells: [
                        DataCell(Text(item['codigo1']?.toString() ?? 'N/A')),
                        DataCell(Text(item['desc1']?.toString() ?? 'N/A')),
                        DataCell(Text(ReportUtils.formatValue(item['cant1']))),
                        DataCell(Text(ReportUtils.formatValue(item['preuni']))),
                        DataCell(Text(ReportUtils.formatValue(item['precio']))),
                      ],
                    );
                  }
                  return const DataRow(cells: [
                    DataCell(Text('N/A')),
                    DataCell(Text('N/A')),
                    DataCell(Text('N/A')),
                    DataCell(Text('N/A')),
                    DataCell(Text('N/A')),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Vtags 카드 (결제 정보 테이블)
  Widget _buildVtagsCard(List<dynamic> vtags) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información de Pago',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                headingRowColor: MaterialStateProperty.all(Colors.purple.withOpacity(0.1)),
                columns: const [
                  DataColumn(label: Text('Cuenta', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Núm. Autorización', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Monto', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  DataColumn(label: Text('Sucursal', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                ],
                rows: vtags.map((item) {
                  if (item is Map<String, dynamic>) {
                    return DataRow(
                      cells: [
                        DataCell(Text(item['cuenta_nombre']?.toString() ?? 'N/A')),
                        DataCell(Text(item['num_autorizacion']?.toString() ?? 'N/A')),
                        DataCell(Text(ReportUtils.formatValue(item['fmonto']))),
                        DataCell(Text(item['sucursal']?.toString() ?? 'N/A')),
                      ],
                    );
                  }
                  return const DataRow(cells: [
                    DataCell(Text('N/A')),
                    DataCell(Text('N/A')),
                    DataCell(Text('N/A')),
                    DataCell(Text('N/A')),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Cheques 카드 (수표 정보 테이블)
  Widget _buildChequesCard(List<dynamic> cheques) {
    // 첫 번째 수표의 키를 사용하여 동적으로 컬럼 생성
    if (cheques.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final firstCheque = cheques.first;
    if (firstCheque is! Map<String, dynamic>) {
      return const SizedBox.shrink();
    }
    
    final keys = firstCheque.keys.toList();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información de Cheques',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                headingRowColor: MaterialStateProperty.all(Colors.purple.withOpacity(0.1)),
                columns: keys.map((key) {
                  return DataColumn(
                    label: Text(
                      key.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
                rows: cheques.map((item) {
                  if (item is Map<String, dynamic>) {
                    return DataRow(
                      cells: keys.map((key) {
                        return DataCell(Text(
                          ReportUtils.formatValue(item[key]),
                        ));
                      }).toList(),
                    );
                  }
                  return DataRow(
                    cells: keys.map((_) => const DataCell(Text('N/A'))).toList(),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 정보 카드 위젯 생성
  Widget _buildInfoCard(String title, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 12),
            ...data.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      '${entry.key}:',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value?.toString() ?? 'N/A',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
  
  /// Online Ventas 카드 (온라인 판매 정보 테이블)
  Widget _buildOnlineVentasCard(List<dynamic> onlineVentas) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ventas Online',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                headingRowColor: MaterialStateProperty.all(Colors.purple.withOpacity(0.1)),
                columns: const [
                  DataColumn(label: Text('Núm. Pedido', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 42))),
                  DataColumn(label: Text('Fecha Registrado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 42))),
                  DataColumn(label: Text('Fecha Pagado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 42))),
                ],
                rows: onlineVentas.map((item) {
                  if (item is Map<String, dynamic>) {
                    // utime을 날짜 형식으로 변환
                    String formatUtime(dynamic utime) {
                      if (utime == null) return 'N/A';
                      try {
                        final timestamp = utime is int ? utime : int.tryParse(utime.toString());
                        if (timestamp != null) {
                          final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
                          return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
                        }
                      } catch (e) {
                        return utime.toString();
                      }
                      return utime.toString();
                    }
                    
                    return DataRow(
                      cells: [
                        DataCell(Text(
                          item['num_pedido']?.toString() ?? 'N/A',
                          style: const TextStyle(fontSize: 42),
                        )),
                        DataCell(Text(
                          formatUtime(item['utime_registrado']),
                          style: const TextStyle(fontSize: 42),
                        )),
                        DataCell(Text(
                          formatUtime(item['utime_pagado']),
                          style: const TextStyle(fontSize: 42),
                        )),
                      ],
                    );
                  }
                  return DataRow(
                    cells: [
                      const DataCell(Text('N/A', style: TextStyle(fontSize: 42))),
                      const DataCell(Text('N/A', style: TextStyle(fontSize: 42))),
                      const DataCell(Text('N/A', style: TextStyle(fontSize: 42))),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
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

  // Tipo 선택 UI (AppBar용)
  Widget _buildTipoSelector() {
    final reportColor = _getReportColor();
    
    // 현재 선택된 값이 items 리스트에 있는지 확인
    final availableIds = _tiposList.map((tipo) {
      final id = tipo['id_tipo'] is int 
          ? tipo['id_tipo'] 
          : (tipo['id_tipo'] != null ? int.tryParse(tipo['id_tipo'].toString()) : null) ??
            (tipo['id'] is int ? tipo['id'] : (tipo['id'] != null ? int.tryParse(tipo['id'].toString()) : null));
      return id;
    }).where((id) => id != null).cast<int>().toList();
    
    final validValue = _selectedTipoId != null && availableIds.contains(_selectedTipoId)
        ? _selectedTipoId
        : null;
    
    // items 생성
    final items = <DropdownMenuItem<int?>>[
      const DropdownMenuItem<int?>(
        value: null,
        child: Text('Todos', style: TextStyle(fontSize: 12)),
      ),
      ..._tiposList.map((tipo) {
        // id_tipo 또는 id 필드 확인
        final id = tipo['id_tipo'] is int 
            ? tipo['id_tipo'] 
            : (tipo['id_tipo'] != null ? int.tryParse(tipo['id_tipo'].toString()) : null) ??
              (tipo['id'] is int ? tipo['id'] : (tipo['id'] != null ? int.tryParse(tipo['id'].toString()) : null));
        
        // tpdesc 필드 확인 (실제 서버 응답 필드명)
        final nombre = tipo['tpdesc']?.toString() ?? 
                      tipo['tipodesc']?.toString() ?? 
                      tipo['tipo_desc']?.toString() ?? 
                      tipo['descripcion']?.toString() ?? 
                      tipo['nombre']?.toString() ?? 
                      tipo['tipo']?.toString() ?? 
                      tipo['tipo_nombre']?.toString() ??
                      'N/A';
        
        if (id == null) {
          print('⚠️ Tipo 항목 ID 없음: $tipo');
          return null;
        }
        if (nombre == 'N/A') {
          print('⚠️ Tipo 항목 이름 없음 (키: ${tipo.keys.toList()}): $tipo');
        }
        return DropdownMenuItem<int?>(
          value: id,
          child: Text(nombre, style: const TextStyle(fontSize: 12)),
        );
      }).where((item) => item != null).cast<DropdownMenuItem<int?>>().toList(),
    ];
    
    // 디버깅: 모든 tipos 데이터를 JSON 형태로 출력
    print('═══════════════════════════════════════════════════════════');
    print('🔍 Tipo 콤보박스 데이터 (JSON 형태)');
    print('═══════════════════════════════════════════════════════════');
    print('_tiposList.length: ${_tiposList.length}');
    print('items.length: ${items.length}');
    print('');
    print('📋 모든 Tipos 데이터:');
    try {
      final jsonString = const JsonEncoder.withIndent('  ').convert(_tiposList);
      print(jsonString);
    } catch (e) {
      print('JSON 변환 오류: $e');
      print('원본 데이터: $_tiposList');
    }
    print('═══════════════════════════════════════════════════════════');
    
    // 각 항목의 필드명 확인
    if (_tiposList.isNotEmpty) {
      print('');
      print('📋 첫 번째 Tipo 항목 상세:');
      final firstTipo = _tiposList.first;
      firstTipo.forEach((key, value) {
        print('   $key: $value (타입: ${value.runtimeType})');
      });
    }
    
    return Tooltip(
      message: 'Filtrar por Tipo',
      child: SizedBox(
        width: 140,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButton<int?>(
            value: validValue,
            hint: const Text('Tipo', style: TextStyle(fontSize: 12, color: Colors.grey)),
            underline: const SizedBox(),
            isDense: true,
            isExpanded: true,
            icon: Icon(Icons.arrow_drop_down, color: reportColor, size: 20),
            selectedItemBuilder: (BuildContext context) {
              return items.map((item) {
                if (item.value == null) {
                  return const Text('Todos', style: TextStyle(fontSize: 12));
                }
                final tipo = _tiposList.firstWhere(
                  (t) {
                    final id = t['id_tipo'] is int 
                        ? t['id_tipo'] 
                        : (t['id_tipo'] != null ? int.tryParse(t['id_tipo'].toString()) : null) ??
                          (t['id'] is int ? t['id'] : (t['id'] != null ? int.tryParse(t['id'].toString()) : null));
                    return id == item.value;
                  },
                  orElse: () => <String, dynamic>{},
                );
                
                // tpdesc 필드 확인 (실제 서버 응답 필드명)
                final nombre = tipo['tpdesc']?.toString() ?? 
                               tipo['tipodesc']?.toString() ?? 
                               tipo['tipo_desc']?.toString() ?? 
                               tipo['descripcion']?.toString() ?? 
                               tipo['nombre']?.toString() ?? 
                               tipo['tipo']?.toString() ?? 
                               tipo['tipo_nombre']?.toString() ??
                               'N/A';
                return Text(nombre, style: const TextStyle(fontSize: 12));
              }).toList();
            },
            items: items,
            onChanged: (int? value) {
              setState(() {
                _selectedTipoId = value;
              });
              _loadData();
            },
          ),
        ),
      ),
    );
  }

  // Temporada 선택 UI (AppBar용)
  Widget _buildTemporadaSelector() {
    final reportColor = _getReportColor();
    
    // 현재 선택된 값이 items 리스트에 있는지 확인
    final availableIds = _temporadasList.map((temporada) {
      final id = temporada['id_temporada'] is int 
          ? temporada['id_temporada'] 
          : (temporada['id_temporada'] != null ? int.tryParse(temporada['id_temporada'].toString()) : null) ??
            (temporada['id'] is int ? temporada['id'] : (temporada['id'] != null ? int.tryParse(temporada['id'].toString()) : null));
      return id;
    }).where((id) => id != null).cast<int>().toList();
    
    final validValue = _selectedTemporadaId != null && availableIds.contains(_selectedTemporadaId)
        ? _selectedTemporadaId
        : null;
    
    // items 생성
    final items = <DropdownMenuItem<int?>>[
      const DropdownMenuItem<int?>(
        value: null,
        child: Text('Todos', style: TextStyle(fontSize: 12)),
      ),
      ..._temporadasList.map((temporada) {
        // id_temporada 또는 id 필드 확인
        final id = temporada['id_temporada'] is int 
            ? temporada['id_temporada'] 
            : (temporada['id_temporada'] != null ? int.tryParse(temporada['id_temporada'].toString()) : null) ??
              (temporada['id'] is int ? temporada['id'] : (temporada['id'] != null ? int.tryParse(temporada['id'].toString()) : null));
        // temporada_nombre, nombre, temporada 필드 확인
        final nombre = temporada['temporada_nombre']?.toString() ?? 
                      temporada['nombre']?.toString() ?? 
                      temporada['temporada']?.toString() ??
                      'N/A';
        if (id == null) return null;
        return DropdownMenuItem<int?>(
          value: id,
          child: Text(nombre, style: const TextStyle(fontSize: 12)),
        );
      }).where((item) => item != null).cast<DropdownMenuItem<int?>>().toList(),
    ];
    
    // 디버깅
    print('🔍 Temporada 콤보박스: _temporadasList.length=${_temporadasList.length}, items.length=${items.length}');
    if (_temporadasList.isNotEmpty) {
      print('   첫 번째 temporada: ${_temporadasList.first}');
    }
    
    return Tooltip(
      message: 'Filtrar por Temporada',
      child: SizedBox(
        width: 140,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButton<int?>(
            value: validValue,
            hint: const Text('Temporada', style: TextStyle(fontSize: 12, color: Colors.grey)),
            underline: const SizedBox(),
            isDense: true,
            isExpanded: true,
            icon: Icon(Icons.arrow_drop_down, color: reportColor, size: 20),
            selectedItemBuilder: (BuildContext context) {
              return items.map((item) {
                if (item.value == null) {
                  return const Text('Todos', style: TextStyle(fontSize: 12));
                }
                final temporada = _temporadasList.firstWhere(
                  (t) {
                    final id = t['id_temporada'] is int 
                        ? t['id_temporada'] 
                        : (t['id_temporada'] != null ? int.tryParse(t['id_temporada'].toString()) : null) ??
                          (t['id'] is int ? t['id'] : (t['id'] != null ? int.tryParse(t['id'].toString()) : null));
                    return id == item.value;
                  },
                  orElse: () => <String, dynamic>{},
                );
                final nombre = temporada['temporada_nombre']?.toString() ?? 
                               temporada['nombre']?.toString() ?? 
                               temporada['temporada']?.toString() ??
                               'N/A';
                return Text(nombre, style: const TextStyle(fontSize: 12));
              }).toList();
            },
            items: items,
            onChanged: (int? value) {
              setState(() {
                _selectedTemporadaId = value;
              });
              _loadData();
            },
          ),
        ),
      ),
    );
  }

  // 지점 선택 UI (AppBar용)
  Widget _buildSucursalSelector() {
    final reportColor = _getReportColor();
    
    return SizedBox(
      width: 140, // 명시적 너비 설정
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButton<String?>(
        value: _selectedSucursal,
        hint: const Text('Todos', style: TextStyle(fontSize: 12)),
        underline: const SizedBox(),
        isDense: true,
          isExpanded: false, // AppBar의 Row 안에서는 false로 설정
        icon: Icon(Icons.arrow_drop_down, color: reportColor, size: 20),
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('Todos', style: TextStyle(fontSize: 12)),
          ),
          if (_availableSucursales != null)
            ..._availableSucursales!.map((sucursal) {
              return DropdownMenuItem<String?>(
                value: sucursal,
                child: Text('Sucursal $sucursal', style: const TextStyle(fontSize: 12)),
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
              // todocodigos인 경우 id_todocodigo가 없으면 편집 불가
              if (widget.reportType == ReportType.todocodigos) {
                final idTodocodigo = codigo['id_todocodigo']?.toString();
                if (idTodocodigo == null || idTodocodigo.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('id_todocodigo가 없어서 편집할 수 없습니다.'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  return;
                }
              }
              
              setState(() {
                _selectedCodigo = Map<String, dynamic>.from(codigo);
                _isEditingCodigo = false;
                _initializeCodigoEditControllers();
              });
            },
            onCodigoDoubleTap: (codigo) {
              // todocodigos인 경우 id_todocodigo가 없으면 편집 불가
              if (widget.reportType == ReportType.todocodigos) {
                final idTodocodigo = codigo['id_todocodigo']?.toString();
                if (idTodocodigo == null || idTodocodigo.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('id_todocodigo가 없어서 편집할 수 없습니다.'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  return;
                }
              }
              
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
            editedCodigoIdentifier: _editedCodigoIdentifier,
            reportType: widget.reportType,
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

    // 편집 가능한 필드만 초기화
    final editableFields = widget.reportType == ReportType.todocodigos
        ? ['tcodigo', 'tdesc', 'tpre1', 'tpre2', 'tpre3', 'tpre4', 'tpre5', 'borrado']
        : ['codigo', 'descripcion', 'pre1', 'pre2', 'pre3', 'pre4', 'pre5', 'b_mostrar_vcontrol', 'borrado'];

    for (var field in editableFields) {
      if (!_codigoEditControllers.containsKey(field)) {
        _codigoEditControllers[field] = TextEditingController();
      }
      
      // FocusNode 초기화
      if (!_codigoFocusNodes.containsKey(field)) {
        _codigoFocusNodes[field] = FocusNode();
      }
      
      // 필드가 없으면 기본값 사용
      final value = _selectedCodigo![field];
      // boolean 필드는 1/0으로 변환
      if (field == 'b_mostrar_vcontrol' || field == 'borrado') {
        // 필드가 없으면 기본값 0 (false)
        if (value == null && !_selectedCodigo!.containsKey(field)) {
          _codigoEditControllers[field]!.text = '0';
        } else {
          _codigoEditControllers[field]!.text = (value == 1 || value == true || value?.toString() == '1') ? '1' : '0';
        }
      } else {
      _codigoEditControllers[field]!.text = value?.toString() ?? '';
      }
    }
  }
  
  // Codigo 편집 리소스 정리
  void _disposeCodigoEditResources() {
    for (var controller in _codigoEditControllers.values) {
      controller.dispose();
    }
    _codigoEditControllers.clear();
    
    for (var focusNode in _codigoFocusNodes.values) {
      focusNode.dispose();
    }
    _codigoFocusNodes.clear();
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
      reportType: widget.reportType,
      buildEditField: (fieldKey, label, order) {
        if (!_codigoEditControllers.containsKey(fieldKey)) {
          _codigoEditControllers[fieldKey] = TextEditingController();
          // 필드가 없으면 기본값 설정
          if (fieldKey == 'b_mostrar_vcontrol' || fieldKey == 'borrado') {
            final value = _selectedCodigo![fieldKey];
            if (!_selectedCodigo!.containsKey(fieldKey) || value == null) {
              _codigoEditControllers[fieldKey]!.text = '0';
            } else {
              _codigoEditControllers[fieldKey]!.text = (value == 1 || value == true || value?.toString() == '1') ? '1' : '0';
            }
          } else {
            _codigoEditControllers[fieldKey]!.text = _selectedCodigo![fieldKey]?.toString() ?? '';
          }
        }
        
        // FocusNode 초기화
        if (!_codigoFocusNodes.containsKey(fieldKey)) {
          _codigoFocusNodes[fieldKey] = FocusNode();
        }
        
        return CodigosBuilder.buildEditField(
          fieldKey: fieldKey,
          label: label,
          controller: _codigoEditControllers[fieldKey]!,
          focusNode: _codigoFocusNodes[fieldKey]!,
          order: order,
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
        reportType: widget.reportType,
      );

      // 서버 응답 확인
      if (response.containsKey('error')) {
        throw Exception(response['error'] ?? 'Error al actualizar codigo');
      }

      // 로컬 데이터 업데이트
      final dataList = _data!['data'] as List;
      final index = widget.reportType == ReportType.todocodigos
          ? dataList.indexWhere((item) => 
              item is Map<String, dynamic> && 
              item['tcodigo'] == _selectedCodigo!['tcodigo'])
          : dataList.indexWhere((item) => 
          item is Map<String, dynamic> && 
          item['codigo'] == _selectedCodigo!['codigo']);
      
      if (index != -1) {
        // 편집된 값들 수집 (편집 가능한 필드만)
        final editableFields = widget.reportType == ReportType.todocodigos
            ? ['tcodigo', 'tdesc', 'tpre1', 'tpre2', 'tpre3', 'tpre4', 'tpre5', 'borrado']
            : ['codigo', 'descripcion', 'pre1', 'pre2', 'pre3', 'pre4', 'pre5', 'b_mostrar_vcontrol', 'borrado'];
        
        final updatedData = <String, dynamic>{};
        for (var entry in _codigoEditControllers.entries) {
          final key = entry.key;
          
          // 편집 가능한 필드만 포함
          if (!editableFields.contains(key)) {
            continue;
          }
          
          final value = entry.value.text.trim();
          
          if (key.startsWith('pre') || key.startsWith('tpre')) {
            final numValue = num.tryParse(value);
            if (numValue != null) {
              updatedData[key] = numValue;
            } else if (value.isEmpty) {
              updatedData[key] = null;
            } else {
              updatedData[key] = value;
            }
          } else if (key == 'b_mostrar_vcontrol' || key == 'borrado') {
            // boolean 필드는 1 또는 0으로 변환
            updatedData[key] = (value == '1' || value.toLowerCase() == 'true') ? 1 : 0;
          } else {
            updatedData[key] = value.isEmpty ? null : value;
          }
        }

        dataList[index] = {...dataList[index] as Map<String, dynamic>, ...updatedData};
        _selectedCodigo = Map<String, dynamic>.from(dataList[index] as Map<String, dynamic>);
        _initializeCodigoEditControllers();
        
        // 편집된 codigo 식별자 저장 (색상 표시용)
        final editedIdentifier = widget.reportType == ReportType.todocodigos
            ? _selectedCodigo!['tcodigo']?.toString()
            : _selectedCodigo!['codigo']?.toString();

      setState(() {
        _isLoading = false;
        _isEditingCodigo = false;
          _selectedCodigo = null; // 편집 패널 닫기
          _editedCodigoIdentifier = editedIdentifier; // 편집된 항목 표시
        });
        
        // 3초 후 색상 표시 제거
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _editedCodigoIdentifier = null;
            });
          }
        });
      } else {
        setState(() {
          _isLoading = false;
          _isEditingCodigo = false;
          _selectedCodigo = null; // 편집 패널 닫기
        });
      }

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

  // 보고서 메뉴 아이템 빌드
  List<PopupMenuEntry<ReportType>> _buildReportMenuItems() {
    return [
      PopupMenuItem<ReportType>(
        value: ReportType.ventas,
        child: Row(
          children: [
            Icon(
              Icons.shopping_cart,
              color: widget.reportType == ReportType.ventas ? Colors.purple : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Ventas',
              style: TextStyle(
                fontWeight: widget.reportType == ReportType.ventas ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (widget.reportType == ReportType.ventas) ...[
              const Spacer(),
              const Icon(Icons.check, color: Colors.purple, size: 18),
            ],
          ],
        ),
      ),
      PopupMenuItem<ReportType>(
        value: ReportType.fventas,
        child: Row(
          children: [
            Icon(
              Icons.receipt,
              color: widget.reportType == ReportType.fventas ? Colors.deepPurple : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'FVentas',
              style: TextStyle(
                fontWeight: widget.reportType == ReportType.fventas ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (widget.reportType == ReportType.fventas) ...[
              const Spacer(),
              const Icon(Icons.check, color: Colors.deepPurple, size: 18),
            ],
          ],
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem<ReportType>(
        value: ReportType.stocks,
        child: Row(
          children: [
            Icon(
              Icons.warehouse,
              color: widget.reportType == ReportType.stocks ? Colors.orange : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Stocks',
              style: TextStyle(
                fontWeight: widget.reportType == ReportType.stocks ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (widget.reportType == ReportType.stocks) ...[
              const Spacer(),
              const Icon(Icons.check, color: Colors.orange, size: 18),
            ],
          ],
        ),
      ),
      PopupMenuItem<ReportType>(
        value: ReportType.codigos,
        child: Row(
          children: [
            Icon(
              Icons.qr_code,
              color: widget.reportType == ReportType.codigos ? Colors.teal : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Codigos',
              style: TextStyle(
                fontWeight: widget.reportType == ReportType.codigos ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (widget.reportType == ReportType.codigos) ...[
              const Spacer(),
              const Icon(Icons.check, color: Colors.teal, size: 18),
            ],
          ],
        ),
      ),
      PopupMenuItem<ReportType>(
        value: ReportType.todocodigos,
        child: Row(
          children: [
            Icon(
              Icons.qr_code_scanner,
              color: widget.reportType == ReportType.todocodigos ? Colors.cyan : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Todo Codigos',
              style: TextStyle(
                fontWeight: widget.reportType == ReportType.todocodigos ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (widget.reportType == ReportType.todocodigos) ...[
              const Spacer(),
              const Icon(Icons.check, color: Colors.cyan, size: 18),
            ],
          ],
        ),
      ),
      PopupMenuItem<ReportType>(
        value: ReportType.items,
        child: Row(
          children: [
            Icon(
              Icons.inventory_2,
              color: widget.reportType == ReportType.items ? Colors.green : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Items',
              style: TextStyle(
                fontWeight: widget.reportType == ReportType.items ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (widget.reportType == ReportType.items) ...[
              const Spacer(),
              const Icon(Icons.check, color: Colors.green, size: 18),
            ],
          ],
        ),
      ),
      PopupMenuItem<ReportType>(
        value: ReportType.ingresos,
        child: Row(
          children: [
            Icon(
              Icons.trending_up,
              color: widget.reportType == ReportType.ingresos ? Colors.indigo : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Ingresos',
              style: TextStyle(
                fontWeight: widget.reportType == ReportType.ingresos ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (widget.reportType == ReportType.ingresos) ...[
              const Spacer(),
              const Icon(Icons.check, color: Colors.indigo, size: 18),
            ],
          ],
        ),
      ),
      PopupMenuItem<ReportType>(
        value: ReportType.gastos,
        child: Row(
          children: [
            Icon(
              Icons.receipt_long,
              color: widget.reportType == ReportType.gastos ? Colors.red : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Gastos',
              style: TextStyle(
                fontWeight: widget.reportType == ReportType.gastos ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (widget.reportType == ReportType.gastos) ...[
              const Spacer(),
              const Icon(Icons.check, color: Colors.red, size: 18),
            ],
          ],
        ),
      ),
      PopupMenuItem<ReportType>(
        value: ReportType.alertas,
        child: Row(
          children: [
            Icon(
              Icons.notifications,
              color: widget.reportType == ReportType.alertas ? Colors.orange : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Alertas',
              style: TextStyle(
                fontWeight: widget.reportType == ReportType.alertas ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (widget.reportType == ReportType.alertas) ...[
              const Spacer(),
              const Icon(Icons.check, color: Colors.orange, size: 18),
            ],
          ],
        ),
      ),
    ];
  }

}


