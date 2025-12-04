import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/report_utils.dart';
import '../widgets/items_date_range_selector.dart';
import '../widgets/report_table_builder.dart';

export '../widgets/report_utils.dart' show ReportType;

class ReportScreen extends StatefulWidget {
  final String serverUrl;
  final ReportType reportType;
  final DateTime? initialDate; // ventas report용 초기 날짜

  const ReportScreen({
    super.key,
    required this.serverUrl,
    required this.reportType,
    this.initialDate,
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
  // Ventas 보고서용 날짜
  DateTime? _ventasDate;
  
  // Codigos 보고서용 상태
  Map<String, dynamic>? _selectedCodigo; // 선택된 codigo
  final Map<String, TextEditingController> _codigoEditControllers = {}; // 편집용 컨트롤러들
  bool _isEditingCodigo = false; // 편집 모드 여부

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService(serverUrl: widget.serverUrl);
    // 스크롤 리스너 추가 (무한 스크롤)
    _scrollController.addListener(_onScroll);
    // Items 보고서의 경우 기본 날짜 설정 (오늘 날짜)
    if (widget.reportType == ReportType.items) {
      final now = DateTime.now();
      _itemsStartDate = now;
      _itemsEndDate = now;
    }
    // Ventas 보고서의 경우 초기 날짜 설정
    if (widget.reportType == ReportType.ventas && widget.initialDate != null) {
      _ventasDate = widget.initialDate;
    }
    _loadData();
  }

  @override
  void dispose() {
    _filteringWordController.dispose();
    _scrollController.dispose();
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
          // filteringWord는 클라이언트 측에서 처리하므로 서버로 전송하지 않음
          data = await _databaseService.getStocksReport();
          break;
        case ReportType.items:
          // items 보고서는 항상 날짜 범위가 필요함 (기본값: 오늘부터 오늘까지)
          final now = DateTime.now();
          final startDate = _itemsStartDate ?? now;
          final endDate = _itemsEndDate ?? now;
          
          final filters = <String, dynamic>{
            'fecha_inicio': DateFormat('yyyy-MM-dd').format(startDate),
            'fecha_fin': DateFormat('yyyy-MM-dd').format(endDate),
          };
          data = await _databaseService.getItemsReport(filters: filters);
          break;
        case ReportType.clientes:
          data = await _databaseService.getClientesReport();
          break;
        case ReportType.gastos:
          data = await _databaseService.getGastosReport();
          break;
        case ReportType.ventas:
          // 날짜 필터가 있으면 날짜 범위로 전달 (해당 날짜의 시작부터 끝까지)
          final filters = _ventasDate != null
              ? <String, dynamic>{
                  'fecha_inicio': DateFormat('yyyy-MM-dd').format(_ventasDate!),
                  'fecha_fin': DateFormat('yyyy-MM-dd').format(_ventasDate!),
                }
              : null;
          data = await _databaseService.getVentasReport(filters: filters);
          break;
        case ReportType.alertas:
          data = await _databaseService.getAlertasReport();
          break;
        case ReportType.codigos:
          data = await _databaseService.getCodigos();
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
      String errorMessage = '알 수 없는 오류가 발생했습니다.';
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

  // 스크롤 이벤트 처리 (무한 스크롤)
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      // 스크롤이 80% 이상 내려갔을 때 더 많은 데이터 로드
      _loadMoreItems();
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
    if (_data == null) return const SizedBox.shrink();
    
    int totalCount = 0;
    if (_data!.containsKey('data') && _data!['data'] is List) {
      totalCount = (_data!['data'] as List).length;
    }
    
    return Text(
      'Total: $totalCount',
      style: const TextStyle(
        fontSize: 11,
        color: Colors.white70,
        fontWeight: FontWeight.normal,
      ),
    );
  }

  // Items 보고서용 필터 섹션 (데이터 개수 + 날짜 범위 + 필터링)
  Widget _buildItemsFilterSection() {
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: _getReportColor().withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: _getReportColor().withOpacity(0.3),
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
            : widget.reportType == ReportType.items
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
                    : widget.reportType == ReportType.codigos
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
                  : Column(
                      children: [
                        // Items 보고서의 날짜 범위 선택 UI 및 필터링
                        if (widget.reportType == ReportType.items)
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
  }

  Widget _buildReportContent() {
    if (_data == null) {
      return const Center(child: Text('No data'));
    }

    // 데이터 구조 분석 및 적절한 위젯 반환
    final data = _data!;
    
    // Stocks 보고서의 경우 특별 처리
    if (widget.reportType == ReportType.stocks && 
        data.containsKey('data') && 
        data['data'] is List) {
      return _buildStocksContent(data);
    }
    
    // Codigos 보고서의 경우 특별 처리
    if (widget.reportType == ReportType.codigos && 
        data.containsKey('data') && 
        data['data'] is List) {
      return _buildCodigosContent(data);
    }
    
    // 'data' 키가 있고 리스트인 경우
    if (data.containsKey('data') && data['data'] is List) {
      final dataList = data['data'] as List;
      if (dataList.isEmpty) {
        return const Center(child: Text('No data available'));
      }
      
      // 첫 번째 항목이 맵이고 여러 키를 가지고 있으면 테이블로 표시
      if (dataList.isNotEmpty && dataList.first is Map) {
        // Items 보고서의 경우 filteringWord 필터 적용
        List<dynamic> filteredDataList = dataList;
        if (widget.reportType == ReportType.items) {
          final filteringWord = _filteringWordController.text.trim().toLowerCase();
          if (filteringWord.isNotEmpty) {
            filteredDataList = dataList.where((item) {
              if (item is Map<String, dynamic>) {
                final codigo1 = item['codigo1']?.toString().toLowerCase() ?? '';
                final desc1 = item['desc1']?.toString().toLowerCase() ?? '';
                return codigo1.contains(filteringWord) || desc1.contains(filteringWord);
              }
              return false;
            }).toList();
          }
        }
        // Ventas 보고서의 경우 날짜 필터 적용 (클라이언트 측)
        if (widget.reportType == ReportType.ventas && _ventasDate != null) {
          final targetDateStr = DateFormat('yyyy-MM-dd').format(_ventasDate!);
          filteredDataList = filteredDataList.where((item) {
            if (item is Map<String, dynamic>) {
              // 여러 가능한 날짜 필드명 확인
              final fecha = item['fecha']?.toString() ?? 
                          item['fecha_venta']?.toString() ?? 
                          item['fechaVenta']?.toString() ?? '';
              
              if (fecha.isNotEmpty) {
                try {
                  // 날짜 문자열을 파싱하여 비교
                  final itemDate = DateTime.parse(fecha);
                  final itemDateStr = DateFormat('yyyy-MM-dd').format(itemDate);
                  return itemDateStr == targetDateStr;
                } catch (e) {
                  // 날짜 파싱 실패 시 문자열 직접 비교
                  return fecha.startsWith(targetDateStr);
                }
              }
            }
            return false;
          }).toList();
        }
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
        // Codigos 보고서의 경우 filteringWord 필터 적용
        if (widget.reportType == ReportType.codigos) {
          final filteringWord = _filteringWordController.text.trim().toLowerCase();
          if (filteringWord.isNotEmpty) {
            filteredDataList = filteredDataList.where((item) {
              if (item is Map<String, dynamic>) {
                final codigo = item['codigo']?.toString().toLowerCase() ?? '';
                final descripcion = item['descripción']?.toString().toLowerCase() ?? 
                                   item['descripcion']?.toString().toLowerCase() ?? '';
                return codigo.contains(filteringWord) || descripcion.contains(filteringWord);
              }
              return false;
            }).toList();
          }
        }
        if (widget.reportType == ReportType.items) {
          
          // Items 보고서의 경우 정렬 적용
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
          
          return ReportTableBuilder.buildTableFromList(
            sortedDataList,
            _displayedItemsCount,
            _itemsPerPage,
            _scrollController,
            widget.reportType,
            sortColumn: _sortColumn,
            sortAscending: _sortAscending,
            onSort: (columnIndex, ascending) {
              setState(() {
                // 키 목록을 정렬된 데이터에서 가져오기 (report_table_builder와 동일한 순서 보장)
                final keys = sortedDataList.isNotEmpty 
                    ? (sortedDataList.first as Map<String, dynamic>).keys.toList()
                    : <String>[];
                if (columnIndex >= 0 && columnIndex < keys.length) {
                  final key = keys[columnIndex];
                  if (_sortColumn == key) {
                    // 같은 칼럼을 클릭하면 정렬 방향 변경
                    _sortAscending = !_sortAscending;
                  } else {
                    // 다른 칼럼을 클릭하면 새 칼럼으로 정렬
                    _sortColumn = key;
                    _sortAscending = true;
                  }
                  // 정렬이 변경되면 처음부터 다시 표시
                  _displayedItemsCount = _itemsPerPage;
                }
              });
            },
          );
        }
        
        return ReportTableBuilder.buildTableFromList(
          filteredDataList,
          _displayedItemsCount,
          _itemsPerPage,
          _scrollController,
          widget.reportType,
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
    
    return const Center(child: Text('Unknown data format'));
  }

  // Stocks 보고서의 vista 타입 표시
  Widget _buildStocksViewType() {
    if (_data == null || !_data!.containsKey('filters')) {
      return const SizedBox.shrink();
    }
    
    final filters = _data!['filters'] as Map<String, dynamic>?;
    if (filters == null || !filters.containsKey('bcolorview')) {
      return const SizedBox.shrink();
    }
    
    final bcolorview = filters['bcolorview'];
    final viewType = (bcolorview == true) ? 'Vista Resumida' : 'VistaD';
    final reportColor = _getReportColor();
    
    // Vista Detallada일 때만 sucursal 필터 표시
    final bool showSucursalFilter = (bcolorview == false);
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
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        color: reportColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            bcolorview == true ? Icons.view_compact : Icons.view_list,
            color: reportColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            viewType,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: reportColor,
            ),
          ),
          // Sucursal이 2개 이상일 때만 콤보박스 표시
          if (showSucursalFilter && sucursales != null && sucursales.length > 1)
            ...[
              const SizedBox(width: 16),
              // ComboBox로 변경
              Container(
                constraints: const BoxConstraints(minWidth: 100),
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButton<String?>(
                  value: _selectedSucursal,
                  hint: const Text('모두', style: TextStyle(fontSize: 12)),
                  underline: const SizedBox(),
                  isDense: true,
                  icon: Icon(Icons.arrow_drop_down, color: reportColor, size: 20),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('모두', style: TextStyle(fontSize: 12)),
                    ),
                    ...sucursales.map((sucursal) {
                      return DropdownMenuItem<String?>(
                        value: sucursal,
                        child: Text(sucursal, style: const TextStyle(fontSize: 12)),
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
          if (_data!.containsKey('summary'))
            const Spacer(),
          if (_data!.containsKey('summary'))
            Text(
              'Total: ${_data!['summary']['total_items'] ?? 0}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  // Stocks 보고서 전용 콘텐츠 빌드
  Widget _buildStocksContent(Map<String, dynamic> data) {
    final dataList = data['data'] as List;
    if (dataList.isEmpty) {
      return const Center(child: Text('No data available'));
    }
    
    final filters = data['filters'] as Map<String, dynamic>?;
    final bcolorview = filters?['bcolorview'] ?? false;
    
    // bcolorview에 따라 다른 필드 매핑 사용
    return _buildStocksTable(dataList, bcolorview == true);
  }

  // Stocks 테이블 빌드 (bcolorview에 따라 다른 필드 사용)
  Widget _buildStocksTable(List<dynamic> dataList, bool isResumida) {
    if (dataList.isEmpty) {
      return const Center(child: Text('No data'));
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
              // 다른 칼럼을 클릭하면 새 칼럼으로 정렬
              _sortColumn = key;
              _sortAscending = true;
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

  // Ventas report 헤더 (날짜 및 sucursal 선택)
  Widget _buildVentasHeader() {
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
        // 날짜 표시 및 선택
        GestureDetector(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _ventasDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
              locale: const Locale('ko', 'KR'),
            );
            
            if (picked != null && picked != _ventasDate) {
              setState(() {
                _ventasDate = picked;
              });
              _loadData();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  _ventasDate != null
                      ? DateFormat('yyyy-MM-dd').format(_ventasDate!)
                      : '날짜',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
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

  // Filtering word 입력 필드 (AppBar용)
  Widget _buildFilteringWordFieldInAppBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _filteringWordController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Filtrar...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          prefixIcon: const Icon(Icons.search, color: Colors.white, size: 20),
          suffixIcon: _filteringWordController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white, size: 18),
                  onPressed: () {
                    setState(() {
                      _filteringWordController.clear();
                      // 클라이언트 측 필터링만 초기화
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              : null,
        ),
        onChanged: (value) {
          setState(() {});
        },
        onSubmitted: (value) {
          // 클라이언트 측에서만 필터링 (codigo, descripcion에서 검색)
          setState(() {
            // filteringWord는 클라이언트 측에서만 사용하므로 서버 요청 없이 UI만 업데이트
          });
        },
      ),
    );
  }

  Widget _buildTableFromList(List<dynamic> dataList) {
    if (dataList.isEmpty) {
      return const Center(child: Text('No data'));
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
        contentPadding: EdgeInsets.zero,
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
    return Container(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.entries.map((entry) {
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
                  child: _buildValueWidget(entry.value),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildValueWidget(dynamic value) {
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

    // filteringWord 필터 적용
    List<dynamic> filteredDataList = dataList;
    final filteringWord = _filteringWordController.text.trim().toLowerCase();
    if (filteringWord.isNotEmpty) {
      filteredDataList = dataList.where((item) {
        if (item is Map<String, dynamic>) {
          final codigo = item['codigo']?.toString().toLowerCase() ?? '';
          final descripcion = item['descripción']?.toString().toLowerCase() ?? 
                             item['descripcion']?.toString().toLowerCase() ?? '';
          return codigo.contains(filteringWord) || descripcion.contains(filteringWord);
        }
        return false;
      }).toList();
    }

    return Row(
      children: [
        // 왼쪽: Codigos 리스트
        Expanded(
          flex: _selectedCodigo != null ? 1 : 1,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: _selectedCodigo != null 
                    ? BorderSide(color: Colors.grey[300]!, width: 1)
                    : BorderSide.none,
              ),
            ),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: filteredDataList.length,
              itemBuilder: (context, index) {
                final codigo = filteredDataList[index] as Map<String, dynamic>;
                final isSelected = _selectedCodigo != null && 
                    _selectedCodigo!['codigo'] == codigo['codigo'];
                
                return ListTile(
                  title: Text(
                    codigo['codigo']?.toString() ?? 'N/A',
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    codigo['descripción']?.toString() ?? 
                    codigo['descripcion']?.toString() ?? 
                    'N/A',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: isSelected,
                  selectedTileColor: Colors.teal.withOpacity(0.1),
                  onTap: () {
                    setState(() {
                      _selectedCodigo = Map<String, dynamic>.from(codigo);
                      _isEditingCodigo = false;
                      // 편집 컨트롤러 초기화
                      _initializeCodigoEditControllers();
                    });
                  },
                );
              },
            ),
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

  // Codigo 편집 컨트롤러 초기화
  void _initializeCodigoEditControllers() {
    if (_selectedCodigo == null) return;

    final fields = [
      'codigo',
      'descripción', // descripción을 기본으로 사용
      'pre1',
      'pre2',
      'pre3',
      'pre4',
      'pre5',
      'borrado',
      'id_woocommerce',
      'id_woocommerce_producto',
    ];

    for (var field in fields) {
      if (!_codigoEditControllers.containsKey(field)) {
        _codigoEditControllers[field] = TextEditingController();
      }
      
      // descripción 필드는 descripcion도 확인
      dynamic value;
      if (field == 'descripción') {
        value = _selectedCodigo!['descripción'] ?? 
                _selectedCodigo!['descripcion'];
      } else {
        value = _selectedCodigo![field];
      }
      
      _codigoEditControllers[field]!.text = value?.toString() ?? '';
    }
  }

  // Codigo 편집 패널 빌드
  Widget _buildCodigoEditPanel() {
    if (_selectedCodigo == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Editar Codigo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _getReportColor(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _selectedCodigo = null;
                    _isEditingCodigo = false;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCodigoEditField('codigo', 'Codigo'),
                  const SizedBox(height: 12),
                  _buildCodigoEditField('descripción', 'Descripción'),
                  const SizedBox(height: 12),
                  _buildCodigoEditField('pre1', 'Precio 1'),
                  const SizedBox(height: 12),
                  _buildCodigoEditField('pre2', 'Precio 2'),
                  const SizedBox(height: 12),
                  _buildCodigoEditField('pre3', 'Precio 3'),
                  const SizedBox(height: 12),
                  _buildCodigoEditField('pre4', 'Precio 4'),
                  const SizedBox(height: 12),
                  _buildCodigoEditField('pre5', 'Precio 5'),
                  const SizedBox(height: 12),
                  _buildCodigoEditField('borrado', 'Borrado'),
                  const SizedBox(height: 12),
                  _buildCodigoEditField('id_woocommerce', 'ID WooCommerce'),
                  const SizedBox(height: 12),
                  _buildCodigoEditField('id_woocommerce_producto', 'ID WooCommerce Producto'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _saveCodigoChanges,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getReportColor(),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Codigo 편집 필드 빌드
  Widget _buildCodigoEditField(String fieldKey, String label) {
    // descripción과 descripcion 필드는 같은 컨트롤러 사용
    String actualKey = fieldKey;
    if (fieldKey == 'descripcion') {
      actualKey = 'descripción'; // descripción을 기본으로 사용
    }
    
    if (!_codigoEditControllers.containsKey(actualKey)) {
      _codigoEditControllers[actualKey] = TextEditingController();
    }
    
    final controller = _codigoEditControllers[actualKey]!;

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

      // 편집된 값들 수집
      final updatedData = <String, dynamic>{};
      for (var entry in _codigoEditControllers.entries) {
        final key = entry.key;
        final value = entry.value.text.trim();
        
        // 숫자 필드는 숫자로 변환 시도
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

      // descripción 필드를 descripcion으로도 전송 (서버 호환성)
      if (updatedData.containsKey('descripción')) {
        updatedData['descripcion'] = updatedData['descripción'];
      }

      // 서버에 업데이트 요청
      await _databaseService.updateCodigo(
        _selectedCodigo!['codigo']?.toString() ?? '',
        updatedData,
      );

      // 로컬 데이터 업데이트
      final dataList = _data!['data'] as List;
      final index = dataList.indexWhere((item) => 
          item is Map<String, dynamic> && 
          item['codigo'] == _selectedCodigo!['codigo']);
      
      if (index != -1) {
        dataList[index] = {...dataList[index] as Map<String, dynamic>, ...updatedData};
        _selectedCodigo = Map<String, dynamic>.from(dataList[index] as Map<String, dynamic>);
      }

      setState(() {
        _isLoading = false;
        _isEditingCodigo = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Codigo actualizado exitosamente'),
            backgroundColor: Colors.green,
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

