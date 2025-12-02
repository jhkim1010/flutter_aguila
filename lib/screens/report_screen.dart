import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../l10n/app_localizations.dart';

enum ReportType {
  stocks,
  items,
  clientes,
  gastos,
  ventas,
  alertas,
}

class ReportScreen extends StatefulWidget {
  final String serverUrl;
  final ReportType reportType;

  const ReportScreen({
    super.key,
    required this.serverUrl,
    required this.reportType,
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

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService(serverUrl: widget.serverUrl);
    // 스크롤 리스너 추가 (무한 스크롤)
    _scrollController.addListener(_onScroll);
    _loadData();
  }

  @override
  void dispose() {
    _filteringWordController.dispose();
    _scrollController.dispose();
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
          // filtering word는 더 이상 사용하지 않음 (컬럼 필터 사용)
          data = await _databaseService.getStocksReport();
          break;
        case ReportType.items:
          data = await _databaseService.getItemsReport();
          break;
        case ReportType.clientes:
          data = await _databaseService.getClientesReport();
          break;
        case ReportType.gastos:
          data = await _databaseService.getGastosReport();
          break;
        case ReportType.ventas:
          data = await _databaseService.getVentasReport();
          break;
        case ReportType.alertas:
          data = await _databaseService.getAlertasReport();
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

  String _getReportTitle() {
    switch (widget.reportType) {
      case ReportType.stocks:
        return 'Stocks';
      case ReportType.items:
        return 'Items';
      case ReportType.clientes:
        return 'Clientes';
      case ReportType.gastos:
        return 'Gastos';
      case ReportType.ventas:
        return 'Ventas';
      case ReportType.alertas:
        return 'Alertas';
    }
  }

  IconData _getReportIcon() {
    switch (widget.reportType) {
      case ReportType.stocks:
        return Icons.warehouse;
      case ReportType.items:
        return Icons.inventory_2;
      case ReportType.clientes:
        return Icons.people;
      case ReportType.gastos:
        return Icons.receipt_long;
      case ReportType.ventas:
        return Icons.shopping_cart;
      case ReportType.alertas:
        return Icons.notifications;
    }
  }

  Color _getReportColor() {
    switch (widget.reportType) {
      case ReportType.stocks:
        return Colors.orange;
      case ReportType.items:
        return Colors.green;
      case ReportType.clientes:
        return Colors.purple;
      case ReportType.gastos:
        return Colors.red;
      case ReportType.ventas:
        return Colors.blue;
      case ReportType.alertas:
        return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reportTitle = _getReportTitle();
    final reportIcon = _getReportIcon();
    final reportColor = _getReportColor();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(reportIcon, color: Colors.white),
            const SizedBox(width: 8),
            Text(reportTitle),
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
    
    // 'data' 키가 있고 리스트인 경우
    if (data.containsKey('data') && data['data'] is List) {
      final dataList = data['data'] as List;
      if (dataList.isEmpty) {
        return const Center(child: Text('No data available'));
      }
      
      // 첫 번째 항목이 맵이고 여러 키를 가지고 있으면 테이블로 표시
      if (dataList.isNotEmpty && dataList.first is Map) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: _buildTableFromList(dataList),
        );
      }
      
      // 카드 형태로 표시할 때도 대량 데이터 처리
      final displayedList = dataList.take(_displayedItemsCount).toList();
      final totalCount = dataList.length;
      final hasMore = _displayedItemsCount < totalCount;
      
      return Column(
        children: [
          // 데이터 개수 표시
          if (totalCount > _itemsPerPage)
            Container(
              padding: const EdgeInsets.all(8),
              color: _getReportColor().withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Mostrando ${displayedList.length} de $totalCount items',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          // 카드 리스트
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                ...displayedList.map((item) => _buildDataCard(item)).toList(),
                if (hasMore)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
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
        padding: const EdgeInsets.all(16),
        children: [
          _buildDataMap(data['data'] as Map<String, dynamic>),
        ],
      );
    }
    
    // 'data' 키가 없고 직접 맵인 경우
    if (data is Map<String, dynamic>) {
      // 테이블 형태로 표시 가능한지 확인
      if (_isTableData(data)) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTable(data),
          ],
        );
      }
      
      return ListView(
        padding: const EdgeInsets.all(16),
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
    final viewType = (bcolorview == true) ? 'Vista Resumida' : 'Vista Detallada';
    final reportColor = _getReportColor();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _buildStocksTable(dataList, bcolorview == true),
    );
  }

  // Stocks 테이블 빌드 (bcolorview에 따라 다른 필드 사용)
  Widget _buildStocksTable(List<dynamic> dataList, bool isResumida) {
    if (dataList.isEmpty) {
      return const Center(child: Text('No data'));
    }
    
    // 필터 적용
    List<dynamic> filteredList = _applyFilters(dataList);
    
    // 정렬 적용
    filteredList = _applySort(filteredList);
    
    // 대량 데이터 처리
    final displayedList = filteredList.take(_displayedItemsCount).toList();
    final totalCount = filteredList.length;
    final hasMore = _displayedItemsCount < totalCount;
    
    // 첫 번째 항목의 키를 컬럼으로 사용
    final firstItem = displayedList.isNotEmpty 
        ? displayedList.first as Map<String, dynamic>
        : dataList.first as Map<String, dynamic>;
    
    // 필드명을 스페인어로 매핑
    final fieldNames = _getStocksFieldNames(isResumida);
    
    // 필터 UI 빌드
    final filterWidgets = _buildColumnFilters(firstItem.keys.toList(), fieldNames);
    
    // 표시할 컬럼 선택 (정렬 기능 포함)
    final columns = firstItem.keys.map((key) {
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
            _sortColumn = key;
            _sortAscending = ascending;
          });
        },
      );
    }).toList();
    
    return Column(
      children: [
        // 필터 UI
        if (filterWidgets.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.filter_list, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Filtros',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const Spacer(),
                    if (_columnFilters.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _columnFilters.clear();
                          });
                        },
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Limpiar'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: filterWidgets,
                ),
              ],
            ),
          ),
        // 데이터 개수 표시
        Container(
          padding: const EdgeInsets.all(8),
          color: _getReportColor().withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Mostrando ${displayedList.length} de $totalCount items',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_columnFilters.isNotEmpty)
                Text(
                  ' (filtrados)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
        // 테이블
        Expanded(
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    sortColumnIndex: _sortColumn != null 
                        ? firstItem.keys.toList().indexOf(_sortColumn!)
                        : null,
                    sortAscending: _sortAscending,
                    columnSpacing: 20,
                    headingRowColor: MaterialStateProperty.all(
                      _getReportColor().withOpacity(0.1),
                    ),
                    columns: columns,
                    rows: displayedList.map((item) {
                      if (item is Map<String, dynamic>) {
                        return DataRow(
                          cells: firstItem.keys.map((key) {
                            final value = item[key];
                            final formattedValue = _formatValue(value);
                            final isNumeric = _isNumeric(value);
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
                      final formattedValue = _formatValue(item);
                      final isNumeric = _isNumeric(item);
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
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
        // 더 보기 버튼
        if (hasMore)
          Padding(
            padding: const EdgeInsets.all(8.0),
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

  // 컬럼 필터 UI 빌드
  List<Widget> _buildColumnFilters(List<String> columnKeys, Map<String, String> fieldNames) {
    return columnKeys.map((key) {
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
        final cellValueStr = _formatValue(cellValue).toLowerCase();
        
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
      final aStr = _formatValue(aValue).toLowerCase();
      final bStr = _formatValue(bValue).toLowerCase();
      final comparison = aStr.compareTo(bStr);
      return _sortAscending ? comparison : -comparison;
    });
    
    return sortedList;
  }

  // Stocks 필드명 매핑 (스페인어)
  Map<String, String> _getStocksFieldNames(bool isResumida) {
    if (isResumida) {
      // Vista Resumida 필드명
      return {
        'tcode': 'Código',
        'tdesc': 'Descripción',
        'first_date': 'Primera Fecha',
        'last_date': 'Última Fecha',
        'pre1': 'Precio 1',
        'pre2': 'Precio 2',
        'pre3': 'Precio 3',
        'pre4': 'Precio 4',
        'pre5': 'Precio 5',
        'totaling3': 'Total Ingreso',
        'totalventa3': 'Total Venta',
        'todaying3': 'Ingreso Hoy',
        'todayvnt3': 'Venta Hoy',
        'totalreservado3': 'Total Reservado',
        'cntoffset3': 'Cnt Offset',
        'stockreal3': 'Stock Real',
        'porcentaje': 'Porcentaje',
        'sucursal': 'Sucursal',
        'ref_id_todocodigo': 'Ref ID',
      };
    } else {
      // Vista Detallada 필드명
      return {
        'codigo': 'Código',
        'descripcion': 'Descripción',
        'first_date': 'Primera Fecha',
        'last_date': 'Última Fecha',
        'pre1': 'Precio 1',
        'pre2': 'Precio 2',
        'pre3': 'Precio 3',
        'pre4': 'Precio 4',
        'pre5': 'Precio 5',
        'totaling': 'Total Ingreso',
        'totalventa': 'Total Venta',
        'todayingreso': 'Ingreso Hoy',
        'todayventa': 'Venta Hoy',
        'totalreservado': 'Total Reservado',
        'cntoffset': 'Cnt Offset',
        'stockreal': 'Stock Real',
        'porcentaje': 'Porcentaje',
        'sucursal': 'Sucursal',
        'id_codigo1': 'ID Código',
      };
    }
  }

  // Filtering word 입력 필드
  Widget _buildFilteringWordField() {
    final reportColor = _getReportColor();
    
    return Container(
      padding: const EdgeInsets.all(16),
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
          Expanded(
            child: TextField(
              controller: _filteringWordController,
              decoration: InputDecoration(
                labelText: 'Filtering Word',
                hintText: '검색어를 입력하세요',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _filteringWordController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _filteringWordController.clear();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {});
              },
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _loadData(filteringWord: value);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              final filteringWord = _filteringWordController.text.trim();
              _loadData(filteringWord: filteringWord.isEmpty ? null : filteringWord);
            },
            icon: const Icon(Icons.search),
            label: const Text('검색'),
            style: ElevatedButton.styleFrom(
              backgroundColor: reportColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ],
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
        // 데이터 개수 표시
        if (totalCount > _itemsPerPage)
          Container(
            padding: const EdgeInsets.all(8),
            color: _getReportColor().withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Mostrando ${displayedList.length} de $totalCount items',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        // 테이블 (가상 스크롤 사용)
        Expanded(
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 20,
                  headingRowColor: MaterialStateProperty.all(
                    _getReportColor().withOpacity(0.1),
                  ),
                  columns: columns,
                  rows: displayedList.map((item) {
                    if (item is Map<String, dynamic>) {
                      return DataRow(
                        cells: firstItem.keys.map((key) {
                          final value = item[key];
                          final formattedValue = _formatValue(value);
                          final isNumeric = _isNumeric(value);
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
                    final formattedValue = _formatValue(item);
                    final isNumeric = _isNumeric(item);
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
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
        // 더 보기 버튼 또는 로딩 인디케이터
        if (hasMore)
          Padding(
            padding: const EdgeInsets.all(8.0),
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

  Widget _buildDataCard(dynamic item) {
    if (item is Map<String, dynamic>) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: item.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
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
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        _formatValue(entry.value),
                        textAlign: _isNumeric(entry.value) ? TextAlign.right : TextAlign.left,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      );
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(item.toString()),
      ),
    );
  }

  Widget _buildDataMap(Map<String, dynamic> data) {
    // 테이블 형태로 표시할 수 있는 데이터인지 확인
    if (_isTableData(data)) {
      return _buildTable(data);
    }

    // 카드 형태로 표시
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: data.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
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
      ),
    );
  }

  Widget _buildValueWidget(dynamic value) {
    if (value is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: (value as Map<String, dynamic>).entries.map((entry) {
          final formattedValue = _formatValue(entry.value);
          final isNumeric = _isNumeric(entry.value);
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
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
          final formattedValue = _formatValue(entry.value);
          final isNumeric = _isNumeric(entry.value);
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${entry.key + 1}. $formattedValue',
              textAlign: isNumeric ? TextAlign.right : TextAlign.left,
              style: const TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
      );
    }
    final formattedValue = _formatValue(value);
    final isNumeric = _isNumeric(value);
    return Text(
      formattedValue,
      textAlign: isNumeric ? TextAlign.right : TextAlign.left,
      style: const TextStyle(fontSize: 16),
    );
  }

  bool _isTableData(Map<String, dynamic> data) {
    // 모든 값이 리스트인 경우 테이블로 표시
    return data.values.every((value) => value is List);
  }

  Widget _buildTable(Map<String, dynamic> data) {
    final columns = data.keys.map((key) {
      return DataColumn(
        label: Text(
          key.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }).toList();

    // 첫 번째 컬럼의 길이를 기준으로 행 수 결정
    final firstKey = data.keys.first;
    final rowCount = (data[firstKey] as List).length;

    final rows = List.generate(rowCount, (index) {
      return DataRow(
        cells: data.keys.map((key) {
          final value = data[key];
          if (value is List && index < value.length) {
            final cellValue = value[index];
            final formattedValue = _formatValue(cellValue);
            final isNumeric = _isNumeric(cellValue);
            return DataCell(
              Text(
                formattedValue,
                textAlign: isNumeric ? TextAlign.right : TextAlign.left,
              ),
            );
          }
          return const DataCell(Text(''));
        }).toList(),
      );
    });

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          headingRowColor: MaterialStateProperty.all(
            _getReportColor().withOpacity(0.1),
          ),
          columns: columns,
          rows: rows,
        ),
      ),
    );
  }

  // 숫자인지 확인하는 헬퍼 함수
  bool _isNumeric(dynamic value) {
    if (value == null) return false;
    if (value is num) return true;
    if (value is String) {
      // 숫자로 변환 가능한 문자열인지 확인
      return double.tryParse(value) != null || int.tryParse(value) != null;
    }
    return false;
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'N/A';
    if (value is num) {
      // 숫자는 천 단위 구분자만 사용 (통화 기호 없음)
      return NumberFormat('#,###').format(value);
    }
    if (value is DateTime) {
      return DateFormat('yyyy-MM-dd HH:mm').format(value);
    }
    if (value is String) {
      // 문자열에서 $ 기호 제거
      String cleanedValue = value.replaceAll('\$', '').trim();
      
      // 숫자로 변환 가능한 문자열인지 확인
      final numValue = num.tryParse(cleanedValue.replaceAll(',', ''));
      if (numValue != null) {
        // 숫자로 변환 가능하면 천 단위 구분자로 포맷팅
        return NumberFormat('#,###').format(numValue);
      }
      
      // 긴 문자열은 자르기
      if (cleanedValue.length > 50) {
        return '${cleanedValue.substring(0, 50)}...';
      }
      
      return cleanedValue;
    }
    // 다른 타입은 문자열로 변환하고 $ 기호 제거
    String strValue = value.toString();
    return strValue.replaceAll('\$', '').trim();
  }

  // 숫자면 오른쪽 정렬, 아니면 기본 정렬로 Text 위젯 생성
  Widget _buildTextWidget(String text, {bool isNumeric = false}) {
    return Text(
      text,
      textAlign: isNumeric ? TextAlign.right : TextAlign.left,
      style: const TextStyle(fontSize: 16),
    );
  }
}

