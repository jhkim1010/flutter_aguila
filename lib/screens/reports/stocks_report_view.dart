import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/database_service.dart';
import '../../services/pdf_service.dart';
import '../../services/excel_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/report_utils.dart';
import '../../widgets/report_filters.dart';
import '../../widgets/report_filter_widgets.dart';
import '../../widgets/report_total_row_builder.dart';
import '../../widgets/stocks_builder.dart';
import '../../widgets/resizable_data_table.dart';
import '../../services/stocks_column_width_storage.dart';
import 'report_view_connector.dart';

/// Stocks 보고서 전용 화면/로직. ReportScreen(셸)에서 라우팅 시 사용.
class StocksReportView extends StatefulWidget {
  final String serverUrl;
  final String? initialFilteringWord;
  final String? initialSortColumn;
  final bool? initialSortAscending;
  final Function(String?, String?, bool?)? onStateChanged;
  final bool useFullWidth;
  final VoidCallback? onMenuPressed;
  final List<String>? initialAvailableSucursales;
  final RegisterShareCallback? registerShare;
  /// AppBar에 필터 바(tipos, temporada, filtering word)를 넣을 때 호출. ReportScreen이 전달.
  final void Function(Widget filterBar)? onFilterBarReady;

  const StocksReportView({
    super.key,
    required this.serverUrl,
    this.initialFilteringWord,
    this.initialSortColumn,
    this.initialSortAscending,
    this.onStateChanged,
    this.useFullWidth = false,
    this.onMenuPressed,
    this.initialAvailableSucursales,
    this.registerShare,
    this.onFilterBarReady,
  });

  @override
  State<StocksReportView> createState() => _StocksReportViewState();
}

class _StocksReportViewState extends State<StocksReportView> {
  late final DatabaseService _databaseService;
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _filteringWordController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _tiposList = [];
  List<Map<String, dynamic>> _temporadasList = [];
  int? _selectedTipoId;
  int? _selectedTemporadaId;
  String? _stocksSortColumn = 'codigo';
  bool _stocksSortAscending = true;
  String? _stocksNextMaxUtime;
  bool _stocksHasMore = false;
  bool _isLoadingMoreStocks = false;
  String? _selectedSucursal;
  String? _selectedStocksColorCode;
  Map<String, double>? _stocksColumnWidths;
  String? _stocksColumnWidthsDbKey;

  Color get _reportColor => ReportUtils.getReportColor(ReportType.stocks);

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService(serverUrl: widget.serverUrl);
    _scrollController.addListener(_onScroll);
    _filteringWordController.addListener(_onFilteringWordChangedDebounced);
    if (widget.initialFilteringWord != null && widget.initialFilteringWord!.isNotEmpty) {
      _filteringWordController.text = widget.initialFilteringWord!;
    }
    if (widget.initialSortColumn != null) {
      _stocksSortColumn = widget.initialSortColumn;
      _stocksSortAscending = widget.initialSortAscending ?? true;
    }
    _loadTiposAndTemporadas();
    _loadData();
  }

  Timer? _filteringWordDebounceTimer;
  void _onFilteringWordChangedDebounced() {
    _filteringWordDebounceTimer?.cancel();
    _filteringWordDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _reloadDataWithFilters();
      }
    });
  }

  @override
  void dispose() {
    _filteringWordDebounceTimer?.cancel();
    _databaseService.dispose();
    _filteringWordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTiposAndTemporadas() async {
    try {
      final tipos = await _databaseService.getTipos();
      final temporadas = await _databaseService.getTemporadas();
      if (mounted) {
        setState(() {
          _tiposList = tipos;
          _temporadasList = temporadas;
        });
      }
    } catch (e) {
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadData({String? filteringWord}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final currentFilteringWord = filteringWord ?? _filteringWordController.text.trim();
      final filters = <String, dynamic>{};
      if (_selectedTipoId != null) filters['tipo_id'] = _selectedTipoId;
      if (_selectedTemporadaId != null) filters['temporada_id'] = _selectedTemporadaId;
      if (_selectedStocksColorCode != null) filters['color_id'] = _selectedStocksColorCode;
      if (_selectedSucursal != null) filters['sucursal'] = _selectedSucursal;

      final data = await _databaseService.getStocksReport(
        filteringWord: currentFilteringWord.isNotEmpty ? currentFilteringWord : null,
        sortColumn: _stocksSortColumn,
        sortAscending: _stocksSortAscending,
        filters: filters.isNotEmpty ? filters : null,
      );
      if (data.containsKey('pagination') && data['pagination'] is Map) {
        final pagination = data['pagination'] as Map<String, dynamic>;
        _stocksHasMore = pagination['hasMore'] == true;
        _stocksNextMaxUtime = pagination['nextMaxUtime']?.toString();
      } else {
        _stocksHasMore = false;
      }
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
        _notifyStateChanged();
        if (_data != null && _data!.isNotEmpty) {
          widget.registerShare?.call(_shareReport);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _reloadDataWithFilters() async {
    ReportTotalRowBuilder.clearCache();
    _stocksNextMaxUtime = null;
    _stocksHasMore = false;
    await _loadData();
  }

  void _notifyStateChanged() {
    if (widget.onStateChanged != null) {
      widget.onStateChanged!(
        _filteringWordController.text.trim().isEmpty ? null : _filteringWordController.text.trim(),
        _stocksSortColumn,
        _stocksSortAscending,
      );
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      _loadNextStocksPage();
    }
  }

  Future<void> _loadNextStocksPage() async {
    if (!_stocksHasMore || _stocksNextMaxUtime == null || _isLoadingMoreStocks) return;
    setState(() => _isLoadingMoreStocks = true);
    try {
      final filteringWord = _filteringWordController.text.trim();
      final filters = <String, dynamic>{};
      if (_selectedTipoId != null) filters['tipo_id'] = _selectedTipoId;
      if (_selectedTemporadaId != null) filters['temporada_id'] = _selectedTemporadaId;
      if (_selectedStocksColorCode != null) filters['color_id'] = _selectedStocksColorCode;
      if (_selectedSucursal != null) filters['sucursal'] = _selectedSucursal;

      final response = await _databaseService.getStocksReport(
        maxUtime: _stocksNextMaxUtime,
        filteringWord: filteringWord.isNotEmpty ? filteringWord : null,
        sortColumn: _stocksSortColumn,
        sortAscending: _stocksSortAscending,
        filters: filters.isNotEmpty ? filters : null,
      );
      if (response.containsKey('data') && response['data'] is List && _data != null && _data!.containsKey('data')) {
        final newData = response['data'] as List;
        final currentData = _data!['data'] as List;
        setState(() {
          _data = { ..._data!, 'data': [...currentData, ...newData] };
        });
      }
      if (response.containsKey('pagination') && response['pagination'] is Map) {
        final pagination = response['pagination'] as Map<String, dynamic>;
        _stocksHasMore = pagination['hasMore'] == true;
        _stocksNextMaxUtime = pagination['nextMaxUtime']?.toString();
      } else {
        _stocksHasMore = false;
      }
    } catch (e) {
      debugPrint('StocksReportView _loadNextStocksPage error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingMoreStocks = false);
    }
  }

  Future<void> _shareReport() async {
    if (_data == null) return;
    if (Platform.isMacOS || Platform.isWindows) {
      _shareAsExcel();
    } else {
      _shareAsPdf();
    }
  }

  Future<void> _shareAsPdf() async {
    if (_data == null) return;
    try {
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
      final filteringWord = _filteringWordController.text.trim();
      final pdfFile = await PdfService.generateReportPdf(
        reportType: ReportType.stocks,
        data: _data!,
        startDate: null,
        endDate: null,
        filteringWord: filteringWord.isEmpty ? null : filteringWord,
        displayedColumns: null,
      );
      if (mounted) Navigator.of(context).pop();
      if (mounted) await Share.shareXFiles([XFile(pdfFile.path)]);
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _shareAsExcel() async {
    if (_data == null) return;
    try {
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
                  Text('Generando Excel...'),
                ],
              ),
            ),
          ),
        ),
      );
      final filteringWord = _filteringWordController.text.trim();
      final excelFile = await ExcelService.generateReportExcel(
        reportType: ReportType.stocks,
        data: _data!,
        startDate: null,
        endDate: null,
        filteringWord: filteringWord.isEmpty ? null : filteringWord,
        displayedColumns: null,
      );
      if (mounted) Navigator.of(context).pop();
      if (mounted) await Share.shareXFiles([XFile(excelFile.path)]);
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildTipoSelector() {
    return ReportFilterWidgets.buildTipoSelector(
      tiposList: _tiposList,
      selectedTipoId: _selectedTipoId,
      onChanged: (int? value) {
        setState(() => _selectedTipoId = value);
        _loadData();
      },
      reportColor: _reportColor,
    );
  }

  Widget _buildTemporadaSelector() {
    return ReportFilterWidgets.buildTemporadaSelector(
      temporadasList: _temporadasList,
      selectedTemporadaId: _selectedTemporadaId,
      onChanged: (int? value) {
        setState(() => _selectedTemporadaId = value);
        _loadData();
      },
      reportColor: _reportColor,
    );
  }

  Widget _buildFilteringWordField() {
    return ReportFilters.buildFilteringWordField(
      controller: _filteringWordController,
      onSubmitted: (_) => _reloadDataWithFilters(),
      onClear: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _filteringWordController.clear();
        });
      },
      forLightBackground: true, // 본문은 밝은 배경이라 진한 글자/테두리로 보이게
    );
  }

  Widget _buildStocksViewType() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) return const SizedBox.shrink();
        Color stocksColor = Colors.orange;
        if (_data != null) {
          if (_data!.containsKey('filters') && _data!['filters'] is Map) {
            final filters = _data!['filters'] as Map<String, dynamic>;
            stocksColor = ReportUtils.isBcolorviewEnabled(filters['bcolorview']) ? Colors.orange : Colors.lightBlue;
          } else if (_data!.containsKey('bcolorview')) {
            stocksColor = ReportUtils.isBcolorviewEnabled(_data!['bcolorview']) ? Colors.orange : Colors.lightBlue;
          }
        }
        return StocksBuilder.buildViewType(
          data: _data,
          selectedSucursal: _selectedSucursal,
          onSucursalChanged: (value) => setState(() => _selectedSucursal = value),
          reportColor: stocksColor,
        );
      },
    );
  }

  Widget _buildStocksContent(Map<String, dynamic> data) {
    Color stocksColor = Colors.orange;
    if (data.containsKey('filters') && data['filters'] is Map) {
      final filters = data['filters'] as Map<String, dynamic>;
      stocksColor = ReportUtils.isBcolorviewEnabled(filters['bcolorview']) ? Colors.orange : Colors.lightBlue;
    } else if (data.containsKey('bcolorview')) {
      stocksColor = ReportUtils.isBcolorviewEnabled(data['bcolorview']) ? Colors.orange : Colors.lightBlue;
    }
    const dbKey = ''; // Stocks 전용 뷰는 DB 키 없이 하나의 저장소 사용
    if (_stocksColumnWidthsDbKey != dbKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final loaded = await StocksColumnWidthStorage.load(dbKey);
        if (mounted) {
          setState(() {
            _stocksColumnWidthsDbKey = dbKey;
            _stocksColumnWidths = loaded;
          });
        }
      });
    }
    final defaults = {
      for (final col in StocksBuilder.buildColumnDefs()) col.key: col.defaultWidth
    };
    final mergedColumnWidths = Map<String, double>.from(defaults)
      ..addAll(_stocksColumnWidths ?? {});

    final dataList = data['data'] as List? ?? [];

    return ResizableDataTable(
      columns: StocksBuilder.buildColumnDefs(),
      rows: StocksBuilder.buildRows(dataList),
      columnWidths: mergedColumnWidths,
      onColumnResize: (key, newWidth) {
        setState(() {
          _stocksColumnWidths ??= {};
          _stocksColumnWidths![key] = newWidth;
        });
        StocksColumnWidthStorage.save(dbKey, _stocksColumnWidths!);
      },
      sortColumn: _stocksSortColumn,
      sortAscending: _stocksSortAscending,
      onSort: (column, ascending) {
        setState(() {
          _stocksSortColumn = column;
          _stocksSortAscending = ascending;
        });
        _notifyStateChanged();
        _reloadDataWithFilters();
      },
      headerColor: stocksColor,
      isLoadingMore: _isLoadingMoreStocks,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _reportColor),
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
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(l10n.errorOccurred, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadData(),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(backgroundColor: _reportColor, foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }
    if (_data == null || _data!.isEmpty) {
      return Center(child: Text(l10n.noData));
    }
    // AppBar에 필터 바 전달 (post-frame으로 하여 setState during build 방지)
    if (widget.onFilterBarReady != null) {
      final filterBar = _buildAppBarFilterRow();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onFilterBarReady?.call(filterBar);
      });
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth >= 800;
        final showFilterBarInBody = widget.onFilterBarReady == null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showFilterBarInBody)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: _buildAppBarFilterRow(),
              ),
            if (!isLargeScreen) _buildStocksViewType(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadData(),
                child: RepaintBoundary(child: _buildStocksContent(_data!)),
              ),
            ),
          ],
        );
      },
    );
  }

  /// AppBar 하단에 표시할 필터 행 (tipos, temporada, filtering word). onFilterBarReady로 전달.
  Widget _buildAppBarFilterRow() {
    return Row(
      children: [
        if (_tiposList.length > 1) ...[
          Expanded(flex: 1, child: _buildTipoSelector()),
          const SizedBox(width: 8),
        ],
        if (_temporadasList.length > 1) ...[
          Expanded(flex: 1, child: _buildTemporadaSelector()),
          const SizedBox(width: 8),
        ],
        Expanded(flex: 2, child: _buildFilteringWordField()),
      ],
    );
  }
}
